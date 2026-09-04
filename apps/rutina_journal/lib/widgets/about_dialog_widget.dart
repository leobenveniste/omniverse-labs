import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'state_button.dart';

class AboutDialogWidget extends StatelessWidget {
  const AboutDialogWidget({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const AboutDialogWidget(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(color: theme.colorScheme.outline, width: 1.0),
      ),
      backgroundColor: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Omniverse Labs Logo
            Image.asset(
              isDark
                  ? 'assets/images/omniverse_labs_white.png'
                  : 'assets/images/omniverse_labs_color.png',
              width: 84,
              height: 84,
              errorBuilder: (_, __, ___) => Icon(
                Icons.all_inclusive_rounded,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Company Heading
            Text(
              l10n.t('aboutCompany'),
              style: AppTypography.section(theme.colorScheme.onSurface).copyWith(
                letterSpacing: 2.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),

            // Mission Statement
            Text(
              l10n.t('aboutMission'),
              textAlign: TextAlign.center,
              style: AppTypography.body(theme.colorScheme.onSurface.withValues(alpha: 0.75)),
            ),
            const SizedBox(height: AppSpacing.md),
            Divider(color: theme.colorScheme.outline),
            const SizedBox(height: AppSpacing.sm),

            // App details
            _buildRow(
              context,
              label: l10n.t('appDetailsLabel'),
              value: 'Ritmo',
              isBold: true,
            ),
            const SizedBox(height: AppSpacing.xs),
            _buildRow(
              context,
              label: l10n.t('packageIdLabel'),
              value: 'com.omniverselabs.ritmo',
            ),
            const SizedBox(height: AppSpacing.xs),
            _buildRow(
              context,
              label: l10n.t('versionLabel'),
              value: '1.0.0 (Build 6)',
            ),
            const SizedBox(height: AppSpacing.xs),
            _buildRow(
              context,
              label: l10n.t('releaseDateLabel'),
              value: l10n.t('releaseDateValue'),
            ),
            const SizedBox(height: AppSpacing.md),

            // Privacy Box
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      l10n.t('privacyGuarantee'),
                      style: AppTypography.caption(theme.colorScheme.onSurface.withValues(alpha: 0.8)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Close Button
            StateButton(
              label: l10n.t('actionClose'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(
    BuildContext context, {
    required String label,
    required String value,
    bool isBold = false,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.caption(theme.colorScheme.onSurface.withValues(alpha: 0.7), isMedium: true),
        ),
        Text(
          value,
          style: AppTypography.caption(
            isBold ? theme.colorScheme.primary : theme.colorScheme.onSurface,
            isMedium: isBold,
          ),
        ),
      ],
    );
  }
}
