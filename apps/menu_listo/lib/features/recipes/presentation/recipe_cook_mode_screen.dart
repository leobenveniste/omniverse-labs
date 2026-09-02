import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:menu_listo/core/localization/app_localizations.dart';
import 'package:menu_listo/core/utils/culinary_catalog.dart';
import 'package:menu_listo/core/utils/portion_calculator.dart';
import 'package:menu_listo/core/widgets/feature_guide_dialog.dart';
import '../../premium/presentation/paywall_sheet.dart';
import '../../premium/providers/premium_provider.dart';
import '../models/recipe_model.dart';

class RecipeCookModeScreen extends ConsumerStatefulWidget {
  final Recipe recipe;
  final int initialServings;

  const RecipeCookModeScreen({
    super.key,
    required this.recipe,
    required this.initialServings,
  });

  @override
  ConsumerState<RecipeCookModeScreen> createState() => _RecipeCookModeScreenState();
}

class _RecipeCookModeScreenState extends ConsumerState<RecipeCookModeScreen> {
  late int _servings;
  int _currentStepIndex = 0;
  final Set<int> _completedSteps = {};
  final Set<String> _checkedIngredients = {};

  bool _isHandsFree = false;
  String _gestureFeedback = '';
  Timer? _gestureFeedbackTimer;

  // Front camera for Hands-Free motion detection
  CameraController? _cameraController;
  bool _isCameraInitializing = false;
  DateTime _lastGestureTime = DateTime.now();
  List<double>? _prevLeftBrightness;
  List<double>? _prevRightBrightness;
  DateTime? _firstTriggerTime;
  String? _firstTriggerSide; // 'sideA' or 'sideB'

  // Embedded Step Timer
  Timer? _stepTimer;
  int _timerSecondsRemaining = 0;
  int _timerInitialSeconds = 0;
  bool _isTimerRunning = false;

