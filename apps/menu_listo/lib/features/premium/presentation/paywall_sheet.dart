import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../providers/premium_provider.dart';

class PaywallSheet extends ConsumerWidget {
  const PaywallSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const PaywallSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final premiumState = ref.watch(premiumProvider);

    final priceText = premiumState.proProduct?.price ?? '\$2.99 USD';

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Crown Icon & Title
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.amber.shade400, Colors.orange.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.workspace_premium_rounded, size: 42, color: Colors.white),
          ),
          const SizedBox(height: 16),

          Text(
            'Menú Listo Pro',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            strings.isSpanish
                ? 'Pago único para siempre. Sin suscripciones ni anuncios.'
                : 'One-time payment forever. No subscriptions or ads.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Pro Benefits List
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.15)),
            ),
            child: Column(
              children: [
                _buildBenefitRow(
                  theme,
                  icon: Icons.all_inclusive_rounded,
                  color: Colors.deepPurpleAccent,
                  title: strings.isSpanish ? 'Recetas Ilimitadas' : 'Unlimited Recipes',
                  subtitle: strings.isSpanish ? 'Guarda y crea todas las recetas que desees sin límites' : 'Save & create without limits',
                ),
                const Divider(height: 20),
                _buildBenefitRow(
                  theme,
                  icon: Icons.pan_tool_outlined,
                  color: Colors.green,
                  title: strings.isSpanish ? 'Modo Cocina Manos Libres' : 'Hands-Free Cook Mode',
                  subtitle: strings.isSpanish ? 'Controla los pasos pasando la mano frente a la cámara' : 'Wave gesture control while cooking',
                ),
                const Divider(height: 20),
                _buildBenefitRow(
                  theme,
                  icon: Icons.kitchen_rounded,
                  color: Colors.blueAccent,
                  title: strings.isSpanish ? 'Buscador de Heladera Completo' : 'Full Pantry Matcher',
                  subtitle: strings.isSpanish ? 'Encuentra qué cocinar con cualquier ingrediente que tengas' : 'Match any ingredients in your fridge',
                ),
                const Divider(height: 20),
                _buildBenefitRow(
                  theme,
                  icon: Icons.document_scanner_rounded,
                  color: Colors.orangeAccent,
                  title: strings.isSpanish ? 'Escáner OCR e Importador Web' : 'OCR Scanner & Web Importer',
                  subtitle: strings.isSpanish ? 'Digitaliza libros de cocina y páginas web al instante' : 'Digitize cook books & recipe websites',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Buy Action Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 2,
              ),
              onPressed: premiumState.isLoading
                  ? null
                  : () async {
                      HapticFeedback.mediumImpact();
                      await ref.read(premiumProvider.notifier).buyPro();
                      if (context.mounted && ref.read(premiumProvider).isProUser) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.green.shade700,
                            content: Row(
                              children: [
                                const Icon(Icons.stars_rounded, color: Colors.amber),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    strings.isSpanish
                                        ? '¡Felicitaciones! Menú Listo Pro está desbloqueado.'
                                        : 'Congratulations! Menú Listo Pro is unlocked.',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
              child: premiumState.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_open_rounded, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          strings.isSpanish
                              ? 'Desbloquear Pro por $priceText'
                              : 'Unlock Pro for $priceText',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),

          // Secondary Restore Button
          TextButton(
            onPressed: premiumState.isLoading
                ? null
                : () async {
                    HapticFeedback.lightImpact();
                    await ref.read(premiumProvider.notifier).restorePurchases();
                    if (context.mounted) {
                      final isPro = ref.read(premiumProvider).isProUser;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isPro
                                ? (strings.isSpanish ? '¡Compras restauradas con éxito!' : 'Purchases restored successfully!')
                                : (strings.isSpanish ? 'No se encontraron compras previas en esta cuenta.' : 'No previous purchases found.'),
                          ),
                        ),
                      );
                      if (isPro) Navigator.pop(context);
                    }
                  },
            child: Text(
              strings.isSpanish ? 'Restaurar compras anteriores' : 'Restore previous purchases',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitRow(
    ThemeData theme, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
