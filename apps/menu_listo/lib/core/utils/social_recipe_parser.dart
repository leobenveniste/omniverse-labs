import 'package:uuid/uuid.dart';
import 'package:menu_listo/core/utils/ingredient_parser.dart';
import '../../features/recipes/models/ingredient_model.dart';
import '../../features/recipes/models/recipe_model.dart';
import '../../features/recipes/models/recipe_step_model.dart';

/// Intelligent parser for recipe posts and reels from social media (Instagram, TikTok, etc.).
/// Handles informal formatting, emojis, bullet points, noise filtering (hashtags, @mentions, CTAs),
/// and automatically identifies title, ingredients, steps, servings, and times.
class SocialRecipeParser {
  SocialRecipeParser._();

  static Recipe parsePostText(String rawText, {String? sourceUrl}) {
    final cleanInput = rawText.trim();
    if (cleanInput.isEmpty) {
      return Recipe(
        id: const Uuid().v4(),
        title: 'Receta de Redes Sociales',
        category: 'Almuerzo',
        baseServings: 2,
        createdAt: DateTime.now(),
        sourceUrl: sourceUrl ?? '',
      );
    }

    final rawLines = cleanInput
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    // 1. Separate & clean metadata, headers, ingredients and steps
    String detectedTitle = '';
    int detectedServings = 2;
    int detectedPrepTime = 15;
    int detectedCookTime = 20;
    String detectedCategory = 'Almuerzo';
    final List<String> extractedTags = ['Social'];

    // If text contains an instagram/tiktok URL inside it, extract it
    final urlMatch = RegExp(r'https?://[^\s]+').firstMatch(cleanInput);
    if (urlMatch != null && (sourceUrl == null || sourceUrl.isEmpty)) {
      final foundUrl = urlMatch.group(0)!;
      if (foundUrl.contains('instagram.com') || foundUrl.contains('tiktok.com')) {
        sourceUrl = foundUrl;
      }
    }

    if (sourceUrl != null && sourceUrl.contains('instagram.com')) {
      extractedTags.add('Instagram');
    } else if (sourceUrl != null && sourceUrl.contains('tiktok.com')) {
      extractedTags.add('TikTok');
    }

    // Filter out purely hashtag lines or social noise lines
    final meaningfulLines = <String>[];
    for (final line in rawLines) {
      if (_isInstagramNoise(line)) continue;
      meaningfulLines.add(line);
    }

    if (meaningfulLines.isEmpty) {
      return Recipe(
        id: const Uuid().v4(),
        title: 'Receta Importada',
        category: 'Almuerzo',
        baseServings: 2,
        createdAt: DateTime.now(),
        sourceUrl: sourceUrl ?? '',
      );
    }

    // 2. Identify Title from first 1-3 lines
    int contentStartIndex = 0;
    for (int i = 0; i < meaningfulLines.length && i < 3; i++) {
      final line = meaningfulLines[i];
      if (_isPotentialTitle(line)) {
        detectedTitle = _cleanTitle(line);
        contentStartIndex = i + 1;
        break;
      }
    }

    if (detectedTitle.isEmpty) {
      detectedTitle = _cleanTitle(meaningfulLines.first);
      contentStartIndex = 1;
    }

    // 3. Scan for Servings, Times & Category across all lines
    for (final line in meaningfulLines) {
      final lower = line.toLowerCase();

      // Servings detection (e.g. "Rinde 4 porciones", "Para 2 personas", "4 servings")
      final servingsMatch = RegExp(
        r'(?:rinde|para|servings?|porciones?|comensales?)\s*[:=]?\s*(\d+)|\b(\d+)\s*(?:porci[oó]n(?:es)?|personas?|servings?|platos?|comensales?)\b',
        caseSensitive: false,
      ).firstMatch(lower);
      if (servingsMatch != null) {
        final numStr = servingsMatch.group(1) ?? servingsMatch.group(2);
        if (numStr != null) {
          final val = int.tryParse(numStr);
          if (val != null && val >= 1 && val <= 30) {
            detectedServings = val;
          }
        }
      }

      // Time detection (e.g. "Listo en 25 min", "Cocción: 30 minutos")
      if (lower.contains('min') || lower.contains('tiempo') || lower.contains('hora')) {
        final timeMatch = RegExp(r'(\d+)\s*(?:min|minuto|m\b)').firstMatch(lower);
        if (timeMatch != null) {
          final t = int.tryParse(timeMatch.group(1)!) ?? 20;
          if (lower.contains('prep')) {
            detectedPrepTime = t;
          } else if (lower.contains('cocci') || lower.contains('horno')) {
            detectedCookTime = t;
          } else {
            detectedCookTime = t;
          }
        }
      }
    }

    // Category detection
    detectedCategory = _inferCategory(detectedTitle, cleanInput);

    // 4. Parse Ingredients & Steps sections
    final List<Ingredient> ingredients = [];
    final List<RecipeStep> steps = [];

    bool inIngredientsSection = false;
    bool inStepsSection = false;

    for (int i = contentStartIndex; i < meaningfulLines.length; i++) {
      final line = meaningfulLines[i];
      final lower = line.toLowerCase();

      // Section triggers
      if (_isIngredientSectionHeader(lower)) {
        inIngredientsSection = true;
        inStepsSection = false;
        continue;
      } else if (_isStepSectionHeader(lower)) {
        inIngredientsSection = false;
        inStepsSection = true;
        continue;
      }

      // If we are explicitly in the Ingredients section
      if (inIngredientsSection && !inStepsSection) {
        if (_looksLikeStep(line)) {
          // Heuristic: an obvious step found while in ingredients switches to steps
          inIngredientsSection = false;
          inStepsSection = true;
          _addStep(steps, line);
        } else {
          final parsed = IngredientParser.parseLine(line);
          if (parsed.name.isNotEmpty) {
            ingredients.add(parsed);
          }
        }
      }
      // If we are explicitly in the Steps section
      else if (inStepsSection) {
        _addStep(steps, line);
      }
      // If no explicit section header has been encountered yet
      else {
        if (_looksLikeStep(line)) {
          inStepsSection = true;
          _addStep(steps, line);
        } else if (_looksLikeIngredient(line)) {
          final parsed = IngredientParser.parseLine(line);
          if (parsed.name.isNotEmpty) {
            ingredients.add(parsed);
          }
        }
      }
    }

    // Fallback: If no structured sections were found, split heuristics
    if (ingredients.isEmpty && steps.isEmpty) {
      for (int i = contentStartIndex; i < meaningfulLines.length; i++) {
        final line = meaningfulLines[i];
        if (_looksLikeIngredient(line)) {
          ingredients.add(IngredientParser.parseLine(line));
        } else if (line.length > 18) {
          _addStep(steps, line);
        }
      }
    }

    return Recipe(
      id: const Uuid().v4(),
      title: detectedTitle,
      category: detectedCategory,
      prepTimeMinutes: detectedPrepTime,
      cookTimeMinutes: detectedCookTime,
      baseServings: detectedServings,
      tags: extractedTags,
      sourceUrl: sourceUrl ?? '',
      ingredients: ingredients,
      steps: steps,
      createdAt: DateTime.now(),
    );
  }

