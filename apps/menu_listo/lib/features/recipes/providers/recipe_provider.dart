import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/recipe_repository.dart';
import '../models/recipe_model.dart';

final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  return RecipeRepository();
});

class RecipeFilterState {
  final String searchQuery;
  final String selectedCategory;
  final bool onlyFavorites;

  const RecipeFilterState({
    this.searchQuery = '',
    this.selectedCategory = 'Todas',
    this.onlyFavorites = false,
  });

  RecipeFilterState copyWith({
    String? searchQuery,
    String? selectedCategory,
    bool? onlyFavorites,
  }) {
    return RecipeFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
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

  void setCategory(String category) {
    state = state.copyWith(selectedCategory: category);
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
        category: _filter.selectedCategory,
        onlyFavorites: _filter.onlyFavorites,
      );
      if (recipes.isEmpty && _filter.searchQuery.isEmpty && (_filter.selectedCategory == 'Todas' || _filter.selectedCategory == 'All') && !_filter.onlyFavorites) {
        await _repo.reloadSampleRecipes();
        recipes = await _repo.getRecipes(
          searchQuery: _filter.searchQuery,
          category: _filter.selectedCategory,
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
    await _repo.toggleFavorite(id, !isFavorite);
    await loadRecipes();
  }

  Future<void> reloadSampleRecipes() async {
    await _repo.reloadSampleRecipes();
    await loadRecipes();
  }
}
