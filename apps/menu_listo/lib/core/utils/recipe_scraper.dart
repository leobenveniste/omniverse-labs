import 'dart:convert';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import '../../features/recipes/models/ingredient_model.dart';
import '../../features/recipes/models/recipe_model.dart';
import '../../features/recipes/models/recipe_step_model.dart';
import 'ingredient_parser.dart';

class RecipeScraper {
  static Future<Recipe?> scrapeUrl(String url) async {
    final cleanUrl = url.trim();
    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse(cleanUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'es-ES,es;q=0.9,en;q=0.8',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return null;
      }

      final document = html_parser.parse(response.body);

      final jsonLdScripts = document.querySelectorAll('script[type="application/ld+json"]');
      for (var script in jsonLdScripts) {
        try {
          final content = script.text.trim();
          if (content.isEmpty) continue;
          final dynamic decoded = json.decode(content);

          final recipeMap = _findRecipeObject(decoded);
          if (recipeMap != null) {
            final parsed = _parseJsonLdRecipe(recipeMap, cleanUrl);
            if (parsed != null && parsed.title.isNotEmpty) {
              return parsed;
            }
          }
        } catch (_) {}
      }

      return _parseOpenGraphAndDom(document, cleanUrl);
    } catch (e) {
      return null;
    }
  }

  static Map<String, dynamic>? _findRecipeObject(dynamic jsonObj) {
    if (jsonObj is Map<String, dynamic>) {
      final type = jsonObj['@type'];
      if (type == 'Recipe' || (type is List && type.contains('Recipe'))) {
        return jsonObj;
      }
      if (jsonObj.containsKey('@graph') && jsonObj['@graph'] is List) {
        for (var item in jsonObj['@graph']) {
          final res = _findRecipeObject(item);
          if (res != null) return res;
        }
      }
    } else if (jsonObj is List) {
      for (var item in jsonObj) {
        final res = _findRecipeObject(item);
        if (res != null) return res;
      }
    }
    return null;
  }

  static Recipe? _parseJsonLdRecipe(Map<String, dynamic> data, String sourceUrl) {
    final title = data['name']?.toString() ?? '';
    final description = data['description']?.toString() ?? '';
    final category = _normalizeCategory(data['recipeCategory']?.toString());

    int servings = 2;
    final yieldVal = data['recipeYield'];
    if (yieldVal != null) {
      if (yieldVal is num) {
        servings = yieldVal.toInt();
      } else if (yieldVal is List && yieldVal.isNotEmpty) {
        servings = _extractNumber(yieldVal.first.toString()) ?? 2;
      } else {
        servings = _extractNumber(yieldVal.toString()) ?? 2;
      }
    }
    if (servings <= 0) servings = 2;

    final prepTime = _parseIsoDuration(data['prepTime']?.toString()) ?? 15;
    final cookTime = _parseIsoDuration(data['cookTime']?.toString()) ?? 20;

    String imageUrl = '';
    final imgObj = data['image'];
    if (imgObj is String) {
      imageUrl = imgObj;
    } else if (imgObj is List && imgObj.isNotEmpty) {
      imageUrl = imgObj.first.toString();
    } else if (imgObj is Map && imgObj['url'] != null) {
      imageUrl = imgObj['url'].toString();
    }

    List<Ingredient> ingredients = [];
    final rawIngredients = data['recipeIngredient'];
    if (rawIngredients is List) {
      for (var line in rawIngredients) {
        if (line != null && line.toString().trim().isNotEmpty) {
          ingredients.add(IngredientParser.parseLine(line.toString()));
        }
      }
    }

    List<RecipeStep> steps = [];
    final rawInstructions = data['recipeInstructions'];
    if (rawInstructions is List) {
      int stepNum = 1;
      for (var item in rawInstructions) {
        if (item is String && item.trim().isNotEmpty) {
          steps.add(RecipeStep(stepNumber: stepNum++, instruction: item.trim()));
        } else if (item is Map) {
          final text = item['text'] ?? item['name'] ?? '';
          if (text.toString().trim().isNotEmpty) {
            steps.add(RecipeStep(stepNumber: stepNum++, instruction: text.toString().trim()));
          }
        }
      }
    } else if (rawInstructions is String && rawInstructions.trim().isNotEmpty) {
      final lines = rawInstructions.split(RegExp(r'\r?\n|\.\s+'));
      int stepNum = 1;
      for (var line in lines) {
        if (line.trim().isNotEmpty) {
          steps.add(RecipeStep(stepNumber: stepNum++, instruction: line.trim()));
        }
      }
    }

    List<String> tags = [];
    final kw = data['keywords'];
    if (kw is String && kw.isNotEmpty) {
      tags = kw.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).take(5).toList();
    } else if (kw is List) {
      tags = kw.map((t) => t.toString().trim()).where((t) => t.isNotEmpty).take(5).toList();
    }

    return Recipe(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      category: category,
      prepTimeMinutes: prepTime,
      cookTimeMinutes: cookTime,
      baseServings: servings,
      tags: tags,
      imageUrl: imageUrl,
      sourceUrl: sourceUrl,
      ingredients: ingredients,
      steps: steps,
    );
  }

  static Recipe _parseOpenGraphAndDom(dynamic document, String sourceUrl) {
    final titleOg = document.querySelector('meta[property="og:title"]')?.attributes['content'] ??
        document.querySelector('title')?.text ??
        'Receta Importada';

    final descOg = document.querySelector('meta[property="og:description"]')?.attributes['content'] ??
        document.querySelector('meta[name="description"]')?.attributes['content'] ??
        '';

    final imageOg = document.querySelector('meta[property="og:image"]')?.attributes['content'] ?? '';

    List<Ingredient> ingredients = [];
    final ingElements = document.querySelectorAll('li[class*="ingredient"], ul[class*="ingredient"] li, .recipe-ingredients li, [itemprop="recipeIngredient"]');
    for (var el in ingElements) {
      final text = el.text.trim();
      if (text.isNotEmpty) {
        ingredients.add(IngredientParser.parseLine(text));
      }
    }

    List<RecipeStep> steps = [];
    final stepElements = document.querySelectorAll('li[class*="instruction"], ol[class*="instruction"] li, .recipe-instructions li, [itemprop="recipeInstructions"] li, [itemprop="recipeInstructions"] p');
    int stepNum = 1;
    for (var el in stepElements) {
      final text = el.text.trim();
      if (text.isNotEmpty && !text.toLowerCase().contains('anuncio') && !text.toLowerCase().contains('publicidad')) {
        steps.add(RecipeStep(stepNumber: stepNum++, instruction: text));
      }
    }

    return Recipe(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: titleOg.trim(),
      description: descOg.trim(),
      category: 'Almuerzo',
      prepTimeMinutes: 15,
      cookTimeMinutes: 20,
      baseServings: 2,
      tags: ['Web'],
      imageUrl: imageOg.trim(),
      sourceUrl: sourceUrl,
      ingredients: ingredients,
      steps: steps,
    );
  }

  static int? _extractNumber(String str) {
    final match = RegExp(r'\d+').firstMatch(str);
    if (match != null) {
      return int.tryParse(match.group(0)!);
    }
    return null;
  }

  static int? _parseIsoDuration(String? duration) {
    if (duration == null || duration.isEmpty) return null;
    final clean = duration.toUpperCase();
    final hoursMatch = RegExp(r'(\d+)H').firstMatch(clean);
    final minutesMatch = RegExp(r'(\d+)M').firstMatch(clean);

    int totalMinutes = 0;
    if (hoursMatch != null) {
      totalMinutes += (int.tryParse(hoursMatch.group(1)!) ?? 0) * 60;
    }
    if (minutesMatch != null) {
      totalMinutes += int.tryParse(minutesMatch.group(1)!) ?? 0;
    }

    if (totalMinutes > 0) return totalMinutes;
    return _extractNumber(duration);
  }

  static String _normalizeCategory(String? cat) {
    if (cat == null) return 'Almuerzo';
    final lower = cat.toLowerCase();
    if (lower.contains('breakfast') || lower.contains('desayuno')) return 'Desayuno';
    if (lower.contains('snack') || lower.contains('merienda')) return 'Merienda';
    if (lower.contains('dinner') || lower.contains('cena')) return 'Cena';
    if (lower.contains('dessert') || lower.contains('postre')) return 'Postre';
    return 'Almuerzo';
  }
}
