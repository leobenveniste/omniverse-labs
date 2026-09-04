import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/routine_service.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/haptics_helper.dart';
import 'state_button.dart';

class RoutineRunnerSheet extends StatelessWidget {
  final RoutineService routineService;

  const RoutineRunnerSheet({
    super.key,
    required this.routineService,
  });

  static void show(BuildContext context, RoutineService service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AnimatedBuilder(
        animation: service,
        builder: (ctx, _) => RoutineRunnerSheet(routineService: service),
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final routine = routineService.activeRoutine;
    final step = routineService.currentStep;

    if (routine == null || step == null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.celebration_rounded, size: 64, color: Colors.amber),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.t('congratsRoutine'),
              style: AppTypography.section(theme.colorScheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.lg),
            StateButton(
              label: l10n.t('actionClose'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }

    final stepIndex = routineService.activeStepIndex;
    final totalSteps = routine.steps.length;
    final progress = (stepIndex + 1) / totalSteps;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          // Header Bar with close
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: l10n.t('actionClose'),
                onPressed: () {
                  routineService.stopRoutine();
                  Navigator.of(context).pop();
                },
              ),
              Text(
                l10n.t('routineStepCounter', args: {
                  'current': '${stepIndex + 1}',
                  'total': '$totalSteps',
                }),
                style: AppTypography.caption(theme.colorScheme.onSurface.withValues(alpha: 0.7), isMedium: true),
              ),
              const SizedBox(width: 48), // spacer balance
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Overall routine progress bar
          LinearProgressIndicator(
            value: progress,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(4),
          ),
          const Spacer(),

          // Step Title
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: AppTypography.display(theme.colorScheme.onSurface),
          ),
          if (step.description != null && step.description!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              step.description!,
              textAlign: TextAlign.center,
              style: AppTypography.body(theme.colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
          ],
          const Spacer(),

          // Large Circular Countdown Timer
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 180,
                height: 180,
                child: CircularProgressIndicator(
                  value: routineService.stepProgress,
                  strokeWidth: 8,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  color: theme.colorScheme.primary,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                _formatTime(routineService.secondsRemaining),
                style: AppTypography.display(theme.colorScheme.onSurface).copyWith(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),

          // Timer Controls (Pause / Play, Next, Prev)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                iconSize: 24,
                icon: const Icon(Icons.skip_previous_rounded),
                tooltip: l10n.t('prevStep'),
                onPressed: stepIndex > 0
                    ? () {
                        HapticsHelper.light();
                        routineService.prevStep();
                      }
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),
              IconButton.filled(
                iconSize: 36,
                icon: Icon(
                  routineService.isRunning
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                ),
                onPressed: () {
                  HapticsHelper.medium();
                  routineService.togglePauseResume();
                },
              ),
              const SizedBox(width: AppSpacing.md),
              IconButton.filledTonal(
                iconSize: 24,
                icon: const Icon(Icons.skip_next_rounded),
                tooltip: l10n.t('nextStep'),
                onPressed: () {
                  HapticsHelper.light();
                  if (stepIndex + 1 == totalSteps) {
                    routineService.finishRoutine();
                  } else {
                    routineService.nextStep();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Bottom Action
          StateButton(
            label: stepIndex + 1 == totalSteps
                ? l10n.t('finishRoutine')
                : l10n.t('nextStep'),
            onPressed: () {
              if (stepIndex + 1 == totalSteps) {
                routineService.finishRoutine();
              } else {
                routineService.nextStep();
              }
            },
          ),
        ],
      ),
    );
  }
}