  static void _addStep(List<RecipeStep> steps, String rawLine) {
    var clean = rawLine.replaceFirst(RegExp(r'^(?:[-*•👉✨✅🔹]|\d+[\.\)\-:]?)\s*'), '').trim();
    if (clean.length > 3 && !_isInstagramNoise(clean)) {
      steps.add(RecipeStep(
        stepNumber: steps.length + 1,
        instruction: clean,
      ));
    }
  }

  static bool _isInstagramNoise(String line) {
    final lower = line.toLowerCase();
    // Hashtags or mentions line
    if (line.startsWith('#') || line.startsWith('@')) return true;
    if (RegExp(r'^(?:#\w+\s*)+$').hasMatch(line)) return true;

    // Common engagement CTAs
    if (lower.contains('guardate este reel') ||
        lower.contains('guardá este reel') ||
        lower.contains('guarda esta receta') ||
        lower.contains('guardate esta receta') ||
        lower.contains('seguime para más') ||
        lower.contains('sígueme para más') ||
        lower.contains('follow for more') ||
        lower.contains('like y comparte') ||
        lower.contains('link en bio') ||
        lower.contains('enlace en mi perfil') ||
        lower.contains('comenta "') ||
        lower.contains('comenta \'') ||
        lower.contains('deja un comentario') ||
        lower.contains('etiqueta a') ||
        lower.contains('etiquetá a')) {
      return true;
    }

    // Standalone URLs
    if (RegExp(r'^https?://[^\s]+$').hasMatch(line)) return true;

    return false;
  }

  static bool _isPotentialTitle(String line) {
    final lower = line.toLowerCase();
    if (lower.startsWith('receta:') ||
        lower.startsWith('título:') ||
        lower.startsWith('hoy preparamos') ||
        lower.startsWith('hoy hacemos') ||
        lower.startsWith('cómo hacer')) {
      return true;
    }
    // High uppercase ratio or surrounded by food emojis
    if (line.length >= 5 && line.length <= 80 && !line.contains(':') && !RegExp(r'^\d').hasMatch(line)) {
      return true;
    }
    return false;
  }

