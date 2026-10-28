import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/settings_service.dart';
import '../../services/firestore_sync_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';
import '../login_screen.dart';
import '../users/users_admin_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showChangePasswordSheet(BuildContext context) {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            final theme = Theme.of(ctx);
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 12,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          IconButton(
                            style: AppTheme.headerIconButtonStyle(ctx),
                            icon: const Icon(Icons.close_rounded, size: 20),
                            tooltip: 'Cerrar',
                            onPressed: isSaving
                                ? null
                                : () => Navigator.of(ctx).pop(),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Cambiar Contraseña',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          FilledButton.icon(
                            style: AppTheme.headerActionButtonStyle(ctx),
                            onPressed: isSaving
                                ? null
                                : () async {
                                    if (formKey.currentState?.validate() ??
                                        false) {
                                      HapticFeedback.mediumImpact();
                                      setSheetState(() => isSaving = true);
                                      final newPass =
                                          passwordController.text.trim();
                                      final authService =
                                          context.read<AuthService>();
                                      final success = await authService
                                          .updatePassword(newPass);

                                      if (ctx.mounted) {
                                        setSheetState(() => isSaving = false);
                                        Navigator.of(ctx).pop();
                                        if (success && context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  '✓ Contraseña actualizada correctamente.'),
                                              backgroundColor:
                                                  AppTheme.neonGreen,
                                            ),
                                          );
                                        } else if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(authService
                                                      .errorMessage ??
                                                  'Error al actualizar contraseña.'),
                                              backgroundColor:
                                                  AppTheme.errorRed,
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  },
                            icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: isSaving
                                  ? const SizedBox(
                                      key: ValueKey('saving'),
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.check_rounded,
                                      key: ValueKey('idle'),
                                      size: 18,
                                    ),
                            ),
                            label: Text(isSaving ? 'Guardando...' : 'Guardar'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Reemplazá tu clave de acceso por una nueva contraseña personal.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondaryColor(ctx),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: passwordController,
                        enabled: !isSaving,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Nueva Contraseña',
                          prefixIcon: Icon(Icons.lock_outline_rounded),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Ingresá una contraseña';
                          }
                          if (v.trim().length < 4) return 'Mínimo 4 caracteres';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: confirmController,
                        enabled: !isSaving,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirmar Contraseña',
                          prefixIcon: Icon(Icons.lock_reset_rounded),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Confirmá la contraseña';
                          }
                          if (v.trim() != passwordController.text.trim()) {
                            return 'Las contraseñas no coinciden';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = context.watch<AuthService>();
    final settingsService = context.watch<SettingsService>();
    final user = authService.currentUser;
    final canManageTeam =
        user != null && (user.canManageUsers || user.canCreateUsers);
    final primary = AppTheme.primaryColor(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const AppHeaderTitle(title: 'Ajustes'),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
            children: [
              // SECCIÓN APARIENCIA E IDIOMA
              const _SectionHeader(title: 'PREFERENCIAS'),
              const SizedBox(height: 8),

              // Tema / Modo de Interfaz
              _ExpressiveSettingCard(
                icon: Icons.palette_outlined,
                iconColor: primary,
                title: 'Tema de Interfaz',
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<ThemeMode>(
                    value: settingsService.themeMode,
                    dropdownColor: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    icon: Icon(
                      Icons.unfold_more_rounded,
                      size: 20,
                      color: primary,
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryColor(context),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text('Automático'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text('Claro'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text('Oscuro'),
                      ),
                    ],
                    onChanged: (newMode) {
                      if (newMode != null) {
                        HapticFeedback.selectionClick();
                        settingsService.setThemeMode(newMode);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Idioma
              _ExpressiveSettingCard(
                icon: Icons.language_rounded,
                iconColor: primary,
                title: 'Idioma',
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: settingsService.locale.languageCode,
                    dropdownColor: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    icon: Icon(
                      Icons.unfold_more_rounded,
                      size: 20,
                      color: primary,
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryColor(context),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'es',
                        child: Text('🇦🇷 Español'),
                      ),
                      DropdownMenuItem(
                        value: 'en',
                        child: Text('🇺🇸 English'),
                      ),
                    ],
                    onChanged: (newLang) {
                      if (newLang != null) {
                        HapticFeedback.selectionClick();
                        settingsService.setLocale(Locale(newLang));
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // SECCIÓN SINCRONIZACIÓN Y NUBE
              const _SectionHeader(title: 'SINCRONIZACIÓN Y NUBE'),
              const SizedBox(height: 8),

              _ExpressiveSettingCard(
                icon: Icons.cloud_sync_rounded,
                iconColor: primary,
                title: 'Sincronizar Datos en la Nube',
                trailing: Icon(
                  Icons.sync_rounded,
                  size: 20,
                  color: primary,
                ),
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Sincronizando con la nube...'),
                        ],
                      ),
                      duration: Duration(seconds: 1),
                    ),
                  );
                  final syncService =
                      context.read<FirestoreSyncService?>();
                  final ok = syncService != null
                      ? await syncService.forceSyncAll()
                      : false;
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok
                            ? '✓ Sincronización con la nube completada'
                            : '⚠️ Error al sincronizar con la nube'),
                        backgroundColor:
                            ok ? AppTheme.neonGreen : AppTheme.errorRed,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 24),

              // SECCIÓN GESTIÓN Y CUENTA
              const _SectionHeader(title: 'CUENTA Y EQUIPO'),
              const SizedBox(height: 8),

              if (canManageTeam) ...[
                _ExpressiveSettingCard(
                  icon: Icons.group_rounded,
                  iconColor: primary,
                  title: 'Panel de Equipo y Voluntarios',
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppTheme.textSecondaryColor(context),
                  ),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const UsersAdminScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],

              _ExpressiveSettingCard(
                icon: Icons.lock_reset_rounded,
                iconColor: primary,
                title: 'Cambiar Contraseña',
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppTheme.textSecondaryColor(context),
                ),
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showChangePasswordSheet(context);
                },
              ),
              const SizedBox(height: 8),

              _ExpressiveSettingCard(
                icon: Icons.logout_rounded,
                iconColor: AppTheme.errorRed,
                title: 'Cerrar Sesión',
                titleColor: AppTheme.errorRed,
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppTheme.errorRed,
                ),
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  await authService.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
              ),

              const SizedBox(height: 32),

              // INFORMACIÓN DE LA APP (LIVIANA, AMIGABLE Y SIN CONTENEDORES)
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      theme.brightness == Brightness.dark
                          ? 'assets/images/logo_white.png'
                          : 'assets/images/logo_color.png',
                      height: 36,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.flight_takeoff_rounded,
                        color: primary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vuelo Controlado Staff',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppTheme.textPrimaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Versión 1.0.22 (Build 25)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Fundación Vuelo Controlado • Reducción de riesgos y daños en espacios de ocio nocturno y festivales.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondaryColor(context),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpressiveSettingCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Color? titleColor;
  final Widget trailing;
  final VoidCallback? onTap;

  const _ExpressiveSettingCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.titleColor,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.cardColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.borderColor(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: titleColor ?? AppTheme.textPrimaryColor(context),
                  ),
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: AppTheme.primaryColor(context),
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
