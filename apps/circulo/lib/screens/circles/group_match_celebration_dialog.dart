import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/circle_group_model.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/circle_avatar_ring.dart';
import '../../widgets/async_feedback_components.dart';
import '../../widgets/interest_tag_chip.dart';
import '../../l10n/app_localizations.dart';
import '../groups/group_chat_screen.dart';

class GroupMatchCelebrationDialog extends StatelessWidget {
  final CircleGroupModel group;

  const GroupMatchCelebrationDialog({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final secondary = AppTheme.secondaryColor(context);
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);

    // Muestra hasta 4 avatares
    final mockMembers = group.memberIds.map((id) {
      return UserModel(
        id: id,
        email: '',
        passwordHash: '',
        firstName: id.replaceAll('user_', '').replaceAll('admin_', ''),
        lastName: '',
        birthDate: DateTime(1998, 1, 1),
        duoInviteCode: '',
        createdAt: DateTime.now(),
      );
    }).toList();

    return Dialog(
      backgroundColor: AppTheme.cardColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: secondary, width: 2),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icono festivo con brillo
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: secondary.withValues(alpha: 0.16),
              ),
              child: Icon(Icons.celebration_rounded, size: 36, color: secondary),
            ),
            const SizedBox(height: 16),

            Text(
              l10n.get('celebrationTitle'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              l10n.get('celebrationSubtitle'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Anillo con los 4 integrantes
            CircleProgressAvatarRing(
              members: mockMembers,
              targetSize: 4,
              avatarRadius: 28,
            ),
            const SizedBox(height: 20),

            // Nombre asignado al Círculo
            Text(
              group.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Gustos que comparten
            if (group.sharedInterests.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: group.sharedInterests.map((interest) {
                  return InterestTagChip(
                    label: l10n.translateInterest(interest),
                    isShared: true,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],

            // Botón Entrar al Chat
            LoadingPrimaryButton(
              label: l10n.get('openGroupChatBtn'),
              accentColor: secondary,
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => GroupChatScreen(group: group),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),

            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l10n.get('keepExploringBtn'),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
