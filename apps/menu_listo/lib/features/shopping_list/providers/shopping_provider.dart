import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:menu_listo/core/utils/portion_calculator.dart';
import 'package:menu_listo/core/utils/shopping_consolidator.dart';
import 'package:menu_listo/features/meal_planner/providers/meal_planner_provider.dart';
import 'package:menu_listo/features/recipes/providers/recipe_provider.dart';
import '../data/shopping_repository.dart';
import '../models/shopping_item_model.dart';

final shoppingRepositoryProvider = Provider<ShoppingRepository>((ref) {
  return ShoppingRepository();
});

final shoppingListProvider = StateNotifierProvider<ShoppingListNotifier, AsyncValue<List<ShoppingItem>>>((ref) {
  final repo = ref.watch(shoppingRepositoryProvider);
  return ShoppingListNotifier(repo, ref);
});

class ShoppingListNotifier extends StateNotifier<AsyncValue<List<ShoppingItem>>> {
  final ShoppingRepository _repo;
  final Ref _ref;

  ShoppingListNotifier(this._repo, this._ref) : super(const AsyncValue.loading()) {
    loadItems();
  }

  Future<void> loadItems() async {
    try {
      state = const AsyncValue.loading();
      final items = await _repo.getShoppingItems();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addItem({required String name, double amount = 0.0, String? unit, String? category}) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;

    final current = state.value ?? [];
    final normalized = cleanName.toLowerCase();
    final existingIdx = current.indexWhere((it) => it.name.toLowerCase() == normalized && it.unit == (unit ?? ''));

    if (existingIdx != -1) {
      final existing = current[existingIdx];
      final updated = existing.copyWith(amount: existing.amount + (amount > 0 ? amount : 1.0));
      await _repo.updateItem(updated);
    } else {
      final item = ShoppingItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: cleanName,
        amount: amount,
        unit: unit ?? '',
        category: category ?? 'General',
      );
      await _repo.saveItem(item);
    }
    await loadItems();
  }

  Future<void> toggleItem(ShoppingItem item) async {
    final updated = item.copyWith(isCompleted: !item.isCompleted);
    await _repo.updateItem(updated);
    await loadItems();
  }

  Future<void> deleteItem(String id) async {
    await _repo.deleteItem(id);
    await loadItems();
  }

  Future<void> clearCompleted() async {
    await _repo.clearCompleted();
    await loadItems();
  }

  Future<void> clearAll() async {
    await _repo.clearAll();
    await loadItems();
  }

  Future<List<ShoppingItem>> getWeeklyConsolidatedItems() async {
    final weekStart = _ref.read(currentWeekStartProvider);
    final weekDates = List.generate(7, (i) {
      final day = weekStart.add(Duration(days: i));
      return DateFormat('yyyy-MM-dd').format(day);
    });

    final mealPlans = await _ref.read(mealPlanRepositoryProvider).getMealPlansForWeek(weekDates);
    if (mealPlans.isEmpty) return [];

    final recipeRepo = _ref.read(recipeRepositoryProvider);
    List<ConsolidableRecipeIngredient> consolidableItems = [];

    for (var plan in mealPlans) {
      if (plan.recipeId != null && plan.recipeId!.isNotEmpty) {
        final recipe = await recipeRepo.getRecipe(plan.recipeId!);
        if (recipe != null && recipe.ingredients.isNotEmpty) {
          final factor = (plan.servings > 0 && recipe.baseServings > 0)
              ? (plan.servings / recipe.baseServings).ceil()
              : 1;

          for (var ing in recipe.ingredients) {
            consolidableItems.add(ConsolidableRecipeIngredient(
              ingredient: ing,
              recipeTitle: recipe.title,
              multiplier: factor,
            ));
          }
        }
      }
    }

    return ShoppingConsolidator.consolidateIngredients(consolidableItems);
  }

  Future<void> addConsolidatedItems(List<ShoppingItem> items) async {
    for (var item in items) {
      await addItem(
        name: item.name,
        amount: item.amount,
        unit: item.unit,
        category: item.category,
      );
    }
    await loadItems();
  }

  Future<int> generateFromWeeklyMealPlan() async {
    final consolidated = await getWeeklyConsolidatedItems();
    if (consolidated.isEmpty) return 0;

    await addConsolidatedItems(consolidated);
    return consolidated.length;
  }

  String buildShareableText({String header = '🛒 Lista de Compras - Menú Listo'}) {
    final items = state.value ?? [];
    if (items.isEmpty) return '';

    final buffer = StringBuffer('$header\n\n');
    for (var item in items) {
      final check = item.isCompleted ? '☑️' : '⬜';
      final formattedAmount = item.amount > 0 ? PortionCalculator.formatAmount(item.amount) : '';
      final unitStr = item.unit.isNotEmpty ? ' ${item.unit}' : '';
      final amountPart = formattedAmount.isNotEmpty ? '$formattedAmount$unitStr ' : '';
      buffer.writeln('$check $amountPart${item.name}');
    }
    return buffer.toString();
  }
}
