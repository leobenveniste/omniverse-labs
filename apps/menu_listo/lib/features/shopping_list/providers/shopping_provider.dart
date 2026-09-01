import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:menu_listo/core/utils/portion_calculator.dart';
import 'package:menu_listo/core/utils/shopping_consolidator.dart';
import 'package:menu_listo/features/meal_planner/providers/meal_planner_provider.dart';
import 'package:menu_listo/features/recipes/data/recipe_repository.dart';
import 'package:menu_listo/features/recipes/models/ingredient_model.dart';
import 'package:menu_listo/features/recipes/providers/recipe_provider.dart';
import '../data/shopping_repository.dart';
import '../models/shopping_item_model.dart';

final shoppingRepositoryProvider = Provider<ShoppingRepository>((ref) {
  return ShoppingRepository();
});

final shoppingListProvider = StateNotifierProvider<ShoppingListNotifier, AsyncValue<List<ShoppingItem>>>((ref) {
  final repo = ref.watch(shoppingRepositoryProvider);
  final recipeRepo = ref.watch(recipeRepositoryProvider);
  final mealPlanNotifier = ref.watch(weeklyMealPlanProvider.notifier);
  return ShoppingListNotifier(repo, recipeRepo, mealPlanNotifier);
});

class ShoppingListNotifier extends StateNotifier<AsyncValue<List<ShoppingItem>>> {
  final ShoppingRepository _repo;
  final RecipeRepository _recipeRepo;
  final WeeklyMealPlanNotifier _mealPlanNotifier;

  ShoppingListNotifier(this._repo, this._recipeRepo, this._mealPlanNotifier) : super(const AsyncValue.loading()) {
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

  Future<void> toggleItem(ShoppingItem item) async {
    final updated = item.copyWith(isCompleted: !item.isCompleted);
    await _repo.updateItem(updated);
    await loadItems();
  }

  Future<void> addItem({required String name, double amount = 0, String unit = '', String category = 'General'}) async {
    final item = ShoppingItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(),
      amount: amount,
      unit: unit.trim(),
      category: category,
    );
    await _repo.saveItem(item);
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

  Future<int> generateFromWeeklyMealPlan() async {
    final weekPlans = await _mealPlanNotifier.loadWeek().then((_) {
      final list = _mealPlanNotifier.state.value ?? [];
      return list;
    });

    List<MapEntry<String, Ingredient>> pairs = [];

    for (var plan in weekPlans) {
      if (plan.recipeId != null && plan.recipeId!.isNotEmpty) {
        final recipe = await _recipeRepo.getRecipe(plan.recipeId!);
        if (recipe != null) {
          final factor = plan.servings / (recipe.baseServings > 0 ? recipe.baseServings : 2);
          for (var ing in recipe.ingredients) {
            final scaled = ing.scale(factor);
            pairs.add(MapEntry(recipe.title, scaled));
          }
        }
      }
    }

    if (pairs.isEmpty) return 0;

    final consolidated = ShoppingConsolidator.consolidateIngredients(pairs);
    await _repo.saveBatchItems(consolidated);
    await loadItems();
    return consolidated.length;
  }

  String buildShareableText({required String header}) {
    final items = state.value ?? [];
    if (items.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln(header);
    buffer.writeln('');

    final pending = items.where((i) => !i.isCompleted).toList();
    final done = items.where((i) => i.isCompleted).toList();

    if (pending.isNotEmpty) {
      for (var item in pending) {
        final amountStr = item.amount > 0 ? '${PortionCalculator.formatAmount(item.amount)} ' : '';
        final unitStr = item.unit.isNotEmpty ? '${item.unit} ' : '';
        buffer.writeln('▫️ $amountStr$unitStr${item.name}');
      }
    }

    if (done.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('✅ *Comprados:*');
      for (var item in done) {
        buffer.writeln('~ ${item.name} ~');
      }
    }

    return buffer.toString();
  }
}
