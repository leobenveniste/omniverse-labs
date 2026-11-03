import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_model.dart';
import '../../models/purchase_model.dart';
import '../../services/billing_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/async_feedback_components.dart';
import '../../widgets/motion_components.dart';

enum PaywallTrigger {
  promoCard,
  dailySwipes,
  rewind,
  whoLikedMe,
  boost,
  general,
}

class PaywallBottomSheet extends StatefulWidget {
  final PaywallTrigger trigger;

  const PaywallBottomSheet({
    super.key,
    this.trigger = PaywallTrigger.general,
  });

  static Future<void> show(
    BuildContext context, {
    PaywallTrigger trigger = PaywallTrigger.general,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PaywallBottomSheet(trigger: trigger),
    );
  }

  @override
  State<PaywallBottomSheet> createState() => _PaywallBottomSheetState();
}

class _PaywallBottomSheetState extends State<PaywallBottomSheet> {
  String _selectedPlan = AppProductIds.plusAnnual;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authService = context.watch<AuthService>();
    final billingService = context.watch<BillingService>();
    final currentUser = authService.currentUser;

    final cardBg = isDark ? const Color(0xFF1E1B2E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1F2937);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra superior de agarre
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Botón de cierre
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('⭐', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text(
                          l10n.get('plusBadge'),
                          style: const TextStyle(
                            color: Color(0xFFD97706),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Título y Subtítulo según el disparador
              _buildTriggerHeader(l10n, textPrimary),
              const SizedBox(height: 20),

              // Lista de Beneficios
              _buildPerksList(context, l10n, textPrimary),
              const SizedBox(height: 20),

              // Selector de Planes (4 Base Plans con descuentos progresivos)
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.55,
                children: [
                  _buildPlanCard(
                    id: AppProductIds.plusAnnual,
                    title: '12 Meses',
                    price: '\$39.99',
                    period: '/ año',
                    badge: '33% OFF',
                    isSelected: _selectedPlan == AppProductIds.plusAnnual,
                    onTap: () => setState(
                        () => _selectedPlan = AppProductIds.plusAnnual),
                  ),
                  _buildPlanCard(
                    id: AppProductIds.plusBiannual,
                    title: '6 Meses',
                    price: '\$22.99',
                    period: '/ sem.',
                    badge: '23% OFF',
                    isSelected: _selectedPlan == AppProductIds.plusBiannual,
                    onTap: () => setState(
                        () => _selectedPlan = AppProductIds.plusBiannual),
                  ),
                  _buildPlanCard(
                    id: AppProductIds.plusQuarterly,
                    title: '3 Meses',
                    price: '\$12.99',
                    period: '/ trim.',
                    badge: '13% OFF',
                    isSelected: _selectedPlan == AppProductIds.plusQuarterly,
                    onTap: () => setState(
                        () => _selectedPlan = AppProductIds.plusQuarterly),
                  ),
                  _buildPlanCard(
                    id: AppProductIds.plusMonthly,
                    title: '1 Mes',
                    price: '\$4.99',
                    period: '/ mes',
                    badge: 'Base',
                    isSelected: _selectedPlan == AppProductIds.plusMonthly,
                    onTap: () => setState(
                        () => _selectedPlan = AppProductIds.plusMonthly),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Botón de Compra / Suscripción
              LoadingPrimaryButton(
                label: l10n.get('getPlusBtn'),
                isLoading: _isProcessing || billingService.isLoading,
                accentColor: const Color(0xFFF59E0B),
                onPressed: currentUser == null
                    ? null
                    : () => _handlePurchase(
                          billingService,
                          authService,
                          currentUser,
                        ),
              ),
              const SizedBox(height: 12),

              // Botón Restaurar compras
              Center(
                child: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.get('savedSuccess')),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    l10n.get('restorePurchases'),
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTriggerHeader(AppLocalizations l10n, Color textPrimary) {
    String title = l10n.get('plusTitle');
    String desc = l10n.get('plusSubtitle');

    switch (widget.trigger) {
      case PaywallTrigger.dailySwipes:
        title = l10n.get('swipesLimitReachedTitle');
        desc = l10n.get('swipesLimitReachedDesc');
        break;
      case PaywallTrigger.rewind:
        title = l10n.get('rewindTitle');
        desc = l10n.get('rewindDesc');
        break;
      case PaywallTrigger.whoLikedMe:
        title = l10n.get('whoLikedMeTitle');
        desc = l10n.get('whoLikedMeLocked');
        break;
      case PaywallTrigger.boost:
        title = l10n.get('boostTitle');
        desc = l10n.get('boostDesc');
        break;
      case PaywallTrigger.promoCard:
      case PaywallTrigger.general:
        title = l10n.get('promoCardHeadline');
        desc = l10n.get('promoCardBody');
        break;
    }

    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          desc,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _buildPerksList(
      BuildContext context, AppLocalizations l10n, Color textPrimary) {
    final perks = [
      {'icon': Icons.all_inclusive, 'text': l10n.get('swipesUnlimited')},
      {'icon': Icons.visibility, 'text': l10n.get('whoLikedMeTitle')},
      {'icon': Icons.replay, 'text': l10n.get('rewindTitle')},
      {'icon': Icons.bolt, 'text': '1 Boost gratuito semanal incluido'},
      {'icon': Icons.group, 'text': 'Círculos activos simultáneos ilimitados'},
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        children: perks
            .map(
              (p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      p['icon'] as IconData,
                      size: 18,
                      color: const Color(0xFFD97706),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        p['text'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildPlanCard({
    required String id,
    required String title,
    required String price,
    required String period,
    required String? badge,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFF59E0B) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ] else ...[
              const SizedBox(height: 18),
            ],
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  period,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePurchase(
    BillingService billingService,
    AuthService authService,
    UserModel currentUser,
  ) async {
    setState(() => _isProcessing = true);

    final success = await billingService.buyProduct(
      productId: _selectedPlan,
      currentUser: currentUser,
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (success) {
      await authService.refreshCurrentUser();
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 ¡Bienvenido a Círculo Plus!'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(billingService.errorMessage ?? 'Error en el pago'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
