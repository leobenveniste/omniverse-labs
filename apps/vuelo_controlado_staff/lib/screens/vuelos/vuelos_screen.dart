import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/event_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_background.dart';
import '../../widgets/whatsapp_icon.dart';
import '../users/create_user_screen.dart';
import '../users/user_detail_roles_screen.dart';

class VuelosScreen extends StatefulWidget {
  const VuelosScreen({super.key});

  @override
  State<VuelosScreen> createState() => _VuelosScreenState();
}

class _VuelosScreenState extends State<VuelosScreen> {
  String _searchQuery = '';
  String _selectedRoleFilter = 'Todos';
  String _selectedRegionFilter = AppRegions.allRegions;

  Future<void> _launchWhatsApp(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$cleanPhone');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  void _showMemberInfoSheet(BuildContext context, UserModel user, int attendanceCount) {
    final theme = Theme.of(context);
    final primary = AppTheme.primaryColor(context);
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);
    final surface = AppTheme.surfaceContainer(context);

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

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
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
                const SizedBox(height: 20),
                CircleAvatar(
                  radius: 36,
                  backgroundColor: surface,
                  backgroundImage: avatarImage,
                  child: avatarImage == null
                      ? Text(
                          user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '?',
                          style: TextStyle(fontSize: 26, color: primary, fontWeight: FontWeight.w700),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  user.fullName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  alignment: WrapAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: primary.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        user.region,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: primary),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$attendanceCount asistencias a eventos',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: user.roles.map((role) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: role == AppRoles.miembro
                            ? theme.colorScheme.surfaceContainerHighest
                            : primary.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: role == AppRoles.miembro
                              ? AppTheme.borderColor(ctx)
                              : primary.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        role.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: role == AppRoles.miembro ? textSecondary : primary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (user.phone.trim().isNotEmpty) ...[
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const WhatsAppIcon(size: 20),
                    label: const Text('Contactar por WhatsApp', style: TextStyle(fontWeight: FontWeight.w700)),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _launchWhatsApp(user.phone);
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final eventService = context.watch<EventService>();
    final currentUser = authService.currentUser;
    final allUsers = authService.users;
    final allEvents = eventService.events;
    final theme = Theme.of(context);
    final primary = AppTheme.primaryColor(context);
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);
    final border = AppTheme.borderColor(context);

    // Regla de visibilidad:
    // Los miembros sin roles específicos solo ven a los usuarios que tienen roles específicos.
    // Los usuarios con roles específicos (o superadmin) pueden ver toda la lista de usuarios.
    final bool hasSpecificRole = currentUser != null &&
        (currentUser.isSuperAdmin ||
            currentUser.roles.any((r) => r != AppRoles.miembro));

    final canManageTeam = currentUser != null &&
        (currentUser.isSuperAdmin ||
            currentUser.hasRole(AppRoles.rrhh) ||
            currentUser.hasRole(AppRoles.organizacion));

    final visibleUsers = allUsers.where((u) {
      if (hasSpecificRole) return true;
      // Miembro raso: solo ve usuarios con roles específicos asignados o superadmin
      return u.isSuperAdmin || u.roles.any((r) => r != AppRoles.miembro);
    }).toList();

    // Filtros de búsqueda, región y rol
    final filteredUsers = visibleUsers.where((u) {
      final query = _searchQuery.trim().toLowerCase();
      final matchesQuery = query.isEmpty ||
          u.fullName.toLowerCase().contains(query) ||
          u.email.toLowerCase().contains(query) ||
          u.roles.any((r) => r.toLowerCase().contains(query));

      final matchesRegion = _selectedRegionFilter == AppRegions.allRegions ||
          u.region == _selectedRegionFilter;

      final matchesRole = _selectedRoleFilter == 'Todos' ||
          u.roles.contains(_selectedRoleFilter);

      return matchesQuery && matchesRegion && matchesRole;
    }).toList();

    // Orden alfabético estricto por nombre completo
    filteredUsers.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const AppHeaderTitle(title: 'Vuelos'),
        actions: [
          if (canManageTeam)
            Tooltip(
              message: 'Crear Nuevo Miembro',
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
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Campo de búsqueda
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Buscar miembro por nombre, rol o email...',
                            prefixIcon: const Icon(Icons.search_rounded, size: 20),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    tooltip: 'Limpiar búsqueda',
                                    onPressed: () => setState(() => _searchQuery = ''),
                                  )
                                : null,
                          ),
                          onChanged: (val) => setState(() => _searchQuery = val),
                        ),
                        const SizedBox(height: 12),

