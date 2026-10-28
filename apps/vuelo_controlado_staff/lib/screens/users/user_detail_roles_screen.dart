import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_background.dart';

class UserDetailRolesScreen extends StatefulWidget {
  final String userId;

  const UserDetailRolesScreen({super.key, required this.userId});

  @override
  State<UserDetailRolesScreen> createState() => _UserDetailRolesScreenState();
}

class _UserDetailRolesScreenState extends State<UserDetailRolesScreen> {
  late List<String> _currentRoles;
  late List<String> _initialRoles;
  bool _isSavingRoles = false;

  @override
  void initState() {
    super.initState();
    final authService = context.read<AuthService>();
    final user = authService.users.firstWhere((u) => u.id == widget.userId);
    _currentRoles = List<String>.from(user.roles);
    if (!_currentRoles.contains(AppRoles.miembro)) {
      _currentRoles.insert(0, AppRoles.miembro);
    }
    _initialRoles = List<String>.from(_currentRoles);
  }

  bool get _hasRoleChanges {
    if (_currentRoles.length != _initialRoles.length) return true;
    return !_currentRoles.every((r) => _initialRoles.contains(r));
  }

  void _toggleRole(String role, bool value) {
    if (role == AppRoles.miembro) return; // Inamovible
    HapticFeedback.selectionClick();
    setState(() {
      if (value) {
        if (!_currentRoles.contains(role)) _currentRoles.add(role);
      } else {
        _currentRoles.remove(role);
      }
    });
  }

