import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import '../services/habit_service.dart';
import '../services/preferences_service.dart';
import '../services/premium_service.dart';
import '../utils/date_utils.dart';

class WidgetSyncService {
  static const String appGroupId = 'group.com.omniverselabs.ritmo';
  static const String androidPulseWidget = 'RitmoPulseWidgetProvider';
  static const String androidBentoWidget = 'RitmoBentoWidgetProvider';
  static const String androidBreathingWidget = 'RitmoBreathingWidgetProvider';
  static const String androidMiniPulseWidget = 'RitmoMiniPulseWidgetProvider';

  final HabitService _habitService;
  final PremiumService _premiumService;
  final PreferencesService? _preferencesService;

  WidgetSyncService(
    this._habitService,
    this._premiumService, [
    this._preferencesService,
  ]) {
    _init();
  }

  void _init() {
    HomeWidget.setAppGroupId(appGroupId);
    _habitService.addListener(syncWidgets);
    _premiumService.addListener(syncWidgets);
    _preferencesService?.addListener(syncWidgets);
    syncWidgets();
  }

  String _calculateCircadianPhase() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'morning';
    } else if (hour >= 12 && hour < 18) {
      return 'afternoon';
    } else {
      return 'night';
    }
  }

  Future<void> syncWidgets() async {
    try {
      final now = DateTime.now();
      final dateKey = AppDateUtils.toDateKey(now);
      final habits = _habitService.getHabitsForDate(now);
      final doneCount = _habitService.getCompletedCountForDate(now);
      final totalCount = habits.length;
      final maxStreak = habits.fold<int>(0, (max, h) {
        final s = _habitService.calculateStreak(h.id);
        return s.current > max ? s.current : max;
      });

      final phase = _calculateCircadianPhase();
      final isPro = _premiumService.isPro;
      final allCompleted = doneCount >= totalCount && totalCount > 0;
      final hasHabits = totalCount > 0;
      final themePreset = _preferencesService?.themePreset.name ?? 'calmSage';
      final isDark = _preferencesService?.themeMode == ThemeMode.dark;
      final breathingMinutes = _premiumService.todayFocusSessionsCount * 5;

      // Common Widget data
      await HomeWidget.saveWidgetData<int>('pulse_streak', maxStreak);
      await HomeWidget.saveWidgetData<int>('pulse_done_count', doneCount);
      await HomeWidget.saveWidgetData<int>('pulse_total_count', totalCount);
      await HomeWidget.saveWidgetData<bool>('all_completed', allCompleted);
      await HomeWidget.saveWidgetData<bool>('has_habits', hasHabits);
      await HomeWidget.saveWidgetData<String>('circadian_phase', phase);
      await HomeWidget.saveWidgetData<String>('theme_preset', themePreset);
      await HomeWidget.saveWidgetData<bool>('is_dark', isDark);
      await HomeWidget.saveWidgetData<bool>('is_pro', isPro);
      await HomeWidget.saveWidgetData<int>('breathing_minutes', breathingMinutes);

      // Top 3 habits for Bento Matrix (fixed key indexing)
      for (int i = 0; i < 3; i++) {
        final slotIndex = i + 1;
        if (i < habits.length) {
          final h = habits[i];
          final done = _habitService.isCompleted(h.id, dateKey);
          await HomeWidget.saveWidgetData<String>('bento_habit_${slotIndex}_title', h.title);
          await HomeWidget.saveWidgetData<bool>('bento_habit_${slotIndex}_done', done);
          await HomeWidget.saveWidgetData<String>('bento_habit_${slotIndex}_id', h.id);
        } else {
          await HomeWidget.saveWidgetData<String>('bento_habit_${slotIndex}_title', '');
          await HomeWidget.saveWidgetData<bool>('bento_habit_${slotIndex}_done', false);
          await HomeWidget.saveWidgetData<String>('bento_habit_${slotIndex}_id', '');
        }
      }

      // Trigger updates across all native widget providers
      await HomeWidget.updateWidget(
        name: androidPulseWidget,
        androidName: androidPulseWidget,
      );
      await HomeWidget.updateWidget(
        name: androidBentoWidget,
        androidName: androidBentoWidget,
      );
      await HomeWidget.updateWidget(
        name: androidBreathingWidget,
        androidName: androidBreathingWidget,
      );
      await HomeWidget.updateWidget(
        name: androidMiniPulseWidget,
        androidName: androidMiniPulseWidget,
      );
    } catch (e) {
      if (kDebugMode) {
        print('WidgetSyncService error: $e');
      }
    }
  }

  /// Checks and reconciles all pending toggles from the interactive home widget
  Future<void> handlePendingWidgetLaunch() async {
    try {
      final pendingHabitId = await HomeWidget.getWidgetData<String>('pending_toggle_habit_id');
      if (pendingHabitId != null && pendingHabitId.isNotEmpty) {
        await HomeWidget.saveWidgetData<String>('pending_toggle_habit_id', '');
        await _habitService.toggleHabit(pendingHabitId, DateTime.now());
      }

      final pendingBatch = await HomeWidget.getWidgetData<String>('pending_toggle_batch');
      if (pendingBatch != null && pendingBatch.isNotEmpty) {
        await HomeWidget.saveWidgetData<String>('pending_toggle_batch', '');
        final ids = pendingBatch.split(',').where((id) => id.isNotEmpty);
        for (final id in ids) {
          await _habitService.toggleHabit(id, DateTime.now());
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('handlePendingWidgetLaunch error: $e');
      }
    }
  }

  /// Checks if a widget triggered a deep link to open a specific screen (e.g. Focus Zone)
  Future<String?> checkPendingOpenScreen() async {
    try {
      const channel = MethodChannel('com.omniverselabs.ritmo/widgets');
      final screenFromChannel = await channel.invokeMethod<String>('consumePendingOpenScreen');
      if (screenFromChannel != null && screenFromChannel.isNotEmpty) {
        return screenFromChannel;
      }
      final widgetScreen = await HomeWidget.getWidgetData<String>('pending_open_screen');
      if (widgetScreen != null && widgetScreen.isNotEmpty) {
        await HomeWidget.saveWidgetData<String>('pending_open_screen', '');
        return widgetScreen;
      }
    } catch (e) {
      if (kDebugMode) {
        print('checkPendingOpenScreen error: $e');
      }
    }
    return null;
  }
}
