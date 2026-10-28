import 'package:flutter/material.dart';
import '../core/theme/app_category_theme.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/haptics_helper.dart';
import '../core/widgets/app_header_title.dart';
import '../core/widgets/category_select_modal.dart';
import '../core/widgets/paywall_sheet.dart';
import '../core/widgets/share_card_modal.dart';
import '../l10n/app_localizations.dart';
import '../models/card_item.dart';
import '../services/app_services.dart';
import '../services/card_service.dart';
import 'gameplay_screen.dart';
import 'settings_screen.dart';

class _DeckMeta {
  final String id;
  final String titleKey;
  final String descKey;
  final bool isProOnly;
  final String? badgeKey;

  const _DeckMeta({
    required this.id,
    required this.titleKey,
    required this.descKey,
    required this.isProOnly,
    this.badgeKey,
  });
}

class _DeckSection {
  final String titleKey;
  final String subKey;
  final String emoji;
  final List<_DeckMeta> decks;

  const _DeckSection({
    required this.titleKey,
    required this.subKey,
    required this.emoji,
    required this.decks,
  });
}

// Grouped Decks by Social Dynamics (Opción A)
const List<_DeckSection> _deckSections = [
  // 1. De a 2 • Parejas y Citas
  _DeckSection(
    titleKey: 'sectionCouplesAndDates',
    subKey: 'sectionCouplesAndDatesSub',
    emoji: '👩‍❤️‍👨',
    decks: [
      _DeckMeta(id: 'dates', titleKey: 'deckDates', descKey: 'deckDatesDesc', isProOnly: false),
      _DeckMeta(id: 'couples', titleKey: 'deckCouples', descKey: 'deckCouplesDesc', isProOnly: true, badgeKey: 'badgeCouplesFav'),
      _DeckMeta(id: 'spicy', titleKey: 'deckSpicy', descKey: 'deckSpicyDesc', isProOnly: true, badgeKey: 'badgeMostPopular'),
      _DeckMeta(id: 'couples_challenges', titleKey: 'deckCouplesChallenges', descKey: 'deckCouplesChallengesDesc', isProOnly: true),
    ],
  ),

  // 2. Con Amigos & Fiesta
  _DeckSection(
    titleKey: 'sectionFriendsAndParty',
    subKey: 'sectionFriendsAndPartySub',
    emoji: '🍻',
    decks: [
      _DeckMeta(id: 'friends', titleKey: 'deckFriends', descKey: 'deckFriendsDesc', isProOnly: false),
      _DeckMeta(id: 'hot_takes', titleKey: 'deckHotTakes', descKey: 'deckHotTakesDesc', isProOnly: true, badgeKey: 'badgeTrending'),
      _DeckMeta(id: 'most_likely', titleKey: 'deckMostLikely', descKey: 'deckMostLikelyDesc', isProOnly: true),
      _DeckMeta(id: 'never_have_i', titleKey: 'deckNeverHaveI', descKey: 'deckNeverHaveIDesc', isProOnly: true, badgeKey: 'badgePartyHit'),
      _DeckMeta(id: 'party', titleKey: 'deckParty', descKey: 'deckPartyDesc', isProOnly: true),
      _DeckMeta(id: 'debates', titleKey: 'deckDebates', descKey: 'deckDebatesDesc', isProOnly: false),
      _DeckMeta(id: 'challenges', titleKey: 'deckChallenges', descKey: 'deckChallengesDesc', isProOnly: true),
      _DeckMeta(id: 'spicy_challenges', titleKey: 'deckSpicyChallenges', descKey: 'deckSpicyChallengesDesc', isProOnly: true),
    ],
  ),

  // 3. Familia & Todos
  _DeckSection(
    titleKey: 'sectionFamilyAndAll',
    subKey: 'sectionFamilyAndAllSub',
    emoji: '🏡',
    decks: [
      _DeckMeta(id: 'family', titleKey: 'deckFamily', descKey: 'deckFamilyDesc', isProOnly: false),
      _DeckMeta(id: 'travel', titleKey: 'deckTravel', descKey: 'deckTravelDesc', isProOnly: true),
    ],
  ),
];

// Flat list helper for modal lookup and backwards compatibility
List<_DeckMeta> get _allDecks => _deckSections.expand((s) => s.decks).toList();

class DecksScreen extends StatelessWidget {
  const DecksScreen({super.key});

