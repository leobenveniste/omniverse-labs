import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/circle_group_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/match_engine_service.dart';
import '../../services/online_firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/async_feedback_components.dart';
import '../../l10n/app_localizations.dart';
import 'group_details_screen.dart';
import 'icebreaker_poll_sheet.dart';
import 'create_group_plan_sheet.dart';

class GroupChatScreen extends StatefulWidget {
  final CircleGroupModel group;

  const GroupChatScreen({super.key, required this.group});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final _msgCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    final user = context.read<AuthService>().currentUser;
    if (user == null) return;

    final firestore = context.read<OnlineFirestoreService>();
    _msgCtrl.clear();

    final msg = GroupMessageModel(
      id: const Uuid().v4(),
      groupId: widget.group.id,
      senderId: user.id,
      senderName: user.firstName,
      type: 'text',
      text: text,
      timestamp: DateTime.now(),
    );

    // Asegurar que el usuario quede como miembro activo (Anti-Fantasmas)
    final group = await firestore.getGroupById(widget.group.id);
    if (group != null) {
      final active = List<String>.from(group.activeConfirmedMemberIds);
      if (!active.contains(user.id)) {
        active.add(user.id);
        await firestore
            .upsertGroup(group.copyWith(activeConfirmedMemberIds: active));
      }
    }

    await firestore.sendMessage(msg);

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthService>();
    final firestore = context.watch<OnlineFirestoreService>();
    final engine = context.watch<MatchEngineService>();
    final user = auth.currentUser;

    final currentGroup = firestore.currentGroups.firstWhere(
      (g) => g.id == widget.group.id,
      orElse: () => widget.group,
    );

