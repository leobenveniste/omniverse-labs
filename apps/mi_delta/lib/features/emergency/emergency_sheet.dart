import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

class EmergencySheet extends StatefulWidget {
  const EmergencySheet({super.key});

  static Future<void> show(BuildContext context) {
    HapticFeedback.heavyImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const EmergencySheet(),
    );
  }

  @override
  State<EmergencySheet> createState() => _EmergencySheetState();
}

class _EmergencySheetState extends State<EmergencySheet> with SingleTickerProviderStateMixin {
  bool _sosSent = false;
  String? _callingTitle;
  double _holdProgress = 0.0;
  Timer? _holdTimer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startHolding() {
    if (_sosSent) return;
    HapticFeedback.selectionClick();
    _holdTimer?.cancel();
    _holdTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        _holdProgress += 0.05 / 3.0; // 3 seconds to reach 1.0
        if (_holdProgress >= 1.0) {
          _holdProgress = 1.0;
          timer.cancel();
          _triggerPanic();
        }
      });
    });
  }

  void _stopHolding() {
    if (_sosSent) return;
    _holdTimer?.cancel();
    setState(() {
      _holdProgress = 0.0;
    });
  }

  void _triggerPanic() {
    HapticFeedback.heavyImpact();
    setState(() => _sosSent = true);
  }

  void _simulateCall(String title, String phone) {
    HapticFeedback.mediumImpact();
    setState(() => _callingTitle = '$title ($phone)');
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) setState(() => _callingTitle = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top drag indicator
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
              const SizedBox(height: 12),

              // Network Status & Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.secondaryEmerald,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.secondaryEmerald.withValues(alpha: 0.6 * _pulseController.value),
                                  blurRadius: 8,
                                  spreadRadius: 3 * _pulseController.value,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'RED SOS CONECTADA',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.secondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 22, color: AppColors.onSurfaceVariant),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Cerrar emergencias',
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Active Live Location Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.near_me_rounded, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ubicación de auxilio fijada',
                            style: TextStyle(fontSize: 10, color: AppColors.onSurfaceMuted, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            'Av. San Martín 1420 (Delta Centro)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.gps_fixed_rounded, size: 12, color: AppColors.secondary),
                          SizedBox(width: 3),
                          Text(
                            '±3m',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Calling Simulation Notification
              if (_callingTitle != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Conectando con $_callingTitle...',
                          style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Silent Panic Card (Hold 3s)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _sosSent ? AppColors.secondaryEmerald : AppColors.emergency.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_sosSent ? AppColors.secondaryEmerald : AppColors.emergency).withValues(alpha: 0.1),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _sosSent ? AppColors.secondaryContainer : AppColors.emergencyContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _sosSent ? Icons.check_circle_rounded : Icons.shield_rounded,
                            size: 14,
                            color: _sosSent ? AppColors.onSecondaryContainer : AppColors.onErrorContainer,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _sosSent ? 'DESPACHO COD CONFIRMADO' : 'CENTRO DE OPERACIONES Y MONITOREO (COD)',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: _sosSent ? AppColors.onSecondaryContainer : AppColors.onErrorContainer,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _sosSent ? '¡Alerta Silenciosa Emitida!' : 'Alerta Silenciosa Inmediata',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _sosSent
                          ? 'Móvil de cercanía y patrulla náutica en camino a tus coordenadas.'
                          : 'Despacha patrullas al instante y transmite coordenadas exactas con canal de audio seguro.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Press & Hold 3s Button
                    if (!_sosSent) ...[
                      GestureDetector(
                        onTapDown: (_) => _startHolding(),
                        onTapUp: (_) => _stopHolding(),
                        onTapCancel: () => _stopHolding(),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Progress Ring
                            SizedBox(
                              width: 108,
                              height: 108,
                              child: CircularProgressIndicator(
                                value: _holdProgress,
                                strokeWidth: 5,
                                backgroundColor: AppColors.surfaceContainerHigh,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.emergency),
                              ),
                            ),
                            // Panic button
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.emergencyLight,
                                    AppColors.emergency,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.emergency.withValues(alpha: 0.35),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.touch_app_rounded, color: Colors.white, size: 28),
                                  SizedBox(height: 2),
                                  Text(
                                    'MANTENER 3s',
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _holdProgress,
                          minHeight: 4,
                          backgroundColor: AppColors.surfaceContainer,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.emergency),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _holdProgress > 0 ? 'Mantén presionado...' : 'Mantén presionado para enviar sin emitir sonido',
                        style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceMuted),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.check_circle_rounded, color: AppColors.secondary, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Patrulla COD despachada (ETA: 4 min)',
                              style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.onSecondaryContainer, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => setState(() => _sosSent = false),
                        child: const Text('Reactivar botón', style: TextStyle(color: AppColors.onSurfaceMuted)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Speed Dial Direct Lines Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.phone_in_talk_rounded, size: 18, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text(
                        'Llamada Rápida Directa',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'Líneas 24hs',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.secondary),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Direct line items
              _buildDirectLineCard(
                title: 'SAME Emergencias',
                eta: '~6 min',
                subtitle: 'Ambulancia, triage crítico y auxilio médico',
                phone: '107',
                icon: Icons.medical_services_rounded,
                badgeColor: AppColors.emergencyContainer,
                badgeTextColor: AppColors.onErrorContainer,
                phoneColor: AppColors.emergency,
              ),
              const SizedBox(height: 8),
              _buildDirectLineCard(
                title: 'Policía & Comando COD',
                subtitle: 'Patrullas de cercanía y prevención en isla',
                phone: '911',
                icon: Icons.local_police_rounded,
                badgeColor: AppColors.surfaceContainer,
                badgeTextColor: AppColors.primary,
                phoneColor: AppColors.primary,
              ),
              const SizedBox(height: 8),
              _buildDirectLineCard(
                title: 'Bomberos Voluntarios',
                subtitle: 'Incendios, rescate náutico fluvial e islas',
                phone: '100',
                icon: Icons.fire_truck_rounded,
                badgeColor: AppColors.tertiaryFixed,
                badgeTextColor: AppColors.onTertiaryContainer,
                phoneColor: AppColors.tertiary,
              ),
              const SizedBox(height: 8),
              _buildDirectLineCard(
                title: 'Defensa Civil y Mareas',
                subtitle: 'Sudestada, tormentas y crecientes del Paraná',
                phone: '103',
                icon: Icons.storm_rounded,
                badgeColor: AppColors.surfaceContainerHigh,
                badgeTextColor: AppColors.onSurface,
                phoneColor: AppColors.primary,
              ),
              const SizedBox(height: 8),
              _buildDirectLineCard(
                title: 'Línea DAMA - Asistencia Género',
                subtitle: 'Guardia 24hs contención y socorro inmediato',
                phone: '144',
                icon: Icons.shield_moon_rounded,
                badgeColor: AppColors.surfaceContainer,
                badgeTextColor: AppColors.primary,
                phoneColor: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDirectLineCard({
    required String title,
    String? eta,
    required String subtitle,
    required String phone,
    required IconData icon,
    required Color badgeColor,
    required Color badgeTextColor,
    required Color phoneColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _simulateCall(title, phone),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: badgeTextColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (eta != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryContainer.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                eta,
                                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.onSecondaryContainer),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    Text(
                      phone,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: phoneColor),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.phone_rounded, size: 14, color: phoneColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
