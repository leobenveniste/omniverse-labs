import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/circle_group_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/online_firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/circle_avatar_ring.dart';
import '../../widgets/interest_tag_chip.dart';
import '../../l10n/app_localizations.dart';

class FormingCirclesScreen extends StatelessWidget {
  const FormingCirclesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthService>();
    final firestore = context.watch<OnlineFirestoreService>();
    final user = auth.currentUser;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Filtrar círculos en formación (2/4 o 3/4) donde participa el usuario
    final formingCircles = firestore.currentGroups
        .where((g) => g.isForming && g.memberIds.contains(user.id))
        .toList();

    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);
    final secondary = AppTheme.secondaryColor(context);

    return AppScaffold(
      title: l10n.get('navForming'),
      subtitle: l10n.get('formingCirclesSubtitle'),
      body: formingCircles.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.hourglass_empty_rounded,
                        size: 56, color: secondary.withValues(alpha: 0.6)),
                    const SizedBox(height: 16),
                    Text(
                      'No tenés círculos en formación aún',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Deslizá perfiles en Descubrir o sumate a pre-grupos para ver el progreso acá.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: textSecondary),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: formingCircles.length,
              itemBuilder: (context, index) {
                final group = formingCircles[index];
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

                final isAlmostFull = group.memberIds.length == 3;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isAlmostFull
                                    ? secondary.withValues(alpha: 0.16)
                                    : AppTheme.surfaceContainer(context),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isAlmostFull
                                      ? secondary
                                      : AppTheme.borderColor(context),
                                ),
                              ),
                              child: Text(
                                isAlmostFull
                                    ? l10n.get('almostFullBadge')
                                    : '${group.memberIds.length}/4 integrantes',
                                style: TextStyle(
                                  color: isAlmostFull
                                      ? secondary
                                      : textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_horiz_rounded),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              onSelected: (val) {
                                if (val == 'leave') {
                                  _leaveGroup(context, group, user);
                                }
                              },
                              itemBuilder: (ctx) => [
                                PopupMenuItem(
                                  value: 'leave',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.exit_to_app_rounded,
                                          color: AppTheme.errorRed, size: 18),
                                      const SizedBox(width: 8),
                                      Text(l10n.get('leaveFormingCircleBtn')),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Text(
                          group.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          group.region,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),

                        Center(
                          child: CircleProgressAvatarRing(
                            members: members,
                            targetSize: 4,
                            avatarRadius: 24,
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (group.sharedInterests.isNotEmpty) ...[
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: group.sharedInterests.map((interest) {
                              return InterestTagChip(
                                label: l10n.translateInterest(interest),
                                isShared: true,
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _leaveGroup(
      BuildContext context, CircleGroupModel group, UserModel user) async {
    final firestore = context.read<OnlineFirestoreService>();
    final newMembers = List<String>.from(group.memberIds)..remove(user.id);
    final updated = group.copyWith(memberIds: newMembers);
    await firestore.upsertGroup(updated);
    HapticFeedback.lightImpact();
  }
}
