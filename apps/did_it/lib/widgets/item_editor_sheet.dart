import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../l10n/app_strings.dart';
import '../models/did_it_models.dart';
import '../services/automation_engine.dart';
import '../theme/app_theme.dart';

/// Bottom sheet editor for creating or modifying a recurring item, cooldown, and chain trigger.
class ItemEditorSheet extends StatefulWidget {
  const ItemEditorSheet({
    super.key,
    required this.strings,
    required this.existingItems,
    this.initialItem,
    this.onSave,
    this.onDelete,
  });

  final AppStrings strings;
  final List<DidItItem> existingItems;
  final DidItItem? initialItem;
  final ValueChanged<DidItItem>? onSave;
  final VoidCallback? onDelete;

  static Future<void> show(
    BuildContext context, {
    required AppStrings strings,
    required List<DidItItem> existingItems,
    DidItItem? initialItem,
    required ValueChanged<DidItItem> onSave,
    VoidCallback? onDelete,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ItemEditorSheet(
        strings: strings,
        existingItems: existingItems,
        initialItem: initialItem,
        onSave: onSave,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<ItemEditorSheet> createState() => _ItemEditorSheetState();
}

class _ItemEditorSheetState extends State<ItemEditorSheet> {
  static const Uuid _uuid = Uuid();
  static const List<int> _intervalPresets = <int>[
    60,
    240,
    480,
    720,
    1440,
    4320,
    10080,
    43200,
    129600,
  ];
  static const List<int> _cooldownPresets = <int>[0, 15, 30, 120, 360];
  static const List<int> _chainDelayPresets = <int>[0, 15, 30, 55, 120];

  late final TextEditingController _titleController;
  late String _categoryIcon;
  late LoopRepeatMode _repeatMode;
  late int _intervalMinutes;
  late int _fixedHour;
  late int _fixedMinute;
  late List<int> _weekdays;
  late int _monthDay;
  late int _cooldownMinutes;
  String? _chainTargetId;
  late int _chainDelayMinutes;
  late bool _notificationsEnabled;

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    _titleController = TextEditingController(text: item?.title ?? '');
    _categoryIcon = item?.categoryIcon ?? 'check';
    _repeatMode = item?.repeatMode ?? LoopRepeatMode.fromLastDone;
    _intervalMinutes = item?.intervalMinutes ?? 480;
    _fixedHour = item?.fixedHour ?? 9;
    _fixedMinute = item?.fixedMinute ?? 0;
    _weekdays = List<int>.from(item?.weekdays ?? const <int>[1, 2, 3, 4, 5, 6, 7]);
    _monthDay = item?.monthDay ?? DateTime.now().day.clamp(1, 31);
    _cooldownMinutes = item?.cooldownMinutes ?? 30;
    _chainTargetId = item?.chainTargetItemId;
    _chainDelayMinutes = item?.chainDelayMinutes ?? 30;
    _notificationsEnabled = item?.notificationsEnabled ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _fixedHour, minute: _fixedMinute),
    );
    if (picked != null) {
      setState(() {
        _fixedHour = picked.hour;
        _fixedMinute = picked.minute;
      });
    }
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final now = DateTime.now();
    final base = widget.initialItem ??
        DidItItem(
          id: _uuid.v4(),
          title: title,
        );

    final draft = base.copyWith(
      title: title,
      categoryIcon: _categoryIcon,
      repeatMode: _repeatMode,
      intervalMinutes: _intervalMinutes,
      fixedHour: _fixedHour,
      fixedMinute: _fixedMinute,
      weekdays: _weekdays.isEmpty ? const <int>[1, 2, 3, 4, 5, 6, 7] : _weekdays,
      monthDay: _monthDay,
      cooldownMinutes: _cooldownMinutes,
      chainTargetItemId: _chainTargetId,
      clearChainTarget: _chainTargetId == null,
      chainDelayMinutes: _chainDelayMinutes,
      notificationsEnabled: _notificationsEnabled,
    );

    final nextDue = widget.initialItem != null &&
            widget.initialItem!.repeatMode == _repeatMode &&
            widget.initialItem!.nextDueAt != null
        ? widget.initialItem!.nextDueAt
        : (_repeatMode == LoopRepeatMode.chainTriggered
            ? null
            : (_repeatMode == LoopRepeatMode.fromLastDone
                ? now
                : AutomationEngine.computeNextDueAt(draft, now)));

    widget.onSave?.call(
      draft.copyWith(
        nextDueAt: nextDue,
        clearNextDueAt: nextDue == null,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final s = widget.strings;
    final candidates = widget.existingItems
        .where((i) => i.id != widget.initialItem?.id && i.flowId == null)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
        border: Border(top: BorderSide(color: palette.border)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.md,
        AppSpacing.base,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.base,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Center(
                child: Container(
                  width: 40,
                  height: AppSpacing.xs,
                  decoration: BoxDecoration(
                    color: palette.border,
                    borderRadius: BorderRadius.circular(AppSpacing.xs),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.base),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      widget.initialItem == null ? s.newItemTitle : s.editItemTitle,
                      style: AppTypography.title.copyWith(color: palette.textPrimary),
                    ),
                  ),
                  if (widget.initialItem != null && widget.onDelete != null)
                    IconButton(
                      tooltip: s.delete,
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onDelete?.call();
                      },
                      icon: Icon(Icons.delete_outline_rounded, color: palette.danger),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.base),
              TextField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: s.itemNameLabel,
                  hintText: s.itemNameHint,
                ),
              ),
              const SizedBox(height: AppSpacing.base),
              Text(
                s.iconLabel,
                style: AppTypography.label.copyWith(color: palette.textSecondary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: DidItIcons.all.entries.map((entry) {
                  final selected = entry.key == _categoryIcon;
                  return ChoiceChip(
                    selected: selected,
                    showCheckmark: false,
                    label: Icon(
                      entry.value,
                      size: 18,
                      color: selected ? palette.onAccentPrimary : palette.textPrimary,
                    ),
                    selectedColor: palette.accentPrimary,
                    onSelected: (_) => setState(() => _categoryIcon = entry.key),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.base),
              Text(
                s.repeatModeLabel,
                style: AppTypography.label.copyWith(color: palette.textSecondary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: <MapEntry<LoopRepeatMode, String>>[
                  MapEntry(LoopRepeatMode.fromLastDone, s.repeatFromLastDone),
                  MapEntry(LoopRepeatMode.fixedDaily, s.repeatDaily),
                  MapEntry(LoopRepeatMode.fixedWeekly, s.repeatWeekly),
                  MapEntry(LoopRepeatMode.fixedMonthly, s.repeatMonthly),
                  MapEntry(LoopRepeatMode.chainTriggered, s.repeatChainOnly),
                ].map((entry) {
                  final selected = _repeatMode == entry.key;
                  return ChoiceChip(
                    selected: selected,
                    label: Text(entry.value),
                    onSelected: (_) => setState(() => _repeatMode = entry.key),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.base),
              if (_repeatMode == LoopRepeatMode.fromLastDone) ...<Widget>[
                Text(
                  s.intervalPresetLabel,
                  style: AppTypography.label.copyWith(color: palette.textSecondary),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _intervalPresets.map((mins) {
                    return ChoiceChip(
                      selected: _intervalMinutes == mins,
                      label: Text(s.formatMinutesHuman(mins)),
                      onSelected: (_) => setState(() => _intervalMinutes = mins),
                    );
                  }).toList(),
                ),
              ] else if (_repeatMode != LoopRepeatMode.chainTriggered) ...<Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        s.scheduleTimeLabel,
                        style: AppTypography.label
                            .copyWith(color: palette.textSecondary),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.access_time_rounded, size: 18),
                      label: Text(
                        '${_fixedHour.toString().padLeft(2, '0')}:${_fixedMinute.toString().padLeft(2, '0')}',
                      ),
                    ),
                  ],
                ),
                if (_repeatMode == LoopRepeatMode.fixedWeekly) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    s.weekdaysLabel,
                    style: AppTypography.label
                        .copyWith(color: palette.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: List<Widget>.generate(7, (idx) {
                      final dayNum = idx + 1;
                      final names = s.isEs
                          ? const ['L', 'M', 'X', 'J', 'V', 'S', 'D']
                          : const ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                      final active = _weekdays.contains(dayNum);
                      return FilterChip(
                        selected: active,
                        label: Text(names[idx]),
                        onSelected: (v) {
                          setState(() {
                            if (v) {
                              _weekdays.add(dayNum);
                            } else if (_weekdays.length > 1) {
                              _weekdays.remove(dayNum);
                            }
                          });
                        },
                      );
                    }),
                  ),
                ],
                if (_repeatMode == LoopRepeatMode.fixedMonthly) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          s.monthDayLabel,
                          style: AppTypography.label
                              .copyWith(color: palette.textSecondary),
                        ),
                      ),
                      DropdownButton<int>(
                        value: _monthDay,
                        items: List<DropdownMenuItem<int>>.generate(
                          31,
                          (i) => DropdownMenuItem<int>(
                            value: i + 1,
                            child: Text('${i + 1}'),
                          ),
                        ),
                        onChanged: (v) {
                          if (v != null) setState(() => _monthDay = v);
                        },
                      ),
                    ],
                  ),
                ],
              ],
              const SizedBox(height: AppSpacing.base),
              Text(
                s.cooldownLabel,
                style: AppTypography.label.copyWith(color: palette.textSecondary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _cooldownPresets.map((mins) {
                  return ChoiceChip(
                    selected: _cooldownMinutes == mins,
                    label: Text(
                      mins == 0 ? s.cooldownNone : s.formatMinutesHuman(mins),
                    ),
                    onSelected: (_) => setState(() => _cooldownMinutes = mins),
                  );
                }).toList(),
              ),
              if (candidates.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.base),
                Text(
                  s.chainTargetLabel,
                  style: AppTypography.label.copyWith(color: palette.textSecondary),
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String?>(
                  initialValue: candidates.any((c) => c.id == _chainTargetId)
                      ? _chainTargetId
                      : null,
                  items: <DropdownMenuItem<String?>>[
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(s.noChainTarget),
                    ),
                    ...candidates.map(
                      (c) => DropdownMenuItem<String?>(
                        value: c.id,
                        child: Text(c.title, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: (val) => setState(() => _chainTargetId = val),
                ),
                if (_chainTargetId != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    s.chainDelayLabel,
                    style: AppTypography.label
                        .copyWith(color: palette.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: _chainDelayPresets.map((mins) {
                      return ChoiceChip(
                        selected: _chainDelayMinutes == mins,
                        label: Text(s.formatMinutesHuman(mins)),
                        onSelected: (_) =>
                            setState(() => _chainDelayMinutes = mins),
                      );
                    }).toList(),
                  ),
                ],
              ],
              const SizedBox(height: AppSpacing.md),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _notificationsEnabled,
                onChanged: (v) => setState(() => _notificationsEnabled = v),
                title: Text(
                  s.notificationsToggle,
                  style: AppTypography.body.copyWith(color: palette.textPrimary),
                ),
              ),
              const SizedBox(height: AppSpacing.base),
              FilledButton(
                onPressed: _submit,
                child: Text(s.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
