import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_model.dart';
import '../../models/purchase_model.dart';
import '../../services/auth_service.dart';
import '../../services/billing_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/async_feedback_components.dart';
import '../../widgets/motion_components.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  String _selectedPlan = AppProductIds.plusAnnual;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authService = context.watch<AuthService>();
    final billingService = context.watch<BillingService>();
    final user = authService.currentUser;

    final textPrimary = isDark ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = isDark ? Colors.white70 : const Color(0xFF4B5563);

    return AppScaffold(
      title: l10n.get('shopTitle'),
      showHelpButton: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // 1. TARJETA PRINCIPAL CÍRCULO PLUS
                _buildPlusHeroCard(
                  context,
                  l10n,
                  user,
                  billingService,
                  authService,
                ),
                const SizedBox(height: 24),

                // 2. SECCIÓN CONSUMIBLES: PERFIL DESTACADO (BOOST)
                _buildSectionTitle(
                  l10n.get('boostTitle'),
                  '⚡ Multiplicá x3 tu visibilidad en el mazo por 60 min',
                  textPrimary,
                  textSecondary,
                ),
                const SizedBox(height: 12),
                _buildBoostCard(
                  context,
                  l10n,
                  user,
                  billingService,
                  authService,
                ),
                const SizedBox(height: 24),

                // 3. SECCIÓN CONSUMIBLES: SUPER-ONDAS
                _buildSectionTitle(
                  l10n.get('superOndaTitle'),
                  '🌊 Notificá afinidad directa con borde de energía dorada',
                  textPrimary,
                  textSecondary,
                ),
                const SizedBox(height: 12),
                _buildSuperOndaCard(
                  context,
                  l10n,
                  user,
                  billingService,
                  authService,
                ),
                const SizedBox(height: 32),

                // Botón Restaurar compras
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.get('savedSuccess')),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.restore, size: 16),
                    label: Text(l10n.get('restorePurchases')),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
    );
  }

  Widget _buildSectionTitle(
    String title,
    String subtitle,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPlusHeroCard(
    BuildContext context,
    AppLocalizations l10n,
    UserModel user,
    BillingService billingService,
    AuthService authService,
  ) {
    final isPlus = user.isPlusMember;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3B0764), // Rich Royal Violet
            Color(0xFF581C87),
            Color(0xFF78350F), // Warm Gold
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.6),
          width: 2,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header de la membresía
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('⭐', style: TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.get('plusTitle'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        isPlus
                            ? 'Membresía activa'
                            : 'Desbloqueá todo el potencial',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (isPlus)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'ACTIVO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Lista de Beneficios
          _buildHeroPerkRow(Icons.all_inclusive, l10n.get('swipesUnlimited')),
          const SizedBox(height: 6),
          _buildHeroPerkRow(Icons.visibility, l10n.get('whoLikedMeTitle')),
          const SizedBox(height: 6),
          _buildHeroPerkRow(Icons.replay, l10n.get('rewindTitle')),
          const SizedBox(height: 6),
          _buildHeroPerkRow(
              Icons.bolt, '1 Boost semanal incluido sin costo extra'),
          const SizedBox(height: 16),

          if (!isPlus) ...[
            // Selector de Planes
            Row(
              children: [
                Expanded(
                  child: _buildHeroPlanOption(
                    id: AppProductIds.plusAnnual,
                    title: 'Anual',
                    price: '\$39.99',
                    subtitle: 'Ahorrás 33%',
                    isSelected: _selectedPlan == AppProductIds.plusAnnual,
                    onTap: () => setState(
                        () => _selectedPlan = AppProductIds.plusAnnual),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildHeroPlanOption(
                    id: AppProductIds.plusMonthly,
                    title: 'Mensual',
                    price: '\$4.99',
                    subtitle: 'Sin compromiso',
                    isSelected: _selectedPlan == AppProductIds.plusMonthly,
                    onTap: () => setState(
                        () => _selectedPlan = AppProductIds.plusMonthly),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Botón de activación
            LoadingPrimaryButton(
              label: l10n.get('getPlusBtn'),
              isLoading: _isProcessing || billingService.isLoading,
              accentColor: const Color(0xFFF59E0B),
              onPressed: () => _buyProduct(
                billingService,
                authService,
                user,
                _selectedPlan,
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: Color(0xFF10B981), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      user.plusExpiresAt != null
                          ? 'Válido hasta ${user.plusExpiresAt!.day}/${user.plusExpiresAt!.month}/${user.plusExpiresAt!.year}'
                          : 'Suscripción Círculo Plus sin límite',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeroPerkRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFFDE68A), size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroPlanOption({
    required String id,
    required String title,
    required String price,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFF59E0B).withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFFF59E0B) : Colors.white24,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              price,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFFFDE68A)
                    : Colors.white.withValues(alpha: 0.6),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TARJETA DE BOOSTS ---
  Widget _buildBoostCard(
    BuildContext context,
    AppLocalizations l10n,
    UserModel user,
    BillingService billingService,
    AuthService authService,
  ) {
    final hasActive = user.hasActiveBoost;
    final remainingMinutes = hasActive && user.activeBoostUntil != null
        ? user.activeBoostUntil!.difference(DateTime.now()).inMinutes
        : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.bolt, color: Color(0xFFD97706), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tus Boosts disponibles: ${user.remainingBoosts}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        hasActive
                            ? '⚡ Activo por $remainingMinutes min más'
                            : 'Sin boost activo en este momento',
                        style: TextStyle(
                          fontSize: 12,
                          color: hasActive
                              ? const Color(0xFF10B981)
                              : Colors.grey,
                          fontWeight: hasActive
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                if (user.remainingBoosts > 0 && !hasActive)
                  ElevatedButton(
                    onPressed: () async {
                      await billingService.activateBoost(user);
                      await authService.refreshCurrentUser();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('⚡ ¡Perfil Destacado activado!'),
                            backgroundColor: Color(0xFFF59E0B),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('Activar'),
                  ),
              ],
            ),
            const Divider(height: 24),

            // Opciones de compra de Boosts
            Row(
              children: [
                Expanded(
                  child: _buildConsumableItem(
                    title: '1 Boost',
                    price: '\$1.99',
                    badge: null,
                    onBuy: () => _buyProduct(
                      billingService,
                      authService,
                      user,
                      AppProductIds.boost1,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildConsumableItem(
                    title: '5 Boosts',
                    price: '\$7.99',
                    badge: '20% OFF',
                    onBuy: () => _buyProduct(
                      billingService,
                      authService,
                      user,
                      AppProductIds.boost5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- TARJETA DE SUPER-ONDAS ---
  Widget _buildSuperOndaCard(
    BuildContext context,
    AppLocalizations l10n,
    UserModel user,
    BillingService billingService,
    AuthService authService,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF06B6D4).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('🌊', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tus Super-Ondas: ${user.remainingSuperOndas}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Usalas en Discover para notificar afinidad prioritaria',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Opciones de compra de Super-Ondas
            Row(
              children: [
                Expanded(
                  child: _buildConsumableItem(
                    title: '3 Super-Ondas',
                    price: '\$2.49',
                    badge: null,
                    onBuy: () => _buyProduct(
                      billingService,
                      authService,
                      user,
                      AppProductIds.superOnda3,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildConsumableItem(
                    title: '10 Super-Ondas',
                    price: '\$6.99',
                    badge: '30% OFF',
                    onBuy: () => _buyProduct(
                      billingService,
                      authService,
                      user,
                      AppProductIds.superOnda10,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsumableItem({
    required String title,
    required String price,
    required String? badge,
    required VoidCallback onBuy,
  }) {
    return PressableScale(
      onTap: onBuy,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD97706),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _buyProduct(
    BillingService billingService,
    AuthService authService,
    UserModel currentUser,
    String productId,
  ) async {
    setState(() => _isProcessing = true);

    final success = await billingService.buyProduct(
      productId: productId,
      currentUser: currentUser,
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (success) {
      await authService.refreshCurrentUser();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 ¡Compra completada con éxito!'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(billingService.errorMessage ?? 'Error en la compra'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
