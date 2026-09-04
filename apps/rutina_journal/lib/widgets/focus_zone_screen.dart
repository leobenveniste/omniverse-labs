import 'dart:async';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/routine.dart';
import '../services/app_services.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/haptics_helper.dart';

class FocusZoneScreen extends StatefulWidget {
  final Routine? routine;

  const FocusZoneScreen({
    super.key,
    this.routine,
  });

  static Future<void> show(BuildContext context, {Routine? routine}) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => FocusZoneScreen(routine: routine),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            child: child,
          );
        },
      ),
    );
  }

  @override
  State<FocusZoneScreen> createState() => _FocusZoneScreenState();
}

class _FocusZoneScreenState extends State<FocusZoneScreen>
    with SingleTickerProviderStateMixin {
  late int _remainingSeconds;
  late int _initialSeconds;
  bool _isRunning = true;
  Timer? _timer;

  // Box Breathing cycle: 4s Inhale, 4s Hold, 4s Exhale, 4s Hold (16s cycle)
  int _boxBreathingTick = 0;
  late AnimationController _breathingAnimController;

  // Routine Step
  int _currentStepIndex = 0;

  @override
  void initState() {
    super.initState();
    final firstStepDuration = widget.routine?.steps.isNotEmpty == true
        ? widget.routine!.steps.first.durationSeconds
        : 10 * 60; // 10 minutes default focus

    _remainingSeconds = firstStepDuration > 0 ? firstStepDuration : 600;
    _initialSeconds = _remainingSeconds;

    // Smooth continuous controller for the 16-second box breathing loop
    _breathingAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();

    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathingAnimController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
          _boxBreathingTick++;
          // Light haptic feedback on phase transitions (every 4 seconds)
          if (_boxBreathingTick % 4 == 0) {
            HapticsHelper.light();
          }
        });
      } else {
        _timer?.cancel();
        setState(() => _isRunning = false);
        _breathingAnimController.stop();
        HapticsHelper.heavy();
        try {
          AppServices.of(context).premiumService.recordFocusSession();
        } catch (_) {}
      }
    });
  }

  void _togglePlayPause() {
    HapticsHelper.selection();
    setState(() {
      _isRunning = !_isRunning;
      if (_isRunning) {
        _breathingAnimController.repeat();
        _startTimer();
      } else {
        _breathingAnimController.stop();
        _timer?.cancel();
      }
    });
  }

  void _adjustTime(int deltaSeconds) {
    HapticsHelper.light();
    setState(() {
      _remainingSeconds = (_remainingSeconds + deltaSeconds).clamp(60, 7200);
      if (_remainingSeconds > _initialSeconds) {
        _initialSeconds = _remainingSeconds;
      }
    });
  }

  void _nextStep() {
    if (widget.routine == null) return;
    if (_currentStepIndex < widget.routine!.steps.length - 1) {
      HapticsHelper.medium();
      setState(() {
        _currentStepIndex++;
        final step = widget.routine!.steps[_currentStepIndex];
        _remainingSeconds = step.durationSeconds;
        _initialSeconds = _remainingSeconds;
      });
    } else {
      HapticsHelper.heavy();
      Navigator.of(context).pop();
    }
  }

  String _formatTime(int totalSecs) {
    final m = totalSecs ~/ 60;
    final s = totalSecs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final theme = Theme.of(context);
    final bgDark = theme.scaffoldBackgroundColor;
    final accentTerracotta = theme.colorScheme.primary;
    final sageMuted = theme.colorScheme.onSurface.withValues(alpha: 0.75);
    final sageSurface = theme.colorScheme.surface;

    final routine = widget.routine;
    final currentStep = routine != null && routine.steps.isNotEmpty
        ? routine.steps[_currentStepIndex]
        : null;

    // Box Breathing Phase Calculation: 0..3 (Inhale), 4..7 (Hold), 8..11 (Exhale), 12..15 (Hold)
    final currentCycleSecond = _boxBreathingTick % 16;
    final int phaseIndex = currentCycleSecond ~/ 4; // 0, 1, 2, 3
    final int phaseCountdown = 4 - (currentCycleSecond % 4);

    String phaseLabel;
    switch (phaseIndex) {
      case 0:
        phaseLabel = l10n.t('boxBreatheInhale');
        break;
      case 1:
        phaseLabel = l10n.t('boxBreatheHold');
        break;
      case 2:
        phaseLabel = l10n.t('boxBreatheExhale');
        break;
      default:
        phaseLabel = l10n.t('boxBreatheHold2');
        break;
    }

    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - AppSpacing.md * 2,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // Top Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                            decoration: BoxDecoration(
                              color: sageSurface,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                              border: Border.all(color: sageMuted.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.spa_rounded, color: accentTerracotta, size: 14),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  l10n.t('focusModeTag'),
                                  style: AppTypography.caption(sageMuted, isMedium: true),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white70),
                            tooltip: l10n.t('actionClose'),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),

                      // Title & Subtitle
                      Text(
                        routine != null ? l10n.t(routine.title) : l10n.t('focusZoneTitle'),
                        textAlign: TextAlign.center,
                        style: AppTypography.display(Colors.white).copyWith(
                          letterSpacing: 0.5,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        currentStep != null
                            ? '${l10n.t('focusStepLabel')} ${_currentStepIndex + 1}: ${currentStep.title}'
                            : l10n.t('boxBreatheGuide'),
                        textAlign: TextAlign.center,
                        style: AppTypography.caption(sageMuted, isMedium: true),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Box Breathing Square Visual (Hero Component)
                      Center(
                        child: AnimatedBuilder(
                          animation: _breathingAnimController,
                          builder: (context, child) {
                            // Scale expands during inhale (0..0.25), stays at peak in hold 1 (0.25..0.5),
                            // contracts during exhale (0.5..0.75), stays compact in hold 2 (0.75..1.0).
                            double scale = 1.0;
                            final val = _breathingAnimController.value;
                            if (val < 0.25) {
                              scale = 0.90 + (val / 0.25) * 0.20; // 0.90 -> 1.10
                            } else if (val < 0.50) {
                              scale = 1.10; // Peak Hold
                            } else if (val < 0.75) {
                              scale = 1.10 - ((val - 0.50) / 0.25) * 0.20; // 1.10 -> 0.90
                            } else {
                              scale = 0.90; // Base Hold
                            }

                            return Transform.scale(
                              scale: _isRunning ? scale : 1.0,
                              child: child,
                            );
                          },
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              color: sageSurface.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                              border: Border.all(
                                color: accentTerracotta.withValues(alpha: _isRunning ? 0.75 : 0.35),
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: accentTerracotta.withValues(alpha: _isRunning ? 0.22 : 0.06),
                                  blurRadius: 36,
                                  spreadRadius: 6,
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Inner geometric guide corner indicators
                                Positioned(
                                  top: 10,
                                  child: Text(
                                    phaseIndex == 0 ? '▲' : '•',
                                    style: TextStyle(
                                      color: phaseIndex == 0 ? accentTerracotta : sageMuted.withValues(alpha: 0.4),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 10,
                                  child: Text(
                                    phaseIndex == 1 ? '▶' : '•',
                                    style: TextStyle(
                                      color: phaseIndex == 1 ? accentTerracotta : sageMuted.withValues(alpha: 0.4),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 10,
                                  child: Text(
                                    phaseIndex == 2 ? '▼' : '•',
                                    style: TextStyle(
                                      color: phaseIndex == 2 ? accentTerracotta : sageMuted.withValues(alpha: 0.4),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 10,
                                  child: Text(
                                    phaseIndex == 3 ? '◀' : '•',
                                    style: TextStyle(
                                      color: phaseIndex == 3 ? accentTerracotta : sageMuted.withValues(alpha: 0.4),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),

                                // Center Phase Label & Countdown
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _isRunning ? phaseLabel : l10n.t('focusPaused'),
                                      textAlign: TextAlign.center,
                                      style: AppTypography.title(Colors.white).copyWith(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    if (_isRunning)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: accentTerracotta.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                        ),
                                        child: Text(
                                          '${phaseCountdown}s',
                                          style: AppTypography.display(accentTerracotta).copyWith(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // General Timer Pill Badge (Compact for session tracking)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: sageSurface,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                          border: Border.all(color: sageMuted.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timer_outlined, color: sageMuted, size: 16),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              _formatTime(_remainingSeconds),
                              style: AppTypography.body(Colors.white, isMedium: true).copyWith(
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Time Adjust & Play / Pause Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Minus 1 min
                          Material(
                            color: sageSurface,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              onTap: () => _adjustTime(-60),
                              child: const Padding(
                                padding: EdgeInsets.all(AppSpacing.sm + 4),
                                child: Icon(Icons.remove_rounded, color: Colors.white70, size: 20),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),

                          // Play / Pause
                          Material(
                            color: accentTerracotta,
                            shape: const CircleBorder(),
                            elevation: 4,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _togglePlayPause,
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Icon(
                                  _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),

                          // Plus 1 min
                          Material(
                            color: sageSurface,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              onTap: () => _adjustTime(60),
                              child: const Padding(
                                padding: EdgeInsets.all(AppSpacing.sm + 4),
                                child: Icon(Icons.add_rounded, color: Colors.white70, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Mindful Neuro Insight Card (Safe wrapped, never overflows)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.sm + 4),
                        decoration: BoxDecoration(
                          color: sageSurface,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(color: sageMuted.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.xs),
                              decoration: BoxDecoration(
                                color: accentTerracotta.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.psychology_rounded, color: accentTerracotta, size: 18),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.t('neuroLinkActiveTitle'),
                                    style: AppTypography.body(Colors.white, isMedium: true),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    l10n.t('neuroLinkActiveBody'),
                                    style: AppTypography.caption(sageMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Bottom Action Button (Next Step or Finish)
                      if (routine != null && routine.steps.isNotEmpty)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentTerracotta,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              ),
                            ),
                            onPressed: _nextStep,
                            icon: Icon(
                              _currentStepIndex < routine.steps.length - 1
                                  ? Icons.arrow_forward_rounded
                                  : Icons.check_circle_outline_rounded,
                            ),
                            label: Text(
                              _currentStepIndex < routine.steps.length - 1
                                  ? l10n.t('focusMarkStepComplete')
                                  : l10n.t('finishRoutine'),
                              style: AppTypography.body(Colors.white, isMedium: true),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
