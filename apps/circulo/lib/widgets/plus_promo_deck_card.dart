import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'app_header.dart';
import 'motion_components.dart';

class PlusPromoDeckCard extends StatelessWidget {
  final VoidCallback onLearnMore;
  final VoidCallback onDismiss;

  const PlusPromoDeckCard({
    super.key,
    required this.onLearnMore,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF2E1065), // Deep Violet
                  const Color(0xFF3B0764),
                  const Color(0xFF78350F), // Rich Amber
                ]
              : [
                  const Color(0xFF4C1D95), // Royal Violet
                  const Color(0xFF6D28D9),
                  const Color(0xFFD97706), // Warm Gold
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.6),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Destellos y figuras decorativas en el fondo
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                ),
              ),
            ),
            Positioned(
              left: -30,
              bottom: 80,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFA855F7).withValues(alpha: 0.2),
                ),
              ),
            ),

            // Contenido estructurado
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Badge superior
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('⭐ ', style: TextStyle(fontSize: 12)),
                            Text(
                              l10n.get('promoCardTag'),
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        tooltip: l10n.get('cancel'),
                        onPressed: onDismiss,
                      ),
                    ],
                  ),
                  const Spacer(),

                  // Icono central con pulso
                  Center(
                    child: PulseBeacon(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.15),
                          border: Border.all(
                            color: const Color(0xFFFDE68A),
                            width: 2,
                          ),
                        ),
                        child: const CirculoLogoIcon(size: 48),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Título principal
                  Text(
                    l10n.get('promoCardHeadline'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Descripción de valor
                  Text(
                    l10n.get('promoCardBody'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3 Beneficios clave con bullets
                  _buildBenefitRow(
                    context,
                    Icons.all_inclusive,
                    l10n.get('swipesUnlimited'),
                  ),
                  const SizedBox(height: 8),
                  _buildBenefitRow(
                    context,
                    Icons.visibility,
                    l10n.get('whoLikedMeTitle'),
                  ),
                  const SizedBox(height: 8),
                  _buildBenefitRow(
                    context,
                    Icons.replay,
                    l10n.get('rewindTitle'),
                  ),

                  const Spacer(),

                  // Botón CTA Primario
                  PressableScale(
                    onTap: onLearnMore,
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFBBF24), // Amber
                            Color(0xFFF59E0B),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFF59E0B).withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        l10n.get('promoCardAction'),
                        style: const TextStyle(
                          color: Color(0xFF1E1B4B),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Indicador sutil de swipe
                  Text(
                    l10n.get('swipeToContinue'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFFFDE68A), size: 16),
        ),
        const SizedBox(width: 10),
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
}
