import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/routine.dart';
import 'storage_service.dart';
import 'habit_service.dart';

class RoutineService extends ChangeNotifier {
  final StorageService _storage;
  final HabitService _habitService;
  final Uuid _uuid = const Uuid();

  List<Routine> _routines = [];
  bool _isLoading = true;

  // Active runner state
  Routine? _activeRoutine;
  int _activeStepIndex = 0;
  int _secondsRemaining = 0;
  bool _isRunning = false;
  Timer? _timer;

  RoutineService(this._storage, this._habitService) {
    load();
  }

  bool get isLoading => _isLoading;
  List<Routine> get routines => _routines;
  Routine? get activeRoutine => _activeRoutine;
  int get activeStepIndex => _activeStepIndex;
  int get secondsRemaining => _secondsRemaining;
  bool get isRunning => _isRunning;

  RoutineStep? get currentStep {
    if (_activeRoutine == null || _activeRoutine!.steps.isEmpty) return null;
    if (_activeStepIndex >= _activeRoutine!.steps.length) return null;
    return _activeRoutine!.steps[_activeStepIndex];
  }

  double get stepProgress {
    final step = currentStep;
    if (step == null || step.durationSeconds == 0) return 1.0;
    final elapsed = step.durationSeconds - _secondsRemaining;
    return (elapsed / step.durationSeconds).clamp(0.0, 1.0);
  }

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    _routines = await _storage.loadRoutines();
    if (_routines.isEmpty) {
      _initDefaultRoutines();
      await _storage.saveRoutines(_routines);
    }

    _isLoading = false;
    notifyListeners();
  }

  void _initDefaultRoutines() {
    _routines = [
      Routine(
        id: _uuid.v4(),
        title: 'routineMorning',
        description: 'routineMorningDesc',
        reminderTime: '07:00',
        reminderEnabled: true,
        steps: [
          RoutineStep(
            id: _uuid.v4(),
            title: 'Hidratación y luz natural',
            durationSeconds: 180,
            description: 'Bebe un vaso grande de agua fresca y abre las cortinas.',
          ),
          RoutineStep(
            id: _uuid.v4(),
            title: 'Movilidad y respiración',
            durationSeconds: 300,
            description: '5 minutos de estiramientos suaves y respiraciones conscientes.',
          ),
          RoutineStep(
            id: _uuid.v4(),
            title: 'Definir 3 prioridades del día',
            durationSeconds: 300,
            description: 'Elige las tres tareas esenciales para una jornada productiva.',
          ),
        ],
      ),
      Routine(
        id: _uuid.v4(),
        title: 'routineEvening',
        description: 'routineEveningDesc',
        reminderTime: '21:30',
        reminderEnabled: true,
        steps: [
          RoutineStep(
            id: _uuid.v4(),
            title: 'Desconexión digital',
            durationSeconds: 120,
            description: 'Pon tu teléfono en modo descanso lejos de la cama.',
          ),
          RoutineStep(
            id: _uuid.v4(),
            title: 'Lectura o audio relajante',
            durationSeconds: 600,
            description: 'Lee un capítulo o escucha música tranquila sin pantallas.',
          ),
          RoutineStep(
            id: _uuid.v4(),
            title: 'Reflexión y gratitud',
            durationSeconds: 180,
            description: 'Agradece tres momentos positivos del día.',
          ),
        ],
      ),
      Routine(
        id: _uuid.v4(),
        title: 'routineWork',
        description: 'routineWorkDesc',
        reminderTime: '18:00',
        steps: [
          RoutineStep(
            id: _uuid.v4(),
            title: 'Bandeja de entrada a cero',
            durationSeconds: 300,
            description: 'Archiva, responde rápido o programa correos pendientes.',
          ),
          RoutineStep(
            id: _uuid.v4(),
            title: 'Planificar la mañana siguiente',
            durationSeconds: 300,
            description: 'Deja listo el primer paso de mañana para arrancar con foco.',
          ),
          RoutineStep(
            id: _uuid.v4(),
            title: 'Cierre mental y desconexión',
            durationSeconds: 60,
            description: 'Cierra tu laptop y respira hondo: la jornada concluyó.',
          ),
        ],
      ),
    ];
  }

  // --- RUNNER CONTROLS ---
  void startRoutine(Routine routine) {
    _activeRoutine = routine;
    _activeStepIndex = 0;
    _secondsRemaining = routine.steps.isNotEmpty ? routine.steps.first.durationSeconds : 0;
    _isRunning = true;
    _startTimer();
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        _secondsRemaining--;
        notifyListeners();
      } else {
        // Step finished
        nextStep();
      }
    });
  }

  void togglePauseResume() {
    if (_isRunning) {
      _timer?.cancel();
      _isRunning = false;
    } else {
      _isRunning = true;
      _startTimer();
    }
    notifyListeners();
  }

  void nextStep() {
    if (_activeRoutine == null) return;
    if (_activeStepIndex + 1 < _activeRoutine!.steps.length) {
      _activeStepIndex++;
      _secondsRemaining = _activeRoutine!.steps[_activeStepIndex].durationSeconds;
      notifyListeners();
    } else {
      // Finished routine!
      finishRoutine();
    }
  }

  void prevStep() {
    if (_activeRoutine == null || _activeStepIndex == 0) return;
    _activeStepIndex--;
    _secondsRemaining = _activeRoutine!.steps[_activeStepIndex].durationSeconds;
    notifyListeners();
  }

  Future<void> finishRoutine() async {
    _timer?.cancel();
    _isRunning = false;

    // Auto-complete tied habits for today
    if (_activeRoutine != null) {
      final now = DateTime.now();
      for (final habitId in _activeRoutine!.tiedHabitIds) {
        if (!_habitService.isCompleted(habitId, '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}')) {
          await _habitService.toggleHabit(habitId, now);
        }
      }
    }

    _activeRoutine = null;
    _activeStepIndex = 0;
    _secondsRemaining = 0;
    notifyListeners();
  }

  void stopRoutine() {
    _timer?.cancel();
    _isRunning = false;
    _activeRoutine = null;
    _activeStepIndex = 0;
    _secondsRemaining = 0;
    notifyListeners();
  }

  Future<void> addRoutine(Routine routine) async {
    _routines.add(routine);
    await _storage.saveRoutines(_routines);
    notifyListeners();
  }

  Future<void> deleteRoutine(String routineId) async {
    _routines.removeWhere((r) => r.id == routineId);
    await _storage.saveRoutines(_routines);
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
