import 'package:flutter/material.dart';
import '../core/theme/app_category_theme.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/haptics_helper.dart';
import '../core/widgets/app_header_title.dart';
import '../core/widgets/category_select_modal.dart';
import '../core/widgets/paywall_sheet.dart';
import '../l10n/app_localizations.dart';
import '../services/app_services.dart';
import 'gameplay_screen.dart';
import 'settings_screen.dart';

class _DeckMeta {
  final String id;
  final String titleKey;
  final String descKey;
  final bool isProOnly;

  const _DeckMeta({
    required this.id,
    required this.titleKey,
    required this.descKey,
    required this.isProOnly,
  });
}

// All decks in unified sequence (Free then PRO, but shown in a single seamless catalog)
const List<_DeckMeta> _allDecks = [
  // Core Free Decks
  _DeckMeta(id: 'dates', titleKey: 'deckDates', descKey: 'deckDatesDesc', isProOnly: false),
  _DeckMeta(id: 'friends', titleKey: 'deckFriends', descKey: 'deckFriendsDesc', isProOnly: false),
  _DeckMeta(id: 'debates', titleKey: 'deckDebates', descKey: 'deckDebatesDesc', isProOnly: false),
  _DeckMeta(id: 'family', titleKey: 'deckFamily', descKey: 'deckFamilyDesc', isProOnly: false),
  // PRO Decks
  _DeckMeta(id: 'spicy', titleKey: 'deckSpicy', descKey: 'deckSpicyDesc', isProOnly: true),
  _DeckMeta(id: 'hot_takes', titleKey: 'deckHotTakes', descKey: 'deckHotTakesDesc', isProOnly: true),
  _DeckMeta(id: 'spicy_challenges', titleKey: 'deckSpicyChallenges', descKey: 'deckSpicyChallengesDesc', isProOnly: true),
  _DeckMeta(id: 'most_likely', titleKey: 'deckMostLikely', descKey: 'deckMostLikelyDesc', isProOnly: true),
  _DeckMeta(id: 'never_have_i', titleKey: 'deckNeverHaveI', descKey: 'deckNeverHaveIDesc', isProOnly: true),
  _DeckMeta(id: 'couples', titleKey: 'deckCouples', descKey: 'deckCouplesDesc', isProOnly: true),
  _DeckMeta(id: 'party', titleKey: 'deckParty', descKey: 'deckPartyDesc', isProOnly: true),
  _DeckMeta(id: 'challenges', titleKey: 'deckChallenges', descKey: 'deckChallengesDesc', isProOnly: true),
  _DeckMeta(id: 'travel', titleKey: 'deckTravel', descKey: 'deckTravelDesc', isProOnly: true),
];

class DecksScreen extends StatelessWidget {
  const DecksScreen({super.key});

  void _openDeck(
    BuildContext context, {
    required String categoryId,
    required String title,
    required bool isProOnly,
    required bool isPro,
  }) {
    final l10n = AppLocalizations.of(context);
    if (isProOnly && !isPro) {
      HapticsHelper.warning();
      PaywallSheet.show(context, customReason: l10n.t('proLockedDeck'));
      return;
    }

    HapticsHelper.selection();
    final cardService = AppServices.of(context).cardService;
    cardService.setCategoryFilter(categoryId);
    cardService.drawNextCard();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GamePlayScreen(
          singleDeckTitle: title,
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
    const proSet = {'couples', 'spicy', 'hot_takes', 'spicy_challenges', 'most_likely', 'never_have_i', 'party', 'challenges', 'travel'};
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
              const SizedBox(height: AppSpacing.md),

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
              // UNIFIED DECKS CATALOG (NOT SPLIT)
              // ==========================================
              ..._allDecks.map((deck) {
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

              // Custom user cards deck (if any exists)
              if (cardService.customCards.isNotEmpty)
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
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
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
          // Ambient decorative watermark of the category icon (noticeable brand art)
          Positioned(
            right: -12,
            top: -12,
            child: Icon(
              catStyle.icon,
              size: 130,
              color: catStyle.primary.withValues(alpha: isDark ? 0.18 : 0.12),
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
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Icon(
                      isLocked ? Icons.lock_outline_rounded : Icons.chevron_right_rounded,
                      color: isLocked ? const Color(0xFFD4AF37) : theme.colorScheme.onSurface.withValues(alpha: 0.35),
                      size: 22,
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
}
