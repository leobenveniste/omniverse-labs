import 'package:flutter/material.dart';
import '../theme/app_category_theme.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/haptics_helper.dart';
import 'paywall_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../../services/app_services.dart';

class CategorySelectModal extends StatefulWidget {
  final Function(Set<String> categories) onCategoriesSelected;

  const CategorySelectModal({super.key, required this.onCategoriesSelected});

  static void show(
    BuildContext context, {
    required Function(Set<String> categories) onCategoriesSelected,
  }) {
    HapticsHelper.selection();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CategorySelectModal(onCategoriesSelected: onCategoriesSelected),
    );
  }

  @override
  State<CategorySelectModal> createState() => _CategorySelectModalState();
}

class _CategorySelectModalState extends State<CategorySelectModal> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    final cardService = AppServices.of(context).cardService;
    if (cardService.activeMultiCategories.isNotEmpty) {
      _selected = Set.from(cardService.activeMultiCategories);
    } else if (cardService.selectedCategory != 'all') {
      _selected = {cardService.selectedCategory};
    } else {
      _selected = {'dates', 'friends'};
    }
  }

  void _applyPreset(Set<String> preset, bool isPro) {
    HapticsHelper.selection();
    setState(() {
      _selected = Set.from(preset);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final services = AppServices.of(context);
    final cardService = services.cardService;
    final premium = services.premiumService;
    final isPro = premium.isPro;

    final categories = [
      // Free Decks
      {'id': 'dates', 'name': l10n.t('deckDates'), 'desc': l10n.t('deckDatesDesc'), 'isPro': false},
      {'id': 'friends', 'name': l10n.t('deckFriends'), 'desc': l10n.t('deckFriendsDesc'), 'isPro': false},
      {'id': 'debates', 'name': l10n.t('deckDebates'), 'desc': l10n.t('deckDebatesDesc'), 'isPro': false},
      {'id': 'family', 'name': l10n.t('deckFamily'), 'desc': l10n.t('deckFamilyDesc'), 'isPro': false},
      if (cardService.customCards.isNotEmpty)
        {'id': 'custom', 'name': l10n.t('deckCustom'), 'desc': l10n.t('deckCustomDesc'), 'isPro': false},
      // Pro Decks
      {'id': 'couples', 'name': l10n.t('deckCouples'), 'desc': l10n.t('deckCouplesDesc'), 'isPro': true},
      {'id': 'spicy', 'name': l10n.t('deckSpicy'), 'desc': l10n.t('deckSpicyDesc'), 'isPro': true},
      {'id': 'couples_challenges', 'name': l10n.t('deckCouplesChallenges'), 'desc': l10n.t('deckCouplesChallengesDesc'), 'isPro': true},
      {'id': 'hot_takes', 'name': l10n.t('deckHotTakes'), 'desc': l10n.t('deckHotTakesDesc'), 'isPro': true},
      {'id': 'spicy_challenges', 'name': l10n.t('deckSpicyChallenges'), 'desc': l10n.t('deckSpicyChallengesDesc'), 'isPro': true},
      {'id': 'most_likely', 'name': l10n.t('deckMostLikely'), 'desc': l10n.t('deckMostLikelyDesc'), 'isPro': true},
      {'id': 'never_have_i', 'name': l10n.t('deckNeverHaveI'), 'desc': l10n.t('deckNeverHaveIDesc'), 'isPro': true},
      {'id': 'party', 'name': l10n.t('deckParty'), 'desc': l10n.t('deckPartyDesc'), 'isPro': true},
      {'id': 'challenges', 'name': l10n.t('deckChallenges'), 'desc': l10n.t('deckChallengesDesc'), 'isPro': true},
      {'id': 'travel', 'name': l10n.t('deckTravel'), 'desc': l10n.t('deckTravelDesc'), 'isPro': true},
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.t('selectCategories'),
                    style: AppTypography.title(theme.colorScheme.onSurface).copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.t('selectCategoriesHint'),
                    style: AppTypography.caption(theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                  ),
                ],
              ),
              if (!isPro)
                GestureDetector(
                  onTap: () => PaywallSheet.show(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFDF00), Color(0xFFD4AF37)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_rounded, size: 12, color: Color(0xFF2A1B00)),
                        SizedBox(width: 4),
                        Text(
                          'PRO',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF2A1B00),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Ambient Fast Presets Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ActionChip(
                  avatar: const Text('🔥', style: TextStyle(fontSize: 13)),
                  label: Text(l10n.t('presetSpicyNight')),
                  onPressed: () {
                    if (!isPro) {
                      PaywallSheet.show(context, customReason: l10n.t('proLockedDeck'));
                      return;
                    }
                    _applyPreset({'couples', 'spicy'}, isPro);
                  },
                ),
                const SizedBox(width: AppSpacing.xs),
                ActionChip(
                  avatar: const Text('🌶️', style: TextStyle(fontSize: 13)),
                  label: Text(l10n.t('presetSpicyDares')),
                  onPressed: () {
                    if (!isPro) {
                      PaywallSheet.show(context, customReason: l10n.t('proLockedDeck'));
                      return;
                    }
                    _applyPreset({'spicy', 'spicy_challenges', 'hot_takes'}, isPro);
                  },
                ),
                const SizedBox(width: AppSpacing.xs),
                ActionChip(
                  avatar: const Text('👥', style: TextStyle(fontSize: 13)),
                  label: Text(l10n.t('presetGroupParty')),
                  onPressed: () {
                    if (!isPro) {
                      PaywallSheet.show(context, customReason: l10n.t('proLockedDeck'));
                      return;
                    }
                    _applyPreset({'most_likely', 'never_have_i', 'party'}, isPro);
                  },
                ),
                const SizedBox(width: AppSpacing.xs),
                ActionChip(
                  avatar: const Text('🎉', style: TextStyle(fontSize: 13)),
                  label: Text(l10n.t('presetTheParty')),
                  onPressed: () {
                    if (!isPro) {
                      PaywallSheet.show(context, customReason: l10n.t('proLockedDeck'));
                      return;
                    }
                    _applyPreset({'party', 'hot_takes', 'friends'}, isPro);
                  },
                ),
                const SizedBox(width: AppSpacing.xs),
                ActionChip(
                  avatar: const Text('❤️', style: TextStyle(fontSize: 13)),
                  label: Text(l10n.t('presetDatesCouples')),
                  onPressed: () => _applyPreset({'dates', 'friends'}, isPro),
                ),
                const SizedBox(width: AppSpacing.xs),
                ActionChip(
                  avatar: const Text('🏡', style: TextStyle(fontSize: 13)),
                  label: Text(l10n.t('presetFamilyRoots')),
                  onPressed: () => _applyPreset({'family', 'friends'}, isPro),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Category Cards List
          Expanded(
            child: ListView.separated(
              itemCount: categories.length,
              separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.xs),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final id = cat['id'] as String;
                final name = cat['name'] as String;
                final desc = cat['desc'] as String;
                final catIsPro = cat['isPro'] as bool;
                final isSelected = _selected.contains(id);
                final catStyle = AppCategoryTheme.of(id);

                final cardBg = isSelected
                    ? (isDark ? catStyle.backgroundDark : catStyle.backgroundLight)
                    : theme.colorScheme.surface;
                final cardBorder = isSelected
                    ? catStyle.primary
                    : theme.colorScheme.outline.withValues(alpha: 0.2);

                return Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: cardBorder,
                      width: isSelected ? 2.0 : 1.0,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      onTap: () {
                        HapticsHelper.selection();
                        if (catIsPro && !isPro) {
                          PaywallSheet.show(context, customReason: l10n.t('proLockedDeck'));
                          return;
                        }

                        setState(() {
                          if (isSelected) {
                            if (_selected.length > 1) {
                              _selected.remove(id);
                            }
                          } else {
                            _selected.add(id);
                          }
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs + 2),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 38,
                              height: 38,
                              child: Center(
                                child: Icon(
                                  catStyle.icon,
                                  color: catStyle.primary,
                                  size: 32,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        name,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                          color: isSelected ? catStyle.primary : theme.colorScheme.onSurface,
                                        ),
                                      ),
                                      if (catIsPro && !isPro) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFDF00),
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.lock_rounded, size: 10, color: Color(0xFF2A1B00)),
                                              SizedBox(width: 2),
                                              Text(
                                                'PRO',
                                                style: TextStyle(
                                                  color: Color(0xFF2A1B00),
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    desc,
                                    style: AppTypography.caption(
                                      theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Checkbox(
                              value: isSelected,
                              activeColor: catStyle.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              onChanged: (val) {
                                if (catIsPro && !isPro) {
                                  PaywallSheet.show(context, customReason: l10n.t('proLockedDeck'));
                                  return;
                                }
                                HapticsHelper.selection();
                                setState(() {
                                  if (val == true) {
                                    _selected.add(id);
                                  } else {
                                    if (_selected.length > 1) {
                                      _selected.remove(id);
                                    }
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Play CTA Button
          ElevatedButton(
            onPressed: () {
              HapticsHelper.medium();
              Navigator.pop(context);
              widget.onCategoriesSelected(_selected);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
              elevation: 4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_arrow_rounded, size: 24),
                const SizedBox(width: 6),
                Text(
                  '${l10n.t('playBtn')} (${_selected.length} mazos)',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
