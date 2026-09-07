import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/haptics_helper.dart';
import '../core/widgets/app_header_title.dart';
import '../core/widgets/paywall_sheet.dart';
import '../l10n/app_localizations.dart';
import '../models/card_item.dart';
import '../services/app_services.dart';
import '../services/card_service.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getLevelColor(int level) {
    switch (level) {
      case 1:
        return const Color(0xFF2D7A4F);
      case 2:
        return const Color(0xFFC85A3B);
      case 3:
        return const Color(0xFF8B5CF6);
      case 4:
        return const Color(0xFFE5BA5A);
      default:
        return const Color(0xFF3B82F6);
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

  Future<void> _showAddQuestionDialog(BuildContext context) async {
    final services = AppServices.of(context);
    final cardService = services.cardService;
    final premiumService = services.premiumService;
    final l10n = AppLocalizations.of(context);

    if (!premiumService.isPro && cardService.customCards.length >= 3) {
      PaywallSheet.show(
        context,
        customReason: l10n.t('proLimitCustom'),
      );
      return;
    }

    final textController = TextEditingController();
    int selectedLevel = 1;
    String selectedCategory = 'dates';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final theme = Theme.of(ctx);

            return Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusXl),
                ),
              ),
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.md,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.t('createQuestionTitle'),
                      style: AppTypography.display(theme.colorScheme.onSurface)
                          .copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Question Text Input
                    TextField(
                      controller: textController,
                      maxLines: 3,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: l10n.t('questionText'),
                        hintText: l10n.t('questionTextHint'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Level Selector
                    Text(
                      l10n.t('selectLevel'),
                      style: AppTypography.caption(theme.colorScheme.onSurfaceVariant, isMedium: true),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      children: [1, 2, 3, 4].map((lvl) {
                        final isSelected = selectedLevel == lvl;
                        return ChoiceChip(
                          label: Text(_getLevelName(lvl, l10n)),
                          selected: isSelected,
                          selectedColor: _getLevelColor(lvl),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                          onSelected: (val) {
                            if (val) setModalState(() => selectedLevel = lvl);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Category Selector
                    Text(
                      l10n.t('selectCategory'),
                      style: AppTypography.caption(theme.colorScheme.onSurfaceVariant, isMedium: true),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      children: [
                        'dates',
                        'couples',
                        'friends',
                        'challenges',
                      ].map((cat) {
                        final isSelected = selectedCategory == cat;
                        String catLabel = cat;
                        if (cat == 'dates') catLabel = l10n.t('deckDates');
                        if (cat == 'couples') catLabel = l10n.t('deckCouples');
                        if (cat == 'friends') catLabel = l10n.t('deckFriends');
                        if (cat == 'challenges') catLabel = l10n.t('deckChallenges');

                        return ChoiceChip(
                          label: Text(catLabel),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) setModalState(() => selectedCategory = cat);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(l10n.t('cancel')),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        ElevatedButton(
                          onPressed: () async {
                            final text = textController.text.trim();
                            if (text.isEmpty) return;
                            HapticsHelper.medium();
                            await cardService.addCustomCard(
                              text: text,
                              level: selectedLevel,
                              category: selectedCategory,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(l10n.t('save')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
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
        final favorites = cardService.favoriteCards;
        final customCards = cardService.customCards;
        final isPro = premiumService.isPro;

        return Scaffold(
          appBar: AppBar(
            title: AppHeaderTitle(
              title: l10n.t('favoritesTitle'),
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
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              indicatorColor: theme.colorScheme.primary,
              indicatorWeight: 3,
              tabs: [
                Tab(text: l10n.t('tabFavorites', args: {'count': favorites.length})),
                Tab(text: l10n.t('tabCustom', args: {'count': customCards.length})),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Favorites List
              favorites.isEmpty
                  ? _buildEmptyView(
                      context,
                      icon: Icons.star_border_rounded,
                      title: l10n.t('noFavoritesTitle'),
                      subtitle: l10n.t('noFavoritesDesc'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: favorites.length,
                      itemBuilder: (context, index) {
                        final card = favorites[index];
                        return _buildCardItemTile(
                          context,
                          card: card,
                          cardService: cardService,
                          l10n: l10n,
                          isCustom: false,
                        );
                      },
                    ),

              // Tab 2: Custom Questions List
              customCards.isEmpty
                  ? _buildEmptyView(
                      context,
                      icon: Icons.edit_note_rounded,
                      title: l10n.t('noCustomTitle'),
                      subtitle: l10n.t('noCustomDesc'),
                      actionLabel: l10n.t('newQuestion'),
                      onAction: () => _showAddQuestionDialog(context),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(
                        left: AppSpacing.md,
                        right: AppSpacing.md,
                        top: AppSpacing.md,
                        bottom: 80,
                      ),
                      itemCount: customCards.length,
                      itemBuilder: (context, index) {
                        final card = customCards[index];
                        return _buildCardItemTile(
                          context,
                          card: card,
                          cardService: cardService,
                          l10n: l10n,
                          isCustom: true,
                        );
                      },
                    ),
            ],
          ),
          floatingActionButton: AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              if (_tabController.index == 1) {
                return FloatingActionButton.extended(
                  onPressed: () => _showAddQuestionDialog(context),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(l10n.t('newQuestion')),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        );
      },
    );
  }

  Widget _buildCardItemTile(
    BuildContext context, {
    required CardItem card,
    required CardService cardService,
    required AppLocalizations l10n,
    required bool isCustom,
  }) {
    final theme = Theme.of(context);
    final levelColor = _getLevelColor(card.level);
    final isSpanish = l10n.locale.languageCode == 'es';
    final cardText = (isSpanish || card.textEn.isEmpty) ? card.textEs : card.textEn;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.18),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: levelColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _getLevelName(card.level, l10n),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: levelColor,
                    ),
                  ),
                ),
                const Spacer(),
                if (isCustom)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    color: theme.colorScheme.error,
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(l10n.t('delete')),
                          content: Text(l10n.t('deleteQuestionConfirm')),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(l10n.t('cancel')),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.error,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(l10n.t('delete')),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        HapticsHelper.medium();
                        cardService.deleteCustomCard(card.id);
                      }
                    },
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.star_rounded, size: 22, color: Color(0xFFE5BA5A)),
                    onPressed: () {
                      HapticsHelper.light();
                      cardService.toggleFavorite(card);
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.share_rounded, size: 20),
                  onPressed: () {
                    HapticsHelper.light();
                    Share.share(l10n.t('shareText', args: {'text': cardText}));
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              cardText,
              style: AppTypography.body(theme.colorScheme.onSurface, isMedium: true)
                  .copyWith(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 56,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: AppTypography.body(theme.colorScheme.onSurface, isMedium: true)
                  .copyWith(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: AppTypography.caption(
                theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_rounded),
                label: Text(actionLabel),
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
