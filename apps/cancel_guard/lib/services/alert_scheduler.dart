import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../l10n/app_strings.dart';
import '../models/guarded_item.dart';

/// Abstraction for scheduling and cancelling local "Cancel By" buffer alerts.
abstract class AlertScheduler {
  Future<void> init({void Function(String itemId)? onTapItem});
  Future<String?> getLaunchItemId();
  Future<bool> areNotificationsEnabled();
  Future<bool> requestPermissions();
  Future<void> scheduleForItem(
    GuardedItem item, {
    required String currency,
    required AppStrings strings,
  });
  Future<void> cancelForItem(GuardedItem item);
}

/// Deterministic notification ID pair derived from [GuardedItem.id].
int notificationIdForStage(String itemId, int stageIndex) {
  var hash = 0x811c9dc5;
  for (final codeUnit in itemId.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return ((hash % 100000000) * 10) + stageIndex;
}

/// Device local notification scheduler using `flutter_local_notifications`.
class LocalAlertScheduler implements AlertScheduler {
  LocalAlertScheduler([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String _channelId = 'cancel_guard_buffers';
  static const String _channelName = 'Cancel-By Alerts';
  static const String _channelDesc =
      'Buffer reminders 24h to 7d before a free trial or renewal charges.';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  @override
  Future<void> init({void Function(String itemId)? onTapItem}) async {
    if (_initialized) return;
    try {
      tz.initializeTimeZones();

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      await _plugin.initialize(
        const InitializationSettings(android: androidInit, iOS: darwinInit),
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            onTapItem?.call(payload);
          }
        },
      );

      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        await androidImpl.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDesc,
            importance: Importance.high,
          ),
        );
      }
      _initialized = true;
    } catch (e) {
      debugPrint('AlertScheduler init skipped/failed: $e');
    }
  }

  @override
  Future<String?> getLaunchItemId() async {
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details?.didNotificationLaunchApp ?? false) {
        final payload = details?.notificationResponse?.payload;
        if (payload != null && payload.isNotEmpty) return payload;
      }
    } catch (e) {
      debugPrint('Failed to inspect launch notification details: $e');
    }
    return null;
  }

  @override
  Future<bool> areNotificationsEnabled() async {
    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        return await androidImpl.areNotificationsEnabled() ?? true;
      }
    } catch (e) {
      debugPrint('Failed to check notification permission: $e');
    }
    return true;
  }

  @override
  Future<bool> requestPermissions() async {
    if (!_initialized) await init();
    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final granted = await androidImpl.requestNotificationsPermission();
        await androidImpl.requestExactAlarmsPermission();
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('Permission request error: $e');
    }
    return true;
  }

  @override
  Future<void> scheduleForItem(
    GuardedItem item, {
    required String currency,
    required AppStrings strings,
  }) async {
    if (!_initialized) await init();
    await cancelForItem(item);

    if (item.status != ItemStatus.active) return;

    final now = DateTime.now();
    final alertTimes = item.scheduledAlertTimes();

    for (var i = 0; i < alertTimes.length; i++) {
      final triggerAt = alertTimes[i];
      if (!triggerAt.isAfter(now)) continue;

      final leadHours = item.alertPreset.hoursBefore[i];
      final amountLabel = strings.formatMoney(currency, item.amount);
      final title = leadHours <= 24
          ? (strings.isEs
              ? '¡Último aviso! Cancela ${item.name} hoy'
              : 'Final Warning: Cancel ${item.name} today')
          : (strings.isEs
              ? 'Aviso ${leadHours}h: ${item.name} renovará pronto'
              : '${leadHours}h Heads-Up: ${item.name} renews soon');
      final body = strings.isEs
          ? 'Evita el cargo de $amountLabel. Toca aquí para abrir el link de cancelación.'
          : 'Avoid the $amountLabel charge. Tap to open your Cancel Escape Hatch.';

      final scheduledTz = tz.TZDateTime.fromMillisecondsSinceEpoch(
        tz.UTC,
        triggerAt.millisecondsSinceEpoch,
      );

      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
      );

      final id = notificationIdForStage(item.id, i);
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          scheduledTz,
          details,
          payload: item.id,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (_) {
        try {
          await _plugin.zonedSchedule(
            id,
            title,
            body,
            scheduledTz,
            details,
            payload: item.id,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        } catch (e) {
          debugPrint('Failed to schedule alert $id: $e');
        }
      }
    }
  }

  @override
  Future<void> cancelForItem(GuardedItem item) async {
    try {
      for (var stage = 0; stage < 4; stage++) {
        await _plugin.cancel(notificationIdForStage(item.id, stage));
      }
    } catch (e) {
      debugPrint('Failed to cancel notifications for ${item.id}: $e');
    }
  }
}

/// No-op scheduler used cleanly in unit and widget tests.
class NoopAlertScheduler implements AlertScheduler {
  final Set<String> scheduledIds = {};
  bool notificationsEnabled = true;

  @override
  Future<bool> areNotificationsEnabled() async => notificationsEnabled;

  @override
  Future<void> cancelForItem(GuardedItem item) async {
    scheduledIds.remove(item.id);
  }

  @override
  Future<String?> getLaunchItemId() async => null;

  @override
  Future<void> init({void Function(String itemId)? onTapItem}) async {}

  @override
  Future<bool> requestPermissions() async {
    notificationsEnabled = true;
    return true;
  }

  @override
  Future<void> scheduleForItem(
    GuardedItem item, {
    required String currency,
    required AppStrings strings,
  }) async {
    if (item.status == ItemStatus.active) {
      scheduledIds.add(item.id);
    }
  }
}
