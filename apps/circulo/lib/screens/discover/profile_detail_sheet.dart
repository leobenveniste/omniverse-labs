import 'package:flutter/material.dart';
import '../../models/swipe_interaction_model.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/circle_avatar_ring.dart';
import '../../widgets/interest_tag_chip.dart';
import '../../l10n/app_localizations.dart';

class ProfileDetailSheet extends StatelessWidget {
  final DeckCandidateItem item;

  const ProfileDetailSheet({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);
    final primary = AppTheme.primaryColor(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderColor(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (item.isCircle) ...[
                // Detalle de Círculo
                Text(
                  item.group?.name ?? 'Círculo',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.group?.region} • ${item.groupMembers.length}/${item.group?.maxMembers} integrantes',
                  style: TextStyle(fontSize: 13, color: textSecondary),
                ),
                const SizedBox(height: 20),

                CircleProgressAvatarRing(
                  members: item.groupMembers,
                  targetSize: item.group?.maxMembers ?? 4,
                  avatarRadius: 30,
                ),
                const SizedBox(height: 20),

                if (item.group?.description != null &&
                    item.group!.description.isNotEmpty) ...[
                  Text(
                    item.group!.description,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                Text(
                  l10n.get('sharedInterestsLabel'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (item.group?.sharedInterests ?? []).map((i) {
                    return InterestTagChip(
                      label: l10n.translateInterest(i),
                      isShared: true,
                    );
                  }).toList(),
                ),
              ] else ...[
                // Detalle de Usuario Individual
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primary.withValues(alpha: 0.15),
                        border: Border.all(color: primary, width: 2),
                      ),
                      child: ClipOval(
                        child: item.user?.photoUrl != null &&
                                item.user!.photoUrl!.isNotEmpty
                            ? Image.network(
                                item.user!.photoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Icon(
                                    Icons.person_rounded,
                                    size: 36),
                              )
                            : const Icon(Icons.person_rounded, size: 36),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item.user?.firstName}, ${item.user?.age}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item.user?.neighborhood.isNotEmpty == true ? "${item.user?.neighborhood}, " : ""}${item.user?.region}',
                            style: TextStyle(
                                fontSize: 13, color: textSecondary),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.tertiaryColor(context),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${GroupRoles.getIcon(item.user?.groupRole ?? '')} ${l10n.translateGroupRole(item.user?.groupRole ?? '')}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (item.user?.bio != null && item.user!.bio.isNotEmpty) ...[
                  Text(
                    'Sobre mí',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.user!.bio,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                Text(
                  'Intereses',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (item.user?.interests ?? []).map((i) {
                    final isShared = item.sharedInterests.contains(i);
                    return InterestTagChip(
                      label: l10n.translateInterest(i),
                      isShared: isShared,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                if (item.user?.favoritePlans.isNotEmpty == true) ...[
                  Text(
                    'Planes favoritos para salir',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: item.user!.favoritePlans.map((p) {
                      return InterestTagChip(
                        label: l10n.translatePlan(p),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}
