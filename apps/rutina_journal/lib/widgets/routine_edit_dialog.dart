import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../l10n/app_localizations.dart';
import '../models/routine.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/haptics_helper.dart';

class RoutineEditDialog extends StatefulWidget {
  final Routine? routine;
  final Function(Routine routine) onSave;

  const RoutineEditDialog({
    super.key,
    this.routine,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    Routine? routine,
    required Function(Routine routine) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RoutineEditDialog(
        routine: routine,
        onSave: onSave,
      ),
    );
  }

  @override
  State<RoutineEditDialog> createState() => _RoutineEditDialogState();
}

class _RoutineEditDialogState extends State<RoutineEditDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late String _selectedIconName;
  late List<_StepDraft> _steps;

  final List<Map<String, dynamic>> _iconOptions = const [
    {'name': 'wb_sunny', 'icon': Icons.wb_sunny_rounded},
    {'name': 'nightlight_round', 'icon': Icons.nightlight_round},
    {'name': 'laptop_mac', 'icon': Icons.laptop_mac_rounded},
    {'name': 'fitness_center', 'icon': Icons.fitness_center_rounded},
    {'name': 'coffee', 'icon': Icons.coffee_rounded},
    {'name': 'menu_book', 'icon': Icons.menu_book_rounded},
    {'name': 'spa', 'icon': Icons.spa_rounded},
    {'name': 'self_improvement', 'icon': Icons.self_improvement_rounded},
    {'name': 'timer', 'icon': Icons.timer_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.routine?.title ?? '');
    _descController = TextEditingController(text: widget.routine?.description ?? '');
    _selectedIconName = widget.routine?.iconName ?? 'wb_sunny';
    _steps = widget.routine != null
        ? widget.routine!.steps
            .map((s) => _StepDraft(
                  id: s.id,
                  titleController: TextEditingController(text: s.title),
                  minutesController: TextEditingController(text: (s.durationSeconds / 60).ceil().toString()),
                ))
            .toList()
        : [
            _StepDraft(
              id: const Uuid().v4(),
              titleController: TextEditingController(),
              minutesController: TextEditingController(text: '5'),
            ),
          ];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    for (final s in _steps) {
      s.dispose();
    }
    super.dispose();
  }

  void _addStep() {
    HapticsHelper.light();
    setState(() {
      _steps.add(_StepDraft(
        id: const Uuid().v4(),
        titleController: TextEditingController(),
        minutesController: TextEditingController(text: '5'),
      ));
    });
  }

  void _removeStep(int index) {
    HapticsHelper.light();
    setState(() {
      final s = _steps.removeAt(index);
      s.dispose();
    });
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final parsedSteps = <RoutineStep>[];
    for (final s in _steps) {
      final sTitle = s.titleController.text.trim();
      if (sTitle.isNotEmpty) {
        final min = int.tryParse(s.minutesController.text.trim()) ?? 5;
        parsedSteps.add(RoutineStep(
          id: s.id,
          title: sTitle,
          durationSeconds: (min * 60).clamp(30, 7200),
        ));
      }
    }

    if (parsedSteps.isEmpty) {
      parsedSteps.add(RoutineStep(
        id: const Uuid().v4(),
        title: title,
        durationSeconds: 300,
      ));
    }

    final newRoutine = Routine(
      id: widget.routine?.id ?? const Uuid().v4(),
      title: title,
      description: _descController.text.trim(),
      iconName: _selectedIconName,
      steps: parsedSteps,
      tiedHabitIds: widget.routine?.tiedHabitIds ?? const [],
      reminderTime: widget.routine?.reminderTime,
      reminderEnabled: widget.routine?.reminderEnabled ?? false,
    );

    HapticsHelper.medium();
    widget.onSave(newRoutine);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isEdit = widget.routine != null;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isEdit ? l10n.t('editRoutine') : l10n.t('newRoutine'),
                style: AppTypography.title(theme.colorScheme.onSurface),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon picker
                  Text(
                    l10n.t('routineIcon'),
                    style: AppTypography.caption(theme.colorScheme.onSurface.withValues(alpha: 0.7), isMedium: true),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  SizedBox(
                    height: 52,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _iconOptions.length,
                      separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
                      itemBuilder: (context, index) {
                        final opt = _iconOptions[index];
                        final isSelected = _selectedIconName == opt['name'];
                        return GestureDetector(
                          onTap: () {
                            HapticsHelper.selection();
                            setState(() => _selectedIconName = opt['name'] as String);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                              border: Border.all(
                                color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              opt['icon'] as IconData,
                              color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                              size: 24,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Routine Name
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: l10n.t('routineNameHint'),
                      labelText: l10n.t('title'),
                      prefixIcon: const Icon(Icons.title_rounded),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Routine Description
                  TextField(
                    controller: _descController,
                    decoration: InputDecoration(
                      hintText: l10n.t('routineDescHint'),
                      labelText: l10n.t('description'),
                      prefixIcon: const Icon(Icons.notes_rounded),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Steps header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.t('routineStepsTitle'),
                        style: AppTypography.section(theme.colorScheme.onSurface),
                      ),
                      TextButton.icon(
                        onPressed: _addStep,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text(l10n.t('addStep')),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Step rows
                  ..._steps.asMap().entries.map((entry) {
                    final index = entry.key;
                    final step = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: step.titleController,
                              decoration: InputDecoration(
                                hintText: l10n.t('stepNameHint'),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          SizedBox(
                            width: 70,
                            child: TextField(
                              controller: step.minutesController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                suffixText: 'm',
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              ),
                            ),
                          ),
                          if (_steps.length > 1)
                            IconButton(
                              icon: Icon(Icons.remove_circle_outline_rounded,
                                  color: theme.colorScheme.error, size: 20),
                              onPressed: () => _removeStep(index),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _save,
              child: Text(l10n.t('save')),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepDraft {
  final String id;
  final TextEditingController titleController;
  final TextEditingController minutesController;

  _StepDraft({
    required this.id,
    required this.titleController,
    required this.minutesController,
  });

  void dispose() {
    titleController.dispose();
    minutesController.dispose();
  }
}
