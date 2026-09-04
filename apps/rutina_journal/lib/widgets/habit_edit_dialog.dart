import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/habit.dart';
import '../models/habit_category.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'state_button.dart';

class HabitEditDialog extends StatefulWidget {
  final Habit? existingHabit;
  final Future<void> Function({
    required String title,
    required HabitCategory category,
    required HabitType type,
    required double targetValue,
    required String unit,
    required List<int> frequencyDays,
    String? reminderTime,
    required bool reminderEnabled,
  }) onSave;
  final VoidCallback? onDelete;

  const HabitEditDialog({
    super.key,
    this.existingHabit,
    required this.onSave,
    this.onDelete,
  });

  static Future<void> show(
    BuildContext context, {
    Habit? habit,
    required Future<void> Function({
      required String title,
      required HabitCategory category,
      required HabitType type,
      required double targetValue,
      required String unit,
      required List<int> frequencyDays,
      String? reminderTime,
      required bool reminderEnabled,
    }) onSave,
    VoidCallback? onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => HabitEditDialog(
        existingHabit: habit,
        onSave: onSave,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<HabitEditDialog> createState() => _HabitEditDialogState();
}

class _HabitEditDialogState extends State<HabitEditDialog> {
  late TextEditingController _titleController;
  late TextEditingController _targetController;
  late TextEditingController _unitController;

  late HabitCategory _selectedCategory;
  late HabitType _selectedType;
  late List<int> _frequencyDays;
  late bool _reminderEnabled;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);

  ButtonState _saveState = ButtonState.idle;
  String? _titleError;

  @override
  void initState() {
    super.initState();
    final h = widget.existingHabit;
    _titleController = TextEditingController(text: h?.title ?? '');
    _targetController = TextEditingController(
      text: h != null ? h.targetValue.toInt().toString() : '1',
    );
    _unitController = TextEditingController(text: h?.unit ?? '');
    _selectedCategory = h?.category ?? HabitCategory.health;
    _selectedType = h?.type ?? HabitType.boolean;
    _frequencyDays = h?.frequencyDays ?? [1, 2, 3, 4, 5, 6, 7];
    _reminderEnabled = h?.reminderEnabled ?? false;

    if (h?.reminderTime != null) {
      final parts = h!.reminderTime!.split(':');
      if (parts.length == 2) {
        _reminderTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 8,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() {
        _titleError = AppLocalizations.of(context).t('errorTitleRequired');
      });
      return;
    }

    setState(() {
      _titleError = null;
      _saveState = ButtonState.loading;
    });

    try {
      final target = double.tryParse(_targetController.text) ?? 1.0;
      final timeStr = _reminderEnabled
          ? '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}'
          : null;

      await widget.onSave(
        title: title,
        category: _selectedCategory,
        type: _selectedType,
        targetValue: target,
        unit: _unitController.text.trim(),
        frequencyDays: _frequencyDays,
        reminderTime: timeStr,
        reminderEnabled: _reminderEnabled,
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saveState = ButtonState.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isEditing = widget.existingHabit != null;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline,
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
                  isEditing ? l10n.t('editHabit') : l10n.t('newHabit'),
                  style: AppTypography.section(theme.colorScheme.onSurface),
                ),
                if (isEditing && widget.onDelete != null)
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded,
                        color: theme.colorScheme.error),
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onDelete!();
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Title Input
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: l10n.t('habitNameLabel'),
                hintText: l10n.t('habitNameHint'),
                errorText: _titleError,
              ),
              onChanged: (_) {
                if (_titleError != null) setState(() => _titleError = null);
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // Category Chips
            Text(
              l10n.t('habitCategoryLabel'),
              style: AppTypography.caption(theme.colorScheme.onSurface, isMedium: true),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: HabitCategory.values.map((cat) {
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(cat.icon, size: 14, color: isSelected ? Colors.white : cat.color),
                      const SizedBox(width: 4),
                      Text(l10n.t(cat.localizationKey)),
                    ],
                  ),
                  selected: isSelected,
                  selectedColor: cat.color,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedCategory = cat);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.md),

            // Habit Type Selector
            Text(
              l10n.t('habitTypeLabel'),
              style: AppTypography.caption(theme.colorScheme.onSurface, isMedium: true),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: Center(child: Text(l10n.t('habitTypeBoolean'))),
                    selected: _selectedType == HabitType.boolean,
                    onSelected: (s) {
                      if (s) setState(() => _selectedType = HabitType.boolean);
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: ChoiceChip(
                    label: Center(child: Text(l10n.t('habitTypeCounter'))),
                    selected: _selectedType == HabitType.counter,
                    onSelected: (s) {
                      if (s) setState(() => _selectedType = HabitType.counter);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Counter Target & Unit (If Counter)
            if (_selectedType == HabitType.counter) ...[
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _targetController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.t('habitTargetLabel'),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _unitController,
                      decoration: InputDecoration(
                        labelText: l10n.t('habitUnitLabel'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Reminder Toggle & Picker
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                l10n.t('reminderLabel'),
                style: AppTypography.body(theme.colorScheme.onSurface),
              ),
              subtitle: _reminderEnabled
                  ? Text(
                      _reminderTime.format(context),
                      style: AppTypography.caption(theme.colorScheme.primary),
                    )
                  : null,
              value: _reminderEnabled,
              onChanged: (val) async {
                if (val) {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _reminderTime,
                  );
                  if (picked != null) {
                    setState(() {
                      _reminderTime = picked;
                      _reminderEnabled = true;
                    });
                  }
                } else {
                  setState(() => _reminderEnabled = false);
                }
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // Save Action
            StateButton(
              label: l10n.t('saveHabit'),
              state: _saveState,
              onPressed: _handleSave,
            ),
          ],
        ),
      ),
    );
  }
}
