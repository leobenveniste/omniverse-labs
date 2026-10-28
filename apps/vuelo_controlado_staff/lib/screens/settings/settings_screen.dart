import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/settings_service.dart';
import '../../services/firestore_sync_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/motion_components.dart';
import '../login_screen.dart';
import '../users/users_admin_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

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

  void _showEditProfileSheet(BuildContext context, UserModel user) {
    final firstNameController = TextEditingController(text: user.firstName);
    final lastNameController = TextEditingController(text: user.lastName);
    final emailController = TextEditingController(text: user.email);
    final phoneController = TextEditingController(text: user.phone);
    final instagramController =
        TextEditingController(text: user.instagram ?? '');
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;
    String? currentPhotoUrl = user.photoUrl;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final theme = Theme.of(ctx);

            Future<void> pickPhoto() async {
              final source = await showModalBottomSheet<ImageSource?>(
                context: ctx,
                backgroundColor: theme.colorScheme.surface,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (modalCtx) {
                  return SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Foto de Perfil',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            leading: const Icon(Icons.camera_alt_rounded,
                                color: AppTheme.neonGreen),
                            title: const Text('Tomar foto con la cámara'),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            onTap: () =>
                                Navigator.of(modalCtx).pop(ImageSource.camera),
                          ),
                          ListTile(
                            leading: const Icon(Icons.photo_library_rounded,
                                color: AppTheme.skyBlue),
                            title: const Text('Elegir de la galería'),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            onTap: () =>
                                Navigator.of(modalCtx).pop(ImageSource.gallery),
                          ),
                          if (currentPhotoUrl != null &&
                              currentPhotoUrl!.isNotEmpty)
                            ListTile(
                              leading: const Icon(Icons.delete_outline_rounded,
                                  color: AppTheme.errorRed),
                              title: const Text('Eliminar foto actual',
                                  style: TextStyle(color: AppTheme.errorRed)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              onTap: () {
                                Navigator.of(modalCtx).pop(null);
                                setSheetState(() => currentPhotoUrl = '');
                              },
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );

              if (source == null) return;

              try {
                final picker = ImagePicker();
                final picked = await picker.pickImage(
                  source: source,
                  maxWidth: 600,
                  maxHeight: 600,
                  imageQuality: 80,
                );

                if (picked != null) {
                  final bytes = await picked.readAsBytes();
                  final base64String =
                      'data:image/jpeg;base64,${base64Encode(bytes)}';
                  setSheetState(() => currentPhotoUrl = base64String);
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text('Error al seleccionar imagen: $e'),
                      backgroundColor: AppTheme.errorRed,
                    ),
                  );
                }
              }
            }

            Future<void> saveProfile() async {
              if (formKey.currentState?.validate() ?? false) {
                HapticFeedback.mediumImpact();
                setSheetState(() => isSaving = true);

                final authService = ctx.read<AuthService>();
                final cleanIg = instagramController.text
                    .trim()
                    .replaceAll('@', '')
                    .replaceAll(' ', '');

                final updatedUser = user.copyWith(
                  firstName: firstNameController.text.trim(),
                  lastName: lastNameController.text.trim(),
                  email: emailController.text.trim(),
                  phone: phoneController.text.trim(),
                  instagram: cleanIg.isNotEmpty ? cleanIg : null,
                  photoUrl: currentPhotoUrl,
                );

                final success = await authService.updateUserProfile(updatedUser);

                if (ctx.mounted) {
                  setSheetState(() => isSaving = false);
                  Navigator.of(ctx).pop();
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✓ Perfil actualizado correctamente.'),
                        backgroundColor: AppTheme.neonGreen,
                      ),
                    );
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(authService.errorMessage ??
                            'Error al actualizar perfil.'),
                        backgroundColor: AppTheme.errorRed,
                      ),
                    );
                  }
                }
              }
            }

            ImageProvider? sheetAvatarImage;
            if (currentPhotoUrl != null && currentPhotoUrl!.trim().isNotEmpty) {
              final raw = currentPhotoUrl!.trim();
              if (raw.startsWith('http')) {
                sheetAvatarImage = NetworkImage(raw);
              } else {
                try {
                  final clean = raw.contains(',') ? raw.split(',').last : raw;
                  sheetAvatarImage = MemoryImage(base64Decode(clean));
                } catch (_) {}
              }
            }

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
                          width: 40,
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
                            icon: const Icon(Icons.close, size: 20),
                            tooltip: 'Cerrar',
                            onPressed: isSaving
                                ? null
                                : () => Navigator.of(ctx).pop(),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Editar Perfil',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          FilledButton.icon(
                            style: AppTheme.headerActionButtonStyle(ctx),
                            onPressed: isSaving ? null : saveProfile,
                            icon: isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      strokeCap: StrokeCap.round,
                                    ),
                                  )
                                : const Icon(Icons.check_rounded, size: 18),
                            label: Text(isSaving ? 'Guardando...' : 'Guardar'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Actualizá tus datos personales y foto de perfil.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondaryColor(ctx),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: GestureDetector(
                          onTap: isSaving ? null : pickPhoto,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 36,
                                backgroundColor:
                                    theme.colorScheme.surfaceContainerHighest,
                                backgroundImage: sheetAvatarImage,
                                child: sheetAvatarImage == null
                                    ? Text(
                                        user.firstName.isNotEmpty
                                            ? user.firstName[0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          fontSize: 24,
                                          color: AppTheme.primaryColor(ctx),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      )
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor(ctx),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: theme.colorScheme.surface,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 16,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: firstNameController,
                              enabled: !isSaving,
                              decoration: const InputDecoration(
                                labelText: 'Nombre',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? 'Requerido'
                                      : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: lastNameController,
                              enabled: !isSaving,
                              decoration: const InputDecoration(
                                labelText: 'Apellido',
                              ),
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? 'Requerido'
                                      : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailController,
                        enabled: !isSaving,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Correo Electrónico',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Requerido';
                          if (!v.contains('@')) return 'Email no válido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: phoneController,
                        enabled: !isSaving,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono de Contacto',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Requerido'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: instagramController,
                        enabled: !isSaving,
                        decoration: const InputDecoration(
                          labelText: 'Usuario de Instagram',
                          hintText: 'ej: mi_usuario (sin @)',
                          prefixIcon: Icon(Icons.camera_alt_outlined),
                          prefixText: '@',
                        ),
                      ),
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

  void _showLanguageSelector(BuildContext context, SettingsService settingsService) {
    HapticFeedback.lightImpact();
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Seleccionar Idioma',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Text('🇦🇷', style: TextStyle(fontSize: 24)),
                  title: const Text('Español', style: TextStyle(fontWeight: FontWeight.w700)),
                  trailing: settingsService.locale.languageCode == 'es'
                      ? const Icon(Icons.check_rounded, color: AppTheme.neonGreen)
                      : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    settingsService.setLocale(const Locale('es'));
                    Navigator.of(ctx).pop();
                  },
                ),
                ListTile(
                  leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
                  title: const Text('English', style: TextStyle(fontWeight: FontWeight.w700)),
                  trailing: settingsService.locale.languageCode == 'en'
                      ? const Icon(Icons.check_rounded, color: AppTheme.neonGreen)
                      : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    settingsService.setLocale(const Locale('en'));
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
          ),
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
    final isDark = theme.brightness == Brightness.dark;
    final isDarkModeActive = settingsService.themeMode == ThemeMode.dark ||
        (settingsService.themeMode == ThemeMode.system && isDark);

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
              // HEADER DE PERFIL (Inspirado en Imagen 2)
              if (user != null) ...[
                _ProfileHeaderTile(
                  user: user,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showEditProfileSheet(context, user);
                  },
                ),
                const SizedBox(height: 24),
              ],

              // SECCIÓN PREFERENCIAS
              const _SectionHeader(title: 'PREFERENCIAS'),
              const SizedBox(height: 8),
              _SettingsGroup(
                children: [
                  _SettingRow(
                    icon: Icons.dark_mode_rounded,
                    iconBgColor: isDark ? const Color(0xFF334155) : const Color(0xFF1E293B),
                    title: 'Modo Oscuro',
                    trailing: Switch.adaptive(
                      value: isDarkModeActive,
                      activeThumbColor: AppTheme.neonGreen,
                      onChanged: (val) {
                        HapticFeedback.selectionClick();
                        settingsService.setThemeMode(
                          val ? ThemeMode.dark : ThemeMode.light,
                        );
                      },
                    ),
                  ),
                  _SettingRow(
                    icon: Icons.language_rounded,
                    iconBgColor: const Color(0xFF6366F1),
                    title: 'Idioma',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          settingsService.locale.languageCode == 'es'
                              ? '🇦🇷 Español'
                              : '🇺🇸 English',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondaryColor(context),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: AppTheme.textSecondaryColor(context),
                        ),
                      ],
                    ),
                    onTap: () => _showLanguageSelector(context, settingsService),
                    isLast: true,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // SECCIÓN CUENTA
              const _SectionHeader(title: 'CUENTA'),
              const SizedBox(height: 8),
              _SettingsGroup(
                children: [
                  if (user != null)
                    _SettingRow(
                      icon: Icons.person_rounded,
                      iconBgColor: const Color(0xFFF59E0B),
                      title: 'Editar Perfil',
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: AppTheme.textSecondaryColor(context),
                      ),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _showEditProfileSheet(context, user);
                      },
                    ),
                  _SettingRow(
                    icon: Icons.lock_rounded,
                    iconBgColor: const Color(0xFF3B82F6),
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
                    isLast: !canManageTeam,
                  ),
                  if (canManageTeam)
                    _SettingRow(
                      icon: Icons.people_alt_rounded,
                      iconBgColor: const Color(0xFF8B5CF6),
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
                      isLast: true,
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // SECCIÓN NOTIFICACIONES
              const _SectionHeader(title: 'NOTIFICACIONES'),
              const SizedBox(height: 8),
              _SettingsGroup(
                children: [
                  _SettingRow(
                    icon: Icons.notifications_rounded,
                    iconBgColor: const Color(0xFF10B981),
                    title: 'Notificaciones',
                    trailing: Switch.adaptive(
                      value: _notificationsEnabled,
                      activeThumbColor: AppTheme.neonGreen,
                      onChanged: (val) {
                        HapticFeedback.selectionClick();
                        setState(() => _notificationsEnabled = val);
                      },
                    ),
                    isLast: true,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // SECCIÓN SINCRONIZACIÓN Y NUBE
              const _SectionHeader(title: 'DATOS Y SINCRONIZACIÓN'),
              const SizedBox(height: 8),
              _SettingsGroup(
                children: [
                  _SettingRow(
                    icon: Icons.cloud_sync_rounded,
                    iconBgColor: const Color(0xFF06B6D4),
                    title: 'Sincronizar Datos en la Nube',
                    subtitle: 'Forzar sincronización con Firestore',
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppTheme.textSecondaryColor(context),
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
                    isLast: true,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // SECCIÓN SESIÓN
              const _SectionHeader(title: 'SESIÓN'),
              const SizedBox(height: 8),
              _SettingsGroup(
                children: [
                  _SettingRow(
                    icon: Icons.logout_rounded,
                    iconBgColor: const Color(0xFFEF4444),
                    title: 'Cerrar Sesión',
                    titleColor: AppTheme.errorRed,
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppTheme.errorRed,
                    ),
                    onTap: () async {
                      HapticFeedback.mediumImpact();
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Cerrar Sesión'),
                          content: const Text(
                            '¿Estás seguro de que deseás cerrar sesión?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancelar'),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.errorRed,
                              ),
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Cerrar Sesión'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && context.mounted) {
                        await authService.logout();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      }
                    },
                    isLast: true,
                  ),
                ],
              ),

              const SizedBox(height: 36),

              // PIE DE PÁGINA (Sutil, como en Imagen 2)
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      theme.brightness == Brightness.dark
                          ? 'assets/images/logo_white.png'
                          : 'assets/images/logo_color.png',
                      height: 32,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.flight_takeoff_rounded,
                        color: AppTheme.primaryColor(context),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vuelo Controlado Staff',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppTheme.textPrimaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Versión 1.0.24 (Build 27)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Fundación Vuelo Controlado • Reducción de daños',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondaryColor(context).withValues(alpha: 0.8),
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

class _ProfileHeaderTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;

  const _ProfileHeaderTile({
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = AppTheme.primaryColor(context);
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);
    final isDark = theme.brightness == Brightness.dark;

    ImageProvider? avatarImage;
    if (user.photoUrl != null && user.photoUrl!.trim().isNotEmpty) {
      final raw = user.photoUrl!.trim();
      if (raw.startsWith('http')) {
        avatarImage = NetworkImage(raw);
      } else {
        try {
          final clean = raw.contains(',') ? raw.split(',').last : raw;
          avatarImage = MemoryImage(base64Decode(clean));
        } catch (_) {}
      }
    }

    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131A22) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: primary.withValues(alpha: isDark ? 0.28 : 0.18),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: primary, width: 2),
              ),
              child: CircleAvatar(
                radius: 26,
                backgroundColor: primary.withValues(alpha: 0.15),
                backgroundImage: avatarImage,
                child: avatarImage == null
                    ? Text(
                        user.firstName.isNotEmpty
                            ? user.firstName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: primary,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Editar datos personales',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;

  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131A22) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: isDark ? 0.15 : 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final Widget trailing;
  final VoidCallback? onTap;
  final bool isLast;

  const _SettingRow({
    required this.icon,
    required this.iconBgColor,
    required this.title,
    this.subtitle,
    this.titleColor,
    required this.trailing,
    this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(icon, color: Colors.white, size: 19),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: titleColor ?? textPrimary,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                trailing,
              ],
            ),
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 66,
            endIndent: 16,
            color: theme.colorScheme.outline.withValues(alpha: isDark ? 0.12 : 0.08),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 2),
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
