import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rutina_journal/models/routine.dart';
import 'package:rutina_journal/services/habit_service.dart';
import 'package:rutina_journal/services/notification_service.dart';
import 'package:rutina_journal/services/routine_service.dart';
import 'package:rutina_journal/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;
  late HabitService habitService;
  late RoutineService routineService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storage = StorageService(prefs);
    final notif = NotificationService();
    habitService = HabitService(storage, notif);
    routineService = RoutineService(storage, habitService, notif);
    await routineService.load();
  });

  group('RoutineService Logic Tests', () {
    test('Initializes with default routines (Morning, Evening, Work, Deep Focus, Midday Reset, Workout)', () {
      expect(routineService.routines.length, 6);
      final morning = routineService.routines.first;
      expect(morning.steps.length, 3);
      expect(morning.totalMinutes, 13);
    });

    test('Can start and step through a routine', () {
      final morning = routineService.routines.first;
      routineService.startRoutine(morning);

      expect(routineService.activeRoutine, morning);
      expect(routineService.activeStepIndex, 0);
      expect(routineService.isRunning, isTrue);

      routineService.nextStep();
      expect(routineService.activeStepIndex, 1);

      routineService.prevStep();
      expect(routineService.activeStepIndex, 0);

      routineService.stopRoutine();
      expect(routineService.activeRoutine, isNull);
      expect(routineService.isRunning, isFalse);
    });

    test('Can add, update, and delete custom routines with reminders', () async {
      final newRoutine = Routine(
        id: 'test_routine_1',
        title: 'Deep Work Sprint',
        description: 'Focus session',
        iconName: 'laptop_mac',
        reminderTime: '09:00',
        reminderEnabled: true,
        steps: const [
          RoutineStep(id: 's1', title: 'Prepare workspace', durationSeconds: 120),
          RoutineStep(id: 's2', title: 'Deep coding', durationSeconds: 1500),
        ],
      );

      await routineService.addRoutine(newRoutine);
      expect(routineService.routines.length, 7);
      expect(routineService.routines.any((r) => r.id == 'test_routine_1'), isTrue);
      expect(routineService.routines.firstWhere((r) => r.id == 'test_routine_1').reminderEnabled, isTrue);
      expect(routineService.routines.firstWhere((r) => r.id == 'test_routine_1').reminderTime, '09:00');

      final updated = newRoutine.copyWith(title: 'Deep Work Sprint 2.0', reminderEnabled: false);
      await routineService.updateRoutine(updated);
      expect(routineService.routines.firstWhere((r) => r.id == 'test_routine_1').title, 'Deep Work Sprint 2.0');
      expect(routineService.routines.firstWhere((r) => r.id == 'test_routine_1').reminderEnabled, isFalse);

      await routineService.deleteRoutine('test_routine_1');
      expect(routineService.routines.length, 6);
      expect(routineService.routines.any((r) => r.id == 'test_routine_1'), isFalse);
    });
    test('Can extend step time and calculate dynamic completion time', () {
      final morning = routineService.routines.first;
      routineService.startRoutine(morning);

      expect(routineService.nextUpcomingStep, isNotNull);
      expect(routineService.nextUpcomingStep!.id, morning.steps[1].id);

      final initialRemaining = routineService.totalRoutineSecondsRemaining;
      final initialStepRemaining = routineService.secondsRemaining;
      final estFinish = routineService.estimatedCompletionTime;
      expect(estFinish, isNotNull);

      // Extend step by 60 seconds
      routineService.extendCurrentStepTime(60);
      expect(routineService.secondsRemaining, initialStepRemaining + 60);
      expect(routineService.totalRoutineSecondsRemaining, initialRemaining + 60);

      // Extend step by 120 seconds
      routineService.extendCurrentStepTime(120);
      expect(routineService.secondsRemaining, initialStepRemaining + 180);
      expect(routineService.totalRoutineSecondsRemaining, initialRemaining + 180);

      routineService.stopRoutine();
      expect(routineService.estimatedCompletionTime, isNull);
      expect(routineService.nextUpcomingStep, isNull);
    });

    test('Deleted default routine does not re-appear when reloading routines', () async {
      expect(routineService.routines.length, 6);
      final morning = routineService.routines.firstWhere((r) => r.title == 'routineMorning');
      await routineService.deleteRoutine(morning.id);

      expect(routineService.routines.length, 5);
      expect(routineService.routines.any((r) => r.title == 'routineMorning'), isFalse);

      // Simulate app restart by calling load() or instantiating a new RoutineService
      await routineService.load();

      expect(routineService.routines.length, 5);
      expect(routineService.routines.any((r) => r.title == 'routineMorning'), isFalse);
    });

    test('Deleting all routines preserves empty list after reloading routines', () async {
      expect(routineService.routines.length, 6);
      final routineIds = routineService.routines.map((r) => r.id).toList();
      for (final id in routineIds) {
        await routineService.deleteRoutine(id);
      }

      expect(routineService.routines.isEmpty, isTrue);

      // Simulate app restart
      await routineService.load();
      expect(routineService.routines.isEmpty, isTrue);
    });

    test('Deleting currently active routine stops the routine runner', () async {
      final morning = routineService.routines.first;
      routineService.startRoutine(morning);
      expect(routineService.isRunning, isTrue);
      expect(routineService.activeRoutine, isNotNull);

      await routineService.deleteRoutine(morning.id);
      expect(routineService.isRunning, isFalse);
      expect(routineService.activeRoutine, isNull);
    });
  });
}
