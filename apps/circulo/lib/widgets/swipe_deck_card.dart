import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/swipe_interaction_model.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import 'circle_avatar_ring.dart';
import 'interest_tag_chip.dart';

class SwipeDeckCard extends StatefulWidget {
  final DeckCandidateItem item;
  final VoidCallback onPass;
  final VoidCallback onConnect;
  final VoidCallback onSuperConnect;
  final VoidCallback onTapDetail;

  const SwipeDeckCard({
    super.key,
    required this.item,
    required this.onPass,
    required this.onConnect,
    required this.onSuperConnect,
    required this.onTapDetail,
  });

  @override
  State<SwipeDeckCard> createState() => _SwipeDeckCardState();
}

class _SwipeDeckCardState extends State<SwipeDeckCard> {
  Offset _dragOffset = Offset.zero;
  double _dragAngle = 0;

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
      _dragAngle = (_dragOffset.dx / 300) * 0.20;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    const threshold = 100.0;
    if (_dragOffset.dx > threshold) {
      HapticFeedback.mediumImpact();
      widget.onConnect();
    } else if (_dragOffset.dx < -threshold) {
      HapticFeedback.lightImpact();
      widget.onPass();
    } else if (_dragOffset.dy < -threshold) {
      HapticFeedback.heavyImpact();
      widget.onSuperConnect();
    } else {
      setState(() {
        _dragOffset = Offset.zero;
        _dragAngle = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final secondary = AppTheme.secondaryColor(context);
    final borderColor = AppTheme.borderColor(context);

    // Indicador visual de swipe
    final double swipeProgress = (_dragOffset.dx / 120).clamp(-1.0, 1.0);

    return GestureDetector(
      onTap: widget.onTapDetail,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform.translate(
        offset: _dragOffset,
        child: Transform.rotate(
          angle: _dragAngle,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.cardColor(context),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: widget.item.isCircle ? secondary : borderColor,
                    width: widget.item.isCircle ? 2.0 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: widget.item.isCircle
                      ? _buildCircleCard(context, l10n)
                      : _buildIndividualCard(context, l10n),
                ),
              ),

              // Overlay dinámico de CONECTAR (verde/violeta)
              if (swipeProgress > 0.15)
                Positioned(
                  top: 24,
                  left: 24,
                  child: Opacity(
                    opacity: swipeProgress.abs(),
                    child: Transform.rotate(
                      angle: -0.2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.emeraldMint,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Text(
                          l10n.get('connectBtn').toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Overlay dinámico de PASAR (rojo/coral)
              if (swipeProgress < -0.15)
                Positioned(
                  top: 24,
                  right: 24,
                  child: Opacity(
                    opacity: swipeProgress.abs(),
                    child: Transform.rotate(
                      angle: 0.2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.errorRed,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Text(
                          l10n.get('passBtn').toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIndividualCard(BuildContext context, AppLocalizations l10n) {
    final user = widget.item.user!;
    final primary = AppTheme.primaryColor(context);
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Foto o Avatar superior
        Expanded(
          flex: 5,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                color: primary.withValues(alpha: 0.15),
                child: user.photoUrl != null && user.photoUrl!.isNotEmpty
                    ? Image.network(
                        user.photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _buildInitialsPlaceholder(user),
                      )
                    : _buildInitialsPlaceholder(user),
              ),
              // Gradiente inferior de legibilidad
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 100,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Badges superiores
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Badge Afinidad
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.favorite_rounded,
                              size: 14, color: AppTheme.vibrantCoral),
                          const SizedBox(width: 6),
                          Text(
                            l10n.format('affinityLabel',
                                {'percent': widget.item.affinityScore}),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Badge Rol
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
                  ],
                ),
              ),
              // Nombre, Edad y Asistencias
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${user.firstName}, ${user.age}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        if (user.totalMeetupsCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.emeraldMint,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified_rounded,
                                    size: 12, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.format('attendedMeetupsCount',
                                      {'count': user.totalMeetupsCount}),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${user.neighborhood.isNotEmpty ? "${user.neighborhood}, " : ""}${user.region}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Bio e Intereses inferiores
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (user.bio.isNotEmpty) ...[
                  Text(
                    user.bio,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  l10n.get('sharedInterestsLabel'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: user.interests.map((interest) {
                        final isShared =
                            widget.item.sharedInterests.contains(interest);
                        return InterestTagChip(
                          label: l10n.translateInterest(interest),
                          isShared: isShared,
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCircleCard(BuildContext context, AppLocalizations l10n) {
    final group = widget.item.group!;
    final secondary = AppTheme.secondaryColor(context);
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);

    final isAlmostFull = group.memberIds.length == 3 && group.maxMembers == 4;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Badge Superior Destacado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isAlmostFull
                  ? secondary
                  : AppTheme.primaryColor(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.flash_on_rounded,
                    size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  isAlmostFull
                      ? l10n.get('almostFullBadge')
                      : l10n.format('expandingGroupBadge', {
                          'current': group.memberIds.length,
                          'max': group.maxMembers
                        }),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            group.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            group.region,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Anillo de integrantes del Círculo
          CircleProgressAvatarRing(
            members: widget.item.groupMembers,
            targetSize: group.maxMembers,
            avatarRadius: 26,
          ),
          const SizedBox(height: 16),

          Text(
            l10n.format('affinityLabel', {'percent': widget.item.affinityScore}),
            style: TextStyle(
              color: secondary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.get('sharedInterestsLabel'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: group.sharedInterests.map((interest) {
                  return InterestTagChip(
                    label: l10n.translateInterest(interest),
                    isShared: true,
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialsPlaceholder(UserModel user) {
    return Center(
      child: Text(
        user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '?',
        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900),
      ),
    );
  }
}