  void _openDeck(
    BuildContext context, {
    required String categoryId,
    required String title,
    required bool isProOnly,
    required bool isPro,
  }) {
    HapticsHelper.selection();
    final cardService = AppServices.of(context).cardService;
    cardService.setCategoryFilter(categoryId);
    cardService.drawNextCard();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GamePlayScreen(
          singleDeckTitle: title,
          isLockedPreview: isProOnly && !isPro,
        ),
      ),
    );
  }

  void _playPreset(
    BuildContext context, {
    required String name,
    required Set<String> categories,
    required bool isPro,
  }) {
    final l10n = AppLocalizations.of(context);
    const proSet = {'couples', 'spicy', 'couples_challenges', 'hot_takes', 'spicy_challenges', 'most_likely', 'never_have_i', 'party', 'challenges', 'travel'};
    final needsPro = categories.any(proSet.contains);

    if (needsPro && !isPro) {
      HapticsHelper.warning();
      PaywallSheet.show(context, customReason: l10n.t('proLockedDeck'));
      return;
    }

    HapticsHelper.selection();
    final cardService = AppServices.of(context).cardService;
    cardService.setMultiCategoryFilter(categories);
    cardService.drawNextCard();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GamePlayScreen(
          singleDeckTitle: name,
        ),
      ),
    );
  }

  void _openCategoryMixModal(BuildContext context) {
    HapticsHelper.medium();
    final cardService = AppServices.of(context).cardService;
    final l10n = AppLocalizations.of(context);

    CategorySelectModal.show(
      context,
      onCategoriesSelected: (categories) {
        cardService.setMultiCategoryFilter(categories);
        cardService.drawNextCard();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GamePlayScreen(
              singleDeckTitle: categories.length == 1
                  ? l10n.t(_allDecks.firstWhere((d) => d.id == categories.first, orElse: () => _allDecks.first).titleKey)
                  : '${categories.length} ${l10n.t('decksTitle')}',
            ),
          ),
        );
      },
    );
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
        final isPro = premiumService.isPro;
        final totalCards = cardService.totalCardsCount;
        final dailyCard = _getDailyCard(cardService, isPro);

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: AppHeaderTitle(
              title: 'Charlemos',
              isPro: isPro,
            ),
            actions: [
              if (!isPro)
                IconButton(
                  icon: const Text('👑', style: TextStyle(fontSize: 18)),
                  tooltip: 'Charlemos PRO',
                  onPressed: () {
                    HapticsHelper.light();
                    PaywallSheet.show(context);
                  },
                ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: l10n.t('settingsTitle'),
                onPressed: () {
                  HapticsHelper.light();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          floatingActionButton: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: FloatingActionButton.extended(
              elevation: 4,
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              icon: const Icon(Icons.shuffle_rounded, size: 22),
              label: Text(
                l10n.t('playFabLabel'),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.3),
              ),
              onPressed: () => _openCategoryMixModal(context),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              top: AppSpacing.xs,
              bottom: 84, // Margin for the FAB
            ),
            children: [
              // Ambient Fast Presets Row
              _buildPresetsRow(context, isPro, l10n, theme),
              const SizedBox(height: AppSpacing.sm),

              // Daily Question Hero Card
              if (dailyCard != null) ...[
                _buildDailyQuestionCard(context, dailyCard, l10n, theme),
                const SizedBox(height: AppSpacing.sm),
              ],

              // Total available counter bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.t('decksTitle'),
                      style: AppTypography.caption(theme.colorScheme.onSurfaceVariant, isMedium: true),
                    ),
                    Text(
                      l10n.t('totalCardsAvailable', args: {'count': totalCards}),
                      style: AppTypography.caption(theme.colorScheme.primary, isMedium: true),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // ==========================================
              // GROUPED SECTIONS (OPCIÓN A)
              // ==========================================
              ..._deckSections.map((section) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Header
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppSpacing.sm,
                        bottom: AppSpacing.xs,
                        left: AppSpacing.xs,
                        right: AppSpacing.xs,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                            alignment: Alignment.center,
                            child: Text(section.emoji, style: const TextStyle(fontSize: 18)),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.t(section.titleKey),
                                  style: AppTypography.title(theme.colorScheme.onSurface).copyWith(
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  l10n.t(section.subKey),
                                  style: AppTypography.caption(theme.colorScheme.onSurfaceVariant),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),

                    // Section Decks Cards
                    ...section.decks.map((deck) {
                      final count = cardService.countByCategory(deck.id);
                      final title = l10n.t(deck.titleKey);
                      final desc = l10n.t(deck.descKey);
                      final isLocked = deck.isProOnly && !isPro;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _buildCategoryDeckCard(
                          context,
                          categoryId: deck.id,
                          title: title,
                          description: desc,
                          count: count,
                          isLocked: isLocked,
                          badgeText: deck.badgeKey != null ? l10n.t(deck.badgeKey!) : null,
                          onTap: () => _openDeck(
                            context,
                            categoryId: deck.id,
                            title: title,
                            isProOnly: deck.isProOnly,
                            isPro: isPro,
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                );
              }),

              // Custom user cards deck (if any exists)
              if (cardService.customCards.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.sm,
                    bottom: AppSpacing.xs,
                    left: AppSpacing.xs,
                    right: AppSpacing.xs,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        alignment: Alignment.center,
                        child: const Text('✍️', style: TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.t('sectionCustomDecks'),
                              style: AppTypography.title(theme.colorScheme.onSurface).copyWith(
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              l10n.t('sectionCustomDecksSub'),
                              style: AppTypography.caption(theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _buildCategoryDeckCard(
                    context,
                    categoryId: 'custom',
                    title: l10n.t('deckCustom'),
                    description: l10n.t('deckCustomDesc'),
                    count: cardService.customCards.length,
                    isLocked: false,
                    onTap: () => _openDeck(
                      context,
                      categoryId: 'custom',
                      title: l10n.t('deckCustom'),
                      isProOnly: false,
                      isPro: isPro,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPresetsRow(
    BuildContext context,
    bool isPro,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ActionChip(
            avatar: const Text('🔥', style: TextStyle(fontSize: 14)),
            label: Text(l10n.t('presetSpicyNight')),
            onPressed: () => _playPreset(
              context,
              name: l10n.t('presetSpicyNight'),
              categories: {'couples', 'spicy', 'hot_takes'},
              isPro: isPro,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          ActionChip(
            avatar: const Text('🌶️', style: TextStyle(fontSize: 14)),
            label: Text(l10n.t('presetSpicyDares')),
            onPressed: () => _playPreset(
              context,
              name: l10n.t('presetSpicyDares'),
              categories: {'spicy', 'spicy_challenges', 'hot_takes'},
              isPro: isPro,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          ActionChip(
            avatar: const Text('👥', style: TextStyle(fontSize: 14)),
            label: Text(l10n.t('presetGroupParty')),
            onPressed: () => _playPreset(
              context,
              name: l10n.t('presetGroupParty'),
              categories: {'most_likely', 'never_have_i', 'party'},
              isPro: isPro,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          ActionChip(
            avatar: const Text('🥂', style: TextStyle(fontSize: 14)),
            label: Text(l10n.t('presetTheParty')),
            onPressed: () => _playPreset(
              context,
              name: l10n.t('presetTheParty'),
              categories: {'party', 'hot_takes', 'friends'},
              isPro: isPro,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          ActionChip(
            avatar: const Text('❤️', style: TextStyle(fontSize: 14)),
            label: Text(l10n.t('presetDatesCouples')),
            onPressed: () => _playPreset(
              context,
              name: l10n.t('presetDatesCouples'),
              categories: {'dates', 'friends'},
              isPro: isPro,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          ActionChip(
            avatar: const Text('🏡', style: TextStyle(fontSize: 14)),
            label: Text(l10n.t('presetFamilyRoots')),
            onPressed: () => _playPreset(
              context,
              name: l10n.t('presetFamilyRoots'),
              categories: {'family', 'friends'},
              isPro: isPro,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          ActionChip(
            avatar: const Text('✈️', style: TextStyle(fontSize: 14)),
            label: Text(l10n.t('presetTravelAdventures')),
            onPressed: () => _playPreset(
              context,
              name: l10n.t('presetTravelAdventures'),
              categories: {'travel', 'friends'},
              isPro: isPro,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDeckCard(
    BuildContext context, {
    required String categoryId,
    required String title,
    required String description,
    required int count,
    required bool isLocked,
    String? badgeText,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final catStyle = AppCategoryTheme.of(categoryId);

    final cardBg = isDark ? catStyle.backgroundDark : catStyle.backgroundLight;
    final cardBorder = isDark ? catStyle.borderDark : catStyle.borderLight;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            catStyle.primary.withValues(alpha: isDark ? 0.25 : 0.16),
            cardBg,
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isLocked
              ? const Color(0xFFD4AF37).withValues(alpha: 0.7)
              : cardBorder.withValues(alpha: 0.9),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: catStyle.primary.withValues(alpha: isDark ? 0.22 : 0.10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Ambient decorative watermark of the category icon (subtle, editorial craft)
          Positioned(
            right: -8,
            top: -8,
            child: IgnorePointer(
              child: Icon(
                catStyle.icon,
                size: 96,
                color: catStyle.primary.withValues(alpha: isDark ? 0.10 : 0.07),
              ),
            ),
          ),

          // Interactive pressable layer
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticsHelper.selection();
                onTap();
              },
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Standalone larger icon (size 52)
                    Icon(
                      catStyle.icon,
                      size: 52,
                      color: catStyle.primary,
                    ),
                    const SizedBox(width: AppSpacing.md),

                    // Texts and metadata
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (badgeText != null) ...[
                            Container(
                              margin: const EdgeInsets.only(bottom: 5),
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFC85A3B).withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: const Color(0xFFC85A3B).withValues(alpha: 0.45),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                badgeText,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFC85A3B),
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: AppTypography.body(theme.colorScheme.onSurface, isMedium: true).copyWith(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              if (isLocked) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFDF00),
                                    borderRadius: BorderRadius.circular(7),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                                        blurRadius: 5,
                                        offset: const Offset(0, 1.5),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.lock_rounded, size: 12, color: Color(0xFF2A1B00)),
                                      SizedBox(width: 3),
                                      Text(
                                        'PRO',
                                        style: TextStyle(
                                          color: Color(0xFF2A1B00),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: AppTypography.caption(
                              theme.colorScheme.onSurface.withValues(alpha: 0.72),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: catStyle.primary.withValues(alpha: isDark ? 0.22 : 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: catStyle.primary.withValues(alpha: 0.35),
                                    width: 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.style_outlined,
                                      size: 13,
                                      color: catStyle.primary,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      '$count cartas',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        color: catStyle.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isLocked) ...[
                                const SizedBox(width: AppSpacing.xs),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE5BA5A).withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFFE5BA5A).withValues(alpha: 0.6),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.play_circle_outline_rounded,
                                        size: 13,
                                        color: Color(0xFFC85A3B),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        l10n.t('freePreviewBadge'),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFFC85A3B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Icon(
                      isLocked ? Icons.play_arrow_rounded : Icons.chevron_right_rounded,
                      color: isLocked ? const Color(0xFFC85A3B) : theme.colorScheme.onSurface.withValues(alpha: 0.35),
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  CardItem? _getDailyCard(CardService cardService, bool isPro) {
    final candidateCards = isPro
        ? cardService.allCards
        : cardService.allCards.where((c) => const {'dates', 'friends', 'debates', 'family'}.contains(c.category)).toList();
    if (candidateCards.isEmpty) return null;
    final now = DateTime.now();
    final dayHash = (now.year * 10000 + now.month * 100 + now.day).abs();
    return candidateCards[dayHash % candidateCards.length];
  }

  Widget _buildDailyQuestionCard(
    BuildContext context,
    CardItem dailyCard,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    final catStyle = AppCategoryTheme.of(dailyCard.category);
    final cardText = dailyCard.getText(l10n.locale.languageCode);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFC85A3B).withValues(alpha: isDark ? 0.22 : 0.12),
            theme.colorScheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: const Color(0xFFC85A3B).withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC85A3B).withValues(alpha: isDark ? 0.16 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFC85A3B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('☀️', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    Text(
                      l10n.t('dailyQuestionTitle').toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFC85A3B),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: catStyle.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  AppCategoryTheme.getCategoryName(dailyCard.category, l10n),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: catStyle.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '«$cardText»',
            style: AppTypography.title(theme.colorScheme.onSurface).copyWith(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticsHelper.selection();
                    final cardService = AppServices.of(context).cardService;
                    cardService.setCategoryFilter(dailyCard.category);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => GamePlayScreen(
                          singleDeckTitle: l10n.t('dailyQuestionTitle'),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                  label: Text(
                    l10n.t('dailyQuestionAction'),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC85A3B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              IconButton(
                icon: const Icon(Icons.share_rounded, size: 20),
                tooltip: l10n.t('shareCard'),
                onPressed: () {
                  HapticsHelper.light();
                  ShareCardModal.show(
                    context,
                    card: dailyCard,
                    cardText: cardText,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
