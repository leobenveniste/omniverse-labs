import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/premium_service.dart';
import '../theme/app_theme.dart';

class PaywallSheet extends StatefulWidget {
  final PremiumService premiumService;
  final String? customReason;

  const PaywallSheet({
    super.key,
    required this.premiumService,
    this.customReason,
  });

  static Future<void> show(
    BuildContext context, {
    required PremiumService premiumService,
    String? customReason,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PaywallSheet(
        premiumService: premiumService,
        customReason: customReason,
      ),
    );
  }

  @override
  State<PaywallSheet> createState() => _PaywallSheetState();
}

class _PaywallSheetState extends State<PaywallSheet> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final service = widget.premiumService;
    final isPro = service.isPro;
    final priceStr = service.proProduct?.price ?? '\$2.49 USD';

    return AnimatedBuilder(
      animation: service,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.bgDark,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: AppTheme.cyberGold.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.cyberGold.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(context).padding.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top drag handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),

                // Hero Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.cyberGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.cyberGold, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.workspace_premium_rounded, color: AppTheme.cyberGold, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '${l10n.t('appName').toUpperCase()} • ${l10n.t('proBadge')}',
                        style: const TextStyle(
                          color: AppTheme.cyberGold,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Headline
                Text(
                  l10n.t('proTitle'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle or custom reason
                Text(
                  widget.customReason ?? l10n.t('proDefaultSubtitle'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                // Features Bento List
                _buildFeatureTile(
                  icon: Icons.emoji_events_rounded,
                  color: AppTheme.cyberGold,
                  title: l10n.t('proBenefitFameTitle'),
                  subtitle: l10n.t('proBenefitFameSub'),
                ),
                const SizedBox(height: 10),
                _buildFeatureTile(
                  icon: Icons.all_inclusive_rounded,
                  color: const Color(0xFF00E676),
                  title: l10n.t('proBenefitHistoryTitle'),
                  subtitle: l10n.t('proBenefitHistorySub'),
                ),
                const SizedBox(height: 10),
                _buildFeatureTile(
                  icon: Icons.palette_outlined,
                  color: const Color(0xFF29B6F6),
                  title: l10n.t('proBenefitMatsTitle'),
                  subtitle: l10n.t('proBenefitMatsSub'),
                ),
                const SizedBox(height: 10),
                _buildFeatureTile(
                  icon: Icons.share_rounded,
                  color: const Color(0xFFFF5252),
                  title: l10n.t('proBenefitShareTitle'),
                  subtitle: l10n.t('proBenefitShareSub'),
                ),
                const SizedBox(height: 24),

                // Purchase Actions
                if (isPro)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cyberGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.cyberGold),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.verified_rounded, color: AppTheme.cyberGold),
                        const SizedBox(width: 8),
                        Text(
                          l10n.t('proAlreadyMember'),
                          style: const TextStyle(
                            color: AppTheme.cyberGold,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  if (service.errorMessage != null) ...[
                    Text(
                      service.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.cyberGold,
                        foregroundColor: Colors.black,
                        elevation: 6,
                        shadowColor: AppTheme.cyberGold.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: service.isLoading ? null : () => service.buyPro(),
                      child: service.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : Text(
                              l10n.t('proUnlockBtn', {'price': priceStr}),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: service.isLoading ? null : () => service.restorePurchases(),
                        child: Text(
                          l10n.t('restorePurchases'),
                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ),
                      const Text('•', style: TextStyle(color: Colors.white24)),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          l10n.t('maybeLater'),
                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],

                // Development Testing Toggle (Strictly tree-shaken in production release builds)
                if (kDebugMode) ...[
                  const Divider(color: Colors.white12, height: 28),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: isPro ? Colors.orangeAccent : Colors.tealAccent,
                    ),
                    icon: Icon(isPro ? Icons.lock_open_rounded : Icons.science_outlined, size: 16),
                    label: Text(
                      isPro ? l10n.t('testProDisable') : l10n.t('testProEnable'),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      await service.setProForTesting(!isPro);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              !isPro ? l10n.t('proActivatedToast') : l10n.t('proDeactivatedToast'),
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
