import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../l10n/app_strings.dart';
import '../models/common_services.dart';
import '../models/guarded_item.dart';
import '../theme/app_theme.dart';

/// Result emitted when saving or acting on a guarded item inside [TrialEntrySheet].
class TrialEntryResult {
  const TrialEntryResult._({
    required this.action,
    this.name,
    this.amount,
    this.kind,
    this.billingCycle,
    this.chargeAt,
    this.alertPreset,
    this.cancelUrl,
    this.notes,
  });

  const TrialEntryResult.save({
    required String name,
    required double amount,
    required ItemKind kind,
    required BillingCycle billingCycle,
    required DateTime chargeAt,
    required AlertPreset alertPreset,
    required String cancelUrl,
    required String notes,
  }) : this._(
          action: TrialSheetAction.save,
          name: name,
          amount: amount,
          kind: kind,
          billingCycle: billingCycle,
          chargeAt: chargeAt,
          alertPreset: alertPreset,
          cancelUrl: cancelUrl,
          notes: notes,
        );

  const TrialEntryResult.markCancelled()
      : this._(action: TrialSheetAction.markCancelled);

  const TrialEntryResult.delete() : this._(action: TrialSheetAction.delete);

  final TrialSheetAction action;
  final String? name;
  final double? amount;
  final ItemKind? kind;
  final BillingCycle? billingCycle;
  final DateTime? chargeAt;
  final AlertPreset? alertPreset;
  final String? cancelUrl;
  final String? notes;
}

enum TrialSheetAction { save, markCancelled, delete }

/// Modal bottom sheet with a filterable 50-service dropdown + custom text support.
class TrialEntrySheet extends StatefulWidget {
  const TrialEntrySheet({
    super.key,
    required this.strings,
    required this.currency,
    this.existingItem,
  });

  final AppStrings strings;
  final String currency;
  final GuardedItem? existingItem;

  @override
  State<TrialEntrySheet> createState() => _TrialEntrySheetState();
}

