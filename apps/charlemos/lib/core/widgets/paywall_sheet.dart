import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../services/app_services.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/haptics_helper.dart';

class PaywallSheet extends StatelessWidget {
  final String? customReason;

  const PaywallSheet({
    super.key,
    this.customReason,
  });

  static Future<void> show(BuildContext context, {String? customReason}) {
    HapticsHelper.medium();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PaywallSheet(customReason: customReason),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final premiumService = AppServices.of(context).premiumService;

    final priceText = premiumService.proProduct?.price ?? '\$2.99 USD';

    return AnimatedBuilder(
      animation: premiumService,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
          ),
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.md,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.92,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Scrollable content
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Glowing Hero Badge
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFE5BA5A), // Soft warm gold
                              Color(0xFFC85A3B), // Terracotta
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFC85A3B).withValues(alpha: 0.35),
                              blurRadius: 20,
                              spreadRadius: 2,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          size: 38,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Title
                      Text(
                        l10n.t('proTitle'),
                        style: AppTypography.display(theme.colorScheme.onSurface).copyWith(
                          fontSize: 26,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        l10n.t('proTagline'),
                        textAlign: TextAlign.center,
                        style: AppTypography.body(theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                      ),

                      // Custom reason banner if triggered by a specific limit
                      if (customReason != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC85A3B).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            border: Border.all(color: const Color(0xFFC85A3B).withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFC85A3B)),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  customReason!,
                                  style: AppTypography.caption(const Color(0xFFC85A3B), isMedium: true),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),

                      // Benefit Cards Container
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                        ),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          children: [
                            _buildBenefitRow(
                              context,
                              icon: Icons.style_rounded,
                              iconColor: const Color(0xFFC85A3B),
                              title: l10n.t('proFeature1Title'),
                              description: l10n.t('proFeature1Desc'),
                            ),
                            const Divider(height: AppSpacing.lg),
                            _buildBenefitRow(
                              context,
                              icon: Icons.dashboard_customize_rounded,
                              iconColor: const Color(0xFF2D7A4F),
                              title: l10n.t('proFeature2Title'),
                              description: l10n.t('proFeature2Desc'),
                            ),
                            const Divider(height: AppSpacing.lg),
                            _buildBenefitRow(
                              context,
                              icon: Icons.edit_note_rounded,
                              iconColor: const Color(0xFF3B82F6),
                              title: l10n.t('proFeature3Title'),
                              description: l10n.t('proFeature3Desc'),
                            ),
                            const Divider(height: AppSpacing.lg),
                            _buildBenefitRow(
                              context,
                              icon: Icons.palette_outlined,
                              iconColor: const Color(0xFF8B5CF6),
                              title: l10n.t('proFeature4Title'),
                              description: l10n.t('proFeature4Desc'),
                            ),
                            const Divider(height: AppSpacing.lg),
                            _buildBenefitRow(
                              context,
                              icon: Icons.all_inclusive_rounded,
                              iconColor: const Color(0xFFE5BA5A),
                              title: l10n.t('proFeature5Title'),
                              description: l10n.t('proFeature5Desc'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Lifetime Value Card
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFC85A3B).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                          border: Border.all(color: const Color(0xFFC85A3B).withValues(alpha: 0.25)),
                        ),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFC85A3B).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.verified_rounded, color: Color(0xFFC85A3B), size: 24),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.t('lifetimeAccessTitle'),
                                    style: AppTypography.body(theme.colorScheme.onSurface, isMedium: true),
                                  ),
                                  Text(
                                    l10n.t('lifetimeAccessDesc'),
                                    style: AppTypography.caption(theme.colorScheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Error message banner
                      if (premiumService.errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: Text(
                            premiumService.errorMessage!,
                            style: AppTypography.caption(theme.colorScheme.onErrorContainer),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],

                      // CTA Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: premiumService.isLoading
                              ? null
                              : () async {
                                  HapticsHelper.medium();
                                  await premiumService.buyPro();
                                  if (context.mounted && premiumService.isPro) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(l10n.t('purchaseSuccess')),
                                        backgroundColor: const Color(0xFF2E7D32),
                                      ),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC85A3B),
                            foregroundColor: Colors.white,
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                          ),
                          child: premiumService.isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                )
                              : Text(
                                  l10n.t('unlockProBtn', args: {'price': priceText}),
                                  style: AppTypography.body(Colors.white, isMedium: true).copyWith(fontSize: 16),
                                ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Restore Purchases
                      TextButton(
                        onPressed: premiumService.isLoading
                            ? null
                            : () async {
                                HapticsHelper.light();
                                final success = await premiumService.restorePurchases();
                                if (context.mounted) {
                                  if (success) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(l10n.t('restoreSuccess')),
                                        backgroundColor: const Color(0xFF2E7D32),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(l10n.t('restoreNotFound')),
                                      ),
                                    );
                                  }
                                }
                              },
                        child: Text(
                          l10n.t('restorePurchases'),
                          style: AppTypography.caption(theme.colorScheme.primary, isMedium: true),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBenefitRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.body(theme.colorScheme.onSurface, isMedium: true),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: AppTypography.caption(theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
