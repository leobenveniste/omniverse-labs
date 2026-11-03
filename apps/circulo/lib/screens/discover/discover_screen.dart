import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/swipe_interaction_model.dart';
import '../../services/auth_service.dart';
import '../../services/billing_service.dart';
import '../../services/ad_service.dart';
import '../../services/match_engine_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/swipe_deck_card.dart';
import '../../widgets/plus_promo_deck_card.dart';
import '../../widgets/google_ad_deck_card.dart';
import '../../l10n/app_localizations.dart';
import 'duo_mode_sheet.dart';
import 'discovery_filters_sheet.dart';
import 'profile_detail_sheet.dart';
import 'likes_received_sheet.dart';
import '../circles/group_match_celebration_dialog.dart';
import '../shop/paywall_bottom_sheet.dart';
import '../shop/shop_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  bool _circlesOnly = false;
  String? _regionFilter;
  int _minAge = 18;
  int _maxAge = 65;

  bool _isProcessingSwipe = false;
  bool _promoCardDismissedForCurrentCycle = false;

  void _onSwipe(
      DeckCandidateItem item, String action, MatchEngineService engine) async {
    final auth = context.read<AuthService>();
    final billing = context.read<BillingService>();
    final user = auth.currentUser;
    if (user == null || _isProcessingSwipe) return;

    // 1. Validar límite de swipes diarios en Free Tier
    if (!user.isPlusMember && user.dailySwipesRemaining <= 0) {
      PaywallBottomSheet.show(context, trigger: PaywallTrigger.dailySwipes);
      return;
    }

    // 2. Validar Super-Onda consumible
    if (action == 'superlike' && user.remainingSuperOndas <= 0 && !user.isPlusMember) {
      PaywallBottomSheet.show(context, trigger: PaywallTrigger.boost);
      return;
    }

    // Feedback táctil regular de swipe M3 Expressive
    HapticFeedback.lightImpact();

    setState(() {
      _isProcessingSwipe = true;
    });

    // Descontar swipe y acumular contador
    await billing.registerSwipeAttempt(user);
    if (action == 'superlike' && user.remainingSuperOndas > 0) {
      await billing.consumeSuperOnda(user);
    }
    await auth.refreshCurrentUser();

    final result = await engine.processSwipe(
      currentUser: user,
      item: item,
      action: action,
    );

    if (mounted) {
      setState(() => _isProcessingSwipe = false);

      if (result.isMatch && result.formedGroup != null) {
        // Doble impacto pesado al desbloquear K4
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 120), () {
          HapticFeedback.heavyImpact();
        });

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => GroupMatchCelebrationDialog(group: result.formedGroup!),
        );
      } else if (result.message != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(result.message!),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthService>();
    final engine = context.watch<MatchEngineService>();
    final adService = context.watch<AdService>();
    final user = auth.currentUser;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final promoType = adService.getPromoTypeForSwipeCount(
      totalSwipes: user.totalSwipesCounter,
      isPlusMember: user.isPlusMember,
    );

    final deck = engine.getDiscoveryDeck(
      currentUser: user,
      regionFilter: _regionFilter,
      minAge: _minAge,
      maxAge: _maxAge,
      circlesOnly: _circlesOnly,
    );

    final primary = AppTheme.primaryColor(context);
    final secondary = AppTheme.secondaryColor(context);

    return AppScaffold(
      title: l10n.get('navDiscover'),
      subtitle: user.region,
      actions: [
        // Botón Likes Recibidos (Quién te dio like)
        Stack(
          children: [
            IconButton(
              tooltip: l10n.get('whoLikedMeTitle'),
              style: AppTheme.headerIconButtonStyle(context),
              icon: const Icon(Icons.favorite_border_rounded, size: 22),
              onPressed: () => LikesReceivedSheet.show(context),
            ),
            if (user.whoLikedMeUserIds.isNotEmpty)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${user.whoLikedMeUserIds.length}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),

        // Botón Círculo Plus / Tienda
        IconButton(
          tooltip: l10n.get('plusTitle'),
          style: AppTheme.headerIconButtonStyle(
            context,
            foregroundColor: const Color(0xFFF59E0B),
          ),
          icon: const Icon(Icons.stars_rounded, size: 22),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ShopScreen()),
          ),
        ),

        // Botón Modo Dupla
        IconButton(
          tooltip: l10n.get('duoModeTitle'),
          style: AppTheme.headerIconButtonStyle(
            context,
            foregroundColor:
                user.hasDuoPartner ? secondary : AppTheme.textSecondaryColor(context),
          ),
          icon: Icon(
            user.hasDuoPartner
                ? Icons.people_rounded
                : Icons.people_outline_rounded,
            size: 22,
          ),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => const DuoModeSheet(),
            );
          },
        ),

        // Botón Filtros
        IconButton(
          tooltip: 'Filtros',
          style: AppTheme.headerIconButtonStyle(context),
          icon: const Icon(Icons.tune_rounded, size: 22),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (_) => DiscoveryFiltersSheet(
                initialRegion: _regionFilter,
                initialAgeRange:
                    RangeValues(_minAge.toDouble(), _maxAge.toDouble()),
                onApply: (res) {
                  setState(() {
                    _regionFilter = res.region;
                    _minAge = res.minAge;
                    _maxAge = res.maxAge;
                  });
                },
              ),
            );
          },
        ),
      ],
      body: Column(
        children: [
          // Banner de Swipes restantes o Círculo Plus activo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                user.isPlusMember
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                const Color(0xFFF59E0B).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('⭐', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 6),
                            Text(
                              l10n.get('swipesUnlimited'),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Row(
                        children: [
                          Icon(
                            Icons.local_fire_department_rounded,
                            size: 16,
                            color: user.dailySwipesRemaining > 5
                                ? primary
                                : AppTheme.errorRed,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.format('swipesRemaining', {
                              'count': user.dailySwipesRemaining,
                            }),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: user.dailySwipesRemaining > 5
                                  ? AppTheme.textSecondaryColor(context)
                                  : AppTheme.errorRed,
                            ),
                          ),
                        ],
                      ),
                if (user.hasActiveBoost)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('⚡ ', style: TextStyle(fontSize: 10)),
                        Text(
                          'Boost Activo',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Selector Modo Todo / Solo Círculos 3/4
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: false,
                  label: Text(l10n.get('filterAll')),
                  icon: const Icon(Icons.style_outlined, size: 16),
                ),
                ButtonSegment(
                  value: true,
                  label: Text(l10n.get('filterCirclesOnly')),
                  icon: const Icon(Icons.flash_on_rounded, size: 16),
                ),
              ],
              selected: {_circlesOnly},
              onSelectionChanged: (val) {
                HapticFeedback.selectionClick();
                setState(() => _circlesOnly = val.first);
              },
            ),
          ),

          // Mazo interactivo
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: deck.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.diversity_1_rounded,
                                size: 56, color: primary.withValues(alpha: 0.5)),
                            const SizedBox(height: 16),
                            Text(
                              l10n.get('emptyDeckTitle'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textPrimaryColor(context),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.get('emptyDeckSubtitle'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondaryColor(context),
                              ),
                            ),
                            const SizedBox(height: 20),
                            OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _circlesOnly = false;
                                  _regionFilter = null;
                                });
                              },
                              child: Text(l10n.get('resetFiltersBtn')),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Stack(
                      children: [
                        if (deck.length > 1)
                          Opacity(
                            opacity: 0.6,
                            child: Transform.scale(
                              scale: 0.94,
                              child: SwipeDeckCard(
                                item: deck[1],
                                onPass: () {},
                                onConnect: () {},
                                onSuperConnect: () {},
                                onTapDetail: () {},
                              ),
                            ),
                          ),
                        SwipeDeckCard(
                          key: ValueKey(deck[0].id),
                          item: deck[0],
                          onPass: () {
                            setState(() => _promoCardDismissedForCurrentCycle = false);
                            _onSwipe(deck[0], 'pass', engine);
                          },
                          onConnect: () {
                            setState(() => _promoCardDismissedForCurrentCycle = false);
                            _onSwipe(deck[0], 'like', engine);
                          },
                          onSuperConnect: () {
                            setState(() => _promoCardDismissedForCurrentCycle = false);
                            _onSwipe(deck[0], 'superlike', engine);
                          },
                          onTapDetail: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (_) => ProfileDetailSheet(item: deck[0]),
                            );
                          },
                        ),

                        // PUBLICIDAD CADA 20 SWIPES ALTERNADA: 1 VEZ PLUS, 1 VEZ GOOGLE ADS
                        if (promoType != PromoCardType.none &&
                            !_promoCardDismissedForCurrentCycle)
                          Positioned.fill(
                            child: Dismissible(
                              key: ValueKey('promo_card_${user.totalSwipesCounter}'),
                              onDismissed: (_) {
                                setState(() =>
                                    _promoCardDismissedForCurrentCycle = true);
                              },
                              child: promoType == PromoCardType.plusPromo
                                  ? PlusPromoDeckCard(
                                      onLearnMore: () {
                                        PaywallBottomSheet.show(
                                          context,
                                          trigger: PaywallTrigger.promoCard,
                                        );
                                      },
                                      onDismiss: () {
                                        setState(() =>
                                            _promoCardDismissedForCurrentCycle =
                                                true);
                                      },
                                    )
                                  : GoogleAdDeckCard(
                                      onDismiss: () {
                                        setState(() =>
                                            _promoCardDismissedForCurrentCycle =
                                                true);
                                      },
                                    ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),

          // Barra inferior de botones de acción táctiles M3 Expressive
          if (deck.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Deshacer (Rewind)
                  _CircleActionButton(
                    icon: Icons.replay_rounded,
                    color: AppTheme.textSecondaryColor(context),
                    size: 46,
                    tooltip: l10n.get('undoBtn'),
                    onPressed: () async {
                      HapticFeedback.selectionClick();
                      if (user.isPlusMember) {
                        final ok = await engine.undoLastSwipe(user.id);
                        if (ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Swipe deshecho con éxito'),
                              duration: Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } else {
                        PaywallBottomSheet.show(
                          context,
                          trigger: PaywallTrigger.rewind,
                        );
                      }
                    },
                  ),

                  // Pasar (X)
                  _CircleActionButton(
                    icon: Icons.close_rounded,
                    color: AppTheme.errorRed,
                    size: 56,
                    tooltip: l10n.get('passBtn'),
                    onPressed: () => _onSwipe(deck[0], 'pass', engine),
                  ),

                  // Super Conectar (★)
                  _CircleActionButton(
                    icon: Icons.star_rounded,
                    color: AppTheme.warmAmber,
                    size: 50,
                    tooltip: l10n.get('superConnectBtn'),
                    onPressed: () =>
                        _onSwipe(deck[0], 'superlike', engine),
                  ),

                  // Conectar (♥)
                  _CircleActionButton(
                    icon: deck[0].isCircle
                        ? Icons.group_add_rounded
                        : Icons.favorite_rounded,
                    color: deck[0].isCircle
                        ? secondary
                        : AppTheme.emeraldMint,
                    size: 60,
                    tooltip: l10n.get('connectBtn'),
                    onPressed: () => _onSwipe(deck[0], 'like', engine),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final String tooltip;
  final VoidCallback? onPressed;

  const _CircleActionButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.tooltip,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        minimumSize: Size(size, size),
        backgroundColor: AppTheme.surfaceContainer(context),
        foregroundColor: color,
        side: BorderSide(
          color: AppTheme.borderColor(context),
          width: 1.5,
        ),
        shape: const CircleBorder(),
      ),
      icon: Icon(icon, size: size * 0.50),
    );
  }
}
