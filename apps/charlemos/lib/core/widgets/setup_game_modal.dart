import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_category_theme.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/haptics_helper.dart';
import 'paywall_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../../services/app_services.dart';

class SetupGameModal extends StatefulWidget {
  final Function(List<String> players, Set<String> categories) onStartGame;

  const SetupGameModal({super.key, required this.onStartGame});

  static void show(
    BuildContext context, {
    required Function(List<String> players, Set<String> categories) onStartGame,
  }) {
    HapticsHelper.selection();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SetupGameModal(onStartGame: onStartGame),
    );
  }

  @override
  State<SetupGameModal> createState() => _SetupGameModalState();
}

class _SetupGameModalState extends State<SetupGameModal> {
  final List<String> _players = [];
  final Set<String> _selectedCategories = {'dates', 'friends'};
  final TextEditingController _playerController = TextEditingController();

  static const String _keyStoredPlayers = 'charlemos_saved_players';

  @override
  void initState() {
    super.initState();
    _loadSavedPlayers();
  }

  @override
  void dispose() {
    _playerController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedPlayers() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_keyStoredPlayers);
    if (saved != null && saved.isNotEmpty) {
      setState(() {
        _players.addAll(saved);
      });
    } else {
      setState(() {
        _players.addAll(['Jugador 1', 'Jugador 2']);
      });
    }
  }

  Future<void> _savePlayers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyStoredPlayers, _players);
  }

  void _addPlayer() {
    final name = _playerController.text.trim();
    if (name.isNotEmpty) {
      HapticsHelper.medium();
      setState(() {
        _players.add(name);
        _playerController.clear();
      });
      _savePlayers();
    }
  }

  void _removePlayer(int index) {
    HapticsHelper.selection();
    setState(() {
      _players.removeAt(index);
    });
    _savePlayers();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final premium = AppServices.of(context).premiumService;
    final isPro = premium.isPro;

    final cardService = AppServices.of(context).cardService;
    final categories = [
      {'id': 'dates', 'name': l10n.t('deckDates'), 'isPro': false},
      {'id': 'friends', 'name': l10n.t('deckFriends'), 'isPro': false},
      {'id': 'debates', 'name': l10n.t('deckDebates'), 'isPro': false},
      {'id': 'family', 'name': l10n.t('deckFamily'), 'isPro': false},
      if (cardService.customCards.isNotEmpty)
        {'id': 'custom', 'name': l10n.t('deckCustom'), 'isPro': false},
      {'id': 'couples', 'name': l10n.t('deckCouples'), 'isPro': true},
      {'id': 'spicy', 'name': l10n.t('deckSpicy'), 'isPro': true},
      {'id': 'couples_challenges', 'name': l10n.t('deckCouplesChallenges'), 'isPro': true},
      {'id': 'hot_takes', 'name': l10n.t('deckHotTakes'), 'isPro': true},
      {'id': 'spicy_challenges', 'name': l10n.t('deckSpicyChallenges'), 'isPro': true},
      {'id': 'most_likely', 'name': l10n.t('deckMostLikely'), 'isPro': true},
      {'id': 'never_have_i', 'name': l10n.t('deckNeverHaveI'), 'isPro': true},
      {'id': 'party', 'name': l10n.t('deckParty'), 'isPro': true},
      {'id': 'challenges', 'name': l10n.t('deckChallenges'), 'isPro': true},
      {'id': 'travel', 'name': l10n.t('deckTravel'), 'isPro': true},
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
        maxHeight: MediaQuery.of(context).size.height * 0.9,
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.groups_rounded, color: theme.colorScheme.primary, size: 24),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.t('setupGameTitle'),
                      style: AppTypography.title(theme.colorScheme.onSurface),
                    ),
                    Text(
                      l10n.t('playModeTitle'),
                      style: AppTypography.caption(theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Categories selection
                  Text(
                    l10n.t('selectCategories'),
                    style: AppTypography.body(theme.colorScheme.onSurface, isMedium: true),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: categories.map((cat) {
                      final id = cat['id'] as String;
                      final name = cat['name'] as String;
                      final catIsPro = cat['isPro'] as bool;
                      final isSelected = _selectedCategories.contains(id);
                      final style = AppCategoryTheme.of(id);

                      return FilterChip(
                        selected: isSelected,
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              style.icon,
                              size: 16,
                              color: isSelected ? Colors.white : style.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(name),
                            if (catIsPro && !isPro) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.lock_rounded, size: 12, color: Color(0xFFE5BA5A)),
                            ],
                          ],
                        ),
                        selectedColor: style.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 13,
                        ),
                        showCheckmark: false,
                        onSelected: (selected) {
                          HapticsHelper.selection();
                          if (catIsPro && !isPro) {
                            PaywallSheet.show(context, customReason: l10n.t('proLockedDeck'));
                            return;
                          }
                          setState(() {
                            if (selected) {
                              _selectedCategories.add(id);
                            } else {
                              if (_selectedCategories.length > 1) {
                                _selectedCategories.remove(id);
                              }
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // 2. Players selection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.t('playersTitle'),
                        style: AppTypography.body(theme.colorScheme.onSurface, isMedium: true),
                      ),
                      Text(
                        '${_players.length} jugadores',
                        style: AppTypography.caption(theme.colorScheme.primary, isMedium: true),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Players Chip List
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: List.generate(_players.length, (idx) {
                      final name = _players[idx];
                      return Chip(
                        avatar: CircleAvatar(
                          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        label: Text(name),
                        deleteIcon: const Icon(Icons.close_rounded, size: 16),
                        onDeleted: _players.length > 2 ? () => _removePlayer(idx) : null,
                      );
                    }),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Add Player input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _playerController,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            hintText: l10n.t('playerNameHint'),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                          ),
                          onSubmitted: (_) => _addPlayer(),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      IconButton.filled(
                        icon: const Icon(Icons.add_rounded),
                        tooltip: l10n.t('addPlayer'),
                        onPressed: _addPlayer,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Start Button
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow_rounded, size: 24),
              label: Text(
                l10n.t('startGame'),
                style: AppTypography.body(Colors.white, isMedium: true).copyWith(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              onPressed: _players.length >= 2 && _selectedCategories.isNotEmpty
                  ? () {
                      HapticsHelper.medium();
                      Navigator.pop(context);
                      widget.onStartGame(_players, _selectedCategories);
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
