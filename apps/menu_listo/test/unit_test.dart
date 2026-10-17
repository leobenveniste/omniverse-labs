import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menu_listo/core/localization/app_localizations.dart';
import 'package:menu_listo/core/utils/culinary_catalog.dart';
import 'package:menu_listo/core/utils/portion_calculator.dart';
import 'package:menu_listo/core/utils/ingredient_parser.dart';
import 'package:menu_listo/core/utils/shopping_consolidator.dart';
import 'package:menu_listo/features/premium/providers/premium_provider.dart';
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
      expect(consolidated.first.category, equals('Verdulería'));
    });
  });

  group('CulinaryCatalog Category Tests', () {
    test('Normalizes and merges Verduras and Verdulería into a single category', () {
      expect(CulinaryCatalog.normalizeCategory('Verduras'), equals('Verdulería'));
      expect(CulinaryCatalog.normalizeCategory('Verdulería'), equals('Verdulería'));
      expect(CulinaryCatalog.normalizeCategory('Hortalizas'), equals('Verdulería'));
      expect(CulinaryCatalog.normalizeCategory('Frutas'), equals('Verdulería'));
      expect(CulinaryCatalog.normalizeCategory(null, ingredientName: 'Zanahoria'), equals('Verdulería'));
      expect(CulinaryCatalog.normalizeCategory(null, ingredientName: 'Bife de chorizo'), equals('Carnicería'));
      expect(CulinaryCatalog.normalizeCategory('Lácteos'), equals('Lácteos y Huevos'));
    });
  });

  group('Privacy & DevMode Tests', () {
    test('AppStrings provides non-empty privacy and data deletion texts in ES and EN', () {
      final es = AppStrings(const Locale('es'));
      final en = AppStrings(const Locale('en'));

      expect(es.privacyPolicy, isNotEmpty);
      expect(es.privacyPolicySubtitle, isNotEmpty);
      expect(es.privacyDialogTitle, isNotEmpty);
      expect(es.privacyDialogContent, isNotEmpty);
      expect(es.clearAllDataTitle, isNotEmpty);
      expect(es.clearAllDataSubtitle, isNotEmpty);

      expect(en.privacyPolicy, isNotEmpty);
      expect(en.privacyPolicySubtitle, isNotEmpty);
      expect(en.privacyDialogTitle, isNotEmpty);
      expect(en.privacyDialogContent, isNotEmpty);
      expect(en.clearAllDataTitle, isNotEmpty);
      expect(en.clearAllDataSubtitle, isNotEmpty);
    });

    test('PremiumState default values guarantee secure production mode', () {
      const state = PremiumState();
      expect(state.isProUser, isFalse);
      expect(state.isDevMode, isFalse);
    });
  });
}

