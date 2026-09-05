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
      _routines = _buildDefaultRoutines();
      await _storage.saveRoutines(_routines);
    } else {
      // Seamlessly merge new default routines if not already added
      final existingTitles = _routines.map((r) => r.title).toSet();
      final defaults = _buildDefaultRoutines();
      bool modified = false;
      // Ensure existing default routines have their specialized icons updated
      final defaultIconMap = {
        for (final d in defaults) d.title: d.iconName,
      };
      _routines = _routines.map((r) {
        if (defaultIconMap.containsKey(r.title) && r.iconName != defaultIconMap[r.title]) {
          modified = true;
          return r.copyWith(iconName: defaultIconMap[r.title]);
        }
        return r;
      }).toList();

      for (final def in defaults) {
        if (!existingTitles.contains(def.title)) {
          _routines.add(def);
          modified = true;
        }
      }
      if (modified) {
        await _storage.saveRoutines(_routines);
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  List<Routine> _buildDefaultRoutines() {
    return [
      Routine(
        id: _uuid.v4(),
        title: 'routineMorning',
        description: 'routineMorningDesc',
        iconName: 'wb_sunny',
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
        iconName: 'nightlight_round',
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
        iconName: 'laptop_mac',
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
      Routine(
        id: _uuid.v4(),
        title: 'routineDeepFocus',
        description: 'routineDeepFocusDesc',
        iconName: 'center_focus_strong',
        reminderTime: '10:00',
        steps: [
          RoutineStep(
            id: _uuid.v4(),
            title: 'Preparar entorno y silenciar distracciones',
            durationSeconds: 120,
            description: 'Pon el móvil boca abajo, llena tu vaso de agua y cierra pestañas innecesarias.',
          ),
          RoutineStep(
            id: _uuid.v4(),
            title: 'Definir objetivo único del bloque',
            durationSeconds: 60,
            description: 'Escribe en una frase clara el entregable tangible de esta sesión.',
          ),
          RoutineStep(
            id: _uuid.v4(),
            title: 'Sesión de trabajo profundo (Deep Work)',
            durationSeconds: 1500,
            description: 'Foco total e ininterrumpido en una sola tarea de alto valor.',
          ),
        ],
      ),
      Routine(
        id: _uuid.v4(),
        title: 'routineMiddayReset',
        description: 'routineMiddayResetDesc',
        iconName: 'coffee',
        reminderTime: '14:00',
        steps: [
          RoutineStep(
            id: _uuid.v4(),
            title: 'Movilidad de cuello, hombros y espalda',
            durationSeconds: 180,
            description: 'Descomprime la postura sentada con rotaciones lentas y estiramientos suaves.',
          ),
          RoutineStep(
            id: _uuid.v4(),
            title: 'Hidratación y mirada al horizonte',
            durationSeconds: 60,
            description: 'Bebe agua y relaja la vista mirando un punto lejano por la ventana.',
          ),
          RoutineStep(
            id: _uuid.v4(),
            title: 'Respiración consciente y calma',
            durationSeconds: 180,
            description: 'Oxigena tu mente con respiraciones profundas para reiniciar tu tarde.',
          ),
        ],
      ),
      Routine(
        id: _uuid.v4(),
        title: 'routineWorkoutWarmup',
        description: 'routineWorkoutWarmupDesc',
        iconName: 'fitness_center',
        reminderTime: '18:30',
        steps: [
          RoutineStep(
            id: _uuid.v4(),
            title: 'Música motivacional e hidratación',
            durationSeconds: 120,
            description: 'Activa tu playlist energética y prepara tu botella de agua.',
          ),
          RoutineStep(
            id: _uuid.v4(),
            title: 'Movilidad articular dinámica',
            durationSeconds: 240,
            description: 'Círculos de tobillos, caderas, hombros y elevaciones de rodillas.',
          ),
          RoutineStep(
            id: _uuid.v4(),
            title: 'Enfoque mental y visualización',
            durationSeconds: 60,
            description: 'Visualiza la intensidad y los objetivos de tu entrenamiento de hoy.',
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

  Future<void> updateRoutine(Routine routine) async {
    final index = _routines.indexWhere((r) => r.id == routine.id);
    if (index != -1) {
      _routines[index] = routine;
      await _storage.saveRoutines(_routines);
      notifyListeners();
    }
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
