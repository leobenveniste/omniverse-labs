import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/habit_service.dart';
import '../services/journal_service.dart';
import '../services/preferences_service.dart';
import '../services/storage_service.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_preset.dart';
import '../theme/app_typography.dart';
import '../utils/haptics_helper.dart';
import '../widgets/heatmap_calendar.dart';
import 'settings_screen.dart';

class AnalyticsScreen extends StatelessWidget {
  final HabitService habitService;
  final JournalService journalService;
  final PreferencesService? prefs;
  final StorageService? storage;

  const AnalyticsScreen({
    super.key,
    required this.habitService,
    required this.journalService,
    this.prefs,
    this.storage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.t('analyticsTitle'),
          style: AppTypography.display(theme.colorScheme.onSurface),
        ),
        actions: [
          if (prefs != null && storage != null)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: l10n.t('navSettings'),
              onPressed: () {
                HapticsHelper.light();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(
                      prefs: prefs!,
                      storage: storage!,
                      habitService: habitService,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: Container(
        decoration: AppTheme.getAtmosphericBackground(
          context,
          prefs?.themePreset ?? AppThemePreset.calmSage,
        ),
        child: AnimatedBuilder(
          animation: Listenable.merge([habitService, journalService]),
          builder: (context, _) {
            final heatmapData = habitService.getHeatmapData(90);
            final habits = habitService.habits;

            // Compute average completion rate over past 7 days
            final past7 = heatmapData.entries.toList().reversed.take(7);
            final avg7 = past7.isEmpty
                ? 0.0
                : past7.fold<double>(0.0, (acc, e) => acc + e.value) / past7.length;

            final consistencyPercent = (avg7 * 100).toInt();

            return ListView(
              padding: const EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                top: AppSpacing.md,
                bottom: 88,
              ),
              children: [
              // Metric cards row
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.t('consistencyScore'),
                              style: AppTypography.caption(
                                theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                isMedium: true,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '$consistencyPercent%',
                              style: AppTypography.display(theme.colorScheme.primary),
                            ),
                            Text(
                              l10n.t('last7Days'),
                              style: AppTypography.caption(
                                theme.colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.t('avgMood'),
                              style: AppTypography.caption(
                                theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                isMedium: true,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '${journalService.getAverageMood().toStringAsFixed(1)} / 5',
                              style: AppTypography.display(theme.colorScheme.secondary),
                            ),
                            Text(
                              l10n.t('reflectiveLog'),
                              style: AppTypography.caption(
                                theme.colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // 90-Day Heatmap
              Text(
                l10n.t('heatmapTitle'),
                style: AppTypography.section(theme.colorScheme.onSurface),
              ),
              const SizedBox(height: AppSpacing.xs),
              HeatmapCalendar(data: heatmapData),
              const SizedBox(height: AppSpacing.md),

              // Mood Correlation Insight Card
              Card(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Icon(
                        Icons.insights_rounded,
                        color: theme.colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.t('moodCorrelationTitle'),
                              style: AppTypography.body(
                                theme.colorScheme.onSurface,
                                isMedium: true,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.t('moodCorrelationInsight'),
                              style: AppTypography.caption(
                                theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Top Streaks Leaderboard
              Text(
                l10n.t('bestStreaks'),
                style: AppTypography.section(theme.colorScheme.onSurface),
              ),
              const SizedBox(height: AppSpacing.xs),
              if (habits.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Center(
                      child: Text(
                        l10n.t('noStreaksYet'),
                        style: AppTypography.body(
                          theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                )
              else
                Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: habits.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: theme.colorScheme.outline.withValues(alpha: 0.5),
                    ),
                    itemBuilder: (context, idx) {
                      final habit = habits[idx];
                      final streak = habitService.calculateStreak(habit.id);

                      return ListTile(
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: habit.category.color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            habit.category.icon,
                            size: 16,
                            color: habit.category.color,
                          ),
                        ),
                        title: Text(
                          habit.title,
                          style: AppTypography.body(theme.colorScheme.onSurface, isMedium: true),
                        ),
                        subtitle: Text(
                          l10n.t('bestStreakDays', args: {'days': '${streak.best}'}),
                          style: AppTypography.caption(theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_fire_department_rounded,
                              color: theme.colorScheme.secondary,
                              size: 18,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${streak.current}d',
                              style: AppTypography.body(theme.colorScheme.secondary, isMedium: true),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              if (prefs != null && storage != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Card(
                  child: ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    title: Text(
                      l10n.t('navSettings'),
                      style: AppTypography.body(theme.colorScheme.onSurface, isMedium: true),
                    ),
                    subtitle: Text(
                      l10n.t('aestheticPresetTitle'),
                      style: AppTypography.caption(theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      HapticsHelper.light();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SettingsScreen(
                            prefs: prefs!,
                            storage: storage!,
                            habitService: habitService,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          );
        },
      ),
    ),
  );
}
}
