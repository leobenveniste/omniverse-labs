import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:menu_listo/core/localization/app_localizations.dart';
import '../models/meal_plan_model.dart';
import '../providers/meal_planner_provider.dart';
import 'widgets/meal_slot_card.dart';
import 'widgets/recipe_picker_sheet.dart';

class WeeklyPlannerScreen extends ConsumerWidget {
  const WeeklyPlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final weekStart = ref.watch(currentWeekStartProvider);
    final weekStartNotifier = ref.read(currentWeekStartProvider.notifier);
    final weekPlanAsync = ref.watch(weeklyMealPlanProvider);
    final weekPlanNotifier = ref.read(weeklyMealPlanProvider.notifier);

    final weekEnd = weekStart.add(const Duration(days: 6));
    final weekFormat = DateFormat('d MMM', strings.isSpanish ? 'es' : 'en');
    final weekRangeTitle = '${weekFormat.format(weekStart)} - ${weekFormat.format(weekEnd)}';

    final days = [
      {'name': strings.isSpanish ? 'Lunes' : 'Monday', 'offset': 0},
      {'name': strings.isSpanish ? 'Martes' : 'Tuesday', 'offset': 1},
      {'name': strings.isSpanish ? 'Miércoles' : 'Wednesday', 'offset': 2},
      {'name': strings.isSpanish ? 'Jueves' : 'Thursday', 'offset': 3},
      {'name': strings.isSpanish ? 'Viernes' : 'Friday', 'offset': 4},
      {'name': strings.isSpanish ? 'Sábado' : 'Saturday', 'offset': 5},
      {'name': strings.isSpanish ? 'Domingo' : 'Sunday', 'offset': 6},
    ];

    final mealSlots = ['breakfast', 'lunch', 'snack', 'dinner'];

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.plannerTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.casino_outlined),
            tooltip: strings.fillRandom,
            onPressed: () => _confirmFillRandom(context, weekPlanNotifier),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: strings.clearWeek,
            onPressed: () => _confirmClearWeek(context, weekPlanNotifier),
          ),
        ],
      ),
      body: Column(
        children: [
          // Week Navigator Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(bottom: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton.filledTonal(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => weekStartNotifier.previousWeek(),
                ),
                Column(
                  children: [
                    Text(
                      weekRangeTitle,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    InkWell(
                      onTap: () => weekStartNotifier.goToToday(),
                      child: Text(
                        strings.today,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                IconButton.filledTonal(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => weekStartNotifier.nextWeek(),
                ),
              ],
            ),
          ),
          // Days List
          Expanded(
            child: weekPlanAsync.when(
              data: (plans) {
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: days.length,
                  itemBuilder: (context, index) {
                    final day = days[index];
                    final dayDate = weekStart.add(Duration(days: day['offset'] as int));
                    final dateStr = DateFormat('yyyy-MM-dd').format(dayDate);
                    final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == dateStr;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Day Title Header
                            Row(
                              children: [
                                Text(
                                  day['name'] as String,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isToday ? theme.colorScheme.primary : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat('d MMM', strings.isSpanish ? 'es' : 'en').format(dayDate),
                                  style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                ),
                                if (isToday) ...[
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      strings.today,
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const Divider(height: 16),
                            // 4 Meal Slots
                            ...mealSlots.map((slot) {
                              final item = plans.cast<MealPlanItem?>().firstWhere(
                                    (p) => p?.dateString == dateStr && p?.mealType == slot,
                                    orElse: () => null,
                                  );

                              return MealSlotCard(
                                mealType: slot,
                                item: item,
                                onTap: () {
                                  RecipePickerSheet.show(
                                    context,
                                    slotTitle: '${day['name']} - $slot',
                                    onRecipeSelected: (recipe) {
                                      weekPlanNotifier.assignMeal(
                                        dateString: dateStr,
                                        mealType: slot,
                                        recipeId: recipe.id,
                                        recipeTitle: recipe.title,
                                        recipeCategory: recipe.category,
                                        servings: recipe.baseServings,
                                      );
                                    },
                                    onCustomEntered: (customName) {
                                      weekPlanNotifier.assignMeal(
                                        dateString: dateStr,
                                        mealType: slot,
                                        recipeTitle: customName,
                                        servings: 2,
                                      );
                                    },
                                  );
                                },
                                onRemove: () {
                                  weekPlanNotifier.removeMealSlot(dateStr, slot);
                                },
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(child: Text(strings.emptyTitle)),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmFillRandom(BuildContext context, WeeklyMealPlanNotifier notifier) {
    final strings = AppStrings.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.fillRandom),
        content: const Text('¿Deseas rellenar automáticamente los espacios vacíos con recetas de tu recetario?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(strings.cancel)),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              notifier.fillRandomSlots();
            },
            child: Text(strings.confirm),
          ),
        ],
      ),
    );
  }

  void _confirmClearWeek(BuildContext context, WeeklyMealPlanNotifier notifier) {
    final strings = AppStrings.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.clearWeek),
        content: Text(strings.clearWeekConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(strings.cancel)),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              notifier.clearCurrentWeek();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text(strings.clearAll),
          ),
        ],
      ),
    );
  }
}
