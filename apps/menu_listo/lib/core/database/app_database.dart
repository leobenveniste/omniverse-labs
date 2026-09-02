import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:menu_listo/features/recipes/models/ingredient_model.dart';
import 'package:menu_listo/features/recipes/models/recipe_model.dart';
import 'package:menu_listo/features/recipes/models/recipe_step_model.dart';
import 'package:menu_listo/features/meal_planner/models/meal_plan_model.dart';
import 'package:menu_listo/features/meal_planner/models/meal_plan_template_model.dart';
import 'package:menu_listo/features/shopping_list/models/shopping_item_model.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('menu_listo.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE recipes (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        titleEn TEXT,
        description TEXT,
        descriptionEn TEXT,
        category TEXT NOT NULL,
        prepTimeMinutes INTEGER NOT NULL,
        cookTimeMinutes INTEGER NOT NULL,
        baseServings INTEGER NOT NULL,
        tags TEXT,
        imageUrl TEXT,
        sourceUrl TEXT,
        isFavorite INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ingredients (
        id TEXT PRIMARY KEY,
        recipeId TEXT NOT NULL,
        amount REAL NOT NULL,
        unit TEXT,
        name TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (recipeId) REFERENCES recipes (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE recipe_steps (
        id TEXT PRIMARY KEY,
        recipeId TEXT NOT NULL,
        stepNumber INTEGER NOT NULL,
        instruction TEXT NOT NULL,
        instructionEn TEXT,
        FOREIGN KEY (recipeId) REFERENCES recipes (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE meal_plans (
        id TEXT PRIMARY KEY,
        dateString TEXT NOT NULL,
        mealType TEXT NOT NULL,
        recipeId TEXT,
        recipeTitle TEXT NOT NULL,
        recipeCategory TEXT,
        servings INTEGER NOT NULL DEFAULT 2,
        customNote TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE shopping_items (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        amount REAL NOT NULL DEFAULT 0,
        unit TEXT,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        category TEXT NOT NULL DEFAULT 'General',
        sourceRecipeTitle TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS meal_plan_templates (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        itemsJson TEXT NOT NULL
      )
    ''');
  }

  // --- RECIPES CRUD ---
  Future<List<Recipe>> getAllRecipes({String? searchQuery, String? category, bool? onlyFavorites}) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    List<String> conditions = [];
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      conditions.add('(title LIKE ? OR description LIKE ? OR tags LIKE ?)');
      final q = '%${searchQuery.trim()}%';
      whereArgs.addAll([q, q, q]);
    }
    if (category != null && category.isNotEmpty && category != 'Todas' && category != 'All') {
      conditions.add('category LIKE ?');
      whereArgs.add('%$category%');
    }
    if (onlyFavorites == true) {
      conditions.add('isFavorite = 1');
    }

    if (conditions.isNotEmpty) {
      whereClause = 'WHERE ${conditions.join(' AND ')}';
    }

    final recipeMaps = await db.rawQuery('SELECT * FROM recipes $whereClause ORDER BY createdAt DESC', whereArgs);

    List<Recipe> recipes = [];
    for (var rMap in recipeMaps) {
      final recipeId = rMap['id'] as String;
      final ingMaps = await db.query('ingredients', where: 'recipeId = ?', whereArgs: [recipeId]);
      final stepMaps = await db.query('recipe_steps', where: 'recipeId = ?', whereArgs: [recipeId], orderBy: 'stepNumber ASC');

      final ingredients = ingMaps.map((m) => Ingredient.fromMap(m)).toList();
      final steps = stepMaps.map((m) => RecipeStep.fromMap(m)).toList();

      recipes.add(Recipe.fromMap(rMap, ingredients: ingredients, steps: steps));
    }
    return recipes;
  }

  Future<Recipe?> getRecipeById(String id) async {
    final db = await database;
    final recipeMaps = await db.query('recipes', where: 'id = ?', whereArgs: [id]);
    if (recipeMaps.isEmpty) return null;

    final ingMaps = await db.query('ingredients', where: 'recipeId = ?', whereArgs: [id]);
    final stepMaps = await db.query('recipe_steps', where: 'recipeId = ?', whereArgs: [id], orderBy: 'stepNumber ASC');

    final ingredients = ingMaps.map((m) => Ingredient.fromMap(m)).toList();
    final steps = stepMaps.map((m) => RecipeStep.fromMap(m)).toList();

    return Recipe.fromMap(recipeMaps.first, ingredients: ingredients, steps: steps);
  }

  Future<void> insertRecipe(Recipe recipe) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('recipes', recipe.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

      await txn.delete('ingredients', where: 'recipeId = ?', whereArgs: [recipe.id]);
      for (var ing in recipe.ingredients) {
        final ingMap = ing.toMap()..['recipeId'] = recipe.id;
        await txn.insert('ingredients', ingMap, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await txn.delete('recipe_steps', where: 'recipeId = ?', whereArgs: [recipe.id]);
      for (var step in recipe.steps) {
        final stepMap = step.toMap()
          ..['id'] = '${recipe.id}_step_${step.stepNumber}'
          ..['recipeId'] = recipe.id;
        await txn.insert('recipe_steps', stepMap, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<void> deleteRecipe(String id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('ingredients', where: 'recipeId = ?', whereArgs: [id]);
      await txn.delete('recipe_steps', where: 'recipeId = ?', whereArgs: [id]);
      await txn.delete('recipes', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<void> toggleFavorite(String id, bool isFavorite) async {
    final db = await database;
    await db.update('recipes', {'isFavorite': isFavorite ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
  }

  // --- MEAL PLAN CRUD ---
  Future<List<MealPlanItem>> getMealPlansForWeek(List<String> dateStrings) async {
    final db = await database;
    final placeholders = List.filled(dateStrings.length, '?').join(',');
    final maps = await db.rawQuery(
      'SELECT * FROM meal_plans WHERE dateString IN ($placeholders)',
      dateStrings,
    );
    return maps.map((m) => MealPlanItem.fromMap(m)).toList();
  }

  Future<void> setMealPlan(MealPlanItem item) async {
    final db = await database;
    await db.insert('meal_plans', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteMealPlan(String id) async {
    final db = await database;
    await db.delete('meal_plans', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearMealPlansForWeek(List<String> dateStrings) async {
    final db = await database;
    final placeholders = List.filled(dateStrings.length, '?').join(',');
    await db.rawDelete('DELETE FROM meal_plans WHERE dateString IN ($placeholders)', dateStrings);
  }

  // --- MEAL PLAN TEMPLATES CRUD ---
  Future<List<MealPlanTemplate>> getAllMealPlanTemplates() async {
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS meal_plan_templates (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        itemsJson TEXT NOT NULL
      )
    ''');
    final maps = await db.query('meal_plan_templates', orderBy: 'createdAt DESC');
    return maps.map((m) => MealPlanTemplate.fromMap(m)).toList();
  }

  Future<void> saveMealPlanTemplate(MealPlanTemplate template) async {
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS meal_plan_templates (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        itemsJson TEXT NOT NULL
      )
    ''');
    await db.insert('meal_plan_templates', template.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteMealPlanTemplate(String id) async {
    final db = await database;
    await db.delete('meal_plan_templates', where: 'id = ?', whereArgs: [id]);
  }

  // --- SHOPPING ITEMS CRUD ---
  Future<List<ShoppingItem>> getAllShoppingItems() async {
    final db = await database;
    final maps = await db.query('shopping_items', orderBy: 'isCompleted ASC, createdAt DESC');
    return maps.map((m) => ShoppingItem.fromMap(m)).toList();
  }

  Future<void> insertShoppingItem(ShoppingItem item) async {
    final db = await database;
    await db.insert('shopping_items', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertBatchShoppingItems(List<ShoppingItem> items) async {
    final db = await database;
    await db.transaction((txn) async {
      for (var item in items) {
        await txn.insert('shopping_items', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<void> updateShoppingItem(ShoppingItem item) async {
    final db = await database;
    await db.update('shopping_items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  Future<void> deleteShoppingItem(String id) async {
    final db = await database;
    await db.delete('shopping_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearCompletedShoppingItems() async {
    final db = await database;
    await db.delete('shopping_items', where: 'isCompleted = 1');
  }

  Future<void> clearAllShoppingItems() async {
    final db = await database;
    await db.delete('shopping_items');
  }

  // --- SEED SAMPLE DATA ---
  Future<void> seedInitialDataIfEmpty() async {
    final db = await database;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM recipes')) ?? 0;
    if (count > 0) return;

    await loadSampleRecipes();
  }

  Future<void> loadSampleRecipes() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/sample_recipes.json');
      final List<dynamic> list = json.decode(jsonString);

      for (var rMap in list) {
        final List<dynamic> rawIngs = rMap['ingredients'] ?? [];
        final List<dynamic> rawSteps = rMap['steps'] ?? [];

        final ings = rawIngs.map((i) => Ingredient.fromMap(Map<String, dynamic>.from(i))).toList();
        final steps = rawSteps.map((s) => RecipeStep.fromMap(Map<String, dynamic>.from(s))).toList();

        final recipe = Recipe.fromMap(Map<String, dynamic>.from(rMap), ingredients: ings, steps: steps);
        await insertRecipe(recipe);
      }
    } catch (e) {
      // Ignored
    }
  }
}
