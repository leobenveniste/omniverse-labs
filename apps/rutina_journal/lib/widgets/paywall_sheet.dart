import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/app_services.dart';
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
                      // Glowing Zen Hero Badge
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFE5BA5A), // Soft warm gold
                              Color(0xFFE07A5F), // Terracotta
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE07A5F).withValues(alpha: 0.35),
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
                            color: const Color(0xFFE07A5F).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            border: Border.all(color: const Color(0xFFE07A5F).withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFE07A5F)),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  customReason!,
                                  style: AppTypography.caption(const Color(0xFFE07A5F), isMedium: true),
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
                              icon: Icons.self_improvement_rounded,
                              iconColor: const Color(0xFFE07A5F),
                              title: l10n.t('proFeatureFocusTitle'),
                              description: l10n.t('proFeatureFocusDesc'),
                            ),
                            const Divider(height: AppSpacing.lg),
                            _buildBenefitRow(
                              context,
                              icon: Icons.all_inclusive_rounded,
                              iconColor: const Color(0xFF2D7A4F),
                              title: l10n.t('proFeatureHabitsTitle'),
                              description: l10n.t('proFeatureHabitsDesc'),
                            ),
                            const Divider(height: AppSpacing.lg),
                            _buildBenefitRow(
                              context,
                              icon: Icons.alt_route_rounded,
                              iconColor: const Color(0xFF3B82F6),
                              title: l10n.t('proFeatureRoutinesTitle'),
                              description: l10n.t('proFeatureRoutinesDesc'),
                            ),
                            const Divider(height: AppSpacing.lg),
                            _buildBenefitRow(
                              context,
                              icon: Icons.palette_outlined,
                              iconColor: const Color(0xFF8B5CF6),
                              title: l10n.t('proFeatureThemesTitle'),
                              description: l10n.t('proFeatureThemesDesc'),
                            ),
                            const Divider(height: AppSpacing.lg),
                            _buildBenefitRow(
                              context,
                              icon: Icons.backup_outlined,
                              iconColor: const Color(0xFFE5BA5A),
                              title: l10n.t('proFeatureBackupTitle'),
                              description: l10n.t('proFeatureBackupDesc'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Error message banner if any
                      if (premiumService.errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            premiumService.errorMessage == 'proSyncing'
                                ? l10n.t('proSyncing')
                                : premiumService.errorMessage!,
                            textAlign: TextAlign.center,
                            style: AppTypography.caption(Colors.redAccent),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Unlock Button CTA
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2D4638),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  onPressed: premiumService.isLoading
                      ? null
                      : () async {
                          HapticsHelper.heavy();
                          await premiumService.buyPro();
                          if (context.mounted && premiumService.isPro) {
                            Navigator.of(context).pop();
                          }
                        },
                  icon: premiumService.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.stars_rounded, color: Color(0xFFE5BA5A)),
                  label: Text(
                    premiumService.isPro
                        ? l10n.t('proActiveTitle')
                        : l10n.t('proUnlockBtn', args: {'price': priceText}),
                    style: AppTypography.body(Colors.white, isMedium: true).copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              // Restore purchases button
              TextButton(
                onPressed: premiumService.isLoading
                    ? null
                    : () async {
                        HapticsHelper.selection();
                        await premiumService.restorePurchases();
                        if (context.mounted) {
                          final isPro = premiumService.isPro;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isPro ? l10n.t('proRestoreSuccess') : l10n.t('proRestoreNone'),
                              ),
                            ),
                          );
                          if (isPro) Navigator.of(context).pop();
                        }
                      },
                child: Text(
                  l10n.t('proRestoreBtn'),
                  style: AppTypography.caption(theme.colorScheme.onSurface.withValues(alpha: 0.65), isMedium: true),
                ),
              ),

              // Testing Toggle (GUARANTEED ONLY VISIBLE IN DEBUG BUILDS)
              if (kDebugMode) ...[
                const SizedBox(height: AppSpacing.xxs),
                TextButton.icon(
                  onPressed: () async {
                    HapticsHelper.medium();
                    final currentlyPro = premiumService.isPro;
                    await premiumService.setProUser(!currentlyPro);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: !currentlyPro ? const Color(0xFF2D7A4F) : const Color(0xFF475569),
                          content: Row(
                            children: [
                              Icon(
                                !currentlyPro ? Icons.stars_rounded : Icons.info_outline_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  !currentlyPro ? l10n.t('testProActivated') : l10n.t('testProDeactivated'),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.science_outlined, size: 16, color: Color(0xFFE07A5F)),
                  label: Text(
                    premiumService.isPro ? l10n.t('deactivateTestPro') : l10n.t('activateTestPro'),
                    style: const TextStyle(
                      color: Color(0xFFE07A5F),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
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
            color: iconColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.body(theme.colorScheme.onSurface, isMedium: true).copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: AppTypography.caption(theme.colorScheme.onSurface.withValues(alpha: 0.65)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
