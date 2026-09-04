import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../models/habit.dart';
import '../services/habit_service.dart';
import '../services/routine_service.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/date_utils.dart';
import '../utils/haptics_helper.dart';
import '../widgets/habit_edit_dialog.dart';
import '../widgets/progress_ring.dart';
import '../widgets/routine_runner_sheet.dart';
import '../widgets/swipe_habit_card.dart';

class TodayScreen extends StatefulWidget {
  final HabitService habitService;
  final RoutineService routineService;

  const TodayScreen({
    super.key,
    required this.habitService,
    required this.routineService,
  });

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final cleanSelected = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final isToday = AppDateUtils.isSameDay(cleanSelected, DateTime.now());
    final dateKey = AppDateUtils.toDateKey(cleanSelected);

    final habits = widget.habitService.getHabitsForDate(cleanSelected);
    final doneCount = widget.habitService.getCompletedCountForDate(cleanSelected);
    final totalCount = habits.length;
    final completionRate = widget.habitService.getCompletionRateForDate(cleanSelected);

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 48,
        leading: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.sm, top: 8, bottom: 8),
          child: Image.asset(
            'assets/images/app_logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.spa_rounded,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ritmo',
              style: AppTypography.display(theme.colorScheme.onSurface).copyWith(
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              DateFormat('EEEE, d MMMM', l10n.locale.languageCode).format(cleanSelected),
              style: AppTypography.caption(
                theme.colorScheme.onSurface.withValues(alpha: 0.6),
                isMedium: true,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: l10n.t('newHabit'),
            onPressed: () => _openAddHabitDialog(context),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([widget.habitService, widget.routineService]),
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.only(bottom: 80),
            children: [
              // Horizontal Date Selector Strip
              _buildDateStrip(context),
              const SizedBox(height: AppSpacing.md),

              // Progress Hero Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        ProgressRing(
                          progress: completionRate,
                          size: 68,
                          strokeWidth: 6,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doneCount == totalCount && totalCount > 0
                                    ? l10n.t('allDone')
                                    : l10n.t('progressSummary', args: {
                                        'done': doneCount,
                                        'total': totalCount,
                                      }),
                                style: AppTypography.body(
                                  theme.colorScheme.onSurface,
                                  isMedium: true,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                isToday
                                    ? l10n.t('swipeToComplete')
                                    : DateFormat('d MMM').format(cleanSelected),
                                style: AppTypography.caption(
                                  theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Quick Routines Row
              if (widget.routineService.routines.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.t('quickRoutines'),
                        style: AppTypography.section(theme.colorScheme.onSurface),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.routineService.routines.length,
                    separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
                    itemBuilder: (context, idx) {
                      final routine = widget.routineService.routines[idx];
                      final localizedTitle = l10n.t(routine.title);
                      return ActionChip(
                        avatar: const Icon(Icons.play_arrow_rounded, size: 16),
                        label: Text(localizedTitle),
                        onPressed: () {
                          HapticsHelper.selection();
                          widget.routineService.startRoutine(routine);
                          RoutineRunnerSheet.show(context, widget.routineService);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // Habits List Section Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  'Hábitos (${habits.length})',
                  style: AppTypography.section(theme.colorScheme.onSurface),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              // Empty state or habits list
              if (habits.isEmpty)
                _buildEmptyState(context, l10n)
              else
                ...habits.map((habit) {
                  final log = widget.habitService.getLog(habit.id, dateKey);
                  final streak = widget.habitService.calculateStreak(habit.id);

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xxs,
                    ),
                    child: SwipeHabitCard(
                      habit: habit,
                      log: log,
                      streak: streak,
                      onToggle: () => widget.habitService.toggleHabit(habit.id, cleanSelected),
                      onDelta: (delta) =>
                          widget.habitService.updateCounter(habit.id, cleanSelected, delta),
                      onEdit: () => _openEditHabitDialog(context, habit),
                    ),
                  );
                }),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddHabitDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.t('newHabit')),
      ),
    );
  }

  Widget _buildDateStrip(BuildContext context) {
    final theme = Theme.of(context);
    final days = AppDateUtils.getWeekDaysAround(DateTime.now(), daysBefore: 5, daysAfter: 1);

    return SizedBox(
      height: 72,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = AppDateUtils.isSameDay(day, _selectedDate);
          final isToday = AppDateUtils.isSameDay(day, DateTime.now());

          return GestureDetector(
            onTap: () {
              HapticsHelper.selection();
              setState(() => _selectedDate = day);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : isToday
                        ? theme.colorScheme.surfaceContainerHighest
                        : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(day).toUpperCase(),
                    style: AppTypography.caption(
                      isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      isMedium: true,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    day.day.toString(),
                    style: AppTypography.body(
                      isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                      isMedium: true,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.spa_outlined,
              size: 48,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.t('noHabitsTitle'),
              style: AppTypography.section(theme.colorScheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.t('noHabitsSubtitle'),
              textAlign: TextAlign.center,
              style: AppTypography.body(theme.colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }

  void _openAddHabitDialog(BuildContext context) {
    HabitEditDialog.show(
      context,
      onSave: ({
        required String title,
        required category,
        required type,
        required double targetValue,
        required String unit,
        required List<int> frequencyDays,
        String? reminderTime,
        required bool reminderEnabled,
      }) async {
        await widget.habitService.addHabit(
          title: title,
          category: category,
          type: type,
          targetValue: targetValue,
          unit: unit,
          frequencyDays: frequencyDays,
          reminderTime: reminderTime,
          reminderEnabled: reminderEnabled,
        );
      },
    );
  }

  void _openEditHabitDialog(BuildContext context, Habit habit) {
    HabitEditDialog.show(
      context,
      habit: habit,
      onSave: ({
        required String title,
        required category,
        required type,
        required double targetValue,
        required String unit,
        required List<int> frequencyDays,
        String? reminderTime,
        required bool reminderEnabled,
      }) async {
        final updated = habit.copyWith(
          title: title,
          category: category,
          type: type,
          targetValue: targetValue,
          unit: unit,
          frequencyDays: frequencyDays,
          reminderTime: reminderTime,
          reminderEnabled: reminderEnabled,
        );
        await widget.habitService.updateHabit(updated);
      },
      onDelete: () async {
        await widget.habitService.deleteHabit(habit.id);
      },
    );
  }
}
