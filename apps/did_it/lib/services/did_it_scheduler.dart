import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';

import '../l10n/app_strings.dart';
import '../models/did_it_models.dart';
import 'automation_engine.dart';
import 'did_it_storage.dart';

const String kDidItActionDone = 'did_it_done';
const String kDidItActionSnooze = 'did_it_snooze';

/// Signature for incoming foreground/launch notification actions.
typedef NotificationActionCallback = Future<void> Function(
  String itemId,
  String? actionId,
);

/// Handles Android notification action buttons when clicked in a background isolate.
@pragma('vm:entry-point')
Future<void> didItNotificationBackgroundHandler(
  NotificationResponse response,
) async {
  WidgetsFlutterBinding.ensureInitialized();
  final itemId = response.payload;
  if (itemId == null || itemId.isEmpty) return;

  final actionId = response.actionId;
  if (actionId != kDidItActionDone && actionId != kDidItActionSnooze) {
    return;
  }

  final storage = await DidItStorage.open();
  await storage.reload();
  final snapshot = storage.loadSnapshot();
  final now = DateTime.now();
  final strings = AppStrings.of(snapshot.localeCode);
  final scheduler = LocalDidItScheduler();
  await scheduler.init();

  if (actionId == kDidItActionDone) {
    final idx = snapshot.items.indexWhere((i) => i.id == itemId);
    if (idx < 0) return;
    final res = AutomationEngine.applyCompletion(
      items: snapshot.items,
      flows: snapshot.flows,
      itemId: itemId,
      now: now,
      eventId: const Uuid().v4(),
      source: 'notification',
    );
    final updatedHistory = <CompletionEvent>[res.event, ...snapshot.history];
    await storage.saveState(
      items: res.items,
      flows: res.flows,
      history: updatedHistory,
    );
    for (final id in res.rescheduleItemIds) {
      final target = res.items.where((i) => i.id == id).firstOrNull;
      if (target != null) {
        await scheduler.scheduleItem(target, strings: strings);
      }
    }
  } else if (actionId == kDidItActionSnooze) {
    final updatedItems = List<DidItItem>.from(snapshot.items);
    final idx = updatedItems.indexWhere((i) => i.id == itemId);
    if (idx < 0) return;
    final snoozedUntil = now.add(Duration(minutes: snapshot.defaultSnoozeMinutes));
    updatedItems[idx] = updatedItems[idx].copyWith(snoozedUntil: snoozedUntil);
    await storage.saveState(
      items: updatedItems,
      flows: snapshot.flows,
      history: snapshot.history,
    );
    await scheduler.scheduleItem(updatedItems[idx], strings: strings);
  }
}

/// Abstract local reminder scheduler supporting Did It / Snooze actions.
abstract class DidItScheduler {
  Future<void> init({NotificationActionCallback? onAction});
  Future<({String itemId, String? actionId})?> getLaunchAction();
  Future<bool> areNotificationsEnabled();
  Future<bool> requestPermissions();
  Future<void> scheduleItem(DidItItem item, {required AppStrings strings});
  Future<void> cancelItem(String itemId);
}

