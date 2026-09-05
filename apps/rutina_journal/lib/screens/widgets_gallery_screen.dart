import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../services/premium_service.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/haptics_helper.dart';
import '../widgets/paywall_sheet.dart';

class WidgetsGalleryScreen extends StatefulWidget {
  final PremiumService premiumService;

  const WidgetsGalleryScreen({
    super.key,
    required this.premiumService,
  });

  @override
  State<WidgetsGalleryScreen> createState() => _WidgetsGalleryScreenState();
}

class _WidgetsGalleryScreenState extends State<WidgetsGalleryScreen> {
  static const MethodChannel _widgetsChannel = MethodChannel('com.omniverselabs.ritmo/widgets');
  bool _isPinningSupported = false;

  @override
  void initState() {
    super.initState();
    _checkPinningSupport();
  }

  Future<void> _checkPinningSupport() async {
    try {
      final supported = await _widgetsChannel.invokeMethod<bool>('isPinningSupported');
      if (mounted) {
        setState(() {
          _isPinningSupported = supported ?? false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isPinningSupported = false;
        });
      }
    }
  }

  Future<void> _pinWidget(BuildContext context, String providerName, String widgetTitle) async {
    HapticsHelper.light();
    try {
      final success = await _widgetsChannel.invokeMethod<bool>('pinWidget', {
        'provider': providerName,
      });

      if (!context.mounted) return;
      if (success == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Añadiendo "$widgetTitle" a tu pantalla de inicio...'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        _showManualAddInstructions(context, widgetTitle);
      }
    } catch (_) {
      if (!context.mounted) return;
      _showManualAddInstructions(context, widgetTitle);
    }
  }

  void _showManualAddInstructions(BuildContext context, String widgetTitle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widgetTitle),
        content: const Text(
          'Para añadir este widget:\n\n'
          '1. Ve a la pantalla de inicio de tu teléfono.\n'
          '2. Mantén presionado un espacio libre.\n'
          '3. Toca "Widgets" y busca "Ritmo".\n'
          '4. Arrastra el widget a tu pantalla.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isPro = widget.premiumService.isPro;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.t('widgetsGalleryTitle'),
          style: AppTypography.title(theme.colorScheme.onSurface),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Header info banner
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.widgets_rounded, color: theme.colorScheme.primary, size: 28),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.t('widgetsGalleryHeader'),
                        style: AppTypography.section(theme.colorScheme.onSurface),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.t('widgetsGallerySub'),
                        style: AppTypography.caption(theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 1. Mindful Pulse (2x2)
          _buildWidgetCard(
            context: context,
            title: 'Pulso Diario (2x2)',
            badge: 'GRATIS',
            badgeColor: theme.colorScheme.primary,
            description: 'Visualiza tu porcentaje diario, racha de fuego y el halo circadiano del día.',
            providerName: 'RitmoPulseWidgetProvider',
            previewWidget: _buildPulsePreview(theme),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 2. Bento Matrix (4x2)
          _buildWidgetCard(
            context: context,
            title: 'Matriz Bento (4x2)',
            badge: 'RITMO PRO',
            badgeColor: const Color(0xFFC85A3B),
            description: 'Acceso directo e interactivo. Toca para marcar o desmarcar tus hábitos en silencio.',
            providerName: 'RitmoBentoWidgetProvider',
            isLocked: !isPro,
            previewWidget: _buildBentoPreview(theme),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 3. Breathing Sanctuary (2x2)
          _buildWidgetCard(
            context: context,
            title: 'Santuario de Respiración (2x2)',
            badge: 'ZEN',
            badgeColor: const Color(0xFF2E7D32),
            description: 'Entra a tu santuario zen con 1 toque. Activa No Molestar automáticamente.',
            providerName: 'RitmoBreathingWidgetProvider',
            previewWidget: _buildBreathingPreview(theme),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 4. Mini Pulse (1x1)
          _buildWidgetCard(
            context: context,
            title: 'Mini Racha (1x1)',
            badge: 'COMPACTO',
            badgeColor: const Color(0xFF5C6BC0),
            description: 'Tu racha y fracción de hábitos en una sola casilla de tu pantalla.',
            providerName: 'RitmoMiniPulseWidgetProvider',
            previewWidget: _buildMiniPreview(theme),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildWidgetCard({
    required BuildContext context,
    required String title,
    required String badge,
    required Color badgeColor,
    required String description,
    required String providerName,
    required Widget previewWidget,
    bool isLocked = false,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + Badge row
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.title(theme.colorScheme.onSurface),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              description,
              style: AppTypography.caption(theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),

            // Visual Preview Box
            Center(child: previewWidget),
            const SizedBox(height: AppSpacing.md),

            // Action Button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  if (isLocked) {
                    HapticsHelper.warning();
                    PaywallSheet.show(
                      context,
                      customReason: 'Desbloquea Ritmo Pro para usar la Matriz Bento interactiva.',
                    );
                    return;
                  }
                  _pinWidget(context, providerName, title);
                },
                icon: Icon(
                  isLocked ? Icons.lock_rounded : Icons.add_to_home_screen_rounded,
                  size: 18,
                ),
                label: Text(
                  isLocked
                      ? 'Desbloquear con Ritmo Pro'
                      : (_isPinningSupported ? 'Añadir a pantalla de inicio' : 'Cómo añadir widget'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: isLocked ? theme.colorScheme.secondary : theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widget Mock Previews ---

  Widget _buildPulsePreview(ThemeData theme) {
    return Container(
      width: 170,
      height: 170,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ritmo • Hoy',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
              ),
              const Row(
                children: [
                  Text('🔥', style: TextStyle(fontSize: 10)),
                  SizedBox(width: 2),
                  Text('7', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFC85A3B))),
                ],
              ),
            ],
          ),
          Column(
            children: [
              Text(
                '75%',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 2),
              Text(
                '3 de 4 completados',
                style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: 0.75,
                  minHeight: 5,
                  backgroundColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                  valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                ),
              ),
            ],
          ),
          Text(
            '🌿 Un pequeño paso para tu paz',
            style: TextStyle(fontSize: 9, color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoPreview(ThemeData theme) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RITMO • MAÑANA',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                  ),
                  Text(
                    '2 de 3 completados',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Text('🔥', style: TextStyle(fontSize: 9)),
                    SizedBox(width: 2),
                    Text('14 días', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFC85A3B))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildBentoRow(theme, 'Agua e hidratación', true),
          const SizedBox(height: 4),
          _buildBentoRow(theme, 'Meditación & calma', true),
          const SizedBox(height: 4),
          _buildBentoRow(theme, 'Lectura profunda', false),
        ],
      ),
    );
  }

  Widget _buildBentoRow(ThemeData theme, String title, bool done) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: done
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            done ? '✓' : '○',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: done ? const Color(0xFF2E7D32) : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreathingPreview(ThemeData theme) {
    return Container(
      width: 170,
      height: 170,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🧘 CALMA',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '🌙 DND',
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                ),
              ),
            ],
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                '✦',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
          ),
          Text(
            'Pausa guiada • 4-4-4-4',
            style: TextStyle(fontSize: 9, color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniPreview(ThemeData theme) {
    return Container(
      width: 90,
      height: 90,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🔥', style: TextStyle(fontSize: 18)),
          Text(
            '7',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFC85A3B)),
          ),
          Text(
            '3/4',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF2D4A2B)),
          ),
        ],
      ),
    );
  }
}
