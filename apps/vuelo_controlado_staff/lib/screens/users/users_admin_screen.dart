import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'create_user_screen.dart';
import 'user_detail_roles_screen.dart';

class UsersAdminScreen extends StatefulWidget {
  const UsersAdminScreen({super.key});

  @override
  State<UsersAdminScreen> createState() => _UsersAdminScreenState();
}

class _UsersAdminScreenState extends State<UsersAdminScreen> {
  String _searchQuery = '';
  String _selectedRoleFilter = 'Todos';

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final currentUser = authService.currentUser;
    final allUsers = authService.users;

    final isSuperAdmin = currentUser?.isSuperAdmin ?? false;
    final canCreate = currentUser?.canCreateUsers ?? false;

    final filteredUsers = allUsers.where((u) {
      final query = _searchQuery.toLowerCase();
      final matchesQuery = u.fullName.toLowerCase().contains(query) ||
          u.email.toLowerCase().contains(query) ||
          u.documentNumber.contains(query);

      final matchesRole = _selectedRoleFilter == 'Todos' ||
          u.roles.contains(_selectedRoleFilter);

      return matchesQuery && matchesRole;
    }).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Equipo y Staff',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            'Padrón de miembros y asignación de roles',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      if (canCreate)
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.neonGreen,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                          ),
                          icon: const Icon(Icons.person_add, size: 18),
                          label: const Text(
                            'Crear Usuario',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const CreateUserScreen(),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Buscador
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre, email o DNI...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () =>
                                  setState(() => _searchQuery = ''),
                            )
                          : null,
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                  const SizedBox(height: 12),

                  // Filtro por roles
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        'Todos',
                        ...AppRoles.allRoles,
                      ].map((role) {
                        final isSelected = _selectedRoleFilter == role;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(role),
                            selected: isSelected,
                            selectedColor:
                                AppTheme.neonGreen.withValues(alpha: 0.2),
                            side: BorderSide(
                              color: isSelected
                                  ? AppTheme.neonGreen
                                  : AppTheme.darkBorder,
                            ),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? AppTheme.neonGreen
                                  : AppTheme.textPrimary,
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            onSelected: (val) {
                              if (val) setState(() => _selectedRoleFilter = role);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (filteredUsers.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text(
                  'No se encontraron usuarios.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final user = filteredUsers[index];
                    return _UserTile(
                      user: user,
                      isSuperAdminViewer: isSuperAdmin,
                      onTap: () {
                        if (isSuperAdmin) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  UserDetailRolesScreen(userId: user.id),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Solo el Superadmin puede modificar los roles de un usuario.'),
                              backgroundColor: AppTheme.warningOrange,
                            ),
                          );
                        }
                      },
                    );
                  },
                  childCount: filteredUsers.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserModel user;
  final bool isSuperAdminViewer;
  final VoidCallback onTap;

  const _UserTile({
    required this.user,
    required this.isSuperAdminViewer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppTheme.darkCard,
          radius: 24,
          child: Text(
            user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '?',
            style: const TextStyle(
              color: AppTheme.neonGreen,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.fullName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            if (user.isSuperAdmin)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.neonGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'SUPERADMIN',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.neonGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              '${user.documentType}: ${user.documentNumber} • ${user.email}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: user.roles.map((r) {
                final isDefault = r == AppRoles.miembro;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDefault
                        ? AppTheme.darkBorder
                        : AppTheme.neonGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isDefault
                          ? AppTheme.darkBorder
                          : AppTheme.neonGreen.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Text(
                    r,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDefault
                          ? AppTheme.textSecondary
                          : AppTheme.neonGreen,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        trailing: isSuperAdminViewer
            ? const Icon(Icons.tune, color: AppTheme.neonGreen, size: 20)
            : null,
      ),
    );
  }
}
