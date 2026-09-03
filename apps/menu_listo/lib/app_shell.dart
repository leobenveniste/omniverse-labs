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
              foregroundColor: Colors.white,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.add_rounded, size: 28),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.35 : 0.08,
              ),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              width: 0.8,
            ),
          ),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            height: 64,
            backgroundColor: theme.colorScheme.surfaceContainer,
            elevation: 0,
            indicatorColor: theme.colorScheme.secondaryContainer,
            indicatorShape: const StadiumBorder(),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              final isSelected = states.contains(WidgetState.selected);
              return IconThemeData(
                size: 26,
                color: isSelected
                    ? theme.colorScheme.onSecondaryContainer
                    : theme.colorScheme.onSurfaceVariant,
              );
            }),
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
            onDestinationSelected: (index) {
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
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.menu_book_outlined),
                selectedIcon: const Icon(Icons.menu_book_rounded),
                label: strings.tabRecipes,
                tooltip: strings.tabRecipes,
              ),
              NavigationDestination(
                icon: const Icon(Icons.calendar_month_outlined),
                selectedIcon: const Icon(Icons.calendar_month_rounded),
                label: strings.tabPlanner,
                tooltip: strings.tabPlanner,
              ),
              NavigationDestination(
                icon: const Icon(Icons.shopping_cart_outlined),
                selectedIcon: const Icon(Icons.shopping_cart_rounded),
                label: strings.tabShopping,
                tooltip: strings.tabShopping,
              ),
              NavigationDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings_rounded),
                label: strings.tabSettings,
                tooltip: strings.tabSettings,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
