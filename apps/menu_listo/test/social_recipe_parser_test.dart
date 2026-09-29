import 'package:flutter_test/flutter_test.dart';
import 'package:menu_listo/core/utils/social_recipe_parser.dart';

void main() {
  group('SocialRecipeParser Tests', () {
    test('Parses full Instagram Reel caption with emojis, bullets, and steps', () {
      const caption = '''
PASTA CREMOSA CON CHAMPIÑONES Y ESPINACAS 🍝✨
Guárdate este reel que queda espectacular y se hace en 15 minutos!

Ingredientes (para 2 personas):
- 200g de pasta corta
- 250g de champiñones laminados
- 1 taza de espinacas frescas
- 2 dientes de ajo picados
- 150ml de crema de leche
- 2 cdas de aceite de oliva
- Sal y pimienta a gusto

Paso a paso:
1. Cocinar la pasta en abundante agua con sal.
2. En una sartén con aceite de oliva, dorar los ajos y los champiñones por 5 min.
3. Agregar las espinacas y cocinar 2 minutos más.
4. Verter la crema de leche, salpimentar y dejar reducir a fuego bajo.
5. Integrar la pasta cocida, mezclar bien y servir caliente.

#recetas #pasta #comidacasera #reels #foodie @recetasfaciles
https://www.instagram.com/reel/C-xyz123/
''';

      final recipe = SocialRecipeParser.parsePostText(caption);

      expect(recipe.title, contains('PASTA CREMOSA CON CHAMPIÑONES Y ESPINACAS'));
      expect(recipe.baseServings, equals(2));
      expect(recipe.ingredients.length, greaterThanOrEqualTo(6));
      expect(recipe.ingredients.any((i) => i.name.contains('champiñones')), isTrue);
      expect(recipe.steps.length, equals(5));
      expect(recipe.steps.first.instruction, contains('Cocinar la pasta'));
      expect(recipe.tags, contains('Instagram'));
      expect(recipe.sourceUrl, equals('https://www.instagram.com/reel/C-xyz123/'));
    });

    test('Parses dessert reel caption and infers category and prep time', () {
      const dessertCaption = '''
✨ BROWNIE FÁCIL EN SARTÉN ✨
Rinde 6 porciones • Listo en 25 min!

INGREDIENTES:
• 2 huevos
• 100g de chocolate semiamargo derretido
• 50g de manteca
• 1/2 taza de azúcar
• 3 cdas de harina común
• 1 pizca de sal

PREPARACIÓN:
1. Batir los huevos con el azúcar hasta blanquear.
2. Incorporar el chocolate derretido con la manteca.
3. Agregar la harina y la pizca de sal con movimientos envolventes.
4. Cocinar a fuego mínimo tapado en sartén por 20 minutos.
''';

      final recipe = SocialRecipeParser.parsePostText(dessertCaption);

      expect(recipe.title, contains('BROWNIE FÁCIL EN SARTÉN'));
      expect(recipe.category, equals('Postre'));
      expect(recipe.baseServings, equals(6));
      expect(recipe.cookTimeMinutes, equals(20));
      expect(recipe.ingredients.length, equals(6));
      expect(recipe.steps.length, equals(4));
    });

    test('Filters out Instagram engagement noise like follow CTAs', () {
      const noisyCaption = '''
Tarta de calabaza rápida
Seguime para más recetas fáciles! Link en bio.

Ingredientes:
1 calabaza mediana
2 huevos
100g queso

Preparación:
1. Hornear la calabaza.
2. Hacer puré y mezclar con huevos y queso.
3. Llevar al horno 20 min.

Comenta "RECETA" para recibir el paso a paso en privado!
''';

      final recipe = SocialRecipeParser.parsePostText(noisyCaption);

      expect(recipe.ingredients.length, equals(3));
      expect(recipe.steps.length, equals(3));
      expect(recipe.steps.any((s) => s.instruction.contains('Comenta')), isFalse);
    });
  });
}
