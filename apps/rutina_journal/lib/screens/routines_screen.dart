import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/routine.dart';
import '../services/app_services.dart';
import '../services/routine_service.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../utils/haptics_helper.dart';
import '../widgets/focus_zone_screen.dart';
import '../widgets/routine_edit_dialog.dart';
import '../widgets/routine_runner_sheet.dart';
import '../widgets/paywall_sheet.dart';
import '../widgets/state_button.dart';
import 'settings_screen.dart';

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
    final appServices = AppServices.of(context);
    final prefs = appServices.preferencesService;
    final storage = appServices.storageService;
    final habitService = appServices.habitService;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.t('routinesTitle'),
          style: AppTypography.display(theme.colorScheme.onSurface),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: l10n.t('newRoutine'),
            onPressed: () {
              HapticsHelper.light();
              final premiumService = appServices.premiumService;
              if (!premiumService.isPro && routineService.routines.length >= 3) {
                PaywallSheet.show(
                  context,
                  customReason: l10n.t('proLimitRoutinesMsg'),
                );
                return;
              }
              RoutineEditDialog.show(
                context,
                onSave: (newRoutine) => routineService.addRoutine(newRoutine),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.t('navSettings'),
            onPressed: () {
              HapticsHelper.light();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(
                    prefs: prefs,
                    storage: storage,
                    habitService: habitService,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.getAtmosphericBackground(context, prefs.themePreset),
        child: AnimatedBuilder(
          animation: routineService,
          builder: (context, _) {
            final routines = routineService.routines;

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // Hero Focus Zone Banner inspired by mockup
                _buildFocusZoneHero(context, l10n, routines.isNotEmpty ? routines.first : null),
                const SizedBox(height: AppSpacing.md),

                // Routine List
                ...routines.map((routine) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _buildRoutineCard(context, routine),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFocusZoneHero(BuildContext context, AppLocalizations l10n, Routine? defaultRoutine) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final heroBg = isDark
        ? theme.colorScheme.surfaceContainerHighest
        : theme.colorScheme.primary;
    final accentColor = theme.colorScheme.secondary;
    final onHero = isDark ? theme.colorScheme.onSurface : theme.colorScheme.onPrimary;

    return Container(
      decoration: BoxDecoration(
        color: heroBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: isDark ? 0.35 : 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                decoration: BoxDecoration(
                  color: (isDark ? theme.colorScheme.surface : Colors.white).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: onHero, size: 14),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      l10n.t('focusModeTag'),
                      style: AppTypography.caption(onHero, isMedium: true),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(Icons.self_improvement_rounded, color: theme.colorScheme.onSecondary, size: 22),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.t('enterFocusZone'),
            style: AppTypography.title(onHero).copyWith(fontSize: 18),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            l10n.t('focusZoneDesc'),
            style: AppTypography.body(onHero.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: theme.colorScheme.onSecondary,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                elevation: 0,
              ),
              onPressed: () {
                HapticsHelper.medium();
                FocusZoneScreen.show(context, routine: defaultRoutine);
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(
                l10n.t('startFocusMode'),
                style: AppTypography.body(theme.colorScheme.onSecondary, isMedium: true),
              ),
            ),
          ),
        ],
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
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(
                    routine.icon,
                    color: theme.colorScheme.primary,
                    size: 26,
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
                          if (routine.reminderEnabled && routine.reminderTime != null && routine.reminderTime!.isNotEmpty) ...[
                            const SizedBox(width: AppSpacing.xs),
                            const Text('•'),
                            const SizedBox(width: AppSpacing.xs),
                            Icon(
                              Icons.alarm_rounded,
                              size: 13,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              routine.reminderTime!,
                              style: AppTypography.caption(
                                theme.colorScheme.primary,
                                isMedium: true,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () {
                    HapticsHelper.light();
                    RoutineEditDialog.show(
                      context,
                      routine: routine,
                      onSave: (updated) => routineService.updateRoutine(updated),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded, size: 20, color: theme.colorScheme.error.withValues(alpha: 0.7)),
                  onPressed: () {
                    HapticsHelper.medium();
                    _confirmDelete(context, routine);
                  },
                ),
              ],
            ),
            if (localizedDesc.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                localizedDesc,
                style: AppTypography.body(theme.colorScheme.onSurface.withValues(alpha: 0.8)),
              ),
            ],
            const SizedBox(height: AppSpacing.md),

            // Step list preview
            ...routine.steps.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final step = entry.value;
              final min = (step.durationSeconds / 60).ceil();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
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

  void _confirmDelete(BuildContext context, Routine routine) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.t('deleteRoutineConfirm')),
        content: Text(l10n.t(routine.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.t('actionCancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () {
              routineService.deleteRoutine(routine.id);
              Navigator.of(ctx).pop();
            },
            child: Text(l10n.t('actionDelete')),
          ),
        ],
      ),
    );
  }
}
