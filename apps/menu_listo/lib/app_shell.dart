import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/localization/app_localizations.dart';
import 'features/recipes/presentation/recipes_list_screen.dart';
import 'features/recipes/presentation/widgets/recipe_creation_options_sheet.dart';
import 'features/meal_planner/presentation/weekly_planner_screen.dart';
import 'features/meal_planner/presentation/widgets/quick_plan_meal_sheet.dart';
import 'features/shopping_list/presentation/shopping_list_screen.dart';
import 'features/shopping_list/presentation/widgets/add_item_dialog.dart';
import 'features/shopping_list/providers/shopping_provider.dart';
import 'features/settings/presentation/settings_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  // Tabs: 0: Recipes (Home - first in list), 1: Planner, 2: Shopping, 3: Settings
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    RecipesListScreen(),
    WeeklyPlannerScreen(),
    ShoppingListScreen(),
    SettingsScreen(),
  ];

  void _onCenterActionPressed(BuildContext context) {
    if (_currentIndex == 1) {
      QuickPlanMealSheet.show(context);
    } else if (_currentIndex == 2) {
      AddShoppingItemDialog.show(
        context,
        onAdd: (name, amount, unit) {
          ref.read(shoppingListProvider.notifier).addItem(
                name: name,
                amount: amount,
                unit: unit,
              );
        },
      );
    } else {
      showRecipeCreationOptions(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButton: _currentIndex == 3
          ? null
          : FloatingActionButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                _onCenterActionPressed(context);
              },
              backgroundColor: theme.colorScheme.primary,
              elevation: 4,
              shape: const CircleBorder(),
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.88),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.add_rounded, color: Colors.white, size: 32),
                ),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
            child: AnimatedBottomNavigationBar.builder(
              itemCount: 4,
              tabBuilder: (int index, bool isActive) {
                final icons = [
                  isActive ? Icons.menu_book_rounded : Icons.menu_book_outlined,
                  isActive ? Icons.calendar_month_rounded : Icons.calendar_month_outlined,
                  Icons.format_list_bulleted_rounded,
                  isActive ? Icons.settings_rounded : Icons.settings_outlined,
                ];
                final tooltips = [
                  strings.tabRecipes,
                  strings.tabPlanner,
                  strings.tabShopping,
                  strings.tabSettings,
                ];
                final primaryColor = theme.colorScheme.primary;
                final unselectedColor = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6);

                return Tooltip(
                  message: tooltips[index],
                  child: Center(
                    child: Icon(
                      icons[index],
                      size: 26,
                      color: isActive ? primaryColor : unselectedColor,
                    ),
                  ),
                );
              },
              activeIndex: _currentIndex,
              gapLocation: _currentIndex == 3 ? GapLocation.none : GapLocation.center,
              notchSmoothness: _currentIndex == 3 ? NotchSmoothness.sharpEdge : NotchSmoothness.verySmoothEdge,
              notchMargin: 8,
              leftCornerRadius: 28,
              rightCornerRadius: 28,
              height: 64,
              backgroundColor: isDark ? const Color(0xFF232E20) : Colors.white,
              splashColor: theme.colorScheme.primary.withValues(alpha: 0.2),
              splashRadius: 26,
              splashSpeedInMilliseconds: 300,
              elevation: 8,
              shadow: Shadow(
                color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
              borderColor: isDark
                  ? Colors.white.withValues(alpha: 0.16)
                  : theme.colorScheme.outline.withValues(alpha: 0.4),
              borderWidth: 1.2,
              onTap: (index) {
                HapticFeedback.selectionClick();
                if (_currentIndex != index) {
                  setState(() => _currentIndex = index);
                  if (index == 1) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) WeeklyPlannerScreen.showGuideIfFirstTime(context);
                    });
                  } else if (index == 2) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) ShoppingListScreen.showGuideIfFirstTime(context);
                    });
                  }
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
