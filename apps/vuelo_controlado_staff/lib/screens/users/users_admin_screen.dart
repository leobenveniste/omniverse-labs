import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_background.dart';
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
    final primary = AppTheme.primaryColor(context);
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);
    final border = AppTheme.borderColor(context);

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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            style: AppTheme.headerIconButtonStyle(context),
            icon: const Icon(Icons.arrow_back_rounded, size: 20),
            tooltip: 'Volver',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        title: const AppHeaderTitle(title: 'Usuarios'),
        actions: [
          if (canCreate)
            Tooltip(
              message: 'Crear Usuario',
              child: FilledButton.icon(
                style: AppTheme.headerActionButtonStyle(context),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text('Nuevo'),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CreateUserScreen(),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      body: AppBackground(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${filteredUsers.length} miembros registrados',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Buscador
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Buscar por nombre, email o DNI...',
                            prefixIcon:
                                const Icon(Icons.search_rounded, size: 20),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded,
                                        size: 18),
                                    tooltip: 'Limpiar búsqueda',
                                    onPressed: () =>
                                        setState(() => _searchQuery = ''),
                                  )
                                : null,
                          ),
                          onChanged: (val) =>
                              setState(() => _searchQuery = val),
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
                                  showCheckmark: false,
                                  label: Text(role),
                                  selected: isSelected,
                                  selectedColor:
                                      primary.withValues(alpha: 0.18),
                                  side: BorderSide(
                                    color: isSelected ? primary : border,
                                  ),
                                  labelStyle: TextStyle(
                                    color: isSelected ? primary : textPrimary,
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                  onSelected: (val) {
                                    if (val) {
                                      HapticFeedback.selectionClick();
                                      setState(
                                          () => _selectedRoleFilter = role);
                                    }
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
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No se encontraron usuarios.',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final user = filteredUsers[index];
                          return _UserTile(
                            user: user,
                            isSuperAdminViewer: isSuperAdmin,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      UserDetailRolesScreen(userId: user.id),
                                ),
                              );
                            },
                          );
                        },
                        childCount: filteredUsers.length,
                      ),
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
    final primary = AppTheme.primaryColor(context);
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);
    final surface = AppTheme.surfaceContainer(context);
    final border = AppTheme.borderColor(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: surface,
          radius: 22,
          child: Text(
            user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '?',
            style: TextStyle(
              color: primary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.fullName,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: textPrimary,
                ),
              ),
            ),
            if (user.isSuperAdmin)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: primary.withValues(alpha: 0.4)),
                ),
                child: Text(
                  'SUPERADMIN',
                  style: TextStyle(
                    fontSize: 12,
                    color: primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${user.documentType}: ${user.documentNumber} • ${user.email}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: user.roles.map((r) {
                final isDefault = r == AppRoles.miembro;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDefault
                        ? surface
                        : primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDefault
                          ? border
                          : primary.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    r,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDefault ? textSecondary : primary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: textSecondary,
          size: 20,
        ),
      ),
    );
  }
}
