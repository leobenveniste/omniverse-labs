import 'package:flutter/material.dart';
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
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: SizedBox(
            height: 72,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Floating Bar Container
                Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E261C) : Colors.white,
                    borderRadius: BorderRadius.circular(36),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                        spreadRadius: 2,
                      ),
                    ],
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: isDark ? 0.3 : 0.5),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Left Section: 0: Recipes, 1: Planner
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildNavItem(
                              index: 0,
                              emoji: '📖',
                              icon: Icons.home_outlined,
                              activeIcon: Icons.home_rounded,
                              tooltip: strings.tabRecipes,
                              theme: theme,
                            ),
                            _buildNavItem(
                              index: 1,
                              emoji: '🗓️',
                              icon: Icons.calendar_month_outlined,
                              activeIcon: Icons.calendar_month_rounded,
                              tooltip: strings.tabPlanner,
                              theme: theme,
                            ),
                          ],
                        ),
                      ),

                      // Center Space for elevated button
                      const SizedBox(width: 68),

                      // Right Section: 2: Shopping, 3: Settings
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildNavItem(
                              index: 2,
                              emoji: '🛒',
                              icon: Icons.format_list_bulleted_rounded,
                              activeIcon: Icons.format_list_bulleted_rounded,
                              tooltip: strings.tabShopping,
                              theme: theme,
                            ),
                            _buildNavItem(
                              index: 3,
                              emoji: '⚙️',
                              icon: Icons.settings_outlined,
                              activeIcon: Icons.settings_rounded,
                              tooltip: strings.tabSettings,
                              theme: theme,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Center Notch Background Circle (cutout effect)
                if (_currentIndex != 3) ...[
                  Positioned(
                    top: -12,
                    child: Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF131912) : const Color(0xFFF7F8F7),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  // Center Prominent Elevated Action Button (+)
                  Positioned(
                    top: -8,
                    child: GestureDetector(
                      onTap: () => _onCenterActionPressed(context),
                      child: Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.primary.withValues(alpha: 0.88),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.4),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.add_rounded, color: Colors.white, size: 32),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String emoji,
    required IconData icon,
    required IconData activeIcon,
    required String tooltip,
    required ThemeData theme,
  }) {
    final isSelected = _currentIndex == index;
    final primaryColor = theme.colorScheme.primary;
    final unselectedColor = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6);

    return InkWell(
      onTap: () {
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
      borderRadius: BorderRadius.circular(24),
      splashColor: primaryColor.withValues(alpha: 0.1),
      highlightColor: Colors.transparent,
      child: Tooltip(
        message: tooltip,
        child: SizedBox(
          width: 52,
          height: 64,
          child: Center(
            child: AnimatedScale(
              scale: isSelected ? 1.18 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: Icon(
                isSelected ? activeIcon : icon,
                size: 26,
                color: isSelected ? primaryColor : unselectedColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
