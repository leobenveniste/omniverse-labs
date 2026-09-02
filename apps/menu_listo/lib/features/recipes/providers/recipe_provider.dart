import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/recipe_repository.dart';
import '../models/recipe_model.dart';

final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  return RecipeRepository();
});

class RecipeFilterState {
  final String searchQuery;
  final Set<String> selectedCategories;
  final bool onlyFavorites;

  const RecipeFilterState({
    this.searchQuery = '',
    this.selectedCategories = const {},
    this.onlyFavorites = false,
  });

  RecipeFilterState copyWith({
    String? searchQuery,
    Set<String>? selectedCategories,
    bool? onlyFavorites,
  }) {
    return RecipeFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      onlyFavorites: onlyFavorites ?? this.onlyFavorites,
    );
  }
}

final recipeFilterProvider = StateNotifierProvider<RecipeFilterNotifier, RecipeFilterState>((ref) {
  return RecipeFilterNotifier();
});

class RecipeFilterNotifier extends StateNotifier<RecipeFilterState> {
  RecipeFilterNotifier() : super(const RecipeFilterState());

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void toggleCategory(String category) {
    final updated = Set<String>.from(state.selectedCategories);
    if (updated.contains(category)) {
      updated.remove(category);
    } else {
      updated.add(category);
    }
    state = state.copyWith(selectedCategories: updated);
  }

  void clearCategories() {
    state = state.copyWith(selectedCategories: const {});
  }

  void toggleOnlyFavorites() {
    state = state.copyWith(onlyFavorites: !state.onlyFavorites);
  }

  void resetFilters() {
    state = const RecipeFilterState();
  }
}

final recipesListProvider = StateNotifierProvider<RecipesListNotifier, AsyncValue<List<Recipe>>>((ref) {
  final repo = ref.watch(recipeRepositoryProvider);
  final filter = ref.watch(recipeFilterProvider);
  return RecipesListNotifier(repo, filter);
});

class RecipesListNotifier extends StateNotifier<AsyncValue<List<Recipe>>> {
  final RecipeRepository _repo;
  final RecipeFilterState _filter;

  RecipesListNotifier(this._repo, this._filter) : super(const AsyncValue.loading()) {
    loadRecipes();
  }

  Future<void> loadRecipes() async {
    try {
      state = const AsyncValue.loading();
      var recipes = await _repo.getRecipes(
        searchQuery: _filter.searchQuery,
        categories: _filter.selectedCategories,
        onlyFavorites: _filter.onlyFavorites,
      );
      if (recipes.isEmpty && _filter.searchQuery.isEmpty && _filter.selectedCategories.isEmpty && !_filter.onlyFavorites) {
        await _repo.reloadSampleRecipes();
        recipes = await _repo.getRecipes(
          searchQuery: _filter.searchQuery,
          categories: _filter.selectedCategories,
          onlyFavorites: _filter.onlyFavorites,
        );
      }
      state = AsyncValue.data(recipes);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveRecipe(Recipe recipe) async {
    await _repo.saveRecipe(recipe);
    await loadRecipes();
  }

  Future<void> deleteRecipe(String id) async {
    await _repo.deleteRecipe(id);
    await loadRecipes();
  }

  Future<void> toggleFavorite(String id, bool isFavorite) async {
    final currentList = state.valueOrNull;
    if (currentList != null) {
      final updated = currentList.map((r) {
        if (r.id == id) {
          return r.copyWith(isFavorite: !isFavorite);
        }
        return r;
      }).toList();
      state = AsyncValue.data(updated);
    }
    await _repo.toggleFavorite(id, !isFavorite);
  }

  Future<void> reloadSampleRecipes() async {
    await _repo.reloadSampleRecipes();
    await loadRecipes();
  }
}