    final isContactShared = user?.canViewContactInGroup(currentGroup.id) ?? false;
    final plans = firestore.getPlansForGroup(currentGroup.id);

    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);
    final primary = AppTheme.primaryColor(context);

    return AppScaffold(
      showHelpButton: false,
      title: currentGroup.name,
      subtitle: '${currentGroup.memberIds.length}/${currentGroup.maxMembers} amigos',
      actions: [
        IconButton(
          tooltip: 'Detalle del Círculo',
          style: AppTheme.headerIconButtonStyle(context),
          icon: const Icon(Icons.info_outline_rounded, size: 22),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => GroupDetailsScreen(group: currentGroup),
              ),
            );
          },
        ),
      ],
      body: Column(
        children: [
          // BARRA SUPERIOR: Privacidad Progresiva
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isContactShared
                ? AppTheme.emeraldMint.withValues(alpha: 0.12)
                : AppTheme.surfaceContainer(context),
            child: Row(
              children: [
                Icon(
                  isContactShared
                      ? Icons.lock_open_rounded
                      : Icons.lock_outline_rounded,
                  size: 18,
                  color: isContactShared ? AppTheme.emeraldMint : primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isContactShared
                      ? l10n.get('contactSharedBadge')
                      : l10n.get('shareContactBtn'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isContactShared
                          ? AppTheme.emeraldMint
                          : textPrimary,
                    ),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: primary,
                  ),
                  onPressed: () {
                    auth.toggleShareContactWithGroup(currentGroup.id);
                  },
                  child: Text(isContactShared ? 'Ocultar' : 'Compartir'),
                ),
              ],
            ),
          ),

          // BANNER ANTI-GRUPOS FANTASMA
          if (currentGroup.inactiveMemberIds.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: AppTheme.warmAmber.withValues(alpha: 0.15),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_outlined,
                      size: 16, color: AppTheme.warmAmber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.format('antiGhostBanner', {
                        'active': currentGroup.activeConfirmedMemberIds.length,
                        'total': currentGroup.memberIds.length,
                      }),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // LISTA DE MENSAJES STREAM EN VIVO
          Expanded(
            child: StreamBuilder<List<GroupMessageModel>>(
              stream: firestore.getMessagesStream(currentGroup.id),
              builder: (context, snapshot) {
                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.forum_outlined,
                              size: 48,
                              color: primary.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          Text(
                            '¡El grupo está listo!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Mandá un mensaje o tirá un rompehielos para romper el silencio.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == user?.id;
                    final isSystem = msg.senderId == 'system';

                    if (isSystem) {
                      return _buildSystemMessage(msg);
                    }

                    if (msg.type == 'plan') {
                      final plan = plans.firstWhere(
                        (p) => p.id == msg.payload['id'],
                        orElse: () => GroupPlanModel.fromJson(msg.payload),
                      );
                      return _buildPlanCard(context, plan, user, engine, l10n);
                    }

                    if (msg.type == 'poll') {
                      return _buildPollCard(context, msg, user, l10n);
                    }

                    return _buildBubbleMessage(context, msg, isMe);
                  },
                );
              },
            ),
          ),

          // BARRA INFERIOR DE ENTRADA DE MENSAJE
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.cardColor(context),
              border: Border(top: BorderSide(color: AppTheme.borderColor(context))),
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Rompehielos o Encuesta',
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  color: primary,
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => IcebreakerPollSheet(group: currentGroup),
                    );
                  },
                ),
                IconButton(
                  tooltip: l10n.get('createPlanBtn'),
                  icon: const Icon(Icons.event_available_rounded),
                  color: AppTheme.secondaryColor(context),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => CreateGroupPlanSheet(group: currentGroup),
                    );
                  },
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: l10n.get('messageHint'),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: l10n.get('sendBtn'),
                  style: IconButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: AppTheme.onPrimaryColor(context),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 18),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemMessage(GroupMessageModel msg) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.tertiaryColor(context).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.tertiaryColor(context).withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        msg.text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildBubbleMessage(
      BuildContext context, GroupMessageModel msg, bool isMe) {
    final primary = AppTheme.primaryColor(context);
    final onPrimary = AppTheme.onPrimaryColor(context);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.76,
        ),
        decoration: BoxDecoration(
          color: isMe ? primary : AppTheme.surfaceContainer(context),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                msg.senderName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: primary,
                ),
              ),
            Text(
              msg.text,
              style: TextStyle(
                fontSize: 14,
                color: isMe ? onPrimary : AppTheme.textPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('HH:mm').format(msg.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: isMe
                    ? onPrimary.withValues(alpha: 0.7)
                    : AppTheme.textMutedColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context,
    GroupPlanModel plan,
    UserModel? currentUser,
    MatchEngineService engine,
    AppLocalizations l10n,
  ) {
    final isCheckedIn = currentUser != null && plan.isUserCheckedIn(currentUser.id);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppTheme.secondaryColor(context), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event_available_rounded,
                    color: AppTheme.secondaryColor(context), size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.get('planTitle'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.secondaryColor(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              plan.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              '${DateFormat('EEE d MMM • HH:mm', l10n.langCode).format(plan.scheduledAt)}${plan.locationName.isNotEmpty ? " • ${plan.locationName}" : ""}',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor(context),
              ),
            ),
            const SizedBox(height: 12),

            // Botón de Check-in de Salida Real
            if (currentUser != null)
              LoadingPrimaryButton(
                height: 44,
                label: isCheckedIn
                    ? l10n.get('checkedInBadge')
                    : l10n.get('checkInMeetupBtn'),
                accentColor: isCheckedIn
                    ? AppTheme.emeraldMint
                    : AppTheme.tertiaryColor(context),
                onPressed: isCheckedIn
                    ? null
                    : () {
                        engine.confirmMeetupCheckIn(
                          groupId: widget.group.id,
                          planId: plan.id,
                          currentUser: currentUser,
                        );
                      },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPollCard(
    BuildContext context,
    GroupMessageModel msg,
    UserModel? currentUser,
    AppLocalizations l10n,
  ) {
    final question = msg.payload['question'] ?? msg.text;
    final options = List<String>.from(msg.payload['options'] ?? []);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📊 $question',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            ...options.map((opt) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainer(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(opt, style: const TextStyle(fontSize: 13)),
                    const Icon(Icons.how_to_vote_outlined, size: 18),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
