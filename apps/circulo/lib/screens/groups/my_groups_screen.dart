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
import '../../l10n/app_localizations.dart';
import 'group_chat_screen.dart';

enum GroupsViewTab {
  activeCircles,
  applications,
}

class MyGroupsScreen extends StatefulWidget {
  const MyGroupsScreen({super.key});

  @override
  State<MyGroupsScreen> createState() => _MyGroupsScreenState();
}

class _MyGroupsScreenState extends State<MyGroupsScreen> {
  GroupsViewTab _currentTab = GroupsViewTab.activeCircles;

  Future<void> _handleCancelApplication(
    BuildContext context,
    CircleGroupModel group,
    String userId,
  ) async {
    final l10n = AppLocalizations.of(context);
    final firestore = context.read<OnlineFirestoreService>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.get('cancelApplication'),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          '${l10n.get('cancelApplicationConfirm')}\n\n"${group.name}"',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.get('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.get('confirm')),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      HapticFeedback.mediumImpact();
      final success = await firestore.cancelApplication(
        groupId: group.id,
        userId: userId,
      );

      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(
            content: Text(l10n.get('applicationCanceledSuccess')),
            backgroundColor: AppTheme.darkSurface,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthService>();
    final firestore = context.watch<OnlineFirestoreService>();
    final user = auth.currentUser;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Círculos activos donde el usuario ya es miembro completo
    final activeGroups = firestore.currentGroups
        .where((g) => g.isActiveGroup && g.memberIds.contains(user.id))
        .toList();

    // Postulaciones activas a Círculos en expansión o formación
    final appliedGroups = firestore.currentGroups.where((g) {
      if (g.memberIds.contains(user.id)) return false;
      final isCandidate = g.candidateVotes.containsKey(user.id);
      final hasLikedSwipe = firestore.currentSwipes.any((s) =>
          s.fromUserId == user.id &&
          s.targetId == g.id &&
          (s.action == 'like' || s.action == 'superlike'));
      return isCandidate || hasLikedSwipe;
    }).toList();

    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);
    final primary = AppTheme.primaryColor(context);

    final subtitle = _currentTab == GroupsViewTab.activeCircles
        ? '${activeGroups.length} círculos activos'
        : '${appliedGroups.length} postulaciones';

    return AppScaffold(
      title: l10n.get('navMyCircles'),
      subtitle: subtitle,
      body: Column(
        children: [
          // Segmented Tab Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<GroupsViewTab>(
              segments: [
                ButtonSegment(
                  value: GroupsViewTab.activeCircles,
                  label: Text(l10n.get('tabMyCircles')),
                  icon: const Icon(Icons.group_work_rounded, size: 16),
                ),
                ButtonSegment(
                  value: GroupsViewTab.applications,
                  label: Text(
                    appliedGroups.isNotEmpty
                        ? '${l10n.get('tabApplications')} (${appliedGroups.length})'
                        : l10n.get('tabApplications'),
                  ),
                  icon: const Icon(Icons.assignment_ind_outlined, size: 16),
                ),
              ],
              selected: {_currentTab},
              onSelectionChanged: (val) {
                HapticFeedback.selectionClick();
                setState(() => _currentTab = val.first);
              },
            ),
          ),

          // Contenido según pestaña
          Expanded(
            child: _currentTab == GroupsViewTab.activeCircles
                ? _buildActiveCirclesTab(
                    context: context,
                    activeGroups: activeGroups,
                    firestore: firestore,
                    l10n: l10n,
                    primary: primary,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  )
                : _buildApplicationsTab(
                    context: context,
                    appliedGroups: appliedGroups,
                    firestore: firestore,
                    userId: user.id,
                    l10n: l10n,
                    primary: primary,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCirclesTab({
    required BuildContext context,
    required List<CircleGroupModel> activeGroups,
    required OnlineFirestoreService firestore,
    required AppLocalizations l10n,
    required Color primary,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    if (activeGroups.isEmpty) {
      return Center(
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
      );
    }

    return ListView.builder(
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
    );
  }

  Widget _buildApplicationsTab({
    required BuildContext context,
    required List<CircleGroupModel> appliedGroups,
    required OnlineFirestoreService firestore,
    required String userId,
    required AppLocalizations l10n,
    required Color primary,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    if (appliedGroups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.assignment_turned_in_outlined,
                  size: 56, color: primary.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(
                l10n.get('noApplicationsTitle'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.get('noApplicationsSubtitle'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: appliedGroups.length,
      itemBuilder: (context, index) {
        final group = appliedGroups[index];
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        l10n.get('statusEvaluating'),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ),
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
                const SizedBox(height: 16),
                // Botón Cancelar Postulación
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorRed,
                      side: BorderSide(
                        color: AppTheme.errorRed.withValues(alpha: 0.4),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: Text(
                      l10n.get('cancelApplication'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    onPressed: () => _handleCancelApplication(
                      context,
                      group,
                      userId,
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
}
