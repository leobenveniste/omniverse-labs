import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';

class KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? valueColor;
  final Color? accentColor;

  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.valueColor,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final effectiveAccent = accentColor ?? colors.primary;

    return Container(
      padding: AppSpacing.paddingCard,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: colors.outline, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: AppTypography.caption(colors.textSecondary, isMedium: true),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: effectiveAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: effectiveAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTypography.display(valueColor ?? colors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              subtitle!,
              style: AppTypography.caption(colors.textTertiary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
