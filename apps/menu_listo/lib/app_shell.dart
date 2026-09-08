import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/localization/app_localizations.dart';
import 'features/premium/presentation/paywall_sheet.dart';
import 'features/premium/providers/premium_provider.dart';
import 'features/recipes/presentation/recipes_list_screen.dart';
import 'features/meal_planner/presentation/weekly_planner_screen.dart';
import 'features/shopping_list/presentation/shopping_list_screen.dart';
import 'features/settings/presentation/settings_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  // Tabs: 0: Planner, 1: Shopping, 2: Recipes (Center Hero Action - Default), 3: Settings
  int _currentIndex = 2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDailyPromo();
    });
  }

  Future<void> _checkDailyPromo() async {
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    final isPro = ref.read(premiumProvider).isProUser;
    if (isPro) return;

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    final lastPromoTimestamp = prefs.getInt('last_pro_promo_timestamp');
    const fourDaysMs = 4 * 24 * 60 * 60 * 1000;

    if (lastPromoTimestamp == null || (now - lastPromoTimestamp) >= fourDaysMs) {
      await prefs.setInt('last_pro_promo_timestamp', now);
      if (mounted) {
        PaywallSheet.show(context);
      }
    }
  }

  // Screens mapped to bottom bar:
  // 0: Planner (Agenda)
  // 1: Shopping (Compras)
  // 2: Recipes (Center Hero Action - Recetas)
  // 3: Settings (Ajustes)
  final List<Widget> _screens = const [
    WeeklyPlannerScreen(),
    ShoppingListScreen(),
    RecipesListScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButton: Container(
        width: 58,
        height: 58,
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
              color: theme.colorScheme.primary.withValues(alpha: 0.38),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              HapticFeedback.mediumImpact();
              if (_currentIndex != 2) {
                setState(() => _currentIndex = 2);
              }
            },
            child: Tooltip(
              message: strings.tabRecipes,
              child: Icon(
                Icons.menu_book_rounded,
                color: theme.colorScheme.onPrimary,
                size: 26,
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
            _buildNavItem(
              index: 0,
              icon: Icons.calendar_month_outlined,
              activeIcon: Icons.calendar_month_rounded,
              label: strings.tabPlanner,
            ),
            _buildNavItem(
              index: 1,
              icon: Icons.shopping_cart_outlined,
              activeIcon: Icons.shopping_cart_rounded,
              label: strings.tabShopping,
            ),
            const SizedBox(width: 48), // Center spacing for notched Recipes button
            _buildNavItem(
              index: 2,
              icon: Icons.menu_book_outlined,
              activeIcon: Icons.menu_book_rounded,
              label: strings.tabRecipes,
            ),
            _buildNavItem(
              index: 3,
              icon: Icons.settings_outlined,
              activeIcon: Icons.settings_rounded,
              label: strings.tabSettings,
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
    final color = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            if (_currentIndex != index) {
              setState(() => _currentIndex = index);
            }
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
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
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
