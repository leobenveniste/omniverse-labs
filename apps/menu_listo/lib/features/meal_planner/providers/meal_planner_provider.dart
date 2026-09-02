import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../recipes/data/recipe_repository.dart';
import '../../recipes/providers/recipe_provider.dart';
import '../data/meal_plan_repository.dart';
import '../models/meal_plan_model.dart';
import '../models/meal_plan_template_model.dart';

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

  Future<int> copyPreviousWeek() async {
    final prevWeekDateStrings = List.generate(7, (i) {
      final date = _weekStart.subtract(const Duration(days: 7)).add(Duration(days: i));
      return DateFormat('yyyy-MM-dd').format(date);
    });

    final prevItems = await _repo.getMealPlansForWeek(prevWeekDateStrings);
    if (prevItems.isEmpty) return 0;

    int copied = 0;
    for (int i = 0; i < 7; i++) {
      final prevDate = prevWeekDateStrings[i];
      final currDate = currentWeekDateStrings[i];
      final dayItems = prevItems.where((it) => it.dateString == prevDate);

      for (var item in dayItems) {
        final newId = '${currDate}_${item.mealType}';
        final newItem = MealPlanItem(
          id: newId,
          dateString: currDate,
          mealType: item.mealType,
          recipeId: item.recipeId,
          recipeTitle: item.recipeTitle,
          recipeCategory: item.recipeCategory,
          servings: item.servings,
          customNote: item.customNote,
        );
        await _repo.setMealPlan(newItem);
        copied++;
      }
    }

    await loadWeek();
    return copied;
  }

  Future<void> applyTemplate(MealPlanTemplate template) async {
    for (var tItem in template.items) {
      if (tItem.dayOffset >= 0 && tItem.dayOffset < 7) {
        final targetDateStr = currentWeekDateStrings[tItem.dayOffset];
        final id = '${targetDateStr}_${tItem.mealType}';
        final item = MealPlanItem(
          id: id,
          dateString: targetDateStr,
          mealType: tItem.mealType,
          recipeId: tItem.recipeId,
          recipeTitle: tItem.recipeTitle,
          recipeCategory: tItem.recipeCategory,
          servings: tItem.servings,
          customNote: tItem.customNote,
        );
        await _repo.setMealPlan(item);
      }
    }
    await loadWeek();
  }
}

// Templates State Notifier
final mealPlanTemplatesProvider = StateNotifierProvider<MealPlanTemplatesNotifier, AsyncValue<List<MealPlanTemplate>>>((ref) {
  final repo = ref.watch(mealPlanRepositoryProvider);
  return MealPlanTemplatesNotifier(repo);
});

class MealPlanTemplatesNotifier extends StateNotifier<AsyncValue<List<MealPlanTemplate>>> {
  final MealPlanRepository _repo;

  MealPlanTemplatesNotifier(this._repo) : super(const AsyncValue.loading()) {
    loadTemplates();
  }

  Future<void> loadTemplates() async {
    try {
      state = const AsyncValue.loading();
      final list = await _repo.getAllTemplates();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveCurrentWeekAsTemplate({
    required String name,
    required List<MealPlanItem> weekItems,
    required List<String> currentWeekDateStrings,
  }) async {
    final List<MealPlanTemplateItem> templateItems = [];

    for (var item in weekItems) {
      final dayOffset = currentWeekDateStrings.indexOf(item.dateString);
      if (dayOffset != -1) {
        templateItems.add(MealPlanTemplateItem(
          dayOffset: dayOffset,
          mealType: item.mealType,
          recipeId: item.recipeId,
          recipeTitle: item.recipeTitle,
          recipeCategory: item.recipeCategory,
          servings: item.servings,
          customNote: item.customNote,
        ));
      }
    }

    final template = MealPlanTemplate(
      name: name,
      items: templateItems,
    );

    await _repo.saveTemplate(template);
    await loadTemplates();
  }

  Future<void> deleteTemplate(String id) async {
    await _repo.deleteTemplate(id);
    await loadTemplates();
  }
}