  Future<void> _saveRoles() async {
    HapticFeedback.mediumImpact();
    setState(() => _isSavingRoles = true);
    final authService = context.read<AuthService>();
    final success =
        await authService.updateUserRoles(widget.userId, _currentRoles);

    if (mounted) {
      setState(() {
        _isSavingRoles = false;
        if (success) {
          _initialRoles = List<String>.from(_currentRoles);
        }
      });
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Roles actualizados exitosamente.'),
            backgroundColor: AppTheme.neonGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                authService.errorMessage ?? 'Error al actualizar roles.'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _pickAndUploadPhoto(BuildContext context, UserModel user) async {
    final theme = Theme.of(context);
    final textPrimary = AppTheme.textPrimaryColor(context);

    final source = await showModalBottomSheet<ImageSource?>(
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
                Text(
                  'Foto de Perfil',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded,
                      color: AppTheme.neonGreen),
                  title: const Text('Tomar foto con la cámara'),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded,
                      color: AppTheme.skyBlue),
                  title: const Text('Elegir de la galería'),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
                ),
                if (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded,
                        color: AppTheme.errorRed),
                    title: const Text('Eliminar foto actual',
                        style: TextStyle(color: AppTheme.errorRed)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    onTap: () async {
                      Navigator.of(ctx).pop(null);
                      final authService = context.read<AuthService>();
                      await authService.updateUserPhoto(
                          userId: user.id, photoUrl: '');
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
        final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        if (!context.mounted) return;
        final authService = context.read<AuthService>();
        final ok = await authService.updateUserPhoto(
          userId: user.id,
          photoUrl: base64String,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ok
                  ? '✓ Foto de perfil actualizada exitosamente.'
                  : 'Error al actualizar la foto.'),
              backgroundColor: ok ? AppTheme.neonGreen : AppTheme.errorRed,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteUser(BuildContext context, UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: AppTheme.errorRed, size: 24),
              SizedBox(width: 8),
              Text('¿Eliminar Usuario?'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Estás seguro de que deseás eliminar permanentemente a ${user.fullName} (${user.email})?',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Esta acción es irreversible y borrará el acceso del usuario a la plataforma.',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorRed,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 44),
              ),
              child: const Text('Eliminar Permanentemente'),
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true && context.mounted) {
      final authService = context.read<AuthService>();
      final ok = await authService.deleteUser(user.id);
      if (!mounted || !context.mounted) return;
      if (ok) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Usuario eliminado exitosamente.'),
            backgroundColor: AppTheme.neonGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authService.errorMessage ??
                'No se pudo eliminar el usuario.'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  void _showEditUserModal(BuildContext context, UserModel user) {
    final formKey = GlobalKey<FormState>();
    final firstNameController = TextEditingController(text: user.firstName);
    final lastNameController = TextEditingController(text: user.lastName);
    final emailController = TextEditingController(text: user.email);
    final docNumberController =
        TextEditingController(text: user.documentNumber);
    final phoneController = TextEditingController(text: user.phone);
    final instagramController =
        TextEditingController(text: user.instagram ?? '');
    String selectedDocType =
        user.documentType.isNotEmpty ? user.documentType : 'DNI';
    bool isSaving = false;

    final docTypes = ['DNI', 'Pasaporte', 'Cédula de Identidad'];
    if (!docTypes.contains(selectedDocType)) {
      docTypes.add(selectedDocType);
    }

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
            final primary = AppTheme.primaryColor(ctx);
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
                              'Editar Usuario',
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
                                    if (!formKey.currentState!.validate()) {
                                      return;
                                    }

                                    HapticFeedback.mediumImpact();
                                    setSheetState(() => isSaving = true);
                                    final authService =
                                        context.read<AuthService>();
                                    final oldDoc = user.documentNumber.trim();
                                    final newDoc =
                                        docNumberController.text.trim();
                                    final docChanged = oldDoc != newDoc;

                                    final success =
                                        await authService.updateUserByAdmin(
                                      userId: user.id,
                                      firstName:
                                          firstNameController.text.trim(),
                                      lastName:
                                          lastNameController.text.trim(),
                                      email: emailController.text.trim(),
                                      documentType: selectedDocType,
                                      documentNumber: newDoc,
                                      phone: phoneController.text.trim(),
                                      instagram:
                                          instagramController.text.trim(),
                                    );

                                    if (ctx.mounted) {
                                      setSheetState(() => isSaving = false);
                                      Navigator.of(ctx).pop();

                                      if (success && context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              docChanged
                                                  ? '✓ Usuario actualizado. Clave restablecida a: $newDoc'
                                                  : '✓ Usuario actualizado exitosamente.',
                                            ),
                                            backgroundColor:
                                                AppTheme.neonGreen,
                                            duration:
                                                const Duration(seconds: 4),
                                          ),
                                        );
                                      } else if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              authService.errorMessage ??
                                                  'Error al actualizar el usuario.',
                                            ),
                                            backgroundColor:
                                                AppTheme.errorRed,
                                          ),
                                        );
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
                      const SizedBox(height: 16),

                      // Nombre y Apellido
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: firstNameController,
                              enabled: !isSaving,
                              decoration: const InputDecoration(
                                labelText: 'Nombre',
                                prefixIcon: Icon(Icons.person_outline_rounded),
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

                      // Tipo y Número de Documento
                      Row(
                        children: [
                          SizedBox(
                            width: 120,
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedDocType,
                              decoration: const InputDecoration(
                                labelText: 'Tipo',
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                              ),
                              items: docTypes.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(type,
                                      style: const TextStyle(fontSize: 14)),
                                );
                              }).toList(),
                              onChanged: isSaving
                                  ? null
                                  : (val) {
                                      if (val != null) {
                                        setSheetState(
                                            () => selectedDocType = val);
                                      }
                                    },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: docNumberController,
                              enabled: !isSaving,
                              decoration: const InputDecoration(
                                labelText: 'Número de Documento',
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                              keyboardType: TextInputType.text,
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? 'Requerido'
                                      : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Banner informativo
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primary.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 16, color: primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Si se edita el documento, la clave de acceso se restablecerá automáticamente a ese nuevo número.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Correo Electrónico
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

                      // Teléfono
                      TextFormField(
                        controller: phoneController,
                        enabled: !isSaving,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono de Contacto',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),

                      // Instagram
                      TextFormField(
                        controller: instagramController,
                        enabled: !isSaving,
                        decoration: const InputDecoration(
                          labelText: 'Usuario de Instagram (Opcional)',
                          hintText: 'ej: usuario (sin @)',
                          prefixIcon: Icon(Icons.camera_alt_outlined),
                          prefixText: '@',
                        ),
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
    final authService = context.watch<AuthService>();
    final currentUser = authService.currentUser;
    final isSuperAdmin = currentUser?.isSuperAdmin ?? false;
    final primary = AppTheme.primaryColor(context);
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);
    final surface = AppTheme.surfaceContainer(context);
    final border = AppTheme.borderColor(context);

    UserModel? user;
    try {
      user = authService.users.firstWhere((u) => u.id == widget.userId);
    } catch (_) {
      user = null;
    }

    if (user == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(
            'Usuario no encontrado.',
            style: TextStyle(color: textSecondary),
          ),
        ),
      );
    }

    final isTargetSuperAdmin = user.isSuperAdmin ||
        user.email.trim().toLowerCase() ==
            AppRoles.superAdminEmail.toLowerCase();

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

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            style: AppTheme.headerIconButtonStyle(context),
            icon: const Icon(Icons.arrow_back_rounded, size: 20),
            tooltip: 'Volver',
            onPressed:
                _isSavingRoles ? null : () => Navigator.of(context).maybePop(),
          ),
        ),
        title: const AppHeaderTitle(title: 'Ficha de Usuario'),
        actions: [
          if (isSuperAdmin)
            FilledButton.icon(
              style: AppTheme.headerActionButtonStyle(context),
              onPressed: (_hasRoleChanges && !_isSavingRoles)
                  ? _saveRoles
                  : null,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _isSavingRoles
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
              label: Text(_isSavingRoles ? 'Guardando...' : 'Guardar'),
            ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            tooltip: 'Opciones de usuario',
            style: AppTheme.headerIconButtonStyle(context),
            icon: const Icon(Icons.more_vert_rounded, size: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: border),
            ),
            onSelected: (value) {
              HapticFeedback.lightImpact();
              if (value == 'edit') {
                _showEditUserModal(context, user!);
              } else if (value == 'delete') {
                _confirmDeleteUser(context, user!);
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18, color: textPrimary),
                    const SizedBox(width: 12),
                    Text(
                      'Editar Datos Personales',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isTargetSuperAdmin && isSuperAdmin)
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded,
                          size: 18, color: AppTheme.errorRed),
                      SizedBox(width: 12),
                      Text(
                        'Eliminar Usuario',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.errorRed,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: AppBackground(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabecera de usuario con datos y botón de edición
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => _pickAndUploadPhoto(context, user!),
                                child: Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 32,
                                      backgroundColor: surface,
                                      backgroundImage: avatarImage,
                                      child: avatarImage == null
                                          ? Text(
                                              user.firstName.isNotEmpty
                                                  ? user.firstName[0].toUpperCase()
                                                  : '?',
                                              style: TextStyle(
                                                fontSize: 22,
                                                color: primary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            )
                                          : null,
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          color: primary,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Theme.of(context).cardColor,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt_rounded,
                                          size: 14,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.fullName,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${user.documentType}: ${user.documentNumber}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: textSecondary,
                                      ),
                                    ),
                                    Text(
                                      user.email,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: textSecondary,
                                      ),
                                    ),
                                    if (user.phone.isNotEmpty)
                                      Text(
                                        'Tel: ${user.phone}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: textSecondary,
                                        ),
                                      ),
                                    if (user.instagram != null &&
                                        user.instagram!.isNotEmpty)
                                      Text(
                                        'IG: @${user.instagram}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: primary,
                                          fontWeight: FontWeight.w700,
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
                  ),
                  const SizedBox(height: 24),

                  // Sección de Roles (Solo Superadmin)
                  if (isSuperAdmin) ...[
                    Text(
                      'Asignación de Roles (Superadmin)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Un usuario puede tener múltiples roles simultáneamente. El rol "Miembro" es obligatorio para todo el staff.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tarjetas expresivas de roles sin divisores
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border),
                      ),
                      child: CheckboxListTile(
                        value: true,
                        onChanged: null,
                        activeColor: primary,
                        title: Text(
                          'Miembro (Base)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          'Rol obligatorio por defecto. Permite sumarse a eventos y registrar fichas.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                          ),
                        ),
                      ),
                    ),
                    _RoleSwitchTile(
                      title: AppRoles.organizacion,
                      subtitle:
                          'Permite crear y coordinar eventos en el sistema.',
                      value: _currentRoles.contains(AppRoles.organizacion),
                      onChanged: (v) => _toggleRole(AppRoles.organizacion, v),
                    ),
                    _RoleSwitchTile(
                      title: AppRoles.produccion,
                      subtitle:
                          'Permite crear eventos y gestionar la logística técnica.',
                      value: _currentRoles.contains(AppRoles.produccion),
                      onChanged: (v) => _toggleRole(AppRoles.produccion, v),
                    ),
                    _RoleSwitchTile(
                      title: AppRoles.rrhh,
                      subtitle:
                          'Permite dar de alta nuevos usuarios y gestionar credenciales.',
                      value: _currentRoles.contains(AppRoles.rrhh),
                      onChanged: (v) => _toggleRole(AppRoles.rrhh, v),
                    ),
                    _RoleSwitchTile(
                      title: AppRoles.comercial,
                      subtitle:
                          'Acceso a métricas de eventos y reportes comerciales.',
                      value: _currentRoles.contains(AppRoles.comercial),
                      onChanged: (v) => _toggleRole(AppRoles.comercial, v),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleSwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final Function(bool) onChanged;

  const _RoleSwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primaryColor(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value
              ? primary.withValues(alpha: 0.45)
              : AppTheme.borderColor(context),
        ),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeThumbColor: primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryColor(context),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondaryColor(context),
          ),
        ),
      ),
    );
  }
}
