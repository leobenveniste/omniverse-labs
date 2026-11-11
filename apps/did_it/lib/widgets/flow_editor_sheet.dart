import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../l10n/app_strings.dart';
import '../models/did_it_models.dart';
import '../theme/app_theme.dart';

/// Bottom sheet editor to create or customize an auto-resetting multi-step CheckFlow.
class FlowEditorSheet extends StatefulWidget {
  const FlowEditorSheet({
    super.key,
    required this.strings,
    this.initialFlow,
    this.initialSteps = const <DidItItem>[],
    this.onSave,
    this.onDelete,
  });

  final AppStrings strings;
  final CheckFlow? initialFlow;
  final List<DidItItem> initialSteps;
  final void Function(CheckFlow flow, List<DidItItem> steps)? onSave;
  final VoidCallback? onDelete;

  static Future<void> show(
    BuildContext context, {
    required AppStrings strings,
    CheckFlow? initialFlow,
    List<DidItItem> initialSteps = const <DidItItem>[],
    required void Function(CheckFlow flow, List<DidItItem> steps) onSave,
    VoidCallback? onDelete,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FlowEditorSheet(
        strings: strings,
        initialFlow: initialFlow,
        initialSteps: initialSteps,
        onSave: onSave,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<FlowEditorSheet> createState() => _FlowEditorSheetState();
}

class _FlowEditorSheetState extends State<FlowEditorSheet> {
  static const Uuid _uuid = Uuid();
  late final TextEditingController _nameController;
  late final TextEditingController _stepController;

  late String _iconKey;
  late FlowResetRule _resetRule;
  late int _cooldownMinutes;
  late int _resetHour;
  late int _resetMinute;
  late List<DidItItem> _steps;

  @override
  void initState() {
    super.initState();
    final f = widget.initialFlow;
    _nameController = TextEditingController(text: f?.title ?? '');
    _stepController = TextEditingController();
    _iconKey = f?.iconKey ?? 'flow';
    _resetRule = f?.resetRule ?? FlowResetRule.onAllComplete;
    _cooldownMinutes = f?.resetCooldownMinutes ?? 15;
    _resetHour = f?.resetHour ?? 6;
    _resetMinute = f?.resetMinute ?? 0;
    _steps = List<DidItItem>.from(widget.initialSteps)
      ..sort((a, b) => a.flowOrder.compareTo(b.flowOrder));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _stepController.dispose();
    super.dispose();
  }

  void _addStep() {
    final text = _stepController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _steps.add(
        DidItItem(
          id: _uuid.v4(),
          title: text,
          categoryIcon: _iconKey,
          repeatMode: LoopRepeatMode.chainTriggered,
          flowId: widget.initialFlow?.id ?? 'pending',
          flowOrder: _steps.length,
          notificationsEnabled: false,
        ),
      );
      _stepController.clear();
    });
  }

  void _submit() {
    final title = _nameController.text.trim();
    if (title.isEmpty || _steps.isEmpty) return;

    final flowId = widget.initialFlow?.id ?? _uuid.v4();
    final flow = (widget.initialFlow ?? CheckFlow(id: flowId, title: title)).copyWith(
      title: title,
      iconKey: _iconKey,
      resetRule: _resetRule,
      resetCooldownMinutes: _cooldownMinutes,
      resetHour: _resetHour,
      resetMinute: _resetMinute,
    );

    final orderedSteps = <DidItItem>[];
    for (var i = 0; i < _steps.length; i++) {
      orderedSteps.add(
        _steps[i].copyWith(
          flowId: flowId,
          flowOrder: i,
          categoryIcon: _iconKey,
        ),
      );
    }

    widget.onSave?.call(flow, orderedSteps);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final s = widget.strings;

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
                      widget.initialFlow == null ? s.newFlowTitle : s.editFlowTitle,
                      style: AppTypography.title.copyWith(color: palette.textPrimary),
                    ),
                  ),
                  if (widget.initialFlow != null && widget.onDelete != null)
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
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: s.flowNameLabel,
                  hintText: s.flowNameHint,
                ),
              ),
              const SizedBox(height: AppSpacing.base),
              Text(
                s.flowResetRuleLabel,
                style: AppTypography.label.copyWith(color: palette.textSecondary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: FlowResetRule.values.map((rule) {
                  final hhmm = '${_resetHour.toString().padLeft(2, '0')}:'
                      '${_resetMinute.toString().padLeft(2, '0')}';
                  return ChoiceChip(
                    selected: _resetRule == rule,
                    label: Text(s.resetRuleLabel(rule.name, _cooldownMinutes, hhmm)),
                    onSelected: (_) => setState(() => _resetRule = rule),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.base),
              Text(
                s.flowStepsLabel,
                style: AppTypography.label.copyWith(color: palette.textSecondary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _stepController,
                      onSubmitted: (_) => _addStep(),
                      decoration: InputDecoration(hintText: s.addStepHint),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton(
                    onPressed: _addStep,
                    child: Text(s.addStepBtn),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ...List<Widget>.generate(_steps.length, (index) {
                final step = _steps[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: palette.surfaceElevated,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: palette.border),
                    ),
                    child: Row(
                      children: <Widget>[
                        Text(
                          '${index + 1}.',
                          style: AppTypography.label
                              .copyWith(color: palette.accentPrimary),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            step.title,
                            style: AppTypography.body
                                .copyWith(color: palette.textPrimary),
                          ),
                        ),
                        IconButton(
                          tooltip: s.delete,
                          onPressed: () => setState(() => _steps.removeAt(index)),
                          icon: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: palette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
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
