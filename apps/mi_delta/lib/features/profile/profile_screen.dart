import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/app_providers.dart';
import '../../widgets/civic_fixed_header.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const ProfileScreen({super.key, this.onBack});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _notifReclamos = true;
  bool _notifRio = true;
  bool _notifTurnos = true;
  bool _biometricsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadBiometricsPreference();
  }

  Future<void> _loadBiometricsPreference() async {
    final enabled = await ref.read(biometricServiceProvider).isBiometricsEnabledInApp();
    if (mounted) {
      setState(() => _biometricsEnabled = enabled);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final currentThemeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: CivicFixedHeader(
        title: 'Mi Perfil',
        showBackButton: true,
        onBack: widget.onBack,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        physics: const BouncingScrollPhysics(),
        children: [
          // Hero Citizen ID Card
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primaryContainer,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.16),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white,
                      child: Text(
                        (user?.name ?? 'V').substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user?.name ?? 'Valentina Delta',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.verified_rounded, size: 16, color: AppColors.secondaryFixed),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? 'vecino@delta.gob.ar',
                            style: const TextStyle(fontSize: 12, color: AppColors.primaryFixedDim),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryContainer.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'IDENTIDAD RENAPER VERIFICADA',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppColors.secondaryFixed,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Citizen Personal Details Section
          const Text(
            'DATOS CIUDADANOS COMPLETOS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                _buildDataRow(
                  icon: Icons.badge_outlined,
                  label: 'Documento Nacional (DNI)',
                  value: user?.dni ?? '29.583.026',
                ),
                const Divider(height: 1),
                _buildDataRow(
                  icon: Icons.email_outlined,
                  label: 'Correo Electrónico',
                  value: user?.email ?? 'leo.benveniste@gmail.com',
                ),
                const Divider(height: 1),
                _buildDataRow(
                  icon: Icons.phone_outlined,
                  label: 'Teléfono Móvil',
                  value: '+54 11 4829-1020',
                ),
                const Divider(height: 1),
                _buildDataRow(
                  icon: Icons.home_outlined,
                  label: 'Dirección Registrada',
                  value: user?.address ?? 'Av. Las Palmeras 1240',
                ),
                const Divider(height: 1),
                _buildDataRow(
                  icon: Icons.location_city_outlined,
                  label: 'Barrio / Localidad',
                  value: user?.locality ?? 'Rincón Náutico',
                ),
                const Divider(height: 1),
                _buildDataRow(
                  icon: Icons.credit_card_outlined,
                  label: 'Número de Socio "Soy Delta"',
                  value: user?.memberNumber ?? 'SD-84920',
                  badge: 'Activo',
                ),
                const Divider(height: 1),
                _buildDataRow(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Estado de Cuenta ABL',
                  value: r'Al día ($ 0,00)',
                  badge: '10% OFF',
                  badgeColor: AppColors.secondaryEmerald,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Theme Selection: Claro / Oscuro / Automático
          const Text(
            'APARIENCIA DEL SISTEMA',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                _buildThemeOption(
                  context,
                  ref,
                  currentMode: currentThemeMode,
                  targetMode: ThemeMode.system,
                  label: 'Automático',
                  icon: Icons.brightness_auto_rounded,
                ),
                const SizedBox(width: 8),
                _buildThemeOption(
                  context,
                  ref,
                  currentMode: currentThemeMode,
                  targetMode: ThemeMode.light,
                  label: 'Claro',
                  icon: Icons.light_mode_rounded,
                ),
                const SizedBox(width: 8),
                _buildThemeOption(
                  context,
                  ref,
                  currentMode: currentThemeMode,
                  targetMode: ThemeMode.dark,
                  label: 'Oscuro',
                  icon: Icons.dark_mode_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Notification Settings
          const Text(
            'PREFERENCIAS Y NOTIFICACIONES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: AppColors.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.cardBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Notificaciones de mis reclamos', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
                  subtitle: const Text('Avances de cuadrillas y resoluciones', style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                  value: _notifReclamos,
                  activeTrackColor: AppColors.secondary,
                  activeThumbColor: Colors.white,
                  onChanged: (v) => setState(() => _notifReclamos = v),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Recordatorio de Turnos', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
                  subtitle: const Text('Avisos 24 horas antes de cada cita', style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                  value: _notifTurnos,
                  activeTrackColor: AppColors.secondary,
                  activeThumbColor: Colors.white,
                  onChanged: (v) => setState(() => _notifTurnos = v),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Alertas Hidrometeorológicas', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
                  subtitle: const Text('Sudestadas, crecidas y defensas del río', style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                  value: _notifRio,
                  activeTrackColor: AppColors.secondary,
                  activeThumbColor: Colors.white,
                  onChanged: (v) => setState(() => _notifRio = v),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Acceso con Huella / Face ID', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
                  subtitle: const Text('Ingresar rápidamente con biometría del celular', style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                  value: _biometricsEnabled,
                  activeTrackColor: AppColors.secondary,
                  activeThumbColor: Colors.white,
                  onChanged: (v) async {
                    HapticFeedback.selectionClick();
                    setState(() => _biometricsEnabled = v);
                    await ref.read(biometricServiceProvider).setBiometricsEnabledInApp(v);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Prominent Logout Section
          // Privacy and Terms Section
          Material(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.shield_outlined, size: 20, color: AppColors.primary),
                ),
                title: const Text(
                  'Privacidad y Protección de Datos',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                ),
                subtitle: const Text(
                  'Políticas de tratamiento cívico, seguridad y derechos ARCO',
                  style: TextStyle(fontSize: 11, color: AppColors.onSurfaceMuted),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.onSurfaceMuted),
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showPrivacyPolicyDialog(context);
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Prominent Logout & Account Deletion Section
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.emergency.withValues(alpha: 0.3)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lock_person_outlined, color: AppColors.emergency, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Gestión de Sesión y Datos',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.emergency,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Podés cerrar tu sesión activa o ejercer tu derecho a la eliminación permanente de tu cuenta y registros cívicos.',
                  style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmLogout(context, ref),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text(
                      'Cerrar Sesión de Mi Delta',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emergency,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmAccountDeletion(context, ref),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.emergency),
                    label: const Text(
                      'Solicitar Eliminación de Datos y Cuenta',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.emergency),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.emergency.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow({
    required IconData icon,
    required String label,
    required String value,
    String? badge,
    Color? badgeColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceMuted, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                ),
              ],
            ),
          ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (badgeColor ?? AppColors.secondary).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: badgeColor ?? AppColors.secondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.emergency, size: 22),
            SizedBox(width: 8),
            Text('¿Cerrar Sesión?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          ],
        ),
        content: const Text(
          'Vas a salir de tu cuenta cívica. Para volver a ingresar necesitarás tu correo o iniciar como vecino demo.',
          style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.onSurfaceMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emergency,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sí, Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  void _confirmAccountDeletion(BuildContext context, WidgetRef ref) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.emergency, size: 22),
            SizedBox(width: 8),
            Text('¿Eliminar Cuenta?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          ],
        ),
        content: const Text(
          'Esta acción solicitará la eliminación permanente de tu cuenta ciudadana, tus turnos agendados y credenciales locales.\n\nConforme a las normativas de protección de datos y las políticas de Google Play, tus datos personales serán eliminados. También podés solicitar la baja escribiendo a omniverselabs@gmail.com.',
          style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.onSurfaceMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authProvider.notifier).deleteAccountAndData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cuenta y datos locales eliminados correctamente.'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emergency,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sí, Eliminar Cuenta'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: AppColors.primary, size: 22),
            SizedBox(width: 8),
            Text('Privacidad y Datos', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mi Delta (Omniverse Labs)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurface),
            ),
            const SizedBox(height: 4),
            const Text(
              'Paquete: com.omniverselabs.mi_delta',
              style: TextStyle(fontSize: 12, color: AppColors.onSurfaceMuted),
            ),
            const SizedBox(height: 12),
            const Text(
              '• Cifrado seguro en tránsito (TLS/HTTPS).\n'
              '• Almacenamiento local protegido.\n'
              '• No vendemos ni compartimos datos con terceros.\n'
              '• Derecho de supresión y eliminación de cuenta garantizado.',
              style: TextStyle(fontSize: 13, height: 1.45, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const SelectableText(
                'https://leobenveniste.github.io/omniverse-labs/mi-delta.html',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    WidgetRef ref, {
    required ThemeMode currentMode,
    required ThemeMode targetMode,
    required String label,
    required IconData icon,
  }) {
    final isSelected = currentMode == targetMode;
    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: 'Modo $label',
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            ref.read(themeModeProvider.notifier).setThemeMode(targetMode);
          },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.cardBorder,
                width: 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.20),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
