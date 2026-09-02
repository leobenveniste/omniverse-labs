import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:menu_listo/core/utils/ingredient_parser.dart';
import '../models/ingredient_model.dart';
import '../models/recipe_model.dart';
import '../models/recipe_step_model.dart';

class RecipePhotoScanner {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final ImagePicker _picker = ImagePicker();

  Future<Recipe?> scanRecipeFromImage({required ImageSource source}) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 90,
      );

      if (pickedFile == null) return null;

      final inputImage = InputImage.fromFilePath(pickedFile.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      if (recognizedText.text.trim().isEmpty) {
        return null;
      }

      return _parseRecognizedTextToRecipe(recognizedText.text, pickedFile.path);
    } catch (e) {
      return null;
    }
  }

  Recipe _parseRecognizedTextToRecipe(String fullText, String imagePath) {
    final lines = fullText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return Recipe(
        id: const Uuid().v4(),
        title: 'Receta Escaneada',
        category: 'Almuerzo',
        baseServings: 4,
        imageUrl: imagePath,
        createdAt: DateTime.now(),
      );
    }

    String title = lines.first;
    int baseServings = 4;
    int prepTimeMinutes = 20;
    int cookTimeMinutes = 30;
    String category = 'Almuerzo';

    List<Ingredient> ingredients = [];
    List<RecipeStep> steps = [];

    bool inIngredients = false;
    bool inSteps = false;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();

      if (lower.contains('porci') || lower.contains('serv') || lower.contains('personas')) {
        final match = RegExp(r'(\d+)').firstMatch(line);
        if (match != null) {
          baseServings = int.tryParse(match.group(1)!) ?? baseServings;
        }
      }

      if (lower.contains('min') || lower.contains('hora') || lower.contains('tiempo')) {
        final match = RegExp(r'(\d+)').firstMatch(line);
        if (match != null) {
          prepTimeMinutes = int.tryParse(match.group(1)!) ?? prepTimeMinutes;
        }
      }

      if (lower.contains('ingrediente') || lower.contains('ingredients')) {
        inIngredients = true;
        inSteps = false;
        continue;
      } else if (lower.contains('preparaci') || lower.contains('pasos') || lower.contains('instruc') || lower.contains('elaboration') || lower.contains('directions') || lower.contains('method')) {
        inIngredients = false;
        inSteps = true;
        continue;
      }

      if (inIngredients && !inSteps) {
        if (line.length > 2) {
          ingredients.add(IngredientParser.parseLine(line));
        }
      } else if (inSteps) {
        if (line.length > 4) {
          final cleanStep = line.replaceFirst(RegExp(r'^(\d+)[.\-\)]\s*'), '').trim();
          if (cleanStep.isNotEmpty) {
            steps.add(RecipeStep(
              stepNumber: steps.length + 1,
              instruction: cleanStep,
            ));
          }
        }
      } else if (i > 0 && i < 4 && !inIngredients && !inSteps) {
        if (RegExp(r'^(\d+|½|¼|¾|⅓|⅔)').hasMatch(line)) {
          ingredients.add(IngredientParser.parseLine(line));
        }
      }
    }

    if (ingredients.isEmpty && steps.isEmpty) {
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i];
        if (RegExp(r'^(\d+|½|¼|¾|⅓|⅔)').hasMatch(line)) {
          ingredients.add(IngredientParser.parseLine(line));
        } else if (line.length > 15) {
          steps.add(RecipeStep(
            stepNumber: steps.length + 1,
            instruction: line,
          ));
        }
      }
    }

    return Recipe(
      id: const Uuid().v4(),
      title: title.length > 60 ? title.substring(0, 60) : title,
      category: category,
      baseServings: baseServings,
      prepTimeMinutes: prepTimeMinutes,
      cookTimeMinutes: cookTimeMinutes,
      imageUrl: imagePath,
      ingredients: ingredients,
      steps: steps,
      createdAt: DateTime.now(),
    );
  }

  void dispose() {
    _textRecognizer.close();
  }
}
