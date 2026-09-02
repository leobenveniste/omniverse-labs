import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:menu_listo/core/localization/app_localizations.dart';
import 'package:menu_listo/core/utils/culinary_catalog.dart';
import 'package:menu_listo/core/utils/portion_calculator.dart';
import '../models/recipe_model.dart';

class RecipeCookModeScreen extends StatefulWidget {
  final Recipe recipe;
  final int initialServings;

  const RecipeCookModeScreen({
    super.key,
    required this.recipe,
    required this.initialServings,
  });

  @override
  State<RecipeCookModeScreen> createState() => _RecipeCookModeScreenState();
}

class _RecipeCookModeScreenState extends State<RecipeCookModeScreen> {
  late int _servings;
  int _currentStepIndex = 0;
  final Set<int> _completedSteps = {};
  final Set<String> _checkedIngredients = {};

  bool _isLargeFont = false;
  bool _isHandsFree = false;
  String _gestureFeedback = '';
  Timer? _gestureFeedbackTimer;

  // Front camera for Hands-Free motion detection
  CameraController? _cameraController;
  bool _isCameraInitializing = false;
  DateTime _lastGestureTime = DateTime.now();
  List<double>? _prevLeftBrightness;
  List<double>? _prevRightBrightness;
  DateTime? _firstHalfTriggerTime;
  String? _firstHalfTriggerSide; // 'left' or 'right'

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

    // Detect minutes: e.g. "15 minutos", "10 min", "20 mins", "1/2 hora"
    final minMatch = RegExp(r'(\d+)\s*(?:minutos?|mins?|min)\b').firstMatch(instruction);
    final hourMatch = RegExp(r'(\d+)\s*(?:horas?|hrs?|hs?|h)\b').firstMatch(instruction);
    final secMatch = RegExp(r'(\d+)\s*(?:segundos?|segs?|seg)\b').firstMatch(instruction);

    if (minMatch != null) {
      detectedSeconds += (int.tryParse(minMatch.group(1)!) ?? 0) * 60;
    }
    if (hourMatch != null) {
      detectedSeconds += (int.tryParse(hourMatch.group(1)!) ?? 0) * 3600;
    }
    if (secMatch != null) {
      detectedSeconds += int.tryParse(secMatch.group(1)!) ?? 0;
    }

    setState(() {
      _timerSecondsRemaining = detectedSeconds;
      _timerInitialSeconds = detectedSeconds;
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
        if (_timerSecondsRemaining > 1) {
          setState(() => _timerSecondsRemaining--);
        } else {
          timer.cancel();
          setState(() {
            _timerSecondsRemaining = 0;
            _isTimerRunning = false;
          });
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
      _timerInitialSeconds += 60;
    });
  }

