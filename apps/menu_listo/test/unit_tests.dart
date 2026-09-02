import 'package:flutter_test/flutter_test.dart';
import 'package:menu_listo/core/utils/portion_calculator.dart';
import 'package:menu_listo/core/utils/ingredient_parser.dart';
import 'package:menu_listo/core/utils/shopping_consolidator.dart';
import 'package:menu_listo/features/recipes/models/ingredient_model.dart';

void main() {
  group('PortionCalculator Tests', () {
    test('Scales ingredients proportionally', () {
      final ing = Ingredient(name: 'Harina', amount: 200, unit: 'g');
      final scaled = ing.scale(1.5);
      expect(scaled.amount, equals(300));
    });

    test('Formats fractional amounts cleanly', () {
      expect(PortionCalculator.formatAmount(0.5), equals('½'));
      expect(PortionCalculator.formatAmount(0.25), equals('¼'));
      expect(PortionCalculator.formatAmount(1.5), equals('1 ½'));
      expect(PortionCalculator.formatAmount(2.0), equals('2'));
    });
  });

  group('IngredientParser Tests', () {
    test('Parses quantity, unit, and name correctly', () {
      final parsed = IngredientParser.parseLine('2 cdas de aceite de oliva');
      expect(parsed.amount, equals(2.0));
      expect(parsed.unit, equals('cdas'));
      expect(parsed.name, contains('aceite de oliva'));
    });
  });

  group('ShoppingConsolidator Tests', () {
    test('Consolidates repeated ingredients by summing amounts', () {
      final items = [
        ConsolidableRecipeIngredient(
          ingredient: Ingredient(name: 'Cebolla', amount: 2, unit: 'u'),
          recipeTitle: 'Tarta',
          multiplier: 1,
        ),
        ConsolidableRecipeIngredient(
          ingredient: Ingredient(name: 'cebollas', amount: 3, unit: 'u'),
          recipeTitle: 'Sopa',
          multiplier: 1,
        ),
      ];

      final consolidated = ShoppingConsolidator.consolidateIngredients(items);
      expect(consolidated.length, equals(1));
      expect(consolidated.first.amount, equals(5.0));
      expect(consolidated.first.sourceRecipeTitle, contains('Tarta'));
      expect(consolidated.first.sourceRecipeTitle, contains('Sopa'));
    });
  });
}
