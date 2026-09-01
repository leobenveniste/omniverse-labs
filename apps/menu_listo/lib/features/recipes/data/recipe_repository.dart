import '../../core/database/app_database.dart';
import '../models/recipe_model.dart';

class RecipeRepository {
  final AppDatabase _db;

  RecipeRepository([AppDatabase? db]) : _db = db ?? AppDatabase.instance;

  Future<List<Recipe>> getRecipes({String? searchQuery, String? category, bool? onlyFavorites}) {
    return _db.getAllRecipes(searchQuery: searchQuery, category: category, onlyFavorites: onlyFavorites);
  }

  Future<Recipe?> getRecipe(String id) {
    return _db.getRecipeById(id);
  }

  Future<void> saveRecipe(Recipe recipe) {
    return _db.insertRecipe(recipe);
  }

  Future<void> deleteRecipe(String id) {
    return _db.deleteRecipe(id);
  }

  Future<void> toggleFavorite(String id, bool isFavorite) {
    return _db.toggleFavorite(id, isFavorite);
  }

  Future<void> reloadSampleRecipes() {
    return _db.loadSampleRecipes();
  }
}