  static String _cleanTitle(String line) {
    var title = line
        .replaceFirst(RegExp(r'^(?:receta|hoy hacemos|hoy preparamos|cómo hacer|aprende a hacer|cómo preparar)[:\s-]*', caseSensitive: false), '')
        .replaceAll(RegExp(r'^(?:[-*•👉✨🤤👇❤️🔥🍝🍕🥗🍰🧁🥩🍞]\s*)+'), '')
        .replaceAll(RegExp(r'[\s👇✨🤤❤️🔥🍝🍕🥗🍰🧁🥩🍞!]+$'), '')
        .trim();

    if (title.isEmpty) return 'Receta de Redes Sociales';
    if (title.length > 70) {
      title = title.substring(0, 70).trim();
    }
    return title;
  }

  static bool _isIngredientSectionHeader(String lower) {
    return lower.startsWith('ingrediente') ||
        lower.startsWith('para la masa') ||
        lower.startsWith('para el relleno') ||
        lower.startsWith('para la salsa') ||
        lower.startsWith('para la crema') ||
        lower.startsWith('para el armado') ||
        lower.startsWith('necesitas') ||
        lower.startsWith('lo que necesitas') ||
        lower.startsWith('ingredients');
  }

  static bool _isStepSectionHeader(String lower) {
    return lower.startsWith('preparaci') ||
        lower.startsWith('paso a paso') ||
        lower.startsWith('procedimiento') ||
        lower.startsWith('instrucciones') ||
        lower.startsWith('elaboraci') ||
        lower.startsWith('como se hace') ||
        lower.startsWith('cómo se hace') ||
        lower.startsWith('manos a la obra') ||
        lower.startsWith('instructions') ||
        lower.startsWith('directions') ||
        lower.startsWith('method') ||
        lower.startsWith('steps');
  }

  static bool _looksLikeIngredient(String line) {
    final clean = line.replaceFirst(RegExp(r'^[-*•👉✨🔹]\s*'), '').trim();
    // Starts with number, fraction, or known quantity
    if (RegExp(r'^(\d+|½|¼|¾|⅓|⅔|\d+\s*/\s*\d+)').hasMatch(clean)) {
      return true;
    }
    final lower = clean.toLowerCase();
    if (lower.startsWith('un ') ||
        lower.startsWith('una ') ||
        lower.startsWith('dos ') ||
        lower.startsWith('tres ') ||
        lower.startsWith('medio ') ||
        lower.startsWith('media ') ||
        lower.startsWith('pizca ') ||
        lower.startsWith('chorro ') ||
        lower.startsWith('sal ') ||
        lower.startsWith('pimienta ') ||
        lower.startsWith('aceite ')) {
      return true;
    }
    return false;
  }

  static bool _looksLikeStep(String line) {
    final clean = line.trim();
    // Numbered step: "1.", "1 -", "Paso 1:"
    if (RegExp(r'^(?:paso\s*)?\d+[\.\)\-:]\s*', caseSensitive: false).hasMatch(clean)) {
      return true;
    }
    final lower = clean.toLowerCase();
    // Imperative verbs in culinary instructions
    if (lower.startsWith('cocinar ') ||
        lower.startsWith('cociná ') ||
        lower.startsWith('mezclar ') ||
        lower.startsWith('mezclá ') ||
        lower.startsWith('dorar ') ||
        lower.startsWith('dorá ') ||
        lower.startsWith('batir ') ||
        lower.startsWith('batí ') ||
        lower.startsWith('incorporar ') ||
        lower.startsWith('incorporá ') ||
        lower.startsWith('llevar a ') ||
        lower.startsWith('llevá a ') ||
        lower.startsWith('hornear ') ||
        lower.startsWith('horneá ') ||
        lower.startsWith('picar ') ||
        lower.startsWith('picá ') ||
        lower.startsWith('cortar ') ||
        lower.startsWith('cortá ') ||
        lower.startsWith('servir ') ||
        lower.startsWith('serví ')) {
      return true;
    }
    return false;
  }

  static String _inferCategory(String title, String fullText) {
    final t = '${title.toLowerCase()} ${fullText.toLowerCase()}';
    if (t.contains('postre') ||
        t.contains('torta') ||
        t.contains('pastel') ||
        t.contains('chocolate') ||
        t.contains('dulce') ||
        t.contains('galletit') ||
        t.contains('muffin') ||
        t.contains('budin') ||
        t.contains('budín') ||
        t.contains('brownie') ||
        t.contains('helado') ||
        t.contains('cookie')) {
      return 'Postre';
    }
    if (t.contains('desayuno') || t.contains('pancake') || t.contains('avena') || t.contains('tostada') || t.contains('smoothie')) {
      return 'Desayuno';
    }
    if (t.contains('merienda') || t.contains('mate') || t.contains('snack') || t.contains('bizcoch')) {
      return 'Merienda';
    }
    if (t.contains('sopa') || t.contains('ensalada liviana') || t.contains('cena') || t.contains('tacos')) {
      return 'Cena';
    }
    return 'Almuerzo';
  }
}
