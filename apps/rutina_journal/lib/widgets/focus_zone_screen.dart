import 'dart:async';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/routine.dart';
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

  // Breathing Guide Animation
  late AnimationController _breathingController;
  late Animation<double> _breathingScale;

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

    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _breathingScale = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOutSine),
    );

    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathingController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _timer?.cancel();
        setState(() => _isRunning = false);
        HapticsHelper.heavy();
      }
    });
  }

  void _togglePlayPause() {
    HapticsHelper.selection();
    setState(() {
      _isRunning = !_isRunning;
      if (_isRunning) {
        _breathingController.repeat(reverse: true);
        _startTimer();
      } else {
        _breathingController.stop();
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

    // Deep immersive calm forest palette
    const bgDark = Color(0xFF131A15);
    const accentTerracotta = Color(0xFFE07A5F);
    const sageMuted = Color(0xFFA5B8AB);
    const sageSurface = Color(0xFF1E2821);

    final routine = widget.routine;
    final currentStep = routine != null && routine.steps.isNotEmpty
        ? routine.steps[_currentStepIndex]
        : null;

    final progress = _initialSeconds > 0
        ? (_initialSeconds - _remainingSeconds) / _initialSeconds
        : 1.0;

    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
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
                        const Icon(Icons.spa_rounded, color: accentTerracotta, size: 14),
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
              const SizedBox(height: AppSpacing.md),

              // Title & Sequence Description
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
                    : l10n.t('focusZoneSubtitle'),
                textAlign: TextAlign.center,
                style: AppTypography.caption(sageMuted, isMedium: true),
              ),
              const Spacer(),

              // Circular Breathing & Focus Progress Indicator
              Center(
                child: AnimatedBuilder(
                  animation: _breathingScale,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isRunning ? _breathingScale.value : 1.0,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accentTerracotta.withValues(alpha: _isRunning ? 0.15 : 0.05),
                          blurRadius: 36,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Track background
                        const SizedBox(
                          width: 210,
                          height: 210,
                          child: CircularProgressIndicator(
                            value: 1.0,
                            strokeWidth: 8,
                            color: sageSurface,
                          ),
                        ),
                        // Active Progress
                        SizedBox(
                          width: 210,
                          height: 210,
                          child: CircularProgressIndicator(
                            value: (1.0 - progress).clamp(0.0, 1.0),
                            strokeWidth: 8,
                            strokeCap: StrokeCap.round,
                            color: accentTerracotta,
                          ),
                        ),
                        // Center Time & Breathing Prompt
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTime(_remainingSeconds),
                              style: AppTypography.display(Colors.white).copyWith(
                                fontSize: 38,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              _isRunning ? l10n.t('breathingInhaleExhale') : l10n.t('focusPaused'),
                              style: AppTypography.caption(sageMuted, isMedium: true),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

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
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: Icon(Icons.remove_rounded, color: Colors.white70, size: 22),
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
                        padding: const EdgeInsets.all(AppSpacing.md + 2),
                        child: Icon(
                          _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 32,
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
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: Icon(Icons.add_rounded, color: Colors.white70, size: 22),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),

              // Mindful Neuro Insight Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: sageSurface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: sageMuted.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: accentTerracotta.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.psychology_rounded, color: accentTerracotta, size: 20),
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
  }
}
