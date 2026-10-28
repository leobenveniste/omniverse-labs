import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/tactile_pressable.dart';
import '../../repositories/storage_repository.dart';

class ProPaywallModal extends StatelessWidget {
  final StorageRepository storage;
  final String? customReason;

  const ProPaywallModal({
    super.key,
    required this.storage,
    this.customReason,
  });

  static Future<void> show(BuildContext context, StorageRepository storage, {String? customReason}) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ProPaywallModal(
        storage: storage,
        customReason: customReason,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sheetBg = isDark ? AppColors.darkCard : AppColors.parchmentCard;
    final goldColor = isDark ? AppColors.goldFoil : AppColors.burgundyBase;
    final textPrimary = isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary;
    final textSecondary = isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.parchmentBorder;

    final isSpanish = t.locale.languageCode == 'es';

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: goldColor.withValues(alpha: 0.6), width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 44,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Hero Gold Emblem
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: isDark
                            ? [AppColors.goldFoilDark, AppColors.goldFoilLight]
                            : [AppColors.burgundyBase, AppColors.burgundyLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? AppColors.goldFoil : AppColors.burgundyBase).withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('👑', style: TextStyle(fontSize: 38)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    isSpanish ? 'EMPACARTE PRO' : 'EMPACARTE PRO',
                    style: AppTypography.displaySerif(color: goldColor).copyWith(fontSize: 24),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isSpanish
                        ? 'El Pasaporte Definitivo del Viajero'
                        : 'The Ultimate Traveler Companion',
                    style: AppTypography.subhead(color: textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),

                  if (customReason != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.stampCrimsonLight.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.stampCrimsonLight.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: AppColors.stampCrimsonLight, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              customReason!,
                              style: AppTypography.bodySmall(color: textPrimary, medium: true),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Lifetime Zen Promise Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.goldFoil : AppColors.burgundyBase).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: goldColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shield_outlined, size: 16, color: goldColor),
                        const SizedBox(width: 8),
                        Text(
                          isSpanish
                              ? 'Compra Única • Sin Suscripciones • 100% Offline'
                              : 'Single Lifetime Purchase • Zero Subscriptions • 100% Offline',
                          style: AppTypography.caption(color: goldColor, medium: true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Feature Cards Comparison
                  _buildFeatureRow(
                    icon: Icons.flight_takeoff_rounded,
                    title: isSpanish ? 'Viajes y Destinos Ilimitados' : 'Unlimited Trips & Destinations',
                    freeDesc: isSpanish ? 'Free: 1 activo / 3 históricos' : 'Free: 1 active / 3 lifetime',
                    proDesc: isSpanish ? 'PRO: Sin límite para siempre' : 'PRO: Unlimited forever',
                    goldColor: goldColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    borderColor: borderColor,
                  ),
                  _buildFeatureRow(
                    icon: Icons.luggage_rounded,
                    title: isSpanish ? 'División en 3 Bultos & Balanza' : '3-Bag Compartments & Weight Scale',
                    freeDesc: isSpanish ? 'Free: Lista única sin bultos' : 'Free: Single basic list',
                    proDesc: isSpanish ? 'PRO: Mochila, Carry-on y Bodega con balanza' : 'PRO: Backpack, Carry-on, Checked with scales',
                    goldColor: goldColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    borderColor: borderColor,
                  ),
                  _buildFeatureRow(
                    icon: Icons.security_rounded,
                    title: isSpanish ? 'Auditor de Seguridad de Aeropuerto' : 'Airport Security & TSA Auditor',
                    freeDesc: isSpanish ? 'Free: No disponible' : 'Free: Not available',
                    proDesc: isSpanish ? 'PRO: Alerta de baterías en bodega y líquidos' : 'PRO: Lithium battery & liquid cabin alerts',
                    goldColor: goldColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    borderColor: borderColor,
                  ),
                  _buildFeatureRow(
                    icon: Icons.hotel_rounded,
                    title: isSpanish ? 'Modo Check-out de Alojamiento' : 'Hotel Check-out Departure Mode',
                    freeDesc: isSpanish ? 'Free: No disponible' : 'Free: Not available',
                    proDesc: isSpanish ? 'PRO: Checklist inverso para no olvidar nada' : 'PRO: Reverse packing so nothing gets left behind',
                    goldColor: goldColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    borderColor: borderColor,
                  ),
                  _buildFeatureRow(
                    icon: Icons.medical_services_outlined,
                    title: isSpanish ? 'Bóveda Offline de Asistencia Médica' : 'Offline Travel Vault & Insurance',
                    freeDesc: isSpanish ? 'Free: No disponible' : 'Free: Not available',
                    proDesc: isSpanish ? 'PRO: Póliza de seguro y hotel para aduana' : 'PRO: Insurance policy & hotel emergency card',
                    goldColor: goldColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    borderColor: borderColor,
                  ),
                  _buildFeatureRow(
                    icon: Icons.push_pin_rounded,
                    title: isSpanish ? 'Siempre Llevo Esto Ilimitado' : 'Unlimited Always-Pack Essentials',
                    freeDesc: isSpanish ? 'Free: Máximo 3 ítems' : 'Free: Up to 3 items',
                    proDesc: isSpanish ? 'PRO: Tu lista personal sin límites' : 'PRO: All your custom essentials forever',
                    goldColor: goldColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    borderColor: borderColor,
                  ),

                  const SizedBox(height: 24),

                  // Pricing & CTA Button
                  TactilePressable(
                    onTap: () async {
                      HapticFeedback.heavyImpact();
                      await storage.unlockPro();
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.burgundyBase,
                            content: Row(
                              children: [
                                const Text('👑', style: TextStyle(fontSize: 22)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    isSpanish
                                        ? '¡Felicitaciones! Has desbloqueado EmpacArte PRO de por vida.'
                                        : 'Congratulations! You unlocked EmpacArte PRO for life.',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [AppColors.goldFoilDark, AppColors.goldFoilLight]
                              : [AppColors.burgundyBase, AppColors.burgundyLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (isDark ? AppColors.goldFoil : AppColors.burgundyBase).withValues(alpha: 0.4),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.stars_rounded, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                isSpanish ? 'DESBLOQUEAR ACCESO PRO' : 'UNLOCK PRO LIFETIME ACCESS',
                                style: AppTypography.subheadSerif(color: Colors.white).copyWith(letterSpacing: 1),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isSpanish ? '\$2.99 USD • Pago único' : '\$2.99 USD • One-time payment',
                            style: AppTypography.caption(color: Colors.white.withValues(alpha: 0.9)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Secondary action / dismiss
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      isSpanish ? 'Continuar en modo gratuito' : 'Continue with free version',
                      style: AppTypography.caption(color: textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String freeDesc,
    required String proDesc,
    required Color goldColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: textSecondary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor.withValues(alpha: 0.8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: goldColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: goldColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodySmall(color: textPrimary, medium: true)),
                const SizedBox(height: 2),
                Text(freeDesc, style: AppTypography.caption(color: textSecondary)),
                Text(proDesc, style: AppTypography.caption(color: goldColor, medium: true)),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.check_circle_rounded, size: 18, color: AppColors.stampEmeraldLight),
          ),
        ],
      ),
    );
  }
}
