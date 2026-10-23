import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class UserDetailRolesScreen extends StatefulWidget {
  final String userId;

  const UserDetailRolesScreen({super.key, required this.userId});

  @override
  State<UserDetailRolesScreen> createState() => _UserDetailRolesScreenState();
}

class _UserDetailRolesScreenState extends State<UserDetailRolesScreen> {
  late List<String> _currentRoles;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final authService = context.read<AuthService>();
    final user = authService.users.firstWhere((u) => u.id == widget.userId);
    _currentRoles = List<String>.from(user.roles);
    if (!_currentRoles.contains(AppRoles.miembro)) {
      _currentRoles.insert(0, AppRoles.miembro);
    }
  }

  void _toggleRole(String role, bool value) {
    if (role == AppRoles.miembro) return; // Inamovible
    setState(() {
      if (value) {
        if (!_currentRoles.contains(role)) _currentRoles.add(role);
      } else {
        _currentRoles.remove(role);
      }
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final authService = context.read<AuthService>();
    final success =
        await authService.updateUserRoles(widget.userId, _currentRoles);

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Roles actualizados exitosamente.'),
            backgroundColor: AppTheme.neonGreen,
          ),
        );
        Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    UserModel? user;
    try {
      user = authService.users.firstWhere((u) => u.id == widget.userId);
    } catch (_) {
      user = null;
    }

    if (user == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Usuario no encontrado.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administración de Roles'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera de usuario
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppTheme.darkCard,
                      child: Text(
                        user.firstName.isNotEmpty
                            ? user.firstName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 22,
                          color: AppTheme.neonGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${user.documentType}: ${user.documentNumber}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          Text(
                            user.email,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Asignación de Roles (Superadmin)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Un usuario puede tener múltiples roles simultáneamente. El rol "Miembro" es obligatorio para todo el staff.',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),

            // Tarjeta de roles
            Card(
              child: Column(
                children: [
                  // Miembro (deshabilitado / inamovible)
                  CheckboxListTile(
                    value: true,
                    onChanged: null,
                    activeColor: AppTheme.neonGreen,
                    title: const Text(
                      'Miembro (Base)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    subtitle: const Text(
                      'Rol obligatorio por defecto. Permite sumarse a eventos y registrar fichas.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ),
                  const Divider(height: 1),

                  // Organización
                  _RoleSwitchTile(
                    title: AppRoles.organizacion,
                    subtitle: 'Permite crear y coordinar eventos en el sistema.',
                    value: _currentRoles.contains(AppRoles.organizacion),
                    onChanged: (v) => _toggleRole(AppRoles.organizacion, v),
                  ),
                  const Divider(height: 1),

                  // Producción
                  _RoleSwitchTile(
                    title: AppRoles.produccion,
                    subtitle: 'Permite crear eventos y gestionar la logística técnica.',
                    value: _currentRoles.contains(AppRoles.produccion),
                    onChanged: (v) => _toggleRole(AppRoles.produccion, v),
                  ),
                  const Divider(height: 1),

                  // RRHH
                  _RoleSwitchTile(
                    title: AppRoles.rrhh,
                    subtitle: 'Permite dar de alta nuevos usuarios y gestionar credenciales.',
                    value: _currentRoles.contains(AppRoles.rrhh),
                    onChanged: (v) => _toggleRole(AppRoles.rrhh, v),
                  ),
                  const Divider(height: 1),

                  // Comercial
                  _RoleSwitchTile(
                    title: AppRoles.comercial,
                    subtitle: 'Acceso a métricas de eventos y reportes comerciales.',
                    value: _currentRoles.contains(AppRoles.comercial),
                    onChanged: (v) => _toggleRole(AppRoles.comercial, v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Botón Guardar
            ElevatedButton.icon(
              icon: const Icon(Icons.save_outlined),
              label: _isSaving
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text('GUARDAR CAMBIOS DE ROLES'),
              onPressed: _isSaving ? null : _save,
            ),
          ],
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
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppTheme.neonGreen,
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
      ),
    );
  }
}
