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
    routineService = RoutineService(storage, habitService);
    await routineService.load();
  });

  group('RoutineService Logic Tests', () {
    test('Initializes with default routines (Morning, Evening, Work)', () {
      expect(routineService.routines.length, 3);
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

    test('Can add, update, and delete custom routines', () async {
      final newRoutine = Routine(
        id: 'test_routine_1',
        title: 'Deep Work Sprint',
        description: 'Focus session',
        iconName: 'laptop_mac',
        steps: const [
          RoutineStep(id: 's1', title: 'Prepare workspace', durationSeconds: 120),
          RoutineStep(id: 's2', title: 'Deep coding', durationSeconds: 1500),
        ],
      );

      await routineService.addRoutine(newRoutine);
      expect(routineService.routines.length, 4);
      expect(routineService.routines.any((r) => r.id == 'test_routine_1'), isTrue);

      final updated = newRoutine.copyWith(title: 'Deep Work Sprint 2.0');
      await routineService.updateRoutine(updated);
      expect(routineService.routines.firstWhere((r) => r.id == 'test_routine_1').title, 'Deep Work Sprint 2.0');

      await routineService.deleteRoutine('test_routine_1');
      expect(routineService.routines.length, 3);
      expect(routineService.routines.any((r) => r.id == 'test_routine_1'), isFalse);
    });
  });
}
