import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/online_firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/circle_avatar_ring.dart';
import '../../l10n/app_localizations.dart';
import 'group_chat_screen.dart';

class MyGroupsScreen extends StatelessWidget {
  const MyGroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthService>();
    final firestore = context.watch<OnlineFirestoreService>();
    final user = auth.currentUser;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Filtrar Círculos activos donde participa el usuario
    final activeGroups = firestore.currentGroups
        .where((g) => g.isActiveGroup && g.memberIds.contains(user.id))
        .toList();

    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);
    final primary = AppTheme.primaryColor(context);

    return AppScaffold(
      title: l10n.get('navMyCircles'),
      subtitle: '${activeGroups.length} círculos activos',
      body: activeGroups.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.group_work_outlined,
                        size: 56, color: primary.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text(
                      'Aún no tenés grupos activos',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cuando hagas match con al menos 4 personas afines, tu Círculo aparecerá acá.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: textSecondary),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: activeGroups.length,
              itemBuilder: (context, index) {
                final group = activeGroups[index];
                final members = group.memberIds.map((mId) {
                  return firestore.currentUsers.firstWhere(
                    (u) => u.id == mId,
                    orElse: () => UserModel(
                      id: mId,
                      email: '',
                      passwordHash: '',
                      firstName: 'Amigo',
                      lastName: '',
                      birthDate: DateTime(1998, 1, 1),
                      duoInviteCode: '',
                      createdAt: DateTime.now(),
                    ),
                  );
                }).toList();

                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => GroupChatScreen(group: group),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: primary.withValues(alpha: 0.15),
                                child: Text(
                                  '${group.memberIds.length}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      group.name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${group.region} • ${group.memberIds.length}/${group.maxMembers} personas',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: CircleProgressAvatarRing(
                              members: members,
                              targetSize: group.maxMembers,
                              avatarRadius: 18,
                            ),
                          ),
                          if (group.lastMessagePreview.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceContainer(context),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.chat_bubble_outline_rounded,
                                      size: 14, color: textSecondary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      group.lastMessagePreview,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
