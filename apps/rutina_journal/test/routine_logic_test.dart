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
  });
}
