import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../models/routine.dart';
import '../services/app_services.dart';
import '../services/routine_service.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../utils/haptics_helper.dart';
import '../widgets/app_header_title.dart';
import '../widgets/first_use_guide_card.dart';
import '../widgets/focus_zone_screen.dart';
import '../widgets/routine_edit_dialog.dart';
import '../widgets/routine_runner_sheet.dart';
import '../widgets/routine_templates_sheet.dart';
import '../widgets/paywall_sheet.dart';
import '../widgets/state_button.dart';

class RoutinesScreen extends StatefulWidget {
  final RoutineService routineService;

  const RoutinesScreen({
    super.key,
    required this.routineService,
  });

  @override
  State<RoutinesScreen> createState() => _RoutinesScreenState();
}

class _RoutinesScreenState extends State<RoutinesScreen> {
  bool _showGuide = false;

  @override
  void initState() {
    super.initState();
    _loadGuideState();
  }

  Future<void> _loadGuideState() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('has_seen_guide_routines') ?? false;
    if (!seen && mounted) {
      setState(() => _showGuide = true);
    }
  }

  Future<void> _dismissGuide() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_guide_routines', true);
    if (mounted) {
      setState(() => _showGuide = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appServices = AppServices.of(context);
    final prefs = appServices.preferencesService;
    final premiumService = appServices.premiumService;

    return Scaffold(
      appBar: AppBar(
        title: AppHeaderTitle(
          title: l10n.t('navRoutines'),
          isPro: premiumService.isPro,
        ),
        actions: [
          if (!premiumService.isPro)
            IconButton(
              icon: const Text('👑', style: TextStyle(fontSize: 18)),
              tooltip: 'Ritmo PRO',
              onPressed: () {
                HapticsHelper.light();
                PaywallSheet.show(context);
              },
            ),
          IconButton(
            icon: const Icon(Icons.auto_awesome_motion_rounded),
            tooltip: l10n.t('exploreTemplates'),
            onPressed: () {
              HapticsHelper.light();
              RoutineTemplatesSheet.show(context, widget.routineService);
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: l10n.t('newRoutine'),
            onPressed: () {
              HapticsHelper.light();
              if (!premiumService.isPro && widget.routineService.routines.length >= 3) {
                PaywallSheet.show(
                  context,
                  customReason: l10n.t('proLimitRoutinesMsg'),
                );
                return;
              }
              RoutineEditDialog.show(
                context,
                onSave: (newRoutine) => widget.routineService.addRoutine(newRoutine),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.getAtmosphericBackground(context, prefs.themePreset),
        child: AnimatedBuilder(
          animation: widget.routineService,
          builder: (context, _) {
            final routines = widget.routineService.routines;

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                if (_showGuide)
                  FirstUseGuideCard(
                    icon: Icons.repeat_rounded,
                    title: l10n.locale.languageCode == 'es' ? 'Tus Rutinas y Flujos' : 'Your Routines & Flows',
                    description: l10n.locale.languageCode == 'es'
                        ? 'Agrupa pasos y hábitos en rutinas guiadas para tus mañanas, noches o momentos de foco.'
                        : 'Group steps and habits into guided routines for your mornings, nights, or focus blocks.',
                    bulletPoints: l10n.locale.languageCode == 'es'
                        ? [
                            'Toca una rutina para iniciar el reproductor paso a paso.',
                            'Crea rutinas con duraciones estimadas y pistas de audio para mantenerte en ritmo.',
                            'Usa el botón (+) arriba para diseñar tus propias secuencias personalizadas.',
                          ]
                        : [
                            'Tap any routine card to launch the guided step-by-step runner.',
                            'Set estimated durations and audio cues to keep your momentum.',
                            'Tap (+) on top to design your own customized routine sequences.',
                          ],
                    onDismiss: _dismissGuide,
                  ),
                // Hero Focus Zone Banner inspired by mockup
                _buildFocusZoneHero(context, l10n, routines.isNotEmpty ? routines.first : null),
                const SizedBox(height: AppSpacing.md),

                // Explore Templates Quick Action
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    side: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  icon: const Icon(Icons.auto_awesome_motion_rounded, size: 18),
                  label: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.t('exploreTemplates'),
                        style: AppTypography.body(Theme.of(context).colorScheme.primary, isMedium: true),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                  onPressed: () {
                    HapticsHelper.light();
                    RoutineTemplatesSheet.show(context, widget.routineService);
                  },
                ),
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
                      onSave: (updated) => widget.routineService.updateRoutine(updated),
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
                widget.routineService.startRoutine(routine);
                RoutineRunnerSheet.show(context, widget.routineService);
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
              widget.routineService.deleteRoutine(routine.id);
              Navigator.of(ctx).pop();
            },
            child: Text(l10n.t('actionDelete')),
          ),
        ],
      ),
    );
  }
}
