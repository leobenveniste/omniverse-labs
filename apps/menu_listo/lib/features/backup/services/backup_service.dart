import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:menu_listo/core/database/app_database.dart';
import 'package:menu_listo/features/recipes/models/ingredient_model.dart';
import 'package:menu_listo/features/recipes/models/recipe_model.dart';
import 'package:menu_listo/features/recipes/models/recipe_step_model.dart';
import 'package:menu_listo/features/shopping_list/models/shopping_item_model.dart';

class BackupService {
  final AppDatabase _db;

  BackupService([AppDatabase? db]) : _db = db ?? AppDatabase.instance;

  Future<String?> exportBackupJson() async {
    try {
      final recipes = await _db.getAllRecipes();
      final shoppingItems = await _db.getAllShoppingItems();

      final backupData = {
        'version': 1,
        'appName': 'Menú Listo',
        'exportedAt': DateTime.now().toIso8601String(),
        'recipes': recipes.map((r) => {
          ...r.toMap(),
          'ingredients': r.ingredients.map((i) => i.toMap()).toList(),
          'steps': r.steps.map((s) => s.toMap()).toList(),
        }).toList(),
        'shopping_items': shoppingItems.map((s) => s.toMap()).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

      final tempDir = await getTemporaryDirectory();
      final dateStr = DateTime.now().toIso8601String().split('T').first;
      final file = File('${tempDir.path}/menu_listo_backup_$dateStr.json');
      await file.writeAsString(jsonString, encoding: utf8);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Copia de Seguridad - Menú Listo ($dateStr)',
        subject: 'Menú Listo Backup',
      );

      return file.path;
    } catch (e) {
      return null;
    }
  }

  Future<bool> importBackupJson() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        return false;
      }

      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final Map<String, dynamic> data = json.decode(content);

      if (data.containsKey('recipes') && data['recipes'] is List) {
        for (var rMap in data['recipes']) {
          final rawIngs = (rMap['ingredients'] as List?) ?? [];
          final rawSteps = (rMap['steps'] as List?) ?? [];

          final recipe = Recipe.fromMap(
            Map<String, dynamic>.from(rMap),
            ingredients: rawIngs.map((i) => Ingredient.fromMap(Map<String, dynamic>.from(i))).toList(),
            steps: rawSteps.map((s) => RecipeStep.fromMap(Map<String, dynamic>.from(s))).toList(),
          );
          await _db.insertRecipe(recipe);
        }
      }

      if (data.containsKey('shopping_items') && data['shopping_items'] is List) {
        for (var sMap in data['shopping_items']) {
          final item = ShoppingItem.fromMap(Map<String, dynamic>.from(sMap));
          await _db.insertShoppingItem(item);
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
