import 'package:menu_listo/features/recipes/models/ingredient_model.dart';

class IngredientParser {
  static final RegExp _amountAndUnitRegex = RegExp(
    r'^([0-9]+\s+[0-9]+/[0-9]+|[0-9]+/[0-9]+|[0-9]+(?:[\.,][0-9]+)?|½|¼|¾|⅓|⅔)\s*([a-zA-ZáéíóúÁÉÍÓÚñÑ]+)?(?:\s+(?:de\s+)?)?(.*)$',
    caseSensitive: false,
  );

  static Ingredient parseLine(String line) {
    var raw = line.trim();
    if (raw.isEmpty) {
      return Ingredient(name: '');
    }

    raw = raw.replaceAll('½', '0.5')
             .replaceAll('¼', '0.25')
             .replaceAll('¾', '0.75')
             .replaceAll('⅓', '0.33')
             .replaceAll('⅔', '0.67');

    raw = raw.replaceFirst(RegExp(r'^(?:[-*•]|\d+[\.\)])\s*'), '').trim();

    final match = _amountAndUnitRegex.firstMatch(raw);
    if (match != null) {
      final amountStr = match.group(1)?.replaceAll(',', '.') ?? '';
      double amount = 0.0;
      if (amountStr.contains('/')) {
        if (amountStr.contains(' ')) {
          final spaceParts = amountStr.split(' ');
          final whole = double.tryParse(spaceParts[0].trim()) ?? 0;
          final fracParts = spaceParts[1].split('/');
          final n = double.tryParse(fracParts[0].trim()) ?? 0;
          final d = double.tryParse(fracParts[1].trim()) ?? 1;
          amount = whole + (d != 0 ? n / d : 0);
        } else {
          final parts = amountStr.split('/');
          if (parts.length == 2) {
            final n = double.tryParse(parts[0].trim()) ?? 0;
            final d = double.tryParse(parts[1].trim()) ?? 1;
            amount = d != 0 ? n / d : 0;
          }
        }
      } else {
        amount = double.tryParse(amountStr) ?? 0.0;
      }

      final unitOrWord = match.group(2)?.trim() ?? '';
      var rest = match.group(3)?.trim() ?? '';

      if (_knownUnits.contains(unitOrWord.toLowerCase())) {
        return _extractNotes(amount: amount, unit: unitOrWord, name: rest.isNotEmpty ? rest : unitOrWord);
      } else {
        final fullName = unitOrWord.isNotEmpty ? '$unitOrWord $rest' : rest;
        return _extractNotes(amount: amount, unit: '', name: fullName.isNotEmpty ? fullName : raw);
      }
    }

    return _extractNotes(amount: 0.0, unit: '', name: raw);
  }

  static Ingredient _extractNotes({required double amount, required String unit, required String name}) {
    var cleanName = name.trim();
    var notes = '';

    final parenMatch = RegExp(r'^(.*?)\((.*?)\)\s*$').firstMatch(cleanName);
    if (parenMatch != null) {
      cleanName = parenMatch.group(1)?.trim() ?? cleanName;
      notes = parenMatch.group(2)?.trim() ?? '';
    } else if (cleanName.contains(',')) {
      final commaIdx = cleanName.indexOf(',');
      notes = cleanName.substring(commaIdx + 1).trim();
      cleanName = cleanName.substring(0, commaIdx).trim();
    }

    return Ingredient(
      amount: amount,
      unit: unit,
      name: cleanName.isNotEmpty ? cleanName : name,
      notes: notes,
    );
  }

  static final Set<String> _knownUnits = {
    'g', 'gr', 'grs', 'gramos', 'grams', 'gram',
    'kg', 'kilo', 'kilos', 'kilogramos',
    'ml', 'mililitros', 'milliliters',
    'l', 'lt', 'litro', 'litros', 'liters',
    'cda', 'cdas', 'cucharada', 'cucharadas', 'tbsp', 'tablespoon', 'tablespoons',
    'cdta', 'cdtas', 'cucharadita', 'cucharaditas', 'tsp', 'teaspoon', 'teaspoons',
    'taza', 'tazas', 'cup', 'cups',
    'pizca', 'pizcas', 'pinch',
    'unidad', 'unidades', 'unit', 'units', 'u',
    'diente', 'dientes', 'clove', 'cloves',
    'atado', 'atados', 'bunch',
    'lata', 'latas', 'can', 'cans',
    'rebanada', 'rebanadas', 'feta', 'fetas', 'slice', 'slices',
    'paquete', 'paquetes', 'pack',
    'chorro', 'chorrito', 'splash',
  };
}
