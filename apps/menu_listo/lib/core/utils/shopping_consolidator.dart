import 'package:menu_listo/features/recipes/models/ingredient_model.dart';
import 'package:menu_listo/features/shopping_list/models/shopping_item_model.dart';

class ShoppingConsolidator {
  static List<ShoppingItem> consolidateIngredients(List<MapEntry<String, Ingredient>> recipeIngredientPairs) {
    final Map<String, _Accumulator> accumulators = {};

    for (var entry in recipeIngredientPairs) {
      final recipeTitle = entry.key;
      final ing = entry.value;

      final normName = _normalizeName(ing.name);
      final normUnit = _normalizeUnit(ing.unit);
      final key = '${normName}_$normUnit';

      if (!accumulators.containsKey(key)) {
        accumulators[key] = _Accumulator(
          name: ing.name.trim(),
          amount: ing.amount,
          unit: ing.unit.trim(),
          recipeTitles: {recipeTitle},
        );
      } else {
        final acc = accumulators[key]!;
        acc.amount += ing.amount;
        acc.recipeTitles.add(recipeTitle);
      }
    }

    return accumulators.values.map((acc) {
      return ShoppingItem(
        id: DateTime.now().microsecondsSinceEpoch.toString() + '_' + acc.name.hashCode.toString(),
        name: acc.name,
        amount: acc.amount,
        unit: acc.unit,
        isCompleted: false,
        category: _guessCategory(acc.name),
        sourceRecipeTitle: acc.recipeTitles.join(', '),
      );
    }).toList();
  }

  static String _normalizeName(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .trim();
  }

  static String _normalizeUnit(String unit) {
    final u = unit.toLowerCase().trim();
    if (u == 'g' || u == 'gr' || u == 'grs' || u == 'gramos' || u == 'grams') return 'g';
    if (u == 'kg' || u == 'kilo' || u == 'kilos' || u == 'kilogramos') return 'kg';
    if (u == 'ml' || u == 'mililitros') return 'ml';
    if (u == 'l' || u == 'lt' || u == 'litro' || u == 'litros') return 'l';
    if (u == 'cda' || u == 'cdas' || u == 'cucharada' || u == 'cucharadas' || u == 'tbsp') return 'cda';
    if (u == 'cdta' || u == 'cdtas' || u == 'cucharadita' || u == 'cucharaditas' || u == 'tsp') return 'cdta';
    if (u == 'taza' || u == 'tazas' || u == 'cup' || u == 'cups') return 'taza';
    if (u == 'unidad' || u == 'unidades' || u == 'u') return 'unidad';
    if (u == 'diente' || u == 'dientes') return 'dientes';
    return u;
  }

  static String _guessCategory(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('manzana') || lower.contains('banana') || lower.contains('tomate') || lower.contains('cebolla') || lower.contains('palta') || lower.contains('limon') || lower.contains('esparrago') || lower.contains('hongo') || lower.contains('papa')) {
      return 'Verdulería';
    }
    if (lower.contains('leche') || lower.contains('queso') || lower.contains('manteca') || lower.contains('yogur') || lower.contains('crema')) {
      return 'Lácteos';
    }
    if (lower.contains('carne') || lower.contains('pollo') || lower.contains('salmon') || lower.contains('pescado') || lower.contains('bife') || lower.contains('cerdo')) {
      return 'Carnicería / Pescadería';
    }
    if (lower.contains('harina') || lower.contains('arroz') || lower.contains('fideos') || lower.contains('avena') || lower.contains('azucar') || lower.contains('sal') || lower.contains('aceite') || lower.contains('caldo')) {
      return 'Almacén';
    }
    return 'General';
  }
}

class _Accumulator {
  final String name;
  double amount;
  final String unit;
  final Set<String> recipeTitles;

  _Accumulator({
    required this.name,
    required this.amount,
    required this.unit,
    required this.recipeTitles,
  });
}
