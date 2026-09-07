import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../core/theme/app_category_theme.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/haptics_helper.dart';
import '../core/widgets/app_header_title.dart';
import '../core/widgets/category_select_modal.dart';
import '../core/widgets/first_use_guide_card.dart';
import '../core/widgets/paywall_sheet.dart';
import '../l10n/app_localizations.dart';
import '../models/card_item.dart';
import '../services/app_services.dart';
import '../services/card_service.dart';
import 'settings_screen.dart';

class GamePlayScreen extends StatefulWidget {
  final String? singleDeckTitle;

  const GamePlayScreen({
    super.key,
    this.singleDeckTitle,
  });

  @override
  State<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<GamePlayScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _exitSlideAnimation;
  late Animation<double> _exitRotationAnimation;
  late Animation<double> _exitFadeAnimation;

  late AnimationController _enterController;
  late Animation<double> _enterScaleAnimation;
  late Animation<Offset> _enterSlideAnimation;
  late Animation<double> _enterFadeAnimation;

  bool _isAnimating = false;
  bool _showGuide = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGuidePref();
    });

    // Exit controller: Card flies smoothly away to the left with natural rotation & fade
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _exitSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.35, 0.04),
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeInCubic),
    );

    _exitRotationAnimation = Tween<double>(
      begin: 0.0,
      end: -0.14, // natural counter-clockwise tilt when flying left
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeIn),
    );

    _exitFadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeInQuad),
    );

    // Enter controller: Next card emerges from bottom/center
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _enterScaleAnimation = Tween<double>(
      begin: 0.93,
      end: 1.0,
    ).animate(
      CurvedAnimation(parent: _enterController, curve: Curves.easeOutBack),
    );

    _enterSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _enterController, curve: Curves.easeOutCubic),
    );

    _enterFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(parent: _enterController, curve: Curves.easeOut),
    );

    _enterController.value = 1.0;
  }

  @override
  void dispose() {
    _slideController.dispose();
    _enterController.dispose();
    super.dispose();
  }

  void _onNextCard(CardService cardService) {
    if (_isAnimating) return;
    _isAnimating = true;
    HapticsHelper.selection();

    // Trigger smooth fly away to left
    _slideController.forward(from: 0.0).then((_) {
      if (!mounted) return;
      // Draw next card
      cardService.drawNextCard();
      _slideController.reset();

      // Animate new card entering
      _enterController.forward(from: 0.0).then((_) {
        if (mounted) {
          setState(() {
            _isAnimating = false;
          });
        }
      });
    });
  }

  Future<void> _loadGuidePref() async {
    final prefs = AppServices.of(context).preferencesService;
    final seen = prefs.hasSeenGuide;
    if (!seen && mounted) {
      setState(() => _showGuide = true);
    }
  }

  void _dismissGuide() {
    setState(() => _showGuide = false);
    AppServices.of(context).preferencesService.setHasSeenGuide(true);
  }

  void _openCategorySelector() {
    HapticsHelper.medium();
    final cardService = AppServices.of(context).cardService;
    CategorySelectModal.show(
      context,
      onCategoriesSelected: (categories) {
        cardService.setMultiCategoryFilter(categories);
        cardService.drawNextCard();
      },
    );
  }

  void _openSettings() {
    HapticsHelper.light();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  String _getCategoryName(String category, AppLocalizations l10n) {
    switch (category) {
      case 'dates':
        return l10n.t('deckDates');
      case 'couples':
        return l10n.t('deckCouples');
      case 'spicy':
        return l10n.t('deckSpicy');
      case 'hot_takes':
        return l10n.t('deckHotTakes');
      case 'spicy_challenges':
        return l10n.t('deckSpicyChallenges');
      case 'most_likely':
        return l10n.t('deckMostLikely');
      case 'never_have_i':
        return l10n.t('deckNeverHaveI');
      case 'party':
        return l10n.t('deckParty');
      case 'friends':
        return l10n.t('deckFriends');
      case 'challenges':
        return l10n.t('deckChallenges');
      case 'debates':
        return l10n.t('deckDebates');
      case 'travel':
        return l10n.t('deckTravel');
      case 'family':
        return l10n.t('deckFamily');
      case 'custom':
        return l10n.t('deckCustom');
      default:
        return category;
    }
  }

  String _getLevelName(int level, AppLocalizations l10n) {
    switch (level) {
      case 1:
        return l10n.t('level1Name');
      case 2:
        return l10n.t('level2Name');
      case 3:
        return l10n.t('level3Name');
      case 4:
        return l10n.t('level4Name');
      default:
        return l10n.t('levelAll');
    }
  }

  Future<void> _confirmResetDeck(CardService cardService) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.t('resetDeck')),
        content: Text(l10n.t('resetDeckConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.t('resetDeck')),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      cardService.resetHistory();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('resetDeckDone'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final services = AppServices.of(context);
    final cardService = services.cardService;
    final premiumService = services.premiumService;

    return AnimatedBuilder(
      animation: Listenable.merge([cardService, premiumService]),
      builder: (context, _) {
        final currentCard = cardService.currentCard;
        final isPro = premiumService.isPro;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: l10n.t('backToDecks'),
              onPressed: () {
                HapticsHelper.light();
                Navigator.pop(context);
              },
            ),
            // Header ALWAYS keeps the app name 'Charlemos'
            title: AppHeaderTitle(
              title: 'Charlemos',
              isPro: isPro,
            ),
            actions: [
              // Pro Upgrade badge if free
              if (!isPro)
                IconButton(
                  icon: const Text('👑', style: TextStyle(fontSize: 18)),
                  tooltip: 'Charlemos PRO',
                  onPressed: () {
                    HapticsHelper.light();
                    PaywallSheet.show(context);
                  },
                ),
              // Reset History button
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: l10n.t('resetDeck'),
                onPressed: () {
                  HapticsHelper.light();
                  _confirmResetDeck(cardService);
                },
              ),
              // Settings directly in Header
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: l10n.t('settingsTitle'),
                onPressed: _openSettings,
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // First-use guide
                if (_showGuide)
                  FirstUseGuideCard(
                    title: l10n.t('guideTitle'),
                    description: l10n.t('guideDesc'),
                    icon: Icons.chat_bubble_outline_rounded,
                    bulletPoints: [
                      l10n.t('guidePoint1'),
                      l10n.t('guidePoint2'),
                      l10n.t('guidePoint3'),
                    ],
                    onDismiss: _dismissGuide,
                  ),

                // Main Interactive Card View Area (Active decks and remaining counter row removed as requested)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: currentCard == null
                        ? _buildEmptyState(context, cardService, l10n)
                        : GestureDetector(
                            onTap: () => _onNextCard(cardService),
                            onHorizontalDragEnd: (details) {
                              if (details.primaryVelocity != null && details.primaryVelocity!.abs() > 150) {
                                _onNextCard(cardService);
                              }
                            },
                            child: AnimatedBuilder(
                              animation: Listenable.merge([_slideController, _enterController]),
                              builder: (context, child) {
                                if (_slideController.isAnimating) {
                                  // Exit animation: Fly away to left with rotation and fade
                                  return SlideTransition(
                                    position: _exitSlideAnimation,
                                    child: Transform.rotate(
                                      angle: _exitRotationAnimation.value,
                                      child: FadeTransition(
                                        opacity: _exitFadeAnimation,
                                        child: child,
                                      ),
                                    ),
                                  );
                                } else {
                                  // Enter animation: Scale, subtle slide, and fade in
                                  return SlideTransition(
                                    position: _enterSlideAnimation,
                                    child: Transform.scale(
                                      scale: _enterScaleAnimation.value,
                                      child: FadeTransition(
                                        opacity: _enterFadeAnimation,
                                        child: child,
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: _buildCardView(
                                context: context,
                                card: currentCard,
                                cardService: cardService,
                                l10n: l10n,
                              ),
                            ),
                          ),
                  ),
                ),

                // Bottom Hint & "Cambiar mazos" Button
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                    bottom: AppSpacing.lg,
                    top: AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      // Subtitle hint
                      Expanded(
                        child: Text(
                          l10n.t('tapOrSwipeNext'),
                          style: AppTypography.caption(
                            theme.colorScheme.onSurface.withValues(alpha: 0.65),
                          ),
                        ),
                      ),
                      // "Cambiar mazos" Button
                      ElevatedButton.icon(
                        onPressed: _openCategorySelector,
                        icon: const Icon(Icons.tune_rounded, size: 20),
                        label: Text(
                          l10n.t('changeCategories'),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardView({
    required BuildContext context,
    required CardItem card,
    required CardService cardService,
    required AppLocalizations l10n,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Category style
    final catStyle = AppCategoryTheme.of(card.category);
    final catColor = catStyle.primary;
    final cardBg = isDark ? catStyle.backgroundDark : catStyle.backgroundLight;
    final cardBorder = isDark ? catStyle.borderDark : catStyle.borderLight;

    final cardText = card.getText(l10n.locale.languageCode);

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cardBg,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            catColor.withValues(alpha: isDark ? 0.30 : 0.18),
            cardBg,
            cardBg,
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: cardBorder,
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: catColor.withValues(alpha: isDark ? 0.35 : 0.22),
            blurRadius: 32,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: isDark ? 0.45 : 0.10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Watermark Silhouette Icon (Clearly Noticeable)
          Positioned(
            right: -25,
            bottom: -25,
            child: IgnorePointer(
              child: Opacity(
                opacity: isDark ? 0.14 : 0.12,
                child: Icon(
                  catStyle.icon,
                  size: 230,
                  color: catColor,
                ),
              ),
            ),
          ),

          // Main Card Content
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card Header: Category Badge & Level Badge (High Contrast)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Category Icon + Title Badge (Solid High Contrast)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? catColor : catColor,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: catColor.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(catStyle.icon, size: 22, color: catStyle.onPrimary),
                          const SizedBox(width: 8),
                          Text(
                            _getCategoryName(card.category, l10n).toUpperCase(),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              color: catStyle.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Level Tag - Distinct pill with border for high contrast
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withValues(alpha: isDark ? 0.85 : 0.90),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.35),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        _getLevelName(card.level, l10n),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Card Main Text (High Contrast & Clear Readability)
                Center(
                  child: Text(
                    cardText,
                    style: AppTypography.display(theme.colorScheme.onSurface).copyWith(
                      fontSize: 25,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const Spacer(),

                // Card Footer: Brand & High Contrast Actions (Share, Copy)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withValues(alpha: isDark ? 0.90 : 0.95),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: catColor.withValues(alpha: 0.5),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        'Charlemos',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: catColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Copy Button with high contrast container
                        Material(
                          color: theme.colorScheme.surface.withValues(alpha: isDark ? 0.80 : 0.90),
                          shape: const CircleBorder(),
                          elevation: 1,
                          child: IconButton(
                            icon: Icon(Icons.copy_rounded, size: 19, color: theme.colorScheme.onSurface),
                            tooltip: l10n.t('copiedToClipboard'),
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                            onPressed: () {
                              HapticsHelper.light();
                              Clipboard.setData(ClipboardData(text: cardText));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.t('copiedToClipboard')),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Share Button with high contrast container
                        Material(
                          color: catColor,
                          shape: const CircleBorder(),
                          elevation: 1.5,
                          child: IconButton(
                            icon: const Icon(Icons.share_rounded, size: 19, color: Colors.white),
                            tooltip: l10n.t('shareCard'),
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                            onPressed: () {
                              HapticsHelper.light();
                              Share.share(
                                l10n.t('shareText', args: {'text': cardText}),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    CardService cardService,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.style_outlined,
            size: 64,
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.t('noCardsMatching'),
            style: AppTypography.body(
              theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: () {
              HapticsHelper.medium();
              cardService.resetHistory();
            },
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n.t('resetDeck')),
          ),
        ],
      ),
    );
  }
}
