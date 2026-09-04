import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../services/habit_service.dart';
import '../services/premium_service.dart';
import '../utils/date_utils.dart';

class WidgetSyncService {
  static const String appGroupId = 'group.com.omniverselabs.ritmo';
  static const String androidPulseWidget = 'RitmoPulseWidgetProvider';
  static const String androidBentoWidget = 'RitmoBentoWidgetProvider';

  final HabitService _habitService;
  final PremiumService _premiumService;

  WidgetSyncService(this._habitService, this._premiumService) {
    _init();
  }

  void _init() {
    HomeWidget.setAppGroupId(appGroupId);
    _habitService.addListener(syncWidgets);
    _premiumService.addListener(syncWidgets);
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

      // Common Pulse data
      await HomeWidget.saveWidgetData<int>('pulse_streak', maxStreak);
      await HomeWidget.saveWidgetData<int>('pulse_done_count', doneCount);
      await HomeWidget.saveWidgetData<int>('pulse_total_count', totalCount);
      await HomeWidget.saveWidgetData<String>('circadian_phase', phase);
      await HomeWidget.saveWidgetData<bool>('is_pro', isPro);

      // Top 3 habits for Bento Matrix
      for (int i = 0; i < 3; i++) {
        if (i < habits.length) {
          final h = habits[i];
          final done = _habitService.isCompleted(h.id, dateKey);
          await HomeWidget.saveWidgetData<String>('bento_habit__title', h.title);
          await HomeWidget.saveWidgetData<bool>('bento_habit__done', done);
          await HomeWidget.saveWidgetData<String>('bento_habit__id', h.id);
        } else {
          await HomeWidget.saveWidgetData<String>('bento_habit__title', '');
          await HomeWidget.saveWidgetData<bool>('bento_habit__done', false);
          await HomeWidget.saveWidgetData<String>('bento_habit__id', '');
        }
      }

      // Trigger native widget update
      await HomeWidget.updateWidget(
        name: androidPulseWidget,
        androidName: androidPulseWidget,
      );
      await HomeWidget.updateWidget(
        name: androidBentoWidget,
        androidName: androidBentoWidget,
      );
    } catch (e) {
      if (kDebugMode) {
        print('WidgetSyncService error: ');
      }
    }
  }

  /// Checks if the widget requested an interactive toggle while the app was brought up
  Future<void> handlePendingWidgetLaunch() async {
    try {
      final pendingHabitId = await HomeWidget.getWidgetData<String>('pending_toggle_habit_id');
      if (pendingHabitId != null && pendingHabitId.isNotEmpty) {
        await HomeWidget.saveWidgetData<String>('pending_toggle_habit_id', '');
        await _habitService.toggleHabit(pendingHabitId, DateTime.now());
      }
    } catch (e) {
      if (kDebugMode) {
        print('handlePendingWidgetLaunch error: ');
      }
    }
  }
}
