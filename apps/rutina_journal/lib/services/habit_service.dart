import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/habit.dart';
import '../models/habit_category.dart';
import '../models/habit_log.dart';
import '../utils/date_utils.dart';
import 'storage_service.dart';
import 'notification_service.dart';

class HabitService extends ChangeNotifier {
  final StorageService _storage;
  final NotificationService _notificationService;
  final Uuid _uuid = const Uuid();

  List<Habit> _habits = [];
  Map<String, HabitLog> _logs = {}; // Key: "${habitId}_${dateKey}"

  bool _isLoading = true;

  HabitService(this._storage, this._notificationService) {
    load();
  }

  bool get isLoading => _isLoading;
  List<Habit> get habits => _habits.where((h) => !h.archived).toList();
  List<Habit> get allHabits => _habits;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    _habits = await _storage.loadHabits();
    final rawLogs = await _storage.loadHabitLogs();
    _logs = {
      for (final log in rawLogs) '${log.habitId}_${log.dateKey}': log,
    };

    _isLoading = false;
    notifyListeners();
  }

  String _makeLogKey(String habitId, String dateKey) => '${habitId}_$dateKey';

  HabitLog? getLog(String habitId, String dateKey) {
    return _logs[_makeLogKey(habitId, dateKey)];
  }

  bool isCompleted(String habitId, String dateKey) {
    final log = getLog(habitId, dateKey);
    return log?.completed ?? false;
  }

  double getCurrentValue(String habitId, String dateKey) {
    final log = getLog(habitId, dateKey);
    return log?.currentValue ?? 0.0;
  }

  List<Habit> getHabitsForDate(DateTime date) {
    final weekday = date.weekday;
    return habits.where((h) => h.isScheduledForWeekday(weekday)).toList();
  }

  int getCompletedCountForDate(DateTime date) {
    final dateKey = AppDateUtils.toDateKey(date);
    final scheduled = getHabitsForDate(date);
    return scheduled.where((h) => isCompleted(h.id, dateKey)).length;
  }

  double getCompletionRateForDate(DateTime date) {
    final scheduled = getHabitsForDate(date);
    if (scheduled.isEmpty) return 0.0;
    final done = getCompletedCountForDate(date);
    return done / scheduled.length;
  }

  // Toggle boolean or mark complete/incomplete
  Future<void> toggleHabit(String habitId, DateTime date) async {
    final habit = _habits.firstWhere((h) => h.id == habitId);
    final dateKey = AppDateUtils.toDateKey(date);
    final key = _makeLogKey(habitId, dateKey);
    final existing = _logs[key];

    final willBeCompleted = !(existing?.completed ?? false);
    final newValue = willBeCompleted ? habit.targetValue : 0.0;

    final updatedLog = HabitLog(
      id: existing?.id ?? _uuid.v4(),
      habitId: habitId,
      dateKey: dateKey,
      currentValue: newValue,
      completed: willBeCompleted,
      completedAt: willBeCompleted ? DateTime.now() : null,
      note: existing?.note,
    );

    _logs[key] = updatedLog;
    notifyListeners();
    await _persistLogs();
  }

  // Update numeric counter habits
  Future<void> updateCounter(String habitId, DateTime date, double delta) async {
    final habit = _habits.firstWhere((h) => h.id == habitId);
    final dateKey = AppDateUtils.toDateKey(date);
    final key = _makeLogKey(habitId, dateKey);
    final existing = _logs[key];

    final current = existing?.currentValue ?? 0.0;
    final next = (current + delta).clamp(0.0, 999999.0);
    final isDone = next >= habit.targetValue;

    final updatedLog = HabitLog(
      id: existing?.id ?? _uuid.v4(),
      habitId: habitId,
      dateKey: dateKey,
      currentValue: next,
      completed: isDone,
      completedAt: isDone ? (existing?.completedAt ?? DateTime.now()) : null,
      note: existing?.note,
    );

    _logs[key] = updatedLog;
    notifyListeners();
    await _persistLogs();
  }

  // Calculate streaks: current streak and best streak
  ({int current, int best}) calculateStreak(String habitId) {
    final habit = _habits.firstWhere(
      (h) => h.id == habitId,
      orElse: () => Habit(
        id: habitId,
        title: '',
        category: HabitCategory.health,
        createdAt: DateTime.now(),
      ),
    );

    final now = DateTime.now();
    var checkDate = DateTime(now.year, now.month, now.day);
    var currentStreak = 0;
    var bestStreak = 0;
    var runningStreak = 0;

    // Check backwards from today for current streak
    final todayKey = AppDateUtils.toDateKey(checkDate);
    final completedToday = isCompleted(habitId, todayKey);
    final scheduledToday = habit.isScheduledForWeekday(checkDate.weekday);

    if (completedToday) {
      currentStreak++;
      runningStreak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    } else if (!scheduledToday) {
      // If not scheduled today, check from yesterday
      checkDate = checkDate.subtract(const Duration(days: 1));
    } else {
      // Not completed today: streak isn't broken yet if checking from yesterday
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    if (runningStreak > bestStreak) bestStreak = runningStreak;

    // Continue counting consecutive past scheduled days
    var streakBroken = false;
    for (int i = 0; i < 365; i++) {
      final dateKey = AppDateUtils.toDateKey(checkDate);
      final isScheduled = habit.isScheduledForWeekday(checkDate.weekday);

      if (isScheduled) {
        if (isCompleted(habitId, dateKey)) {
          if (!streakBroken) currentStreak++;
          runningStreak++;
          if (runningStreak > bestStreak) bestStreak = runningStreak;
        } else {
          streakBroken = true;
          runningStreak = 0;
        }
      }
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    if (currentStreak > bestStreak) bestStreak = currentStreak;
    return (current: currentStreak, best: bestStreak);
  }

  // Heatmap: completion rate per day over the past N days
  Map<DateTime, double> getHeatmapData(int daysCount) {
    final days = AppDateUtils.getPastDays(daysCount);
    final result = <DateTime, double>{};
    for (final day in days) {
      result[day] = getCompletionRateForDate(day);
    }
    return result;
  }

  // Create Habit
  Future<void> addHabit({
    required String title,
    required HabitCategory category,
    HabitType type = HabitType.boolean,
    double targetValue = 1.0,
    String unit = '',
    List<int> frequencyDays = const [1, 2, 3, 4, 5, 6, 7],
    String? reminderTime,
    bool reminderEnabled = false,
  }) async {
    final newHabit = Habit(
      id: _uuid.v4(),
      title: title.trim(),
      category: category,
      type: type,
      targetValue: targetValue,
      unit: unit.trim(),
      frequencyDays: frequencyDays,
      reminderTime: reminderTime,
      reminderEnabled: reminderEnabled,
      createdAt: DateTime.now(),
    );

    _habits.add(newHabit);
    await _storage.saveHabits(_habits);
    _scheduleHabitReminderIfNeeded(newHabit);
    notifyListeners();
  }

  // Update Habit
  Future<void> updateHabit(Habit updated) async {
    final index = _habits.indexWhere((h) => h.id == updated.id);
    if (index >= 0) {
      _habits[index] = updated;
      await _storage.saveHabits(_habits);
      _scheduleHabitReminderIfNeeded(updated);
      notifyListeners();
    }
  }

  // Delete Habit
  Future<void> deleteHabit(String habitId) async {
    _habits.removeWhere((h) => h.id == habitId);
    _logs.removeWhere((key, _) => key.startsWith('${habitId}_'));
    await _storage.saveHabits(_habits);
    await _persistLogs();
    _notificationService.cancel(habitId.hashCode);
    notifyListeners();
  }

  void _scheduleHabitReminderIfNeeded(Habit habit) {
    final id = habit.id.hashCode;
    if (habit.reminderEnabled && habit.reminderTime != null) {
      final parts = habit.reminderTime!.split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]) ?? 8;
        final minute = int.tryParse(parts[1]) ?? 0;
        _notificationService.scheduleDaily(
          id: id,
          channelId: 'habit_reminders',
          channelName: 'Recordatorios de Hábitos',
          title: habit.title,
          body: 'Momento para tu hábito: ${habit.title}',
          hour: hour,
          minute: minute,
        );
      }
    } else {
      _notificationService.cancel(id);
    }
  }

  Future<void> _persistLogs() async {
    await _storage.saveHabitLogs(_logs.values.toList());
  }

  // Seed sample starter habits for quick evaluation
  Future<void> loadSampleData() async {
    final samples = [
      Habit(
        id: _uuid.v4(),
        title: 'Hidratación Matutina (500ml)',
        category: HabitCategory.health,
        type: HabitType.counter,
        targetValue: 500,
        unit: 'ml',
        frequencyDays: [1, 2, 3, 4, 5, 6, 7],
        reminderTime: '07:30',
        reminderEnabled: true,
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
      ),
      Habit(
        id: _uuid.v4(),
        title: 'Lectura Reflexiva',
        category: HabitCategory.personal,
        type: HabitType.counter,
        targetValue: 20,
        unit: 'págs',
        frequencyDays: [1, 2, 3, 4, 5, 6, 7],
        reminderTime: '21:00',
        reminderEnabled: true,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      Habit(
        id: _uuid.v4(),
        title: 'Meditation & Breathwork',
        category: HabitCategory.mind,
        type: HabitType.boolean,
        frequencyDays: [1, 2, 3, 4, 5, 6, 7],
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
      Habit(
        id: _uuid.v4(),
        title: 'Caminar 30 Minutos al Aire Libre',
        category: HabitCategory.health,
        type: HabitType.boolean,
        frequencyDays: [1, 2, 3, 4, 5],
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
      Habit(
        id: _uuid.v4(),
        title: 'Evitar Pantallas 30m Antes de Dormir',
        category: HabitCategory.sleep,
        type: HabitType.boolean,
        frequencyDays: [1, 2, 3, 4, 5, 6, 7],
        createdAt: DateTime.now().subtract(const Duration(days: 12)),
      ),
    ];

    for (final s in samples) {
      _habits.add(s);
      // Simulate historical logs over past 7 days
      for (int d = 1; d <= 7; d++) {
        final date = DateTime.now().subtract(Duration(days: d));
        if (d % 2 == 0 || d < 4) {
          final dateKey = AppDateUtils.toDateKey(date);
          final key = _makeLogKey(s.id, dateKey);
          _logs[key] = HabitLog(
            id: _uuid.v4(),
            habitId: s.id,
            dateKey: dateKey,
            currentValue: s.targetValue,
            completed: true,
            completedAt: date,
          );
        }
      }
    }

    await _storage.saveHabits(_habits);
    await _persistLogs();
    notifyListeners();
  }
}
