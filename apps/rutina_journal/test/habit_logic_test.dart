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
  });
}
