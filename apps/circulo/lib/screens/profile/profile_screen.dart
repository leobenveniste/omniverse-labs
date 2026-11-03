import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/interest_tag_chip.dart';
import '../../l10n/app_localizations.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import '../discover/duo_mode_sheet.dart';
import '../shop/shop_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final primary = AppTheme.primaryColor(context);
    final secondary = AppTheme.secondaryColor(context);
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);

    return AppScaffold(
      title: l10n.get('navProfile'),
      actions: [
        IconButton(
          tooltip: l10n.get('settingsTitle'),
          style: AppTheme.headerIconButtonStyle(context),
          icon: const Icon(Icons.settings_outlined, size: 22),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // TARJETA DE VISTA PREVIA DEL PERFIL
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primary.withValues(alpha: 0.15),
                            border: Border.all(color: primary, width: 2.5),
                          ),
                          child: ClipOval(
                            child: user.photoUrl != null &&
                                    user.photoUrl!.isNotEmpty
                                ? Image.network(
                                    user.photoUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Center(
                                      child: Text(
                                        user.firstName.isNotEmpty
                                            ? user.firstName[0].toUpperCase()
                                            : 'C',
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      user.firstName.isNotEmpty
                                          ? user.firstName[0].toUpperCase()
                                          : 'C',
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.cardColor(context),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppTheme.borderColor(context)),
                            ),
                            child: Text(
                              GroupRoles.getIcon(user.groupRole),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Nombre y Edad
                    Text(
                      '${user.fullName}, ${user.age}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${user.neighborhood.isNotEmpty ? "${user.neighborhood}, " : ""}${user.region}',
                      style: TextStyle(fontSize: 13, color: textSecondary),
                    ),
                    const SizedBox(height: 16),

                    // Métricas / Insignias
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Insignia Rol
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.tertiaryColor(context),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${GroupRoles.getIcon(user.groupRole)} ${l10n.translateGroupRole(user.groupRole)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Insignia Asistencias Reales
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.emeraldMint,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified_rounded,
                                  size: 14, color: Colors.white),
                              const SizedBox(width: 6),
                              Text(
                                l10n.format('attendedMeetupsCount',
                                    {'count': user.totalMeetupsCount}),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (user.bio.isNotEmpty) ...[
                      Text(
                        user.bio,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    OutlinedButton.icon(
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: Text(l10n.get('editProfileBtn')),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const EditProfileScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // CARD CÍRCULO PLUS & TIENDA
            Card(
              elevation: user.isPlusMember ? 2 : 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: user.isPlusMember
                      ? const Color(0xFFF59E0B)
                      : Colors.transparent,
                  width: user.isPlusMember ? 2 : 0,
                ),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('⭐', style: TextStyle(fontSize: 18)),
                ),
                title: Row(
                  children: [
                    Text(
                      l10n.get('plusTitle'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (user.isPlusMember) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'ACTIVO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: Text(
                  user.isPlusMember
                      ? '⚡ Boosts: ${user.remainingBoosts} • 🌊 Super-Ondas: ${user.remainingSuperOndas}'
                      : 'Swipes ilimitados, quién te dio like y 1 Boost semanal.',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ShopScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // BANNER MODO DUPLA
            Card(
              child: ListTile(
                leading: Icon(Icons.people_rounded, color: secondary),
                title: Text(
                  l10n.get('duoModeTitle'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  user.hasDuoPartner
                      ? 'Activo con partner'
                      : 'Buscá amigos de a 2 para llegar a 4 el doble de rápido',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const DuoModeSheet(),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // INTERESES PROPIOS
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tus Intereses',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: user.interests.map((i) {
                        return InterestTagChip(
                          label: l10n.translateInterest(i),
                          isShared: true,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
