import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../providers/meal_planner_provider.dart';
import 'recipe_picker_sheet.dart';

class QuickPlanMealSheet extends ConsumerStatefulWidget {
  const QuickPlanMealSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const QuickPlanMealSheet(),
    );
  }

  @override
  ConsumerState<QuickPlanMealSheet> createState() => _QuickPlanMealSheetState();
}

class _QuickPlanMealSheetState extends ConsumerState<QuickPlanMealSheet> {
  int _selectedDayOffset = 0;
  String _selectedSlot = 'lunch';

  @override
  void initState() {
    super.initState();
    // Default to today's weekday offset
    final weekday = DateTime.now().weekday; // 1 = Mon, 7 = Sun
    _selectedDayOffset = (weekday - 1).clamp(0, 6);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final weekStart = ref.watch(currentWeekStartProvider);

    final days = [
      {'name': strings.isSpanish ? 'Lun' : 'Mon', 'offset': 0},
      {'name': strings.isSpanish ? 'Mar' : 'Tue', 'offset': 1},
      {'name': strings.isSpanish ? 'Mié' : 'Wed', 'offset': 2},
      {'name': strings.isSpanish ? 'Jue' : 'Thu', 'offset': 3},
      {'name': strings.isSpanish ? 'Vie' : 'Fri', 'offset': 4},
      {'name': strings.isSpanish ? 'Sáb' : 'Sat', 'offset': 5},
      {'name': strings.isSpanish ? 'Dom' : 'Sun', 'offset': 6},
    ];

    final slots = [
      {'id': 'breakfast', 'name': strings.mealBreakfast, 'emoji': '☕', 'icon': Icons.wb_twilight},
      {'id': 'lunch', 'name': strings.mealLunch, 'emoji': '🍲', 'icon': Icons.wb_sunny_outlined},
      {'id': 'snack', 'name': strings.mealSnack, 'emoji': '🥐', 'icon': Icons.coffee_outlined},
      {'id': 'dinner', 'name': strings.mealDinner, 'emoji': '🌙', 'icon': Icons.nightlight_outlined},
    ];

    final targetDate = weekStart.add(Duration(days: _selectedDayOffset));
    final dateStr = DateFormat('yyyy-MM-dd').format(targetDate);
    final formattedDate = DateFormat('EEEE d MMMM', strings.isSpanish ? 'es' : 'en').format(targetDate);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Text('🪄', style: TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.isSpanish ? 'Planificar en la Agenda' : 'Plan a Meal',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        strings.isSpanish ? 'Elige el momento perfecto para tu comida' : 'Pick the perfect moment for your meal',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Step 1: Select Day
            Text(
              strings.isSpanish ? '1. Selecciona el día:' : '1. Select day:',
              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: days.map((d) {
                  final offset = d['offset'] as int;
                  final dayDate = weekStart.add(Duration(days: offset));
                  final isSelected = _selectedDayOffset == offset;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: isSelected,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      label: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(d['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(DateFormat('d').format(dayDate), style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                      onSelected: (_) => setState(() => _selectedDayOffset = offset),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 18),

            // Step 2: Select Slot
            Text(
              strings.isSpanish ? '2. Momento de la comida:' : '2. Meal moment:',
              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: slots.map((s) {
                final id = s['id'] as String;
                final isSelected = _selectedSlot == id;

                return ChoiceChip(
                  avatar: Text(s['emoji'] as String, style: const TextStyle(fontSize: 16)),
                  selected: isSelected,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  label: Text(s['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                  onSelected: (_) => setState(() => _selectedSlot = id),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Button to Choose Recipe
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.restaurant_menu_rounded),
                label: Text(
                  strings.isSpanish ? 'Elegir receta para planificar' : 'Choose Recipe',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                onPressed: () {
                  Navigator.of(context).pop();

                  final slotName = slots.firstWhere((s) => s['id'] == _selectedSlot)['name'] as String;
                  RecipePickerSheet.show(
                    context,
                    slotTitle: '$formattedDate ($slotName)',
                    onRecipeSelected: (recipe, servings) {
                      ref.read(weeklyMealPlanProvider.notifier).assignMeal(
                            dateString: dateStr,
                            mealType: _selectedSlot,
                            recipeId: recipe.id,
                            recipeTitle: recipe.title,
                            recipeCategory: recipe.category,
                            servings: servings,
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: theme.colorScheme.primary,
                          content: Text(
                            strings.isSpanish
                                ? '✨ ¡"${recipe.title}" agregada a la agenda!'
                                : '✨ "${recipe.title}" added to planner!',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                    onCustomEntered: (customName, servings) {
                      ref.read(weeklyMealPlanProvider.notifier).assignMeal(
                            dateString: dateStr,
                            mealType: _selectedSlot,
                            recipeTitle: customName,
                            servings: servings,
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: theme.colorScheme.primary,
                          content: Text(
                            strings.isSpanish
                                ? '✨ ¡"$customName" agregada a la agenda!'
                                : '✨ "$customName" added to planner!',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
