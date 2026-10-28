import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/motion_components.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _showFullscreenQrDialog({
    required BuildContext context,
    required String title,
    required String data,
    required String handle,
    required IconData icon,
  }) {
    HapticFeedback.lightImpact();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 260),
      transitionBuilder: (ctx, anim, _, child) {
        final curved =
            CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.84, end: 1.0).animate(curved),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      pageBuilder: (ctx, anim, secAnim) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppTheme.neonGreen, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 20, color: AppTheme.emeraldDark),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF111827),
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF374151)),
                      tooltip: 'Cerrar',
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: QrImageView(
                    data: data,
                    version: QrVersions.auto,
                    size: 224,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF000000),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF000000),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.emeraldDark.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    handle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.emeraldDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickPhotoDirectly(BuildContext context, UserModel user) async {
    HapticFeedback.lightImpact();
    final theme = Theme.of(context);
    final source = await showModalBottomSheet<ImageSource?>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
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
                  onTap: () => Navigator.of(modalCtx).pop(ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded,
                      color: AppTheme.skyBlue),
                  title: const Text('Elegir de la galería'),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onTap: () => Navigator.of(modalCtx).pop(ImageSource.gallery),
                ),
                if (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded,
                        color: AppTheme.errorRed),
                    title: const Text('Eliminar foto actual',
                        style: TextStyle(color: AppTheme.errorRed)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    onTap: () => Navigator.of(modalCtx).pop(null),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (!context.mounted) return;

    final authService = context.read<AuthService>();
    if (source == null) {
      if (user.photoUrl != null && user.photoUrl!.isNotEmpty) {
        await authService.updateUserPhoto(userId: user.id, photoUrl: '');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Foto de perfil eliminada'),
              backgroundColor: AppTheme.neonGreen,
            ),
          );
        }
      }
      return;
    }

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 80,
      );

      if (picked != null && context.mounted) {
        final bytes = await picked.readAsBytes();
        final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        final ok = await authService.updateUserPhoto(
          userId: user.id,
          photoUrl: base64String,
        );
        if (ok && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Foto de perfil actualizada'),
              backgroundColor: AppTheme.neonGreen,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar foto: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  void _showConfigureProfileSheet(BuildContext context, UserModel user) {
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

            Future<void> saveProfile() async {
              if (!(formKey.currentState?.validate() ?? false)) return;
              setSheetState(() => isSaving = true);
              HapticFeedback.mediumImpact();
              final authService = context.read<AuthService>();
              final ok = await authService.updateProfile(
                firstName: firstNameController.text,
                lastName: lastNameController.text,
                email: emailController.text,
                phone: phoneController.text,
                instagram: instagramController.text,
                photoUrl: currentPhotoUrl,
              );
              if (ctx.mounted) {
                setSheetState(() => isSaving = false);
                Navigator.of(ctx).pop();
                if (ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✓ Perfil actualizado correctamente'),
                      backgroundColor: AppTheme.neonGreen,
                    ),
                  );
                }
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                left: 20,
                right: 20,
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
                        'Actualizá tus datos personales. El usuario de Instagram se reflejará en tu código QR.',
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

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;

    if (user == null) {
      return const SizedBox.shrink();
    }

    const instagramVueloUrl = 'https://www.instagram.com/vuelocontrolado/';
    final userIg = user.instagram?.trim() ?? '';
    final userIgUrl = userIg.isNotEmpty
        ? 'https://www.instagram.com/$userIg/'
        : instagramVueloUrl;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const AppHeaderTitle(title: 'Perfil'),
        actions: [
          IconButton(
            style: AppTheme.headerIconButtonStyle(context),
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar Perfil',
            onPressed: () {
              HapticFeedback.lightImpact();
              _showConfigureProfileSheet(context, user);
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          final qrSize =
              ((availableWidth - 32 - 12) / 2 - 20).clamp(120.0, 180.0);

          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildIdCard(context, user, userIg, userIgUrl, instagramVueloUrl),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Icon(
                          Icons.qr_code_2_rounded,
                          size: 18,
                          color: AppTheme.primaryColor(context),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'CÓDIGOS QR DE ACCESO',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primaryColor(context),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildDualQrRow(
                      context: context,
                      userIgUrl: userIgUrl,
                      instagramVueloUrl: instagramVueloUrl,
                      userIg: userIg,
                      qrSize: qrSize,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _getRoleBadgeLabel(UserModel user) {
    if (user.email.toLowerCase() == AppRoles.superAdminEmail.toLowerCase()) {
      return 'Coordinación General';
    }
    if (user.roles.contains(AppRoles.rrhh)) {
      return 'Gestión & RRHH';
    }
    if (user.roles.contains(AppRoles.produccion)) {
      return 'Producción & Eventos';
    }
    if (user.roles.contains(AppRoles.organizacion)) {
      return 'Organización';
    }
    if (user.roles.contains(AppRoles.comercial)) {
      return 'Comercial';
    }
    final extraRoles = user.roles.where((r) => r != AppRoles.miembro).toList();
    if (extraRoles.isNotEmpty) {
      return extraRoles.first;
    }
    return 'Reducción de Daños';
  }

  Widget _buildIdCard(
    BuildContext context,
    UserModel user,
    String userIg,
    String userIgUrl,
    String instagramVueloUrl,
  ) {
    final primary = AppTheme.primaryColor(context);
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

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

    final roleLabel = _getRoleBadgeLabel(user);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131A22) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: primary.withValues(alpha: isDark ? 0.28 : 0.20),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // HERO PORTRAIT SUPERIOR CON BORDES CURVOS
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            child: Stack(
              children: [
                if (avatarImage != null)
                  Image(
                    image: avatarImage,
                    width: double.infinity,
                    height: 270,
                    fit: BoxFit.cover,
                  )
                else
                  Container(
                    width: double.infinity,
                    height: 230,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                const Color(0xFF0F172A),
                                const Color(0xFF1E293B),
                                primary.withValues(alpha: 0.15),
                              ]
                            : [
                                primary.withValues(alpha: 0.15),
                                const Color(0xFFE2E8F0),
                              ],
                      ),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: primary, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 52,
                          backgroundColor: primary.withValues(alpha: 0.2),
                          child: Text(
                            user.firstName.isNotEmpty
                                ? user.firstName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Gradiente inferior para legibilidad
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.35),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.65),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),

                // Tag superior izquierdo: Vuelo Controlado Staff
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.60),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.flight_takeoff_rounded,
                          size: 13,
                          color: AppTheme.neonGreen,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'STAFF OFICIAL',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Botón superior derecho: Cambiar Foto
                Positioned(
                  top: 12,
                  right: 12,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _pickPhotoDirectly(context, user),
                      child: Tooltip(
                        message: 'Cambiar foto de perfil',
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // CUERPO DE LA TARJETA
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre en negrita + Badge verificado
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        user.fullName,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.verified_rounded,
                      color: AppTheme.neonGreen,
                      size: 22,
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Rótulo de rol y mención de Instagram
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: isDark ? 0.16 : 0.10),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        roleLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                          color: primary,
                        ),
                      ),
                    ),
                    if (userIg.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.camera_alt_outlined,
                              size: 12,
                              color: textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '@$userIg',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 16),

                // Datos de Contacto
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F151C)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.email_outlined, size: 16, color: primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          user.email,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Botones píldora para acciones de QR e Instagram
                Row(
                  children: [
                    Expanded(
                      child: PressableScale(
                        onTap: () => _showFullscreenQrDialog(
                          context: context,
                          title: 'MI INSTAGRAM',
                          data: userIgUrl,
                          handle: userIg.isNotEmpty
                              ? '@$userIg'
                              : '@configura_tu_ig',
                          icon: Icons.camera_alt_outlined,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: primary.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code_rounded,
                                  size: 16, color: primary),
                              const SizedBox(width: 6),
                              Text(
                                'Mi QR',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PressableScale(
                        onTap: () => _showFullscreenQrDialog(
                          context: context,
                          title: 'VUELO CONTROLADO',
                          data: instagramVueloUrl,
                          handle: '@vuelocontrolado',
                          icon: Icons.flight_takeoff_rounded,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: theme.colorScheme.outline
                                  .withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.flight_takeoff_rounded,
                                size: 16,
                                color: textPrimary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'QR Vuelo',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Botón Editar Información
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    icon: const Icon(Icons.edit_note_rounded, size: 18),
                    label: const Text(
                      'Editar Datos Personales',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _showConfigureProfileSheet(context, user);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDualQrRow({
    required BuildContext context,
    required String userIgUrl,
    required String instagramVueloUrl,
    required String userIg,
    required double qrSize,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildQrCard(
            context: context,
            title: 'MI INSTAGRAM',
            data: userIgUrl,
            handle: userIg.isNotEmpty ? '@$userIg' : '@configura_tu_ig',
            icon: Icons.camera_alt_outlined,
            qrSize: qrSize,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQrCard(
            context: context,
            title: 'VUELO CONTROLADO',
            data: instagramVueloUrl,
            handle: '@vuelocontrolado',
            icon: Icons.flight_takeoff_rounded,
            qrSize: qrSize,
          ),
        ),
      ],
    );
  }

  Widget _buildQrCard({
    required BuildContext context,
    required String title,
    required String data,
    required String handle,
    required IconData icon,
    required double qrSize,
  }) {
    final primary = AppTheme.primaryColor(context);

    return PressableScale(
      onTap: () => _showFullscreenQrDialog(
        context: context,
        title: title,
        data: data,
        handle: handle,
        icon: icon,
      ),
      targetScale: 0.95,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: primary.withValues(alpha: 0.28),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 14, color: AppTheme.emeraldDark),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Tooltip(
                    message: 'Ampliar QR',
                    child: Icon(
                      Icons.fullscreen_rounded,
                      size: 16,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              QrImageView(
                data: data,
                version: QrVersions.auto,
                size: qrSize,
                padding: EdgeInsets.zero,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF000000),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF000000),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.emeraldDark.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  handle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.emeraldDark,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
