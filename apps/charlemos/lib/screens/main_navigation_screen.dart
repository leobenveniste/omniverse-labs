import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/haptics_helper.dart';
import '../core/widgets/paywall_sheet.dart';
import '../core/widgets/setup_game_modal.dart';
import '../l10n/app_localizations.dart';
import '../services/app_services.dart';
import 'decks_screen.dart';
import 'favorites_screen.dart';
import 'gameplay_screen.dart';
import 'settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDailyPromo();
    });
  }

  Future<void> _checkDailyPromo() async {
    try {
      final premium = AppServices.of(context).premiumService;
      if (premium.isPro) return;

      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      final lastTimestamp = prefs.getInt('last_charlemos_pro_promo_timestamp');
      const fourDaysMs = 4 * 24 * 60 * 60 * 1000;

      if (lastTimestamp == null || (now - lastTimestamp) >= fourDaysMs) {
        await prefs.setInt('last_charlemos_pro_promo_timestamp', now);
        if (mounted) {
          PaywallSheet.show(context);
        }
      }
    } catch (_) {}
  }

  void _openGroupGameModal() {
    HapticsHelper.medium();
    SetupGameModal.show(
      context,
      onStartGame: (players, categories) {
        final cardService = AppServices.of(context).cardService;
        cardService.setMultiCategoryFilter(categories);

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const GamePlayScreen(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    // 3 main tabs: Decks (0), Favorites (1), Settings (2)
    final screens = const [
      DecksScreen(),
      FavoritesScreen(),
      SettingsScreen(),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: screens[_currentIndex],
        ),
      ),
      floatingActionButton: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.secondary,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.45),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _openGroupGameModal,
            child: Tooltip(
              message: l10n.t('navPlay'),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.play_arrow_rounded,
                    color: theme.colorScheme.onPrimary,
                    size: 30,
                  ),
                  Text(
                    l10n.t('navPlay'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        elevation: 8,
        padding: EdgeInsets.zero,
        height: 64,
        color: theme.colorScheme.surface,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Tab 0: Decks
            _buildNavItem(
              index: 0,
              icon: Icons.dashboard_outlined,
              activeIcon: Icons.dashboard_rounded,
              label: l10n.t('navDecks'),
            ),
            // Spacer for center docked Play FAB
            const SizedBox(width: 54),
            // Tab 1: Favorites
            _buildNavItem(
              index: 1,
              icon: Icons.star_outline_rounded,
              activeIcon: Icons.star_rounded,
              label: l10n.t('navFavorites'),
            ),
            // Tab 2: Settings
            _buildNavItem(
              index: 2,
              icon: Icons.settings_outlined,
              activeIcon: Icons.settings_rounded,
              label: l10n.t('navSettings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final theme = Theme.of(context);
    final isSelected = _currentIndex == index;
    final color = isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: InkWell(
          onTap: () {
            HapticsHelper.selection();
            setState(() => _currentIndex = index);
          },
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
