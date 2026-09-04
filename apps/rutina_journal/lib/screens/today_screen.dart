import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../models/habit.dart';
import '../models/routine.dart';
import '../services/app_services.dart';
import '../services/habit_service.dart';
import '../services/routine_service.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../utils/date_utils.dart';
import '../utils/haptics_helper.dart';
import '../widgets/habit_edit_dialog.dart';
import '../widgets/routine_edit_dialog.dart';
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
    final prefs = AppServices.of(context).preferencesService;

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
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              DateFormat('EEEE, d MMMM', l10n.locale.languageCode).format(_selectedDate),
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
      body: Container(
        decoration: AppTheme.getAtmosphericBackground(context, prefs.themePreset),
        child: AnimatedBuilder(
          animation: Listenable.merge([widget.habitService, widget.routineService]),
          builder: (context, _) {
            // Evaluated INSIDE the builder so it immediately reacts to habit updates
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

            return ListView(
              padding: const EdgeInsets.only(bottom: 88),
              children: [
                const SizedBox(height: AppSpacing.xs),
                // Monday-start 7-day full width week strip
                _buildWeekStrip(context),
                const SizedBox(height: AppSpacing.md),

                // Painted Linear Progress Banner
                _buildLinearProgressBanner(context, l10n, doneCount, totalCount, completionRate, isToday, cleanSelected),
                const SizedBox(height: AppSpacing.lg),

                // Icon-based Routine Launcher Row
                if (widget.routineService.routines.isNotEmpty) ...[
                  _buildRoutineLauncherSection(context, l10n),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Habits List Section Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${l10n.t('habitsTitle')} ($totalCount)',
                        style: AppTypography.section(theme.colorScheme.onSurface),
                      ),
                      if (doneCount > 0)
                        Text(
                          '$doneCount / $totalCount',
                          style: AppTypography.caption(
                            theme.colorScheme.primary,
                            isMedium: true,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),

                // Habits List or Empty state
                if (habits.isEmpty)
                  _buildEmptyState(context, l10n)
                else
                  ...habits.map((habit) {
                    final log = widget.habitService.getLog(habit.id, dateKey);
                    final streak = widget.habitService.calculateStreak(habit.id);

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'today_fab',
        onPressed: () => _openAddHabitDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.t('newHabit')),
      ),
    );
  }

  /// 7-day Monday-to-Sunday full width strip (no horizontal scroll)
  Widget _buildWeekStrip(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    // Calculate Monday of the current selected date's week
    final weekday = _selectedDate.weekday; // Monday is 1, Sunday is 7
    final monday = _selectedDate.subtract(Duration(days: weekday - 1));
    final weekDays = List.generate(7, (i) => monday.add(Duration(days: i)));

    final dayLetters = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    if (l10n.locale.languageCode == 'en') {
      dayLetters[0] = 'M';
      dayLetters[1] = 'T';
      dayLetters[2] = 'W';
      dayLetters[3] = 'T';
      dayLetters[4] = 'F';
      dayLetters[5] = 'S';
      dayLetters[6] = 'S';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: [
          // Week navigation controls
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, size: 24),
                  tooltip: l10n.t('prevStep'),
                  onPressed: () {
                    HapticsHelper.selection();
                    setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 7)));
                  },
                ),
                Text(
                  DateFormat('MMMM yyyy', l10n.locale.languageCode).format(_selectedDate).toUpperCase(),
                  style: AppTypography.caption(
                    theme.colorScheme.onSurface.withValues(alpha: 0.75),
                    isMedium: true,
                  ).copyWith(letterSpacing: 1.2),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, size: 24),
                  tooltip: l10n.t('nextStep'),
                  onPressed: () {
                    HapticsHelper.selection();
                    setState(() => _selectedDate = _selectedDate.add(const Duration(days: 7)));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          // 7 equal items in a Row
          Row(
            children: List.generate(7, (idx) {
              final day = weekDays[idx];
              final isSelected = AppDateUtils.isSameDay(day, _selectedDate);
              final isToday = AppDateUtils.isSameDay(day, DateTime.now());
              final isWeekend = day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: GestureDetector(
                    onTap: () {
                      HapticsHelper.selection();
                      setState(() => _selectedDate = day);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : isToday
                                ? theme.colorScheme.primary.withValues(alpha: 0.15)
                                : isWeekend
                                    ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                                    : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : isToday
                                  ? theme.colorScheme.primary.withValues(alpha: 0.5)
                                  : isWeekend
                                      ? theme.colorScheme.outline.withValues(alpha: 0.4)
                                      : theme.colorScheme.outline.withValues(alpha: 0.2),
                          width: isSelected || isToday ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            dayLetters[idx],
                            style: AppTypography.caption(
                              isSelected
                                  ? theme.colorScheme.onPrimary
                                  : isWeekend
                                      ? theme.colorScheme.primary.withValues(alpha: 0.8)
                                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              isMedium: true,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            day.day.toString(),
                            style: AppTypography.body(
                              isSelected
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
                              isMedium: true,
                            ).copyWith(
                              fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                          if (isToday)
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.primary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// Painted Linear Progress Banner
  Widget _buildLinearProgressBanner(
    BuildContext context,
    AppLocalizations l10n,
    int doneCount,
    int totalCount,
    double completionRate,
    bool isToday,
    DateTime cleanSelected,
  ) {
    final theme = Theme.of(context);
    final percentage = (completionRate * 100).toInt();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Container(
        height: 76,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: completionRate == 1.0 && totalCount > 0
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.25),
            width: completionRate == 1.0 && totalCount > 0 ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Background Painted Progress Fill
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: completionRate),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              builder: (context, val, _) {
                return FractionallySizedBox(
                  widthFactor: val.clamp(0.0, 1.0),
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: 0.16),
                          theme.colorScheme.primary.withValues(alpha: 0.28),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Content Overlay
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: completionRate == 1.0 && totalCount > 0
                          ? theme.colorScheme.primary
                          : theme.colorScheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      completionRate == 1.0 && totalCount > 0
                          ? Icons.stars_rounded
                          : Icons.bolt_rounded,
                      color: completionRate == 1.0 && totalCount > 0
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doneCount == totalCount && totalCount > 0
                              ? l10n.t('allDone')
                              : l10n.t('progressSummary', args: {
                                  'done': doneCount,
                                  'total': totalCount,
                                }),
                          style: AppTypography.body(theme.colorScheme.onSurface, isMedium: true),
                        ),
                        const SizedBox(height: 2),
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
                  Text(
                    '$percentage%',
                    style: AppTypography.title(theme.colorScheme.primary).copyWith(
                      fontWeight: FontWeight.w800,
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

  /// Icon-based Routine Launcher Section
  Widget _buildRoutineLauncherSection(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final routines = widget.routineService.routines;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.t('routinesTitle'),
                style: AppTypography.section(theme.colorScheme.onSurface),
              ),
              IconButton(
                icon: const Icon(Icons.add_rounded, size: 20),
                tooltip: l10n.t('newRoutine'),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                onPressed: () {
                  HapticsHelper.light();
                  RoutineEditDialog.show(
                    context,
                    onSave: (newRoutine) => widget.routineService.addRoutine(newRoutine),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          height: 60,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            scrollDirection: Axis.horizontal,
            itemCount: routines.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
            itemBuilder: (context, idx) {
              final routine = routines[idx];
              final title = l10n.t(routine.title);

              return Tooltip(
                message: '$title (${routine.totalMinutes}m)',
                child: Semantics(
                  button: true,
                  label: '$title, ${routine.totalMinutes}m',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    onTap: () {
                      HapticsHelper.medium();
                      widget.routineService.startRoutine(routine);
                      RoutineRunnerSheet.show(context, widget.routineService);
                    },
                    child: Container(
                      width: 56,
                      height: 58,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.shadow.withValues(alpha: 0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            routine.icon,
                            color: theme.colorScheme.primary,
                            size: 22,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${routine.totalMinutes}m',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
