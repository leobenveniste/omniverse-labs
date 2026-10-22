import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics_helper.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/settings_provider.dart';

class PaywallSheet extends StatefulWidget {
  final SettingsProvider settingsProvider;
  final String? customReason;

  const PaywallSheet({
    super.key,
    required this.settingsProvider,
    this.customReason,
  });

  static Future<void> show(
    BuildContext context, {
    required SettingsProvider settingsProvider,
    String? customReason,
  }) {
    HapticsHelper.medium();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PaywallSheet(
        settingsProvider: settingsProvider,
        customReason: customReason,
      ),
    );
  }

  @override
  State<PaywallSheet> createState() => _PaywallSheetState();
}

class _PaywallSheetState extends State<PaywallSheet> {
  bool _isLoading = false;

  Future<void> _handleBuy() async {
    HapticsHelper.medium();
    setState(() => _isLoading = true);
    try {
      final success = await widget.settingsProvider.buyPro();
      if (!mounted) return;
      if (widget.settingsProvider.isPro) {
        Navigator.of(context).pop();
      } else if (!success) {
        // If purchase initiation failed or not completed
        debugPrint('Buy Pro not completed');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRestore() async {
    HapticsHelper.light();
    setState(() => _isLoading = true);
    try {
      await widget.settingsProvider.restorePurchases();
      if (!mounted) return;
      if (widget.settingsProvider.isPro) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final settingsProvider = widget.settingsProvider;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
        border: Border.all(color: colors.outline, width: 1.2),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Badge & Title
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.proGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    border: Border.all(color: colors.proGold.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stars_rounded, color: colors.proGold, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        l10n.t('lifetimePassBadge'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: colors.proGold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            Text(
              l10n.t('paywallTitle'),
              textAlign: TextAlign.center,
              style: AppTypography.display(colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              widget.customReason ?? l10n.t('paywallDefaultSubtitle'),
              textAlign: TextAlign.center,
              style: AppTypography.body(colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Features List
            _buildFeatureItem(
              icon: Icons.all_inclusive_rounded,
              title: l10n.t('featureUnlimitedTradesTitle'),
              subtitle: l10n.t('featureUnlimitedTradesSubtitle'),
              colors: colors,
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildFeatureItem(
              icon: Icons.show_chart_rounded,
              title: l10n.t('featureAnalyticsTitle'),
              subtitle: l10n.t('featureAnalyticsSubtitle'),
              colors: colors,
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildFeatureItem(
              icon: Icons.file_download_outlined,
              title: l10n.t('featureExportTitle'),
              subtitle: l10n.t('featureExportSubtitle'),
              colors: colors,
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildFeatureItem(
              icon: Icons.psychology_rounded,
              title: l10n.t('featureMindsetTitle'),
              subtitle: l10n.t('featureMindsetSubtitle'),
              colors: colors,
            ),

            const SizedBox(height: AppSpacing.lg),

            // Primary Buy Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
              ),
              onPressed: _isLoading ? null : _handleBuy,
              child: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.onPrimary,
                      ),
                    )
                  : Text(
                      l10n.t('unlockProPriceButton'),
                      style: AppTypography.body(colors.onPrimary, isBold: true),
                    ),
            ),
            const SizedBox(height: AppSpacing.xs),

            // Restore Purchases
            TextButton(
              onPressed: _isLoading ? null : _handleRestore,
              child: Text(
                l10n.t('restorePurchasesAction'),
                style: AppTypography.caption(colors.textSecondary),
              ),
            ),

            // Developer Shortcut in Paywall (Protected by devMode)
            if (settingsProvider.isDevMode) ...[
              const Divider(),
              const SizedBox(height: AppSpacing.xs),
              InkWell(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                onTap: () async {
                  HapticsHelper.medium();
                  await settingsProvider.toggleTestPro(true);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.t('activatingTestProToast')),
                      ),
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.science_rounded, color: colors.proGold, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        l10n.t('testProShortcut'),
                        style: AppTypography.caption(colors.proGold, isBold: true),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required AppColors colors,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: colors.outline, width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
            ),
            child: Icon(icon, color: colors.secondary, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.body(colors.textPrimary, isBold: true),
                ),
                Text(
                  subtitle,
                  style: AppTypography.caption(colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
