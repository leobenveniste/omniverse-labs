import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/circle_group_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/match_engine_service.dart';
import '../../services/online_firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/async_feedback_components.dart';
import '../../l10n/app_localizations.dart';

class GroupDetailsScreen extends StatefulWidget {
  final CircleGroupModel group;

  const GroupDetailsScreen({super.key, required this.group});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  late final TextEditingController _nameCtrl;
  late int _maxMembers;
  late bool _isOpenForExpansion;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.group.name);
    _maxMembers = widget.group.maxMembers;
    _isOpenForExpansion = widget.group.isOpenForExpansion;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final engine = context.read<MatchEngineService>();
    final firestore = context.read<OnlineFirestoreService>();

    await SavingOverlayHUD.run(
      context,
      message: 'Guardando configuración del Círculo...',
      successMessage: 'Círculo actualizado',
      task: () async {
        final updated = widget.group.copyWith(
          name: _nameCtrl.text.trim(),
          maxMembers: _maxMembers,
          isOpenForExpansion: _isOpenForExpansion,
        );
        await firestore.upsertGroup(updated);
        await engine.updateGroupExpansionSettings(
          widget.group.id,
          isOpen: _isOpenForExpansion,
          maxMembers: _maxMembers,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthService>();
    final firestore = context.watch<OnlineFirestoreService>();
    final engine = context.watch<MatchEngineService>();
    final currentUser = auth.currentUser;

    final group = firestore.currentGroups.firstWhere(
      (g) => g.id == widget.group.id,
      orElse: () => widget.group,
    );

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

    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);
    final primary = AppTheme.primaryColor(context);

    return AppScaffold(
      title: l10n.get('groupDetailsTitle'),
      actions: [
        IconButton(
          tooltip: 'Guardar cambios',
          style: AppTheme.headerIconButtonStyle(context),
          icon: const Icon(Icons.check_rounded),
          onPressed: _saveSettings,
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Nombre del Círculo
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre del Círculo',
                prefixIcon: Icon(Icons.groups_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 24),

            // SECCIÓN DE EXPANSIÓN HASTA 10 PERSONAS
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.cardColor(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.borderColor(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.group_add_rounded, color: primary, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.get('expandGroupTitle'),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Permite que el Círculo crezca recibiendo amigos compatibles mediante votación de los miembros.',
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                  const SizedBox(height: 16),

                  SwitchListTile(
                    title: Text(
                      l10n.get('allowExpansionToggle'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    value: _isOpenForExpansion,
                    activeThumbColor: primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      setState(() => _isOpenForExpansion = val);
                    },
                  ),

                  if (_isOpenForExpansion) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.get('maxMembersLabel'),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          '$_maxMembers personas',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: primary,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _maxMembers.toDouble(),
                      min: 4,
                      max: 10,
                      divisions: 6,
                      activeColor: primary,
                      onChanged: (v) {
                        setState(() => _maxMembers = v.round());
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // BANDEJA DE VOTACIÓN DE CANDIDATOS (Miembros 5 al 10)
            if (group.candidateVotes.isNotEmpty) ...[
              Text(
                l10n.get('candidateVotesTitle'),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...group.candidateVotes.entries.map((entry) {
                final candidateId = entry.key;
                final voters = entry.value;
                final candidate = firestore.currentUsers.firstWhere(
                  (u) => u.id == candidateId,
                  orElse: () => UserModel(
                    id: candidateId,
                    email: '',
                    passwordHash: '',
                    firstName: 'Postulante',
                    lastName: '',
                    birthDate: DateTime(1998, 1, 1),
                    duoInviteCode: '',
                    createdAt: DateTime.now(),
                  ),
                );

                final hasVoted = voters.contains(currentUser?.id);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: primary.withValues(alpha: 0.15),
                          child: Text(
                            candidate.firstName.isNotEmpty
                                ? candidate.firstName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${candidate.firstName}, ${candidate.age}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                              Text(
                                '${voters.length}/${group.memberIds.length} votos a favor',
                                style: TextStyle(
                                    fontSize: 12, color: textSecondary),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.get('voteAccept'),
                          icon: Icon(
                            hasVoted
                                ? Icons.thumb_up_alt_rounded
                                : Icons.thumb_up_alt_outlined,
                            color: AppTheme.emeraldMint,
                          ),
                          onPressed: () {
                            if (currentUser != null) {
                              engine.voteForExpansionCandidate(
                                groupId: group.id,
                                candidateUserId: candidate.id,
                                voterUserId: currentUser.id,
                                approve: !hasVoted,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],

            // LISTA DE INTEGRANTES (4 a 10)
            Text(
              l10n.format('groupMembersTitle', {'count': members.length}),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            ...members.map((member) {
              final isMe = member.id == currentUser?.id;
              final isContactUnlocked =
                  member.canViewContactInGroup(group.id) || isMe;
              final isInactive = group.inactiveMemberIds.contains(member.id);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: primary.withValues(alpha: 0.15),
                            child: Text(
                              member.firstName.isNotEmpty
                                  ? member.firstName[0].toUpperCase()
                                  : '?',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '${member.firstName} ${member.lastName}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700),
                                    ),
                                    if (isMe) ...[
                                      const SizedBox(width: 6),
                                      const Text('(Tú)',
                                          style: TextStyle(fontSize: 11)),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${GroupRoles.getIcon(member.groupRole)} ${l10n.translateGroupRole(member.groupRole)} • ${member.totalMeetupsCount} salidas',
                                  style: TextStyle(
                                      fontSize: 12, color: textSecondary),
                                ),
                              ],
                            ),
                          ),

                          // Botón Anti-Fantasmas si el miembro nunca interactuó
                          if (isInactive && !isMe) ...[
                            IconButton(
                              tooltip: l10n.get('releaseInactiveSeatBtn'),
                              icon: const Icon(Icons.person_remove_rounded,
                                  color: AppTheme.warmAmber, size: 20),
                              onPressed: () {
                                engine.releaseInactiveSeat(
                                  groupId: group.id,
                                  inactiveUserId: member.id,
                                );
                              },
                            ),
                          ],
                        ],
                      ),

                      // Contactos desbloqueados (Privacidad Progresiva)
                      if (isContactUnlocked &&
                          (member.instagram != null ||
                              member.phone.isNotEmpty)) ...[
                        const Divider(height: 20),
                        Row(
                          children: [
                            if (member.instagram != null &&
                                member.instagram!.isNotEmpty)
                              ActionChip(
                                avatar: const Icon(
                                    Icons.alternate_email_rounded,
                                    size: 14),
                                label: Text('@${member.instagram}'),
                                onPressed: () {
                                  launchUrl(Uri.parse(
                                      'https://instagram.com/${member.instagram}'));
                                },
                              ),
                            const SizedBox(width: 8),
                            if (member.phone.isNotEmpty)
                              ActionChip(
                                avatar: const Icon(Icons.chat_rounded,
                                    size: 14, color: AppTheme.emeraldMint),
                                label: const Text('WhatsApp'),
                                onPressed: () {
                                  launchUrl(Uri.parse(
                                      'https://wa.me/${member.phone.replaceAll(RegExp(r"[^\d]"), "")}'));
                                },
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),

            // Salir del Círculo
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.errorRed,
                side: const BorderSide(color: AppTheme.errorRed),
              ),
              icon: const Icon(Icons.exit_to_app_rounded),
              label: Text(l10n.get('leaveGroupBtn')),
              onPressed: () async {
                if (currentUser != null) {
                  final nav = Navigator.of(context);
                  final newMembers = List<String>.from(group.memberIds)
                    ..remove(currentUser.id);
                  await firestore
                      .upsertGroup(group.copyWith(memberIds: newMembers));
                  if (mounted) {
                    nav.pop();
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