class _TrialEntrySheetState extends State<TrialEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameFocusNode = FocusNode();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _cancelUrlController;
  late final TextEditingController _notesController;

  late ItemKind _kind;
  late BillingCycle _billingCycle;
  late DateTime _chargeAt;
  late AlertPreset _alertPreset;
  int? _selectedDurationDays;

  bool get _isEditing => widget.existingItem != null;

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    _nameController = TextEditingController(text: item?.name ?? '');
    _priceController = TextEditingController(
      text: item != null ? item.amount.toStringAsFixed(2) : '',
    );
    _cancelUrlController = TextEditingController(text: item?.cancelUrl ?? '');
    _notesController = TextEditingController(text: item?.notes ?? '');

    _kind = item?.kind ?? ItemKind.trial;
    _billingCycle = item?.billingCycle ?? BillingCycle.monthly;
    _chargeAt = item?.chargeAt ?? _defaultDateInDays(7);
    _alertPreset = item?.alertPreset ?? AlertPreset.buffer48And24;
    _selectedDurationDays = item == null ? 7 : null;
  }

  @override
  void dispose() {
    _nameFocusNode.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _cancelUrlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  DateTime _defaultDateInDays(int days) {
    final target = DateTime.now().add(Duration(days: days));
    return DateTime(target.year, target.month, target.day, 10, 0);
  }

  Future<void> _pickCustomDate() async {
    final now = DateTime.now();
    final initial = _chargeAt.isAfter(now) ? _chargeAt : now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedDurationDays = null;
      _chargeAt = DateTime(picked.year, picked.month, picked.day, 10, 0);
    });
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    HapticFeedback.mediumImpact();
    final parsedAmount =
        double.tryParse(_priceController.text.replaceAll(',', '.').trim()) ??
            0.0;
    Navigator.of(context).pop(
      TrialEntryResult.save(
        name: _nameController.text.trim(),
        amount: parsedAmount,
        kind: _kind,
        billingCycle: _billingCycle,
        chargeAt: _chargeAt,
        alertPreset: _alertPreset,
        cancelUrl: _cancelUrlController.text.trim(),
        notes: _notesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    final palette = AppPalette.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final maxSheetHeight = MediaQuery.sizeOf(context).height * 0.9;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      child: Container(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusPill),
          ),
          border: Border(
            top: BorderSide(color: palette.border),
            left: BorderSide(color: palette.border),
            right: BorderSide(color: palette.border),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.base,
          AppSpacing.md,
          AppSpacing.base,
          AppSpacing.base + bottomInset,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: AppSpacing.xl,
                  height: AppSpacing.xs,
                  decoration: BoxDecoration(
                    color: palette.border,
                    borderRadius: BorderRadius.circular(AppSpacing.xs),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEditing
                          ? strings.sheetTitleEdit
                          : strings.sheetTitleNew,
                      style: AppTypography.title
                          .copyWith(color: palette.textPrimary),
                    ),
                  ),
                  Tooltip(
                    message: MaterialLocalizations.of(context).closeButtonTooltip,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.sm),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return RawAutocomplete<String>(
                            textEditingController: _nameController,
                            focusNode: _nameFocusNode,
                            optionsBuilder: (textEditingValue) {
                              final query =
                                  textEditingValue.text.trim().toLowerCase();
                              if (query.isEmpty) return kCommonServices;
                              return kCommonServices.where(
                                (service) =>
                                    service.toLowerCase().contains(query),
                              );
                            },
                            onSelected: (_) =>
                                HapticFeedback.selectionClick(),
                            fieldViewBuilder: (
                              context,
                              controller,
                              focusNode,
                              onFieldSubmitted,
                            ) {
                              return TextFormField(
                                controller: controller,
                                focusNode: focusNode,
                                textCapitalization: TextCapitalization.words,
                                decoration: InputDecoration(
                                  labelText: strings.serviceNameLabel,
                                  hintText: strings.serviceNameHint,
                                  suffixIcon: Icon(
                                    Icons.arrow_drop_down_rounded,
                                    color: palette.textSecondary,
                                  ),
                                ),
                                validator: (value) =>
                                    (value == null || value.trim().isEmpty)
                                        ? strings.serviceNameError
                                        : null,
                              );
                            },
                            optionsViewBuilder: (context, onSelected, options) {
                              return Align(
                                alignment: Alignment.topLeft,
                                child: Material(
                                  elevation: 6,
                                  color: palette.surfaceElevated,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusMd,
                                    ),
                                    side: BorderSide(color: palette.border),
                                  ),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxHeight: 220,
                                      maxWidth: constraints.maxWidth,
                                    ),
                                    child: ListView.separated(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: AppSpacing.xs,
                                      ),
                                      shrinkWrap: true,
                                      itemCount: options.length,
                                      separatorBuilder: (_, _) => Divider(
                                        height: 1,
                                        color: palette.border,
                                      ),
                                      itemBuilder: (context, index) {
                                        final option = options.elementAt(index);
                                        return ListTile(
                                          dense: true,
                                          title: Text(
                                            option,
                                            style: AppTypography.body.copyWith(
                                              color: palette.textPrimary,
                                            ),
                                          ),
                                          onTap: () => onSelected(option),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: strings.priceLabel,
                          prefixText: '${widget.currency} ',
                        ),
                        validator: (value) {
                          final parsed = double.tryParse(
                            (value ?? '').replaceAll(',', '.').trim(),
                          );
                          if (parsed == null || parsed <= 0) {
                            return strings.priceError;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.base),
                      Text(
                        strings.typeLabel,
                        style: AppTypography.label
                            .copyWith(color: palette.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          _SelectableChip(
                            label: strings.trialType,
                            selected: _kind == ItemKind.trial,
                            onTap: () => setState(() {
                              _kind = ItemKind.trial;
                              _billingCycle = BillingCycle.monthly;
                            }),
                          ),
                          _SelectableChip(
                            label: strings.recurringType,
                            selected: _kind == ItemKind.recurring,
                            onTap: () =>
                                setState(() => _kind = ItemKind.recurring),
                          ),
                          if (_kind == ItemKind.recurring) ...[
                            _SelectableChip(
                              label: strings.cycleMonthly,
                              selected: _billingCycle == BillingCycle.monthly,
                              onTap: () => setState(() {
                                _billingCycle = BillingCycle.monthly;
                                _selectedDurationDays = 30;
                                _chargeAt = _defaultDateInDays(30);
                              }),
                            ),
                            _SelectableChip(
                              label: strings.cycleAnnual,
                              selected: _billingCycle == BillingCycle.annual,
                              onTap: () => setState(() {
                                _billingCycle = BillingCycle.annual;
                                _alertPreset = AlertPreset.buffer7dAnd48h;
                                _selectedDurationDays = 365;
                                _chargeAt = _defaultDateInDays(365);
                              }),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.base),
                      Text(
                        strings.chargeDateLabel,
                        style: AppTypography.label
                            .copyWith(color: palette.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final days in const [7, 14, 30])
                            _SelectableChip(
                              label: strings.durationChipLabel(days),
                              selected: _selectedDurationDays == days,
                              onTap: () => setState(() {
                                _selectedDurationDays = days;
                                _chargeAt = _defaultDateInDays(days);
                              }),
                            ),
                          OutlinedButton.icon(
                            onPressed: _pickCustomDate,
                            icon:
                                const Icon(Icons.calendar_today_rounded, size: 16),
                            label: Text(
                              '${strings.pickDate}: ${DateFormat.yMMMd().format(_chargeAt)}',
                              style: AppTypography.label
                                  .copyWith(color: palette.textPrimary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.base),
                      Text(
                        strings.alertBufferLabel,
                        style: AppTypography.label
                            .copyWith(color: palette.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final preset in AlertPreset.values)
                            _SelectableChip(
                              label: strings.alertPresetLabel(preset),
                              selected: _alertPreset == preset,
                              onTap: () =>
                                  setState(() => _alertPreset = preset),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.base),
                      TextFormField(
                        controller: _cancelUrlController,
                        keyboardType: TextInputType.url,
                        decoration: InputDecoration(
                          labelText: strings.cancelUrlLabel,
                          hintText: strings.cancelUrlHint,
                          prefixIcon: const Icon(Icons.link_rounded, size: 18),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          labelText: strings.notesLabel,
                          hintText: strings.notesHint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.base),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.shield_outlined),
                  label: Text(
                    _isEditing
                        ? strings.saveChangesCta
                        : strings.activateShieldCta,
                  ),
                ),
              ),
              if (_isEditing) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    if (widget.existingItem!.status == ItemStatus.active)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context)
                              .pop(const TrialEntryResult.markCancelled()),
                          child: Text(strings.markCancelled),
                        ),
                      ),
                    if (widget.existingItem!.status == ItemStatus.active)
                      const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context)
                            .pop(const TrialEntryResult.delete()),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: palette.dangerText,
                        ),
                        child: Text(strings.deleteItem),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectableChip extends StatelessWidget {
  const _SelectableChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return ChoiceChip(
      label: Text(
        label,
        style: AppTypography.label.copyWith(
          color: selected ? palette.onAccentPrimary : palette.textPrimary,
        ),
      ),
      selected: selected,
      onSelected: (_) {
        HapticFeedback.selectionClick();
        onTap();
      },
      selectedColor: palette.accentPrimary,
      backgroundColor: palette.surfaceElevated,
      side: BorderSide(
        color: selected ? palette.accentPrimary : palette.border,
      ),
      showCheckmark: false,
    );
  }
}
