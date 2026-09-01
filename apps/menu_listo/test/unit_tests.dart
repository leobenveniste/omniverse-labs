import 'package:flutter_test/flutter_test.dart';
import 'package:menu_listo/core/utils/ingredient_parser.dart';
import 'package:menu_listo/core/utils/portion_calculator.dart';
import 'package:menu_listo/core/utils/shopping_consolidator.dart';
import 'package:menu_listo/features/recipes/models/ingredient_model.dart';

void main() {
  group('PortionCalculator Tests', () {
    test('Scales ingredients proportionally', () {
      // 250g for 2 persons -> scaled to 4 persons should be 500g
      final result = PortionCalculator.calculateAmount(
        baseAmount: 250.0,
        baseServings: 2,
        targetServings: 4,
      );
      expect(result, equals(500.0));
    });

    test('Formats fractional amounts cleanly', () {
      expect(PortionCalculator.formatAmount(0.5), equals('½'));
      expect(PortionCalculator.formatAmount(1.5), equals('1 ½'));
      expect(PortionCalculator.formatAmount(2.0), equals('2'));
      expect(PortionCalculator.formatAmount(250.0), equals('250'));
    });
  });

  group('IngredientParser Tests', () {
    test('Parses quantity, unit, name and notes correctly', () {
      final ing1 = IngredientParser.parseLine('250 g de harina 0000 (tamizada)');
      expect(ing1.amount, equals(250.0));
      expect(ing1.unit, equals('g'));
      expect(ing1.name, contains('harina 0000'));
      expect(ing1.notes, equals('tamizada'));

      final ing2 = IngredientParser.parseLine('2 cucharadas de aceite de oliva');
      expect(ing2.amount, equals(2.0));
      expect(ing2.unit, equals('cucharadas'));
      expect(ing2.name, contains('aceite de oliva'));

      final ing3 = IngredientParser.parseLine('1/2 taza de leche');
      expect(ing3.amount, equals(0.5));
      expect(ing3.unit, equals('taza'));
      expect(ing3.name, contains('leche'));
    });
  });

  group('ShoppingConsolidator Tests', () {
    test('Consolidates repeated ingredients by summing amounts', () {
      final pairs = [
        MapEntry('Risotto', Ingredient(amount: 200, unit: 'g', name: 'Arroz Carnaroli')),
        MapEntry('Guiso', Ingredient(amount: 300, unit: 'g', name: 'Arroz Carnaroli')),
        MapEntry('Ensalada', Ingredient(amount: 2, unit: 'unidades', name: 'Tomates')),
      ];

      final consolidated = ShoppingConsolidator.consolidateIngredients(pairs);

      expect(consolidated.length, equals(2));
      final rice = consolidated.firstWhere((i) => i.name.toLowerCase().contains('arroz'));
      expect(rice.amount, equals(500.0));
      expect(rice.unit, equals('g'));
      expect(rice.sourceRecipeTitle, contains('Risotto'));
      expect(rice.sourceRecipeTitle, contains('Guiso'));
    });
  });
}
