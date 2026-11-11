import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../l10n/app_strings.dart';
import '../models/guarded_item.dart';
import '../theme/app_theme.dart';

/// Displays an active or cancelled trial/subscription with Escape Hatch & ROI actions.
class GuardedItemCard extends StatelessWidget {
  const GuardedItemCard({
    super.key,
    required this.item,
    required this.currency,
    required this.strings,
    required this.onTap,
    required this.onOpenCancelLink,
    required this.onMarkCancelled,
    this.onRestore,
    this.onDelete,
    this.isHighlighted = false,
  });

  final GuardedItem item;
  final String currency;
  final AppStrings strings;
  final VoidCallback onTap;
  final VoidCallback onOpenCancelLink;
  final VoidCallback onMarkCancelled;
  final VoidCallback? onRestore;
  final VoidCallback? onDelete;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final now = DateTime.now();
    final urgency = item.urgencyAt(now);
    final isActive = item.status == ItemStatus.active;
    final hasCancelLink = item.cancelUrl.trim().isNotEmpty;
    final cardPalette = _UrgencyPalette.from(
      urgency,
      palette: palette,
      isActive: isActive,
    );
    final formattedDate = DateFormat.MMMd().format(item.chargeAt);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: isHighlighted ? palette.surfaceElevated : palette.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isHighlighted ? palette.accentPrimary : cardPalette.borderColor,
          width: isHighlighted ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Container(
                        width: AppSpacing.sm,
                        height: AppSpacing.sm,
                        decoration: BoxDecoration(
                          color: cardPalette.dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: AppTypography.title
                                .copyWith(color: palette.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            isActive
                                ? '${strings.countdownText(item, now)} • $formattedDate'
                                : '${strings.alertPresetLabel(item.alertPreset)} • $formattedDate',
                            style: AppTypography.body.copyWith(
                              color: isActive
                                  ? cardPalette.statusTextColor
                                  : palette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          strings.formatMoney(currency, item.amount),
                          style: AppTypography.title.copyWith(
                            color: palette.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        Text(
                          strings.cycleSuffix(item.billingCycle),
                          style: AppTypography.label
                              .copyWith(color: palette.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                if (item.notes.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    item.notes,
                    style: AppTypography.label.copyWith(
                      fontWeight: FontWeight.w400,
                      color: palette.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                if (isActive)
                  Row(
                    children: [
                      if (hasCancelLink) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              onOpenCancelLink();
                            },
                            icon: const Icon(Icons.open_in_new_rounded, size: 16),
                            label: Text(
                              strings.openCancelLink,
                              style: AppTypography.label.copyWith(
                                color: palette.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            onMarkCancelled();
                          },
                          icon: const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 16,
                          ),
                          label: Text(
                            strings.markCancelled,
                            style: AppTypography.label.copyWith(
                              color: palette.onAccentPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onRestore,
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: Text(
                            strings.restoreItem,
                            style: AppTypography.label.copyWith(
                              color: palette.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Tooltip(
                        message: strings.deleteItem,
                        child: SizedBox(
                          height: AppSpacing.minTouchTarget,
                          width: AppSpacing.minTouchTarget,
                          child: OutlinedButton(
                            onPressed: onDelete,
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              foregroundColor: palette.dangerText,
                            ),
                            child: Semantics(
                              label: strings.deleteItem,
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UrgencyPalette {
  const _UrgencyPalette({
    required this.dotColor,
    required this.borderColor,
    required this.statusTextColor,
  });

  final Color dotColor;
  final Color borderColor;
  final Color statusTextColor;

  factory _UrgencyPalette.from(
    UrgencyLevel urgency, {
    required AppPalette palette,
    required bool isActive,
  }) {
    if (!isActive) {
      return _UrgencyPalette(
        dotColor: palette.textSecondary,
        borderColor: palette.border,
        statusTextColor: palette.textSecondary,
      );
    }
    return switch (urgency) {
      UrgencyLevel.expired || UrgencyLevel.urgent24h => _UrgencyPalette(
          dotColor: palette.danger,
          borderColor: palette.danger,
          statusTextColor: palette.dangerText,
        ),
      UrgencyLevel.warning48h => _UrgencyPalette(
          dotColor: palette.warning,
          borderColor: palette.warning,
          statusTextColor: palette.warningText,
        ),
      UrgencyLevel.safe => _UrgencyPalette(
          dotColor: palette.accentPrimary,
          borderColor: palette.border,
          statusTextColor: palette.textSecondary,
        ),
    };
  }
}