  void _showTimerAlert() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.deepOrange,
        duration: const Duration(seconds: 5),
        content: const Row(
          children: [
            Icon(Icons.alarm_on, color: Colors.white, size: 28),
            SizedBox(width: 12),
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
      // Turn off
      await _cameraController?.dispose();
      _cameraController = null;
      setState(() {
        _isHandsFree = false;
        _gestureFeedback = '';
      });
    } else {
      // Turn on
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
    if (now.difference(_lastGestureTime).inMilliseconds < 1200) {
      return; // Cooldown between gesture steps
    }

    final plane = image.planes[0];
    final bytes = plane.bytes;
    final width = image.width;
    final height = image.height;

    // Sample pixels across left and right halves
    double leftSum = 0;
    int leftCount = 0;
    double rightSum = 0;
    int rightCount = 0;

    final midX = width ~/ 2;
    // Step by 4 for fast zero-lag optical difference
    for (int y = 0; y < height; y += 4) {
      for (int x = 0; x < width; x += 4) {
        final idx = y * width + x;
        if (idx < bytes.length) {
          final val = bytes[idx].toDouble();
          if (x < midX) {
            leftSum += val;
            leftCount++;
          } else {
            rightSum += val;
            rightCount++;
          }
        }
      }
    }

    final leftAvg = leftCount > 0 ? leftSum / leftCount : 0.0;
    final rightAvg = rightCount > 0 ? rightSum / rightCount : 0.0;

    if (_prevLeftBrightness == null || _prevRightBrightness == null) {
      _prevLeftBrightness = [leftAvg];
      _prevRightBrightness = [rightAvg];
      return;
    }

    final leftDiff = (leftAvg - _prevLeftBrightness!.last).abs();
    final rightDiff = (rightAvg - _prevRightBrightness!.last).abs();

    _prevLeftBrightness!.add(leftAvg);
    if (_prevLeftBrightness!.length > 5) _prevLeftBrightness!.removeAt(0);

    _prevRightBrightness!.add(rightAvg);
    if (_prevRightBrightness!.length > 5) _prevRightBrightness!.removeAt(0);

    const threshold = 18.0;

    // Optical wave state machine
    if (_firstHalfTriggerSide == null) {
      if (rightDiff > threshold && rightDiff > leftDiff * 1.5) {
        _firstHalfTriggerSide = 'right';
        _firstHalfTriggerTime = now;
      } else if (leftDiff > threshold && leftDiff > rightDiff * 1.5) {
        _firstHalfTriggerSide = 'left';
        _firstHalfTriggerTime = now;
      }
    } else {
      final elapsed = now.difference(_firstHalfTriggerTime!).inMilliseconds;
      if (elapsed > 700) {
        // Timed out
        _firstHalfTriggerSide = null;
      } else if (elapsed > 100) {
        // Check if other side swept
        if (_firstHalfTriggerSide == 'right' && leftDiff > threshold) {
          // Right-to-Left sweep ➔ Next Step!
          _triggerGesture(isNext: true);
          _firstHalfTriggerSide = null;
        } else if (_firstHalfTriggerSide == 'left' && rightDiff > threshold) {
          // Left-to-Right sweep ➔ Previous Step!
          _triggerGesture(isNext: false);
          _firstHalfTriggerSide = null;
        }
      }
    }
  }

  void _triggerGesture({required bool isNext}) {
    _lastGestureTime = DateTime.now();
    setState(() {
      _gestureFeedback = isNext ? '👉 Siguiente Paso (Gesto detectado)' : '👈 Paso Anterior (Gesto detectado)';
      if (isNext) {
        _completedSteps.add(_currentStepIndex);
        if (_currentStepIndex < widget.recipe.steps.length - 1) {
          _currentStepIndex++;
          _initTimerForCurrentStep();
        } else {
          _showFinishedDialog(context);
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.cookModeTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Icon(Icons.lock_clock, size: 12, color: theme.colorScheme.primary),
                const SizedBox(width: 4),
                Text(strings.cookModeWakeLockNotice, style: theme.textTheme.labelSmall),
              ],
            ),
          ],
        ),
        actions: [
          // Font size toggle
          IconButton(
            icon: Icon(_isLargeFont ? Icons.text_decrease : Icons.text_increase),
            tooltip: _isLargeFont ? 'Tamaño normal' : 'Letra grande (Modo mostrador)',
            onPressed: () => setState(() => _isLargeFont = !_isLargeFont),
          ),
          // Hands-free motion toggle
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
            // Progress Bar with smooth tween animation
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

            // Hands-free gesture feedback banner
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
              )
            else if (_isHandsFree)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                color: Colors.green.withValues(alpha: 0.15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.back_hand, size: 14, color: Colors.green),
                    const SizedBox(width: 6),
                    Text(
                      strings.isSpanish
                          ? 'Manos Libres Activo: Pasa la mano frente a la pantalla'
                          : 'Hands-Free Active: Wave hand in front of camera',
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ],
                ),
              ),

            // FIXED ALWAYS-VISIBLE INGREDIENT LIST (WITHOUT DIVIDERS)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        '${strings.ingredientsTitle} ($_servings ${strings.persons})',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_checkedIngredients.length}/${widget.recipe.ingredients.length} listos',
                        style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 48,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.recipe.ingredients.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final ing = widget.recipe.ingredients[index];
                        final scaledIng = ing.scale(scalingFactor);
                        final isChecked = _checkedIngredients.contains(ing.id);
                        final emoji = CulinaryCatalog.getEmoji(ing.name);

                        return InkWell(
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
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isChecked
                                  ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                                  : theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isChecked
                                    ? Colors.transparent
                                    : theme.colorScheme.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(emoji, style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 6),
                                Text(
                                  PortionCalculator.formatIngredientDisplay(
                                    amount: scaledIng.amount,
                                    unit: scaledIng.unit,
                                    name: scaledIng.name,
                                  ),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    decoration: isChecked ? TextDecoration.lineThrough : null,
                                    color: isChecked
                                        ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                                if (isChecked) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.check_circle, size: 14, color: Colors.green),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // STEP INSTRUCTION & TIMER BODY
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
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
                        // Step Number Badge
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

                        // Step Instruction Card (without dividers)
                        Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                Text(
                                  currentStep.instruction,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontSize: _isLargeFont ? 26 : 20,
                                    fontWeight: FontWeight.w600,
                                    height: 1.5,
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

                        // Embedded Step Timer (if duration detected)
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
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // NAVIGATION BUTTONS
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
                      icon: const Icon(Icons.arrow_back),
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
                            _showFinishedDialog(context);
                          }
                        });
                      },
                      icon: Icon(_currentStepIndex == totalSteps - 1 ? Icons.check_circle : Icons.arrow_forward),
                      label: Text(_currentStepIndex == totalSteps - 1 ? strings.finishCooking : strings.nextStep),
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

  void _showFinishedDialog(BuildContext context) {
    final strings = AppStrings.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Text('🎉', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 10),
            Text(strings.isSpanish ? '¡Felicitaciones!' : 'Congratulations!'),
          ],
        ),
        content: Text(
          strings.isSpanish
              ? '¡Has completado todos los pasos de ${widget.recipe.title}! ¡A disfrutar tu comida!'
              : 'You completed all steps for ${widget.recipe.title}! Enjoy your meal!',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: Text(strings.finishCooking),
          ),
        ],
      ),
    );
  }
}
