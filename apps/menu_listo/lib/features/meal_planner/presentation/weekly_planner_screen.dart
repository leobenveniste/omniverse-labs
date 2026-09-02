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
            icon: const Icon(Icons.bookmarks_outlined),
            tooltip: strings.isSpanish ? 'Plantillas de Menú' : 'Meal Templates',
            onPressed: () => _showTemplatesSheet(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: strings.isSpanish ? 'Repetir semana anterior' : 'Repeat previous week',
            onPressed: () => _confirmCopyPreviousWeek(context, weekPlanNotifier),
          ),
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
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
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
                                onAdjustServings: item != null
                                    ? (servings) {
                                        weekPlanNotifier.assignMeal(
                                          dateString: dateStr,
                                          mealType: slot,
                                          recipeId: item.recipeId,
                                          recipeTitle: item.recipeTitle,
                                          recipeCategory: item.recipeCategory,
                                          servings: servings,
                                          customNote: item.customNote,
                                        );
                                      }
                                    : null,
                                onTap: () {
                                  String slotLabel;
                                  switch (slot) {
                                    case 'breakfast':
                                      slotLabel = strings.mealBreakfast;
                                      break;
                                    case 'lunch':
                                      slotLabel = strings.mealLunch;
                                      break;
                                    case 'snack':
                                      slotLabel = strings.mealSnack;
                                      break;
                                    case 'dinner':
                                      slotLabel = strings.mealDinner;
                                      break;
                                    default:
                                      slotLabel = slot;
                                  }

                                  RecipePickerSheet.show(
                                    context,
                                    slotTitle: '${day['name']} ($slotLabel)',
                                    onRecipeSelected: (recipe, servings) {
                                      weekPlanNotifier.assignMeal(
                                        dateString: dateStr,
                                        mealType: slot,
                                        recipeId: recipe.id,
                                        recipeTitle: recipe.title,
                                        recipeCategory: recipe.category,
                                        servings: servings,
                                      );
                                    },
                                    onCustomEntered: (customName, servings) {
                                      weekPlanNotifier.assignMeal(
                                        dateString: dateStr,
                                        mealType: slot,
                                        recipeTitle: customName,
                                        servings: servings,
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

  void _confirmCopyPreviousWeek(BuildContext context, WeeklyMealPlanNotifier notifier) {
    final strings = AppStrings.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.isSpanish ? 'Repetir semana anterior' : 'Repeat previous week'),
        content: Text(
          strings.isSpanish
              ? '¿Deseas copiar todas las comidas planificadas de la semana pasada en la semana actual?'
              : 'Do you want to copy all planned meals from last week into this week?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(strings.cancel)),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final count = await notifier.copyPreviousWeek();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      count > 0
                          ? (strings.isSpanish ? 'Se copiaron $count comidas con éxito' : 'Copied $count meals successfully')
                          : (strings.isSpanish ? 'No se encontraron comidas en la semana anterior' : 'No meals found in previous week'),
                    ),
                  ),
                );
              }
            },
            child: Text(strings.confirm),
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

  void _showTemplatesSheet(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final templatesAsync = ref.watch(mealPlanTemplatesProvider);
    final currentWeekItems = ref.watch(weeklyMealPlanProvider).value ?? [];
    final weekNotifier = ref.read(weeklyMealPlanProvider.notifier);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
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
                    child: const Icon(Icons.bookmarks_rounded, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.isSpanish ? 'Mis Plantillas de Menú' : 'My Meal Templates',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          strings.isSpanish
                              ? 'Guarda semanas completas para reutilizarlas cuando quieras'
                              : 'Save full weeks and reuse them anytime',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Button to save current week as a new template
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.tonalIcon(
                  onPressed: currentWeekItems.isEmpty
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          _showSaveTemplateDialog(context, ref, currentWeekItems, weekNotifier.currentWeekDateStrings);
                        },
                  icon: const Icon(Icons.add_task_rounded, size: 20),
                  label: Text(
                    strings.isSpanish
                        ? 'Guardar semana actual como plantilla'
                        : 'Save current week as template',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                strings.isSpanish ? 'Plantillas guardadas' : 'Saved Templates',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: templatesAsync.when(
                  data: (templates) {
                    if (templates.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bookmark_border_rounded, size: 48, color: theme.colorScheme.outline),
                            const SizedBox(height: 12),
                            Text(
                              strings.isSpanish
                                  ? 'Aún no tienes plantillas guardadas.'
                                  : 'No saved templates yet.',
                              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      itemCount: templates.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final t = templates[index];
                        final dateFormat = DateFormat('d MMM yyyy', strings.isSpanish ? 'es' : 'en');

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.25)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t.name,
                                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          '${t.items.length} ${strings.isSpanish ? "comidas programadas" : "meals scheduled"} • ${dateFormat.format(t.createdAt)}',
                                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                    onPressed: () {
                                      ref.read(mealPlanTemplatesProvider.notifier).deleteTemplate(t.id);
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  icon: const Icon(Icons.check_circle_outline, size: 18),
                                  label: Text(
                                    strings.isSpanish
                                        ? 'Aplicar a la semana activa'
                                        : 'Apply to active week',
                                  ),
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    await ref.read(weeklyMealPlanProvider.notifier).applyTemplate(t);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            strings.isSpanish
                                                ? '¡Plantilla "${t.name}" aplicada con éxito!'
                                                : 'Template "${t.name}" applied successfully!',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSaveTemplateDialog(
    BuildContext context,
    WidgetRef ref,
    List<MealPlanItem> weekItems,
    List<String> currentWeekDateStrings,
  ) {
    final strings = AppStrings.of(context);
    final ctrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.isSpanish ? 'Guardar como Plantilla' : 'Save as Template'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.isSpanish
                  ? 'Ingresa un nombre descriptivo para esta semana:'
                  : 'Enter a descriptive name for this week:',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: strings.isSpanish ? 'ej. Semana Express / Menú Ligero' : 'e.g. Quick Week / Healthy Menu',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(strings.cancel)),
          FilledButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                await ref.read(mealPlanTemplatesProvider.notifier).saveCurrentWeekAsTemplate(
                      name: name,
                      weekItems: weekItems,
                      currentWeekDateStrings: currentWeekDateStrings,
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        strings.isSpanish
                            ? '¡Plantilla "$name" guardada con éxito!'
                            : 'Template "$name" saved successfully!',
                      ),
                    ),
                  );
                }
              }
            },
            child: Text(strings.save),
          ),
        ],
      ),
    );
  }
}
