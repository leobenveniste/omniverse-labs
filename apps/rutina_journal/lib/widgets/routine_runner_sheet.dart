import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/app_services.dart';
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
    final audio = AppServices.of(context).audioService;
    if (audio.isSoundEnabled) {
      audio.playRoutineAmbient();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AnimatedBuilder(
        animation: service,
        builder: (ctx, _) => RoutineRunnerSheet(routineService: service),
      ),
    ).whenComplete(() {
      audio.stopAmbient();
    });
  }

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatClockTime(DateTime time, BuildContext context) {
    final use24Hour = MediaQuery.of(context).alwaysUse24HourFormat;
    final hour = use24Hour ? time.hour : (time.hour % 12 == 0 ? 12 : time.hour % 12);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = use24Hour ? '' : (time.hour >= 12 ? ' PM' : ' AM');
    return '$hour:$minute$period';
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
    final finishTime = routineService.estimatedCompletionTime;
    final upNext = routineService.nextUpcomingStep;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Column(
        children: [
          // Header Bar with close & step counter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: l10n.t('actionClose'),
                onPressed: () {
                  HapticsHelper.light();
                  routineService.stopRoutine();
                  Navigator.of(context).pop();
                },
              ),
              // Dynamic finish time anchor badge
              if (finishTime != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(
                        l10n.t('finishEstimate', args: {'time': _formatClockTime(finishTime, context)}),
                        style: AppTypography.caption(theme.colorScheme.onPrimaryContainer, isMedium: true),
                      ),
                    ],
                  ),
                ),
              Text(
                l10n.t('routineStepCounter', args: {
                  'current': '${stepIndex + 1}',
                  'total': '$totalSteps',
                }),
                style: AppTypography.caption(theme.colorScheme.onSurface.withValues(alpha: 0.7), isMedium: true),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

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
                width: 176,
                height: 176,
                child: CircularProgressIndicator(
                  value: routineService.stepProgress,
                  strokeWidth: 8,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  color: theme.colorScheme.primary,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(routineService.secondsRemaining),
                    style: AppTypography.display(theme.colorScheme.onSurface).copyWith(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (routineService.isRunning) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      routine.title.startsWith('routine') ? l10n.t(routine.title) : routine.title,
                      style: AppTypography.caption(theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Quick extension buffer chips (+1 min / +2 min)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ActionChip(
                avatar: const Icon(Icons.add_rounded, size: 14),
                label: Text(l10n.t('addOneMin')),
                labelStyle: AppTypography.caption(theme.colorScheme.primary, isMedium: true),
                backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
                side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                onPressed: () {
                  HapticsHelper.light();
                  routineService.extendCurrentStepTime(60);
                },
              ),
              const SizedBox(width: AppSpacing.sm),
              ActionChip(
                avatar: const Icon(Icons.add_rounded, size: 14),
                label: Text(l10n.t('addTwoMin')),
                labelStyle: AppTypography.caption(theme.colorScheme.primary, isMedium: true),
                backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
                side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                onPressed: () {
                  HapticsHelper.light();
                  routineService.extendCurrentStepTime(120);
                },
              ),
            ],
          ),
          const Spacer(),

          // Next upcoming step preview
          if (upNext != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      l10n.t('upNext', args: {'step': upNext.title}),
                      style: AppTypography.caption(
                        theme.colorScheme.onSurface.withValues(alpha: 0.75),
                        isMedium: true,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '(${(upNext.durationSeconds / 60).ceil()}m)',
                    style: AppTypography.caption(
                      theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Timer Controls (Prev, Pause / Play, Next)
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
          const SizedBox(height: AppSpacing.md),

          // Bottom Primary Action
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