  @override
  void initState() {
    super.initState();
    _servings = widget.initialServings;
    WakelockPlus.enable();
    _initTimerForCurrentStep();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkFirstTimeGuide());
  }

  Future<void> _checkFirstTimeGuide() async {
    final strings = AppStrings.of(context);
    await FeatureGuideDialog.showIfFirstTime(
      context: context,
      prefKey: 'has_seen_guide_cook_mode',
      headerIcon: Icons.soup_kitchen_rounded,
      headerColor: Colors.orangeAccent,
      title: strings.isSpanish ? '¡Bienvenido al Modo Cocina!' : 'Welcome to Cook Mode!',
      subtitle: strings.isSpanish
          ? 'Cocina cómodamente paso a paso con letra grande y manos libres.'
          : 'Cook comfortably step by step with large text and hands-free control.',
      features: [
        FeatureGuideItem(
          icon: Icons.pan_tool_outlined,
          iconColor: Colors.green,
          title: strings.isSpanish ? 'Control Manos Libres por Gestos' : 'Hands-Free Gesture Control',
          description: strings.isSpanish
              ? 'Toca el botón de la mano arriba para activar la cámara: pasa la mano de derecha a izquierda para avanzar de paso, y al revés para retroceder sin manchar la pantalla.'
              : 'Tap the hand icon on top to activate the camera: wave right-to-left for next step, and left-to-right for previous step without touching your screen.',
        ),
        FeatureGuideItem(
          icon: Icons.timer_outlined,
          iconColor: Colors.blueAccent,
          title: strings.isSpanish ? 'Temporizadores Inteligentes' : 'Smart Step Timers',
          description: strings.isSpanish
              ? 'Si un paso requiere tiempo (ej. 15 minutos), el temporizador se configura automáticamente.'
              : 'If a step has a cooking duration (e.g. 15 minutes), the timer configures automatically.',
        ),
        FeatureGuideItem(
          icon: Icons.people_outline_rounded,
          iconColor: Colors.purpleAccent,
          title: strings.isSpanish ? 'Ajuste de Porciones en Vivo' : 'Live Portion Scaling',
          description: strings.isSpanish
              ? 'Usa los botones + y - para ajustar comensales y los ingredientes se recalculan al instante.'
              : 'Use + and - buttons to adjust servings and ingredients will scale on the fly.',
        ),
      ],
    );
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _gestureFeedbackTimer?.cancel();
    _cameraController?.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  void _initTimerForCurrentStep() {
    _stepTimer?.cancel();
    _isTimerRunning = false;

    final steps = widget.recipe.steps;
    if (steps.isEmpty || _currentStepIndex >= steps.length) {
      _timerSecondsRemaining = 0;
      _timerInitialSeconds = 0;
      return;
    }

    final instruction = steps[_currentStepIndex].instruction.toLowerCase();
    int detectedSeconds = 0;

    final hourMatch = RegExp(r'(\d+)\s*(?:hora|horas|hr|hrs|h)\b').firstMatch(instruction);
    final minMatch = RegExp(r'(\d+)\s*(?:minuto|minutos|min|mins|m)\b').firstMatch(instruction);
    final secMatch = RegExp(r'(\d+)\s*(?:segundo|segundos|seg|segs|s)\b').firstMatch(instruction);

    if (hourMatch != null) {
      detectedSeconds += (int.tryParse(hourMatch.group(1)!) ?? 0) * 3600;
    }
    if (minMatch != null) {
      detectedSeconds += (int.tryParse(minMatch.group(1)!) ?? 0) * 60;
    }
    if (secMatch != null) {
      detectedSeconds += (int.tryParse(secMatch.group(1)!) ?? 0);
    }

    setState(() {
      _timerInitialSeconds = detectedSeconds;
      _timerSecondsRemaining = detectedSeconds;
    });
  }

  void _toggleStepTimer() {
    if (_isTimerRunning) {
      _stepTimer?.cancel();
      setState(() => _isTimerRunning = false);
    } else {
      if (_timerSecondsRemaining <= 0) return;
      setState(() => _isTimerRunning = true);
      _stepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        if (_timerSecondsRemaining > 1) {
          setState(() => _timerSecondsRemaining--);
        } else {
          timer.cancel();
          setState(() {
            _timerSecondsRemaining = 0;
            _isTimerRunning = false;
          });
          HapticFeedback.heavyImpact();
          _showTimerAlert();
        }
      });
    }
  }

  void _resetStepTimer() {
    _stepTimer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _timerSecondsRemaining = _timerInitialSeconds;
    });
  }

  void _addMinuteToTimer() {
    setState(() {
      _timerSecondsRemaining += 60;
      if (_timerInitialSeconds == 0) _timerInitialSeconds = 60;
    });
  }

  void _showTimerAlert() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.deepOrange.shade800,
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
        content: const Row(
          children: [
            Icon(Icons.alarm_on, color: Colors.white),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '⏰ ¡Tiempo cumplido para este paso!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleHandsFreeMode() async {
    if (_isHandsFree) {
      await _cameraController?.dispose();
      _cameraController = null;
      setState(() {
        _isHandsFree = false;
        _gestureFeedback = '';
      });
    } else {
      final isPro = ref.read(premiumProvider).isProUser;
      if (!isPro) {
        PaywallSheet.show(context);
        return;
      }

      setState(() => _isCameraInitializing = true);
      try {
        final cameras = await availableCameras();
        final frontCamera = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first,
        );

        _cameraController = CameraController(
          frontCamera,
          ResolutionPreset.low,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.yuv420,
        );

        await _cameraController!.initialize();
        if (!mounted) return;

        setState(() {
          _isHandsFree = true;
          _isCameraInitializing = false;
        });

        _cameraController!.startImageStream(_processCameraFrame);
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isHandsFree = false;
          _isCameraInitializing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo acceder a la cámara frontal: $e')),
        );
      }
    }
  }

  void _processCameraFrame(CameraImage image) {
    if (!_isHandsFree || image.planes.isEmpty) return;

    final now = DateTime.now();
    if (now.difference(_lastGestureTime).inMilliseconds < 1600) {
      return;
    }

    final plane = image.planes[0];
    final bytes = plane.bytes;
    final width = image.width;
    final height = image.height;

    // Portrait mode front-camera frame analysis:
    // In portrait, rows (y) map to the screen's horizontal sweep.
    final midY = height ~/ 2;
    double sideA = 0;
    int countA = 0;
    double sideB = 0;
    int countB = 0;

    for (int y = 0; y < height; y += 4) {
      for (int x = 0; x < width; x += 4) {
        final idx = y * width + x;
        if (idx < bytes.length) {
          final val = bytes[idx].toDouble();
          if (y < midY) {
            sideA += val;
            countA++;
          } else {
            sideB += val;
            countB++;
          }
        }
      }
    }

    final avgA = countA > 0 ? sideA / countA : 0.0;
    final avgB = countB > 0 ? sideB / countB : 0.0;

    if (_prevLeftBrightness == null || _prevRightBrightness == null) {
      _prevLeftBrightness = [avgA];
      _prevRightBrightness = [avgB];
      return;
    }

    final diffA = (avgA - _prevLeftBrightness!.last).abs();
    final diffB = (avgB - _prevRightBrightness!.last).abs();

    _prevLeftBrightness!.add(avgA);
    if (_prevLeftBrightness!.length > 5) _prevLeftBrightness!.removeAt(0);

    _prevRightBrightness!.add(avgB);
    if (_prevRightBrightness!.length > 5) _prevRightBrightness!.removeAt(0);

    // Filter out global uniform ambient shifts (flicker, walking past)
    final diffDiff = (diffA - diffB).abs();
    if (diffDiff < 10.0) return;

    const threshold = 25.0;

    // Optical directional swipe state machine
    if (_firstTriggerSide == null) {
      if (diffB > threshold && diffB > diffA * 1.5) {
        _firstTriggerSide = 'sideB';
        _firstTriggerTime = now;
      } else if (diffA > threshold && diffA > diffB * 1.5) {
        _firstTriggerSide = 'sideA';
        _firstTriggerTime = now;
      }
    } else {
      final elapsed = now.difference(_firstTriggerTime!).inMilliseconds;
      if (elapsed > 700) {
        // Timed out, reset trigger
        _firstTriggerSide = null;
      } else if (elapsed > 100) {
        if (_firstTriggerSide == 'sideB' && diffA > threshold && diffA > diffB * 1.3) {
          // Right-to-Left sweep ➔ Siguiente Paso
          _firstTriggerSide = null;
          _triggerGesture(isNext: true);
        } else if (_firstTriggerSide == 'sideA' && diffB > threshold && diffB > diffA * 1.3) {
          // Left-to-Right sweep ➔ Paso Anterior
          _firstTriggerSide = null;
          _triggerGesture(isNext: false);
        }
      }
    }
  }

  void _triggerGesture({required bool isNext}) {
    _lastGestureTime = DateTime.now();
    HapticFeedback.mediumImpact();
    setState(() {
      _gestureFeedback = isNext ? '👉 Siguiente Paso (Gesto detectado)' : '👈 Paso Anterior (Gesto detectado)';
      if (isNext) {
        _completedSteps.add(_currentStepIndex);
        if (_currentStepIndex < widget.recipe.steps.length - 1) {
          _currentStepIndex++;
          _initTimerForCurrentStep();
        } else {
          _finishCooking();
        }
      } else {
        if (_currentStepIndex > 0) {
          _currentStepIndex--;
          _initTimerForCurrentStep();
        }
      }
    });

    _gestureFeedbackTimer?.cancel();
    _gestureFeedbackTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _gestureFeedback = '');
    });
  }

  void _finishCooking() {
    WakelockPlus.disable();
    _cameraController?.dispose();
    final strings = AppStrings.of(context);
    final title = widget.recipe.title;

    Navigator.of(context).popUntil((route) => route.isFirst);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green.shade800,
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            const Text('🎉', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                strings.isSpanish
                    ? '¡Felicitaciones! Terminaste de cocinar "$title". ¡A disfrutar!'
                    : 'Congratulations! You finished cooking "$title"!',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final steps = widget.recipe.steps;
    final totalSteps = steps.length;
    final currentStep = steps.isNotEmpty && _currentStepIndex < totalSteps ? steps[_currentStepIndex] : null;
    final scalingFactor = _servings / (widget.recipe.baseServings > 0 ? widget.recipe.baseServings : 2);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(strings.cookModeTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: _isCameraInitializing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(_isHandsFree ? Icons.back_hand : Icons.back_hand_outlined),
            tooltip: _isHandsFree ? 'Desactivar Manos Libres' : 'Activar Manos Libres (Cámara frontal)',
            color: _isHandsFree ? Colors.green : null,
            onPressed: () {
              HapticFeedback.lightImpact();
              _toggleHandsFreeMode();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              tween: Tween<double>(
                begin: 0,
                end: totalSteps > 0 ? ((_currentStepIndex + 1) / totalSteps) : 0,
              ),
              builder: (context, val, _) => LinearProgressIndicator(
                value: val,
                minHeight: 6,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
              ),
            ),

            if (_gestureFeedback.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: Colors.green.shade800,
                child: Text(
                  _gestureFeedback,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.04, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: Column(
                    key: ValueKey<int>(_currentStepIndex),
                    children: [
                      if (currentStep != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${strings.step} ${_currentStepIndex + 1} ${strings.ofSteps} $totalSteps',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          child: Padding(
                            padding: const EdgeInsets.all(22.0),
                            child: Column(
                              children: [
                                Text(
                                  currentStep.instruction,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    height: 1.45,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                CheckboxListTile(
                                  value: _completedSteps.contains(_currentStepIndex),
                                  onChanged: (val) {
                                    HapticFeedback.lightImpact();
                                    setState(() {
                                      if (val == true) {
                                        _completedSteps.add(_currentStepIndex);
                                      } else {
                                        _completedSteps.remove(_currentStepIndex);
                                      }
                                    });
                                  },
                                  title: Text(
                                    'Paso completado',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _completedSteps.contains(_currentStepIndex)
                                          ? theme.colorScheme.primary
                                          : null,
                                    ),
                                  ),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ],
                            ),
                          ),
                        ),

                        if (_timerInitialSeconds > 0) ...[
                          const SizedBox(height: 16),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: (_isTimerRunning && _timerSecondsRemaining <= 10 && _timerSecondsRemaining > 0)
                                  ? Colors.orange.withValues(alpha: 0.15)
                                  : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: (_isTimerRunning && _timerSecondsRemaining <= 10 && _timerSecondsRemaining > 0)
                                    ? Colors.deepOrange
                                    : (_isTimerRunning ? theme.colorScheme.primary : theme.colorScheme.outline.withValues(alpha: 0.3)),
                                width: _isTimerRunning ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.timer,
                                      color: _isTimerRunning ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatDuration(_timerSecondsRemaining),
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: _timerSecondsRemaining == 0
                                            ? Colors.red
                                            : theme.colorScheme.onSurface,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    FilledButton.icon(
                                      onPressed: _timerSecondsRemaining > 0
                                          ? () {
                                              HapticFeedback.mediumImpact();
                                              _toggleStepTimer();
                                            }
                                          : null,
                                      icon: Icon(_isTimerRunning ? Icons.pause : Icons.play_arrow),
                                      label: Text(_isTimerRunning ? 'Pausar' : 'Iniciar Temporizador'),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        HapticFeedback.lightImpact();
                                        _resetStepTimer();
                                      },
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Reiniciar'),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton.filledTonal(
                                      tooltip: '+1 minuto',
                                      icon: const Icon(Icons.more_time),
                                      onPressed: () {
                                        HapticFeedback.lightImpact();
                                        _addMinuteToTimer();
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.25)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.inventory_2_outlined, size: 18, color: theme.colorScheme.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${strings.ingredientsTitle} ($_servings ${strings.persons})',
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${_checkedIngredients.length}/${widget.recipe.ingredients.length} listos',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...widget.recipe.ingredients.map((ing) {
                                if (ing.isSectionHeader) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 10, bottom: 4),
                                    child: Text(
                                      ing.name.endsWith(':') ? ing.name : '${ing.name}:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  );
                                }

                                final scaledIng = ing.scale(scalingFactor);
                                final isChecked = _checkedIngredients.contains(ing.id);
                                final emoji = CulinaryCatalog.getEmoji(ing.name);

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: InkWell(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      setState(() {
                                        if (isChecked) {
                                          _checkedIngredients.remove(ing.id);
                                        } else {
                                          _checkedIngredients.add(ing.id);
                                        }
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isChecked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                            color: isChecked ? Colors.green : theme.colorScheme.outline,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(emoji, style: const TextStyle(fontSize: 18)),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              PortionCalculator.formatIngredientDisplay(
                                                amount: scaledIng.amount,
                                                unit: scaledIng.unit,
                                                name: scaledIng.name,
                                              ),
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                decoration: isChecked ? TextDecoration.lineThrough : null,
                                                color: isChecked
                                                    ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                                                    : theme.colorScheme.onSurface,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(top: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _currentStepIndex > 0
                          ? () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _currentStepIndex--;
                                _initTimerForCurrentStep();
                              });
                            }
                          : null,
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: Text(strings.previousStep),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        setState(() {
                          _completedSteps.add(_currentStepIndex);
                          if (_currentStepIndex < totalSteps - 1) {
                            _currentStepIndex++;
                            _initTimerForCurrentStep();
                          } else {
                            HapticFeedback.heavyImpact();
                            _finishCooking();
                          }
                        });
                      },
                      icon: Icon(_currentStepIndex == totalSteps - 1 ? Icons.check_circle_rounded : Icons.arrow_forward_rounded),
                      label: Text(_currentStepIndex == totalSteps - 1
                          ? (strings.isSpanish ? '¡Listo!' : 'Done!')
                          : strings.nextStep),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    final mStr = minutes.toString().padLeft(2, '0');
    final sStr = seconds.toString().padLeft(2, '0');

    if (hours > 0) {
      final hStr = hours.toString().padLeft(2, '0');
      return '$hStr:$mStr:$sStr';
    }
    return '$mStr:$sStr';
  }
}
