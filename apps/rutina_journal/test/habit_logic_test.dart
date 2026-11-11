import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rutina_journal/models/habit.dart';
import 'package:rutina_journal/models/habit_category.dart';
import 'package:rutina_journal/services/habit_service.dart';
import 'package:rutina_journal/services/notification_service.dart';
import 'package:rutina_journal/services/storage_service.dart';
import 'package:rutina_journal/utils/date_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;
  late NotificationService notif;
  late HabitService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storage = StorageService(prefs);
    notif = NotificationService();
    service = HabitService(storage, notif);
    await service.load();
  });

  group('HabitService Logic Tests', () {
    test('Can create, retrieve, and toggle boolean habit', () async {
      await service.addHabit(
        title: 'Meditar',
        category: HabitCategory.mind,
        type: HabitType.boolean,
      );

      expect(service.habits.length, 1);
      final habit = service.habits.first;
      expect(habit.title, 'Meditar');

      final now = DateTime.now();
      final dateKey = AppDateUtils.toDateKey(now);

      expect(service.isCompleted(habit.id, dateKey), isFalse);

      await service.toggleHabit(habit.id, now);
      expect(service.isCompleted(habit.id, dateKey), isTrue);

      await service.toggleHabit(habit.id, now);
      expect(service.isCompleted(habit.id, dateKey), isFalse);
    });

    test('Can increment and complete counter habits', () async {
      await service.addHabit(
        title: 'Agua',
        category: HabitCategory.health,
        type: HabitType.counter,
        targetValue: 2000,
        unit: 'ml',
      );

      final habit = service.habits.first;
      final now = DateTime.now();
      final dateKey = AppDateUtils.toDateKey(now);

      await service.updateCounter(habit.id, now, 500);
      expect(service.getCurrentValue(habit.id, dateKey), 500);
      expect(service.isCompleted(habit.id, dateKey), isFalse);

      await service.updateCounter(habit.id, now, 1500);
      expect(service.getCurrentValue(habit.id, dateKey), 2000);
      expect(service.isCompleted(habit.id, dateKey), isTrue);
    });

    test('Calculates streaks accurately across consecutive days', () async {
      await service.addHabit(
        title: 'Lectura',
        category: HabitCategory.personal,
      );

      final habit = service.habits.first;
      final now = DateTime.now();

      // Today completed
      await service.toggleHabit(habit.id, now);

      var streak = service.calculateStreak(habit.id);
      expect(streak.current, 1);
      expect(streak.best, 1);

      // Yesterday completed
      final yesterday = now.subtract(const Duration(days: 1));
      await service.toggleHabit(habit.id, yesterday);

      streak = service.calculateStreak(habit.id);
      expect(streak.current, 2);
      expect(streak.best, 2);
    });

    test('Can explicitly set habit completion state idempotently', () async {
      await service.addHabit(
        title: 'Caminar',
        category: HabitCategory.health,
      );

      final habit = service.habits.first;
      final now = DateTime.now();
      final dateKey = AppDateUtils.toDateKey(now);

      // Set true
      await service.setHabitCompletion(habit.id, now, true);
      expect(service.isCompleted(habit.id, dateKey), isTrue);

      // Idempotent call
      await service.setHabitCompletion(habit.id, now, true);
      expect(service.isCompleted(habit.id, dateKey), isTrue);

      // Set false
      await service.setHabitCompletion(habit.id, now, false);
      expect(service.isCompleted(habit.id, dateKey), isFalse);
    });

    test('Can create and filter daily, weekly, and monthly habits', () async {
      await service.addHabit(
        title: 'Diario 1',
        category: HabitCategory.productivity,
        frequencyType: HabitFrequencyType.daily,
      );
      await service.addHabit(
        title: 'Gimnasio',
        category: HabitCategory.health,
        frequencyType: HabitFrequencyType.weekly,
        frequencyTarget: 3,
      );
      await service.addHabit(
        title: 'Finanzas',
        category: HabitCategory.finance,
        frequencyType: HabitFrequencyType.monthly,
        frequencyTarget: 1,
      );

      final now = DateTime.now();
      expect(service.getDailyHabits(now).length, 1);
      expect(service.getWeeklyHabits().length, 1);
      expect(service.getMonthlyHabits().length, 1);

      final weeklyHabit = service.getWeeklyHabits().first;
      expect(weeklyHabit.frequencyTarget, 3);
      expect(weeklyHabit.frequencyType, HabitFrequencyType.weekly);

      final monthlyHabit = service.getMonthlyHabits().first;
      expect(monthlyHabit.frequencyTarget, 1);
      expect(monthlyHabit.frequencyType, HabitFrequencyType.monthly);
    });

    test('Tracks weekly progress and calculates weekly streaks', () async {
      await service.addHabit(
        title: 'Crossfit',
        category: HabitCategory.health,
        frequencyType: HabitFrequencyType.weekly,
        frequencyTarget: 2,
      );

      final habit = service.getWeeklyHabits().first;
      final now = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));

      var progress = service.getWeeklyProgress(habit.id, now);
      expect(progress.completed, 0);
      expect(progress.target, 2);
      expect(progress.isMet, isFalse);

      // Complete on Monday
      await service.setHabitCompletion(habit.id, monday, true);
      progress = service.getWeeklyProgress(habit.id, now);
      expect(progress.completed, 1);
      expect(progress.isMet, isFalse);

      // Complete on Tuesday (target reached!)
      await service.setHabitCompletion(habit.id, monday.add(const Duration(days: 1)), true);
      progress = service.getWeeklyProgress(habit.id, now);
      expect(progress.completed, 2);
      expect(progress.isMet, isTrue);

      // Current week reached -> streak is 1
      var streak = service.calculateStreak(habit.id);
      expect(streak.current, 1);

      // Previous week also completed 2 days
      final lastMonday = monday.subtract(const Duration(days: 7));
      await service.setHabitCompletion(habit.id, lastMonday, true);
      await service.setHabitCompletion(habit.id, lastMonday.add(const Duration(days: 1)), true);

      streak = service.calculateStreak(habit.id);
      expect(streak.current, 2);
      expect(streak.best, 2);
    });

    test('Tracks monthly progress and calculates monthly streaks', () async {
      await service.addHabit(
        title: 'Ahorro e Inversión',
        category: HabitCategory.finance,
        frequencyType: HabitFrequencyType.monthly,
        frequencyTarget: 1,
      );

      final habit = service.getMonthlyHabits().first;
      final now = DateTime.now();
      final firstDayThisMonth = DateTime(now.year, now.month, 1);

      var progress = service.getMonthlyProgress(habit.id, now);
      expect(progress.completed, 0);
      expect(progress.isMet, isFalse);

      // Complete today
      await service.setHabitCompletion(habit.id, firstDayThisMonth, true);
      progress = service.getMonthlyProgress(habit.id, now);
      expect(progress.completed, 1);
      expect(progress.isMet, isTrue);

      var streak = service.calculateStreak(habit.id);
      expect(streak.current, 1);

      // Complete previous month
      final prevMonthDate = DateTime(now.year, now.month - 1, 1);
      await service.setHabitCompletion(habit.id, prevMonthDate, true);

      streak = service.calculateStreak(habit.id);
      expect(streak.current, 2);
      expect(streak.best, 2);
    });

    test('Habit model parses legacy JSON with full backward compatibility', () {
      final legacyJson = {
        'id': 'legacy-id-123',
        'title': 'Hábito Antiguo',
        'category': 'health',
        'type': 'boolean',
        'targetValue': 1.0,
        'unit': '',
        'frequencyDays': [1, 2, 3, 4, 5],
        'createdAt': '2026-01-01T00:00:00.000',
        'archived': false,
      };

      final parsed = Habit.fromJson(legacyJson);
      expect(parsed.frequencyType, HabitFrequencyType.daily);
      expect(parsed.frequencyTarget, 5); // From frequencyDays.length
      expect(parsed.isScheduledForWeekday(1), isTrue);
      expect(parsed.isScheduledForWeekday(6), isFalse);

      final serialized = parsed.toJson();
      expect(serialized['frequencyType'], 'daily');
      expect(serialized['frequencyTarget'], 5);
    });
  });
}