                        // Filtros de Región y Rol en fila scrolleable
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              // Dropdown de Región
                              Container(
                                height: 38,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: primary.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedRegionFilter,
                                    icon: Icon(Icons.arrow_drop_down_rounded, color: primary),
                                    dropdownColor: theme.cardColor,
                                    borderRadius: BorderRadius.circular(16),
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    items: [
                                      const DropdownMenuItem(
                                        value: AppRegions.allRegions,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.public, size: 15),
                                            SizedBox(width: 6),
                                            Text(AppRegions.allRegions),
                                          ],
                                        ),
                                      ),
                                      ...AppRegions.all.map((r) => DropdownMenuItem(
                                            value: r,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.place_outlined, size: 15),
                                                SizedBox(width: 6),
                                                Text(r),
                                              ],
                                            ),
                                          )),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        HapticFeedback.selectionClick();
                                        setState(() => _selectedRegionFilter = val);
                                      }
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Filtros rápidos por Rol
                              ...['Todos', ...AppRoles.allRoles].map((role) {
                                final isSelected = _selectedRoleFilter == role;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    showCheckmark: false,
                                    label: Text(role),
                                    selected: isSelected,
                                    selectedColor: primary.withValues(alpha: 0.18),
                                    side: BorderSide(
                                      color: isSelected ? primary : border,
                                    ),
                                    labelStyle: TextStyle(
                                      color: isSelected ? primary : textPrimary,
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    ),
                                    onSelected: (val) {
                                      if (val) {
                                        HapticFeedback.selectionClick();
                                        setState(() => _selectedRoleFilter = role);
                                      }
                                    },
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${filteredUsers.length} miembros encontrados',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: textSecondary,
                              ),
                            ),
                            if (!hasSpecificRole)
                              Text(
                                'Mostrando roles de coordinación y staff',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: textSecondary.withValues(alpha: 0.8),
                                ),
                              ),
                          ],
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline_rounded,
                              size: 56,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No se encontraron miembros con los filtros seleccionados.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(16, 4, 16, MediaQuery.paddingOf(context).bottom + 96),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final user = filteredUsers[index];
                          final attendanceCount = user.getAttendanceCount(allEvents);

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

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Card(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  if (canManageTeam) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => UserDetailRolesScreen(userId: user.id),
                                      ),
                                    );
                                  } else {
                                    _showMemberInfoSheet(context, user, attendanceCount);
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: AppTheme.surfaceContainer(context),
                                        radius: 22,
                                        backgroundImage: avatarImage,
                                        child: avatarImage == null
                                            ? Text(
                                                user.firstName.isNotEmpty
                                                    ? user.firstName[0].toUpperCase()
                                                    : '?',
                                                style: TextStyle(
                                                  color: primary,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              )
                                            : null,
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
                                                    user.fullName,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 15,
                                                      color: textPrimary,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (user.isSuperAdmin) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: primary.withValues(alpha: 0.16),
                                                      borderRadius: BorderRadius.circular(6),
                                                      border: Border.all(color: primary.withValues(alpha: 0.4)),
                                                    ),
                                                    child: Text(
                                                      'ADMIN',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: primary,
                                                        fontWeight: FontWeight.w900,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Wrap(
                                              spacing: 6,
                                              runSpacing: 4,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: primary.withValues(alpha: 0.12),
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(color: primary.withValues(alpha: 0.25)),
                                                  ),
                                                  child: Text(
                                                    user.region,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w700,
                                                      color: primary,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: theme.colorScheme.surfaceContainerHighest,
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    '$attendanceCount asist.',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: textSecondary,
                                                    ),
                                                  ),
                                                ),
                                                ...user.roles
                                                    .where((r) => r != AppRoles.miembro)
                                                    .map((r) => Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: AppTheme.skyBlue.withValues(alpha: 0.12),
                                                            borderRadius: BorderRadius.circular(6),
                                                            border: Border.all(color: AppTheme.skyBlue.withValues(alpha: 0.25)),
                                                          ),
                                                          child: Text(
                                                            r,
                                                            style: const TextStyle(
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.w700,
                                                              color: AppTheme.skyBlue,
                                                            ),
                                                          ),
                                                        )),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (user.phone.trim().isNotEmpty)
                                        Tooltip(
                                          message: 'Enviar WhatsApp',
                                          child: IconButton(
                                            icon: const WhatsAppIcon(size: 18),
                                            visualDensity: VisualDensity.compact,
                                            onPressed: () {
                                              HapticFeedback.lightImpact();
                                              _launchWhatsApp(user.phone);
                                            },
                                          ),
                                        ),
                                      if (canManageTeam)
                                        Icon(
                                          Icons.chevron_right_rounded,
                                          color: textSecondary.withValues(alpha: 0.6),
                                          size: 20,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
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
