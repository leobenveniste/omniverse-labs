import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

class SolicitarTurnoModal extends StatelessWidget {
  final VoidCallback? onNavigateToTramites;

  const SolicitarTurnoModal({
    super.key,
    this.onNavigateToTramites,
  });

  static void show(BuildContext context, {VoidCallback? onNavigateToTramites}) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SolicitarTurnoModal(
        onNavigateToTramites: onNavigateToTramites,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Solicitar Nuevo Turno Municipal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Seleccioná el área y sede para coordinar tu cita presencial.',
              style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            _buildTurnoOption(
              icon: Icons.badge_rounded,
              title: 'Licencias de Conducir',
              subtitle: 'Renovación, ampliación y primera licencia',
              onTap: () {
                Navigator.pop(context);
                onNavigateToTramites?.call();
              },
            ),
            const SizedBox(height: 8),
            _buildTurnoOption(
              icon: Icons.pets_rounded,
              title: 'Zoonosis & Vacunación',
              subtitle: 'Castración y antirrábica gratuita en móvil',
              onTap: () {
                Navigator.pop(context);
                onNavigateToTramites?.call();
              },
            ),
            const SizedBox(height: 8),
            _buildTurnoOption(
              icon: Icons.medical_services_rounded,
              title: 'Salud & Centros CAPS',
              subtitle: 'Medicina general, odontología y pediatría',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Accediendo al sistema de turnos de salud municipal...'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTurnoOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.outline),
          ],
        ),
      ),
    );
  }
}