int notificationIdForItem(String itemId) {
  var hash = 0x811c9dc5;
  for (final codeUnit in itemId.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return (hash % 2000000000) + 1;
}

class LocalDidItScheduler implements DidItScheduler {
  LocalDidItScheduler([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String _channelId = 'did_it_loops';
  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  @override
  Future<void> init({NotificationActionCallback? onAction}) async {
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
        onDidReceiveNotificationResponse: (response) async {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            await onAction?.call(payload, response.actionId);
          }
        },
        onDidReceiveBackgroundNotificationResponse:
            didItNotificationBackgroundHandler,
      );

      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        await androidImpl.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            'DidIt Loops & Chains',
            description: 'Offline repeating action & chain reminders.',
            importance: Importance.high,
          ),
        );
      }
      _initialized = true;
    } catch (e) {
      debugPrint('DidItScheduler init skipped/failed: $e');
    }
  }

  @override
  Future<({String itemId, String? actionId})?> getLaunchAction() async {
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details?.didNotificationLaunchApp ?? false) {
        final payload = details?.notificationResponse?.payload;
        if (payload != null && payload.isNotEmpty) {
          return (
            itemId: payload,
            actionId: details?.notificationResponse?.actionId,
          );
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<bool> areNotificationsEnabled() async {
    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await androidImpl?.areNotificationsEnabled() ?? true;
    } catch (_) {
      return true;
    }
  }

  @override
  Future<bool> requestPermissions() async {
    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final granted = await androidImpl.requestNotificationsPermission();
        return granted ?? false;
      }
      final iosImpl = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosImpl != null) {
        return await iosImpl.requestPermissions(alert: true, sound: true) ??
            false;
      }
    } catch (_) {}
    return false;
  }

  @override
  Future<void> scheduleItem(DidItItem item, {required AppStrings strings}) async {
    final notifId = notificationIdForItem(item.id);
    if (!item.notificationsEnabled) {
      await cancelItem(item.id);
      return;
    }

    final due = item.effectiveDueAt;
    if (due == null) {
      await cancelItem(item.id);
      return;
    }

    final now = DateTime.now();
    if (!due.isAfter(now.add(const Duration(seconds: 5)))) {
      await cancelItem(item.id);
      return;
    }

    try {
      await init();
      final scheduledAt = tz.TZDateTime.from(due, tz.local);
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          strings.notifChannelName,
          channelDescription: strings.notifChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              kDidItActionDone,
              strings.notifActionDone,
              showsUserInterface: false,
              cancelNotification: true,
            ),
            AndroidNotificationAction(
              kDidItActionSnooze,
              strings.notifActionSnooze,
              showsUserInterface: false,
              cancelNotification: true,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true),
      );

      final desc = _repeatDesc(item, strings);
      await _plugin.zonedSchedule(
        notifId,
        item.title,
        strings.notifBodyDue(desc),
        scheduledAt,
        details,
        payload: item.id,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Failed exact schedule for ${item.id}: $e');
      try {
        final scheduledAt = tz.TZDateTime.from(due, tz.local);
        await _plugin.zonedSchedule(
          notifId,
          item.title,
          strings.notifBodyDue(_repeatDesc(item, strings)),
          scheduledAt,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              strings.notifChannelName,
              channelDescription: strings.notifChannelDesc,
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          payload: item.id,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (_) {}
    }
  }

  @override
  Future<void> cancelItem(String itemId) async {
    try {
      await _plugin.cancel(notificationIdForItem(itemId));
    } catch (_) {}
  }

  String _repeatDesc(DidItItem item, AppStrings strings) {
    switch (item.repeatMode) {
      case LoopRepeatMode.fromLastDone:
        return strings.formatMinutesHuman(item.intervalMinutes);
      case LoopRepeatMode.fixedDaily:
        return strings.repeatDaily;
      case LoopRepeatMode.fixedWeekly:
        return strings.repeatWeekly;
      case LoopRepeatMode.fixedMonthly:
        return strings.repeatMonthly;
      case LoopRepeatMode.chainTriggered:
        return strings.repeatChainOnly;
    }
  }
}

/// Deterministic no-op scheduler for fast isolated widget/unit tests.
class NoopDidItScheduler implements DidItScheduler {
  final List<String> scheduledIds = <String>[];
  final List<String> cancelledIds = <String>[];

  @override
  Future<bool> areNotificationsEnabled() async => true;

  @override
  Future<void> cancelItem(String itemId) async {
    cancelledIds.add(itemId);
  }

  @override
  Future<({String itemId, String? actionId})?> getLaunchAction() async => null;

  @override
  Future<void> init({NotificationActionCallback? onAction}) async {}

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<void> scheduleItem(DidItItem item, {required AppStrings strings}) async {
    scheduledIds.add(item.id);
  }
}
