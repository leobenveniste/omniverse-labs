import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/loud_models.dart';
import '../services/loud_controller.dart';
import '../theme/app_theme.dart';

/// Modal bottom sheet to save the active sound reading locally and review/delete saved checks.
class SavedChecksSheet extends StatefulWidget {
  const SavedChecksSheet({
    super.key,
    required this.controller,
    this.startInSaveMode = false,
  });

  final LoudController controller;
  final bool startInSaveMode;

  static Future<void> show(
    BuildContext context, {
    required LoudController controller,
    bool startInSaveMode = false,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SavedChecksSheet(
        controller: controller,
        startInSaveMode: startInSaveMode,
      ),
    );
  }

  @override
  State<SavedChecksSheet> createState() => _SavedChecksSheetState();
}

class _SavedChecksSheetState extends State<SavedChecksSheet> {
  final TextEditingController _labelController = TextEditingController();

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _saveCurrent() async {
    HapticFeedback.mediumImpact();
    final saved = await widget.controller.saveCurrentCheck(_labelController.text);
    if (!mounted) return;
    if (saved != null) {
      _labelController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.controller.strings.checkSavedSnackbar)),
      );
    }
  }

  String _formatDate(int epochMs) {
    final dt = DateTime.fromMillisecondsSinceEpoch(epochMs);
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$mm/$dd $hh:$min';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final palette = AppPalette.of(context);
        final strings = widget.controller.strings;
        final checks = widget.controller.savedChecks;
        final canSaveCurrent =
            widget.startInSaveMode && widget.controller.hasSamples;

        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Container(
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
                const SizedBox(height: AppSpacing.base),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        canSaveCurrent
                            ? strings.saveCurrentCheckTitle
                            : strings.savedChecksTitle,
                        style: AppTypography.title.copyWith(
                          color: palette.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: strings.gotItCta,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close_rounded,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (canSaveCurrent) ...[
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _labelController,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _saveCurrent(),
                    decoration: InputDecoration(
                      hintText: strings.checkLabelHint,
                      prefixIcon: Icon(
                        Icons.place_outlined,
                        color: palette.accentPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final preset in strings.quickContextLabels)
                        ActionChip(
                          label: Text(
                            preset,
                            style: AppTypography.label.copyWith(
                              color: palette.textPrimary,
                            ),
                          ),
                          backgroundColor: palette.surfaceElevated,
                          side: BorderSide(color: palette.border),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            _labelController.text = preset;
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ElevatedButton.icon(
                    onPressed: _saveCurrent,
                    icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                    label: Text(strings.saveCheckButton),
                  ),
                  const SizedBox(height: AppSpacing.base),
                  Divider(height: 1, color: palette.border),
                  const SizedBox(height: AppSpacing.md),
                ],
                Flexible(
                  child: checks.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.lg,
                          ),
                          child: Text(
                            strings.noSavedChecksYet,
                            textAlign: TextAlign.center,
                            style: AppTypography.body.copyWith(
                              color: palette.textSecondary,
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: checks.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final item = checks[index];
                            final zoneColor = switch (item.zone) {
                              SafetyZone.safe => palette.accentPrimary,
                              SafetyZone.moderate => palette.textSecondary,
                              SafetyZone.caution => palette.warning,
                              SafetyZone.damageRisk => palette.danger,
                            };

                            return Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: palette.surfaceElevated,
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusMd),
                                border: Border.all(color: palette.border),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: zoneColor,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.label,
                                          style: AppTypography.body.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: palette.textPrimary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          '${strings.avgLabel} ${item.avgDb.toStringAsFixed(1)} dB · '
                                          '${strings.peakLabel} ${item.peakDb.toStringAsFixed(1)} dB · '
                                          '${_formatDate(item.createdAtMs)}',
                                          style: AppTypography.label.copyWith(
                                            fontWeight: FontWeight.w400,
                                            color: palette.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: strings.deleteCheckTooltip,
                                    onPressed: () {
                                      HapticFeedback.selectionClick();
                                      widget.controller
                                          .deleteSavedCheck(item.id);
                                    },
                                    icon: Icon(
                                      Icons.delete_outline_rounded,
                                      color: palette.textSecondary,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
