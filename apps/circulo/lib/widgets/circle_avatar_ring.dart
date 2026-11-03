import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';

class CircleProgressAvatarRing extends StatelessWidget {
  final List<UserModel> members;
  final int targetSize; // 4 a 10
  final double avatarRadius;
  final bool showRoleBadge;
  final ValueChanged<UserModel>? onMemberTap;

  const CircleProgressAvatarRing({
    super.key,
    required this.members,
    this.targetSize = 4,
    this.avatarRadius = 22,
    this.showRoleBadge = true,
    this.onMemberTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primaryColor(context);
    final secondary = AppTheme.secondaryColor(context);
    final borderColor = AppTheme.borderColor(context);
    final textMuted = AppTheme.textMutedColor(context);

    final totalSlots = targetSize.clamp(4, 10);
    final isAlmostFull = (totalSlots - members.length) == 1;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: List.generate(totalSlots, (index) {
        if (index < members.length) {
          final member = members[index];
          return GestureDetector(
            onTap: onMemberTap != null ? () => onMemberTap!(member) : null,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: avatarRadius * 2,
                  height: avatarRadius * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primary,
                      width: 2,
                    ),
                    color: primary.withValues(alpha: 0.15),
                  ),
                  child: ClipOval(
                    child: member.photoUrl != null &&
                            member.photoUrl!.isNotEmpty
                        ? Image.network(
                            member.photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _buildInitials(member),
                          )
                        : _buildInitials(member),
                  ),
                ),
                if (showRoleBadge)
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor(context),
                        shape: BoxShape.circle,
                        border: Border.all(color: borderColor, width: 1),
                      ),
                      child: Text(
                        GroupRoles.getIcon(member.groupRole),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
              ],
            ),
          );
        } else {
          // Asiento libre
          final isNextSeat = index == members.length;
          return Container(
            width: avatarRadius * 2,
            height: avatarRadius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isNextSeat && isAlmostFull
                  ? secondary.withValues(alpha: 0.12)
                  : Colors.transparent,
              border: Border.all(
                color: isNextSeat && isAlmostFull
                    ? secondary
                    : borderColor.withValues(alpha: 0.8),
                width: isNextSeat && isAlmostFull ? 1.8 : 1.2,
                style: BorderStyle.solid,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.add_rounded,
                size: 18,
                color: isNextSeat && isAlmostFull ? secondary : textMuted,
              ),
            ),
          );
        }
      }),
    );
  }

  Widget _buildInitials(UserModel user) {
    final initials = user.firstName.isNotEmpty
        ? user.firstName.substring(0, 1).toUpperCase()
        : 'C';
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
