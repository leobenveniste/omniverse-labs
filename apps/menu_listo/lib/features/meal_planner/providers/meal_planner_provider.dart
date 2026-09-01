import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../recipes/data/recipe_repository.dart';
import '../../recipes/providers/recipe_provider.dart';
import '../data/meal_plan_repository.dart';
import '../models/meal_plan_model.dart';

final mealPlanRepositoryProvider = Provider<MealPlanRepository>((ref) {
  return MealPlanRepository();
});

// Holds the currently focused week starting Monday
final currentWeekStartProvider = StateNotifierProvider<CurrentWeekStartNotifier, DateTime>((ref) {
  return CurrentWeekStartNotifier();
});

class CurrentWeekStartNotifier extends StateNotifier<DateTime> {
  CurrentWeekStartNotifier() : super(_findMonday(DateTime.now()));

  static DateTime _findMonday(DateTime date) {
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: date.weekday - 1));
  }

  void nextWeek() {
    state = state.add(const Duration(days: 7));
  }

  void previousWeek() {
    state = state.subtract(const Duration(days: 7));
  }

  void goToToday() {
    state = _findMonday(DateTime.now());
  }
}

final weeklyMealPlanProvider = StateNotifierProvider<WeeklyMealPlanNotifier, AsyncValue<List<MealPlanItem>>>((ref) {
  final repo = ref.watch(mealPlanRepositoryProvider);
  final weekStart = ref.watch(currentWeekStartProvider);
  final recipeRepo = ref.watch(recipeRepositoryProvider);
  return WeeklyMealPlanNotifier(repo, weekStart, recipeRepo);
});

class WeeklyMealPlanNotifier extends StateNotifier<AsyncValue<List<MealPlanItem>>> {
  final MealPlanRepository _repo;
  final DateTime _weekStart;
  final RecipeRepository _recipeRepo;

  WeeklyMealPlanNotifier(this._repo, this._weekStart, this._recipeRepo) : super(const AsyncValue.loading()) {
    loadWeek();
  }

  List<String> get currentWeekDateStrings {
    return List.generate(7, (i) {
      final date = _weekStart.add(Duration(days: i));
      return DateFormat('yyyy-MM-dd').format(date);
    });
  }

  Future<void> loadWeek() async {
    try {
      state = const AsyncValue.loading();
      final items = await _repo.getMealPlansForWeek(currentWeekDateStrings);
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> assignMeal({
    required String dateString,
    required String mealType,
    String? recipeId,
    required String recipeTitle,
    String? recipeCategory,
    int servings = 2,
    String customNote = '',
  }) async {
    final id = '${dateString}_$mealType';
    final item = MealPlanItem(
      id: id,
      dateString: dateString,
      mealType: mealType,
      recipeId: recipeId,
      recipeTitle: recipeTitle,
      recipeCategory: recipeCategory,
      servings: servings,
      customNote: customNote,
    );
    await _repo.setMealPlan(item);
    await loadWeek();
  }

  Future<void> removeMealSlot(String dateString, String mealType) async {
    final id = '${dateString}_$mealType';
    await _repo.deleteMealPlan(id);
    await loadWeek();
  }

  Future<void> clearCurrentWeek() async {
    await _repo.clearMealPlansForWeek(currentWeekDateStrings);
    await loadWeek();
  }

  Future<void> fillRandomSlots() async {
    final allRecipes = await _recipeRepo.getRecipes();
    if (allRecipes.isEmpty) return;

    final random = Random();
    final mealTypes = ['breakfast', 'lunch', 'snack', 'dinner'];
    final currentItems = state.value ?? [];

    for (var dateStr in currentWeekDateStrings) {
      for (var mealType in mealTypes) {
        final existing = currentItems.any((item) => item.dateString == dateStr && item.mealType == mealType);
        if (!existing) {
          // Find recipes matching category or pick any
          String targetCategory = 'Almuerzo';
          if (mealType == 'breakfast') targetCategory = 'Desayuno';
          if (mealType == 'snack') targetCategory = 'Merienda';
          if (mealType == 'dinner') targetCategory = 'Cena';

          var matching = allRecipes.where((r) => r.category.toLowerCase() == targetCategory.toLowerCase()).toList();
          if (matching.isEmpty) matching = allRecipes;

          final picked = matching[random.nextInt(matching.length)];
          final id = '${dateStr}_$mealType';
          final item = MealPlanItem(
            id: id,
            dateString: dateStr,
            mealType: mealType,
            recipeId: picked.id,
            recipeTitle: picked.title,
            recipeCategory: picked.category,
            servings: picked.baseServings,
          );
          await _repo.setMealPlan(item);
        }
      }
    }
    await loadWeek();
  }
}
