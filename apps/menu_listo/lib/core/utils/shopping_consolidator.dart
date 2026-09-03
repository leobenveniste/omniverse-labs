import 'package:uuid/uuid.dart';
import 'package:menu_listo/core/utils/culinary_catalog.dart';
import 'package:menu_listo/features/recipes/models/ingredient_model.dart';
import 'package:menu_listo/features/shopping_list/models/shopping_item_model.dart';

class ConsolidableRecipeIngredient {
  final Ingredient ingredient;
  final String recipeTitle;
  final int multiplier;

  const ConsolidableRecipeIngredient({
    required this.ingredient,
    required this.recipeTitle,
    this.multiplier = 1,
  });
}

class ShoppingConsolidator {
  static List<ShoppingItem> consolidateIngredients(
    List<ConsolidableRecipeIngredient> items,
  ) {
    final Map<String, _ConsolidatedAccumulator> accumulators = {};

    for (var entry in items) {
      final ing = entry.ingredient;
      if (ing.isSectionHeader) continue;
      final recipeTitle = entry.recipeTitle;
      final multiplier = entry.multiplier > 0 ? entry.multiplier : 1;
      final cleanName = _normalizeName(ing.name);

      if (cleanName.isEmpty) continue;

      final normalizedUnit = _normalizeUnit(ing.unit);
      final key = '${cleanName}__$normalizedUnit';

      final totalAmount = (ing.amount > 0 ? ing.amount : 1.0) * multiplier;

      if (!accumulators.containsKey(key)) {
        accumulators[key] = _ConsolidatedAccumulator(
          displayName: _capitalize(ing.name),
          normalizedName: cleanName,
          unit: normalizedUnit,
          amount: totalAmount,
          recipeTitles: {recipeTitle},
        );
      } else {
        final acc = accumulators[key]!;
        acc.amount += totalAmount;
        if (recipeTitle.isNotEmpty) {
          acc.recipeTitles.add(recipeTitle);
        }
      }
    }

    return accumulators.values.map((acc) {
      return ShoppingItem(
        id: const Uuid().v4(),
        name: acc.displayName,
        amount: acc.amount,
        unit: acc.unit,
        isCompleted: false,
        category: _guessCategory(acc.normalizedName),
        sourceRecipeTitle: acc.recipeTitles.where((t) => t.isNotEmpty).join(', '),
      );
    }).toList();
  }

  static String _normalizeName(String name) {
    var s = name.toLowerCase().trim();
    s = s.replaceAll(RegExp(r'[.,;!?:()\[\]{}]'), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (s.endsWith('es') && s.length > 4) {
      s = s.substring(0, s.length - 2);
    } else if (s.endsWith('s') && !s.endsWith('ss') && s.length > 3) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }

  static String _normalizeUnit(String unit) {
    final u = unit.toLowerCase().trim();
    if (u == 'gramos' || u == 'gr' || u == 'grs' || u == 'grams') return 'g';
    if (u == 'kilos' || u == 'kilo' || u == 'kilogramos') return 'kg';
    if (u == 'mililitros' || u == 'milliliters') return 'ml';
    if (u == 'litros' || u == 'litro' || u == 'liters' || u == 'lt') return 'l';
    if (u == 'cucharadas' || u == 'cucharada' || u == 'tbsp') return 'cda';
    if (u == 'cucharaditas' || u == 'cucharadita' || u == 'tsp') return 'cdta';
    if (u == 'unidades' || u == 'unidad' || u == 'units' || u == 'unit') return 'u';
    if (u == 'tazas' || u == 'cups' || u == 'cup') return 'taza';
    return u;
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  static String _guessCategory(String name) {
    return CulinaryCatalog.getCategory(name);
  }
}

class _ConsolidatedAccumulator {
  final String displayName;
  final String normalizedName;
  final String unit;
  double amount;
  final Set<String> recipeTitles;

  _ConsolidatedAccumulator({
    required this.displayName,
    required this.normalizedName,
    required this.unit,
    required this.amount,
    required this.recipeTitles,
  });
}
