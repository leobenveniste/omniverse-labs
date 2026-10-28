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

    // Separar número de teléfono en país (+54), código de área (ej: 11) y número local
    String initialCountry = '+54';
    String initialArea = '';
    String initialNumber = '';

    final rawPhone = user.phone.trim();
    if (rawPhone.isNotEmpty) {
      if (rawPhone.startsWith('+')) {
        if (rawPhone.startsWith('+54')) {
          initialCountry = '+54';
          String rest = rawPhone.substring(3).trim();
          if (rest.startsWith('9')) rest = rest.substring(1).trim();
          final parts = rest.split(RegExp(r'[\s\-]+')).where((s) => s.isNotEmpty).toList();
          if (parts.length >= 2) {
            initialArea = parts[0];
            initialNumber = parts.sublist(1).join(' ');
          } else if (rest.length >= 10) {
            initialArea = rest.substring(0, 2);
            initialNumber = rest.substring(2);
          } else {
            initialNumber = rest;
          }
        } else {
          final match = RegExp(r'^(\+\d{1,3})\s*(.*)$').firstMatch(rawPhone);
          if (match != null) {
            initialCountry = match.group(1) ?? '+54';
            final rest = (match.group(2) ?? '').trim();
            final parts = rest.split(RegExp(r'[\s\-]+')).where((s) => s.isNotEmpty).toList();
            if (parts.length >= 2) {
              initialArea = parts[0];
              initialNumber = parts.sublist(1).join(' ');
            } else {
              initialNumber = rest;
            }
          } else {
            initialNumber = rawPhone;
          }
        }
      } else {
        final digits = rawPhone.replaceAll(RegExp(r'[^\d]'), '');
        if (digits.startsWith('54')) {
          initialCountry = '+54';
          String rest = digits.substring(2);
          if (rest.startsWith('9')) rest = rest.substring(1);
          if (rest.length >= 10) {
            initialArea = rest.substring(0, 2);
            initialNumber = rest.substring(2);
          } else {
            initialNumber = rest;
          }
        } else if (digits.length >= 10) {
          initialArea = digits.substring(0, 2);
          initialNumber = digits.substring(2);
        } else {
          initialNumber = rawPhone;
        }
      }
    }

    final countryCodeController = TextEditingController(text: initialCountry);
    final areaCodeController = TextEditingController(text: initialArea);
    final phoneNumberController = TextEditingController(text: initialNumber);

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
              final action = await showModalBottomSheet<String?>(
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
                            onTap: () => Navigator.of(modalCtx).pop('camera'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.photo_library_rounded,
                                color: AppTheme.skyBlue),
                            title: const Text('Elegir de la galería'),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            onTap: () => Navigator.of(modalCtx).pop('gallery'),
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
                              onTap: () => Navigator.of(modalCtx).pop('delete'),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );

              // Si se cierra el modal tocando afuera o con atrás, no hacemos nada (no se elimina la foto)
              if (action == null) return;

              if (action == 'delete') {
                setSheetState(() => currentPhotoUrl = '');
                return;
              }

              try {
                final picker = ImagePicker();
                final source = action == 'camera' ? ImageSource.camera : ImageSource.gallery;
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

                final cCode = countryCodeController.text.trim();
                final aCode = areaCodeController.text.trim().replaceAll(RegExp(r'[^\d]'), '');
                final lNum = phoneNumberController.text.trim().replaceAll(RegExp(r'[^\d]'), '');

                String assembledPhone = '';
                if (aCode.isNotEmpty || lNum.isNotEmpty) {
                  final prefix = cCode.isNotEmpty ? cCode : '+54';
                  if (aCode.isNotEmpty && lNum.isNotEmpty) {
                    assembledPhone = '$prefix $aCode $lNum';
                  } else {
                    assembledPhone = '$prefix ${aCode.isNotEmpty ? aCode : lNum}'.trim();
                  }
                }

                final updatedUser = user.copyWith(
                  firstName: firstNameController.text.trim(),
                  lastName: lastNameController.text.trim(),
                  email: emailController.text.trim(),
                  phone: assembledPhone,
                  instagram: cleanIg.isNotEmpty ? cleanIg : null,
                  photoUrl: (currentPhotoUrl != null &&
                          currentPhotoUrl!.trim().isNotEmpty)
                      ? currentPhotoUrl!.trim()
                      : null,
                  clearPhoto: currentPhotoUrl == null ||
                      currentPhotoUrl!.trim().isEmpty,
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Teléfono de Contacto (WhatsApp)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textSecondaryColor(ctx),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 78,
                                child: TextFormField(
                                  controller: countryCodeController,
                                  enabled: !isSaving,
                                  keyboardType: TextInputType.phone,
                                  decoration: const InputDecoration(
                                    labelText: 'País',
                                    hintText: '+54',
                                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 88,
                                child: TextFormField(
                                  controller: areaCodeController,
                                  enabled: !isSaving,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Área',
                                    hintText: '11',
                                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: phoneNumberController,
                                  enabled: !isSaving,
                                  keyboardType: TextInputType.phone,
                                  decoration: const InputDecoration(
                                    labelText: 'Número',
                                    hintText: '1234 5678',
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
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

  void _showThemeSelector(BuildContext context, SettingsService settingsService) {
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
                  'Tema de la Aplicación',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.brightness_auto_rounded, color: AppTheme.skyBlue),
                  title: const Text('Automático', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Detecta el modo del dispositivo', style: TextStyle(fontSize: 12)),
                  trailing: settingsService.isAutoTheme
                      ? const Icon(Icons.check_rounded, color: AppTheme.neonGreen)
                      : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    settingsService.setThemeMode(ThemeMode.system);
                    Navigator.of(ctx).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.dark_mode_rounded, color: Color(0xFF94A3B8)),
                  title: const Text('Modo Oscuro', style: TextStyle(fontWeight: FontWeight.w700)),
                  trailing: (!settingsService.isAutoTheme && settingsService.themeMode == ThemeMode.dark)
                      ? const Icon(Icons.check_rounded, color: AppTheme.neonGreen)
                      : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    settingsService.setThemeMode(ThemeMode.dark);
                    Navigator.of(ctx).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.light_mode_rounded, color: Color(0xFFF59E0B)),
                  title: const Text('Modo Claro', style: TextStyle(fontWeight: FontWeight.w700)),
                  trailing: (!settingsService.isAutoTheme && settingsService.themeMode == ThemeMode.light)
                      ? const Icon(Icons.check_rounded, color: AppTheme.neonGreen)
                      : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    settingsService.setThemeMode(ThemeMode.light);
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
                  leading: const Icon(Icons.language_rounded, color: AppTheme.skyBlue),
                  title: const Text('Automático', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Detecta el idioma del dispositivo', style: TextStyle(fontSize: 12)),
                  trailing: settingsService.isAutoLocale
                      ? const Icon(Icons.check_rounded, color: AppTheme.neonGreen)
                      : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    settingsService.setAutoLocale();
                    Navigator.of(ctx).pop();
                  },
                ),
                ListTile(
                  leading: const Text('🇦🇷', style: TextStyle(fontSize: 24)),
                  title: const Text('Español', style: TextStyle(fontWeight: FontWeight.w700)),
                  trailing: (!settingsService.isAutoLocale && settingsService.locale.languageCode == 'es')
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
                  trailing: (!settingsService.isAutoLocale && settingsService.locale.languageCode == 'en')
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
                    icon: Icons.palette_rounded,
                    iconBgColor: isDark ? const Color(0xFF334155) : const Color(0xFF1E293B),
                    title: 'Tema',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          settingsService.isAutoTheme
                              ? 'Automático'
                              : (settingsService.themeMode == ThemeMode.dark ? 'Oscuro' : 'Claro'),
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
                    onTap: () => _showThemeSelector(context, settingsService),
                  ),
                  _SettingRow(
                    icon: Icons.language_rounded,
                    iconBgColor: const Color(0xFF6366F1),
                    title: 'Idioma',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          settingsService.isAutoLocale
                              ? 'Automático'
                              : (settingsService.locale.languageCode == 'es'
                                  ? '🇦🇷 Español'
                                  : '🇺🇸 English'),
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
                      title: 'Administrar equipo',
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
                      'Versión 1.0.27 (Build 30)',
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
