import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_strings.dart';
import '../models/pulse_models.dart';
import '../theme/app_theme.dart';

/// Modal sheet to save the current Stage Console tempo into a 1-Tap Setlist Slot or edit an existing one.
class SlotEditorSheet extends StatefulWidget {
  const SlotEditorSheet({
    super.key,
    this.existingSlot,
    required this.currentBpm,
    required this.currentSignature,
    required this.strings,
    required this.onSave,
    this.onDelete,
  });

  final SetlistSlot? existingSlot;
  final int currentBpm;
  final TimeSignatureOption currentSignature;
  final AppStrings strings;
  final Future<void> Function(
    String name,
    int bpm,
    TimeSignatureOption signature,
  ) onSave;
  final Future<void> Function()? onDelete;

  @override
  State<SlotEditorSheet> createState() => _SlotEditorSheetState();
}

class _SlotEditorSheetState extends State<SlotEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late int _bpm;
  late TimeSignatureOption _signature;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingSlot;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _bpm = existing?.bpm ?? widget.currentBpm;
    _signature = existing?.signature ?? widget.currentSignature;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();
    await widget.onSave(_nameController.text.trim(), _bpm, _signature);
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final strings = widget.strings;
    final isEditing = widget.existingSlot != null;

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
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              const SizedBox(height: AppSpacing.md),
              Text(
                isEditing ? strings.slotSheetTitleEdit : strings.slotSheetTitleNew,
                style: AppTypography.title.copyWith(color: palette.textPrimary),
              ),
              const SizedBox(height: AppSpacing.base),
              TextFormField(
                controller: _nameController,
                autofocus: !isEditing,
                textCapitalization: TextCapitalization.words,
                maxLength: 24,
                style: AppTypography.body.copyWith(color: palette.textPrimary),
                decoration: InputDecoration(
                  labelText: strings.slotNameLabel,
                  hintText: strings.slotNameHint,
                  counterText: '',
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? strings.slotNameError
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: palette.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: palette.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$_bpm ${strings.bpmUnit} · ${_signature.label}',
                      style: AppTypography.title.copyWith(
                        color: palette.accentPrimary,
                      ),
                    ),
                    if (isEditing &&
                        (_bpm != widget.currentBpm ||
                            _signature != widget.currentSignature))
                      TextButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _bpm = widget.currentBpm;
                            _signature = widget.currentSignature;
                          });
                        },
                        child: Text(strings.updateToCurrentTempo),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.base),
              Row(
                children: [
                  if (isEditing && widget.onDelete != null) ...[
                    OutlinedButton.icon(
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: palette.danger,
                        size: 18,
                      ),
                      label: Text(
                        strings.deleteSlotCta,
                        style: AppTypography.body.copyWith(
                          color: palette.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () async {
                        HapticFeedback.mediumImpact();
                        await widget.onDelete!();
                        if (context.mounted) {
                          Navigator.of(context).pop(true);
                        }
                      },
                    ),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : _submit,
                      child: Text(
                        isEditing ? strings.saveChangesCta : strings.saveSlotCta,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
