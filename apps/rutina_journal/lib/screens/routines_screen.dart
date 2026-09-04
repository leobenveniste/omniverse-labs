import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/routine.dart';
import '../services/routine_service.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/haptics_helper.dart';
import '../widgets/routine_runner_sheet.dart';
import '../widgets/state_button.dart';

class RoutinesScreen extends StatelessWidget {
  final RoutineService routineService;

  const RoutinesScreen({
    super.key,
    required this.routineService,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.t('routinesTitle'),
          style: AppTypography.display(theme.colorScheme.onSurface),
        ),
      ),
      body: AnimatedBuilder(
        animation: routineService,
        builder: (context, _) {
          final routines = routineService.routines;

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: routines.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final routine = routines[index];
              return _buildRoutineCard(context, routine);
            },
          );
        },
      ),
    );
  }

  Widget _buildRoutineCard(BuildContext context, Routine routine) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final localizedTitle = l10n.t(routine.title);
    final localizedDesc = l10n.t(routine.description);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(
                    routine.title.contains('Morning')
                        ? Icons.wb_sunny_rounded
                        : routine.title.contains('Evening')
                            ? Icons.bedtime_rounded
                            : Icons.work_outline_rounded,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizedTitle,
                        style: AppTypography.section(theme.colorScheme.onSurface),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Row(
                        children: [
                          Text(
                            l10n.t('routineSteps', args: {'count': routine.steps.length}),
                            style: AppTypography.caption(
                              theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              isMedium: true,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          const Text('•'),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            l10n.t('routineDuration', args: {'minutes': routine.totalMinutes}),
                            style: AppTypography.caption(
                              theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              isMedium: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              localizedDesc,
              style: AppTypography.body(theme.colorScheme.onSurface.withValues(alpha: 0.8)),
            ),
            const SizedBox(height: AppSpacing.md),

            // Step list preview
            ...routine.steps.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final step = entry.value;
              final min = (step.durationSeconds / 60).ceil();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$idx',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        step.title,
                        style: AppTypography.caption(theme.colorScheme.onSurface),
                      ),
                    ),
                    Text(
                      '${min}m',
                      style: AppTypography.caption(
                        theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: AppSpacing.lg),

            // Start Button
            StateButton(
              label: l10n.t('startRoutine'),
              icon: Icons.play_arrow_rounded,
              onPressed: () {
                HapticsHelper.medium();
                routineService.startRoutine(routine);
                RoutineRunnerSheet.show(context, routineService);
              },
            ),
          ],
        ),
      ),
    );
  }
}
