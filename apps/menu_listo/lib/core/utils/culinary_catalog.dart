class CulinaryIngredientItem {
  final String name;
  final String nameEn;
  final String emoji;
  final String defaultUnit;
  final String category;

  const CulinaryIngredientItem({
    required this.name,
    required this.nameEn,
    required this.emoji,
    this.defaultUnit = 'g',
    this.category = 'General',
  });
}

class CulinaryCatalog {
  static const List<CulinaryIngredientItem> ingredients = [
    // Verduras & Hortalizas
    CulinaryIngredientItem(name: 'Cebolla', nameEn: 'Onion', emoji: '🧅', defaultUnit: 'u', category: 'Verduras'),
    CulinaryIngredientItem(name: 'Cebolla morada', nameEn: 'Red onion', emoji: '🧅', defaultUnit: 'u', category: 'Verduras'),
    CulinaryIngredientItem(name: 'Cebolla de verdeo', nameEn: 'Scallion / Green onion', emoji: '🧅', defaultUnit: 'u', category: 'Verduras'),
    CulinaryIngredientItem(name: 'Ajo', nameEn: 'Garlic', emoji: '🧄', defaultUnit: 'dientes', category: 'Verduras'),
    CulinaryIngredientItem(name: 'Tomate', nameEn: 'Tomato', emoji: '🍅', defaultUnit: 'u', category: 'Verduras'),
    CulinaryIngredientItem(name: 'Tomates cherry', nameEn: 'Cherry tomatoes', emoji: '🍅', defaultUnit: 'g', category: 'Verduras'),
    CulinaryIngredientItem(name: 'Zanahoria', nameEn: 'Carrot', emoji: '🥕', defaultUnit: 'u', category: 'Verduras'),
    CulinaryIngredientItem(name: 'Papa / Patata', nameEn: 'Potato', emoji: '🥔', defaultUnit: 'u', category: 'Verduras'),
    CulinaryIngredientItem(name: 'Batata / Camote', nameEn: 'Sweet potato', emoji: '🍠', defaultUnit: 'u', category: 'Verduras'),
    CulinaryIngredientItem(name: 'Palta / Aguacate', nameEn: 'Avocado', emoji: '🥑', defaultUnit: 'u', category: 'Verduras'),
    CulinaryIngredientItem(name: 'Morrón rojo / Pimiento rojo', nameEn: 'Red bell pepper', emoji: '🌶️', defaultUnit: 'u', category: 'Verduras'),
    CulinaryIngredientItem(name: 'Morrón verde / Pimiento verde', nameEn: 'Green bell pepper', emoji: '🫑', defaultUnit: 'u', category: 'Verduras'),
    CulinaryIngredientItem(name: 'Morrón amarillo / Pimiento amarillo', nameEn: 'Yellow bell pepper', emoji: '🫑', defaultUnit: 'u', category: 'Verduras'),
    CulinaryIngredientItem(name: 'Morrón / Pimiento / Ají', nameEn: 'Bell pepper', emoji: '🫑', defaultUnit: 'u', category: 'Verduras'),
    CulinaryIngredientItem(name: 'Champiñones / Hongos', nameEn: 'Mushrooms', emoji: '🍄', defaultUnit: 'g', category: 'Verduras'),
    CulinaryIngredientItem(name: 'Portobellos', nameEn: 'Portobello mushrooms', emoji: '🍄', defaultUnit: 'g', category: 'Verduras'),
    CulinaryIngredientItem(name: 'Espinaca', nameEn: 'Spinach', emoji: '🥬', defaultUnit: 'g', category: 'Verduras'),
    CulinaryIngredientItem(name: 'Acelga', nameEn: 'Swiss chard', emoji: '🥬', defaultUnit: 'atado', category: 'Verduras'),
    CulinaryIngredientItem(name: 'Lechuga', nameEn: 'Lettuce', emoji: '🥬', defaultUnit: 'u', category: 'Verduras'),
    CulinaryIngredientItem(name: 'Rúcula', nameEn: 'Arugula / Rocket', emoji: '🥬', defaultUnit: 'g', category: 'Verduras'),
    CulinaryIngredientItem(name: 'Brócoli', nameEn: 'Broccoli', emoji: '🥦', defaultUnit: 'g', category: 'Verduras'),
    CulinaryIngredientItem(name: 'Coliflor', nameEn: 'Cauliflower', emoji: '🥦', defaultUnit: 'u', category: 'Verduras'),
    CulinaryIngredientItem(name: 'Calabaza / Zapallo', nameEn: 'Pumpkin / Squash', emoji: '🎃', defaultUnit: 'g', category: 'Verduras'),
    CulinaryIngredientItem(name: 'Zucchini / Calabacín', nameEn: 'Zucchini', emoji: '🥒', defaultUnit: 'u', category: 'Verduras'),
    CulinaryIngredientItem(name: 'Berenjena', nameEn: 'Eggplant', emoji: '🍆', defaultUnit: 'u', category: 'Verduras'),
    CulinaryIngredientItem(name: 'Pepino', nameEn: 'Cucumber', emoji: '🥒', defaultUnit: 'u', category: 'Verduras'),
    CulinaryIngredientItem(name: 'Choclo / Maíz', nameEn: 'Corn', emoji: '🌽', defaultUnit: 'u', category: 'Verduras'),
    CulinaryIngredientItem(name: 'Espárragos', nameEn: 'Asparagus', emoji: '🥬', defaultUnit: 'atado', category: 'Verduras'),
    CulinaryIngredientItem(name: 'Puerro', nameEn: 'Leek', emoji: '🧅', defaultUnit: 'u', category: 'Verduras'),
    CulinaryIngredientItem(name: 'Apio', nameEn: 'Celery', emoji: '🥬', defaultUnit: 'tallos', category: 'Verduras'),
    CulinaryIngredientItem(name: 'Remolacha', nameEn: 'Beetroot', emoji: '🥕', defaultUnit: 'u', category: 'Verduras'),
    CulinaryIngredientItem(name: 'Ciboulette / Cebollino', nameEn: 'Chives', emoji: '🌿', defaultUnit: 'cda', category: 'Verduras'),

    // Frutas
    CulinaryIngredientItem(name: 'Limón', nameEn: 'Lemon', emoji: '🍋', defaultUnit: 'u', category: 'Frutas'),
    CulinaryIngredientItem(name: 'Lima', nameEn: 'Lime', emoji: '🍋', defaultUnit: 'u', category: 'Frutas'),
    CulinaryIngredientItem(name: 'Naranja', nameEn: 'Orange', emoji: '🍊', defaultUnit: 'u', category: 'Frutas'),
    CulinaryIngredientItem(name: 'Banana / Plátano', nameEn: 'Banana', emoji: '🍌', defaultUnit: 'u', category: 'Frutas'),
    CulinaryIngredientItem(name: 'Manzana', nameEn: 'Apple', emoji: '🍎', defaultUnit: 'u', category: 'Frutas'),
    CulinaryIngredientItem(name: 'Manzana verde', nameEn: 'Green apple', emoji: '🍏', defaultUnit: 'u', category: 'Frutas'),
    CulinaryIngredientItem(name: 'Pera', nameEn: 'Pear', emoji: '🍐', defaultUnit: 'u', category: 'Frutas'),
    CulinaryIngredientItem(name: 'Frutillas / Fresas', nameEn: 'Strawberries', emoji: '🍓', defaultUnit: 'g', category: 'Frutas'),
    CulinaryIngredientItem(name: 'Arándanos', nameEn: 'Blueberries', emoji: '🫐', defaultUnit: 'g', category: 'Frutas'),
    CulinaryIngredientItem(name: 'Frambuesas', nameEn: 'Raspberries', emoji: '🍓', defaultUnit: 'g', category: 'Frutas'),
    CulinaryIngredientItem(name: 'Durazno / Melocotón', nameEn: 'Peach', emoji: '🍑', defaultUnit: 'u', category: 'Frutas'),
    CulinaryIngredientItem(name: 'Piña / Ananá', nameEn: 'Pineapple', emoji: '🍍', defaultUnit: 'u', category: 'Frutas'),
    CulinaryIngredientItem(name: 'Mango', nameEn: 'Mango', emoji: '🥭', defaultUnit: 'u', category: 'Frutas'),
    CulinaryIngredientItem(name: 'Uvas', nameEn: 'Grapes', emoji: '🍇', defaultUnit: 'g', category: 'Frutas'),
    CulinaryIngredientItem(name: 'Sandía', nameEn: 'Watermelon', emoji: '🍉', defaultUnit: 'g', category: 'Frutas'),
    CulinaryIngredientItem(name: 'Melón', nameEn: 'Melon', emoji: '🍈', defaultUnit: 'u', category: 'Frutas'),
    CulinaryIngredientItem(name: 'Kiwi', nameEn: 'Kiwi', emoji: '🥝', defaultUnit: 'u', category: 'Frutas'),
    CulinaryIngredientItem(name: 'Coco', nameEn: 'Coconut', emoji: '🥥', defaultUnit: 'g', category: 'Frutas'),

    // Carnes & Aves
    CulinaryIngredientItem(name: 'Pechuga de pollo', nameEn: 'Chicken breast', emoji: '🍗', defaultUnit: 'g', category: 'Carnes'),
    CulinaryIngredientItem(name: 'Pollo entero', nameEn: 'Whole chicken', emoji: '🍗', defaultUnit: 'kg', category: 'Carnes'),
    CulinaryIngredientItem(name: 'Muslos de pollo', nameEn: 'Chicken thighs', emoji: '🍗', defaultUnit: 'u', category: 'Carnes'),
    CulinaryIngredientItem(name: 'Carne picada / Molida', nameEn: 'Ground beef', emoji: '🥩', defaultUnit: 'g', category: 'Carnes'),
    CulinaryIngredientItem(name: 'Bife / Entrecot', nameEn: 'Beef steak', emoji: '🥩', defaultUnit: 'g', category: 'Carnes'),
    CulinaryIngredientItem(name: 'Lomo vacuno', nameEn: 'Beef tenderloin', emoji: '🥩', defaultUnit: 'g', category: 'Carnes'),
    CulinaryIngredientItem(name: 'Carne de cerdo / Bondiola', nameEn: 'Pork shoulder', emoji: '🥩', defaultUnit: 'g', category: 'Carnes'),
    CulinaryIngredientItem(name: 'Panceta / Bacon / Tocino', nameEn: 'Bacon', emoji: '🥓', defaultUnit: 'g', category: 'Carnes'),
    CulinaryIngredientItem(name: 'Jamón cocido', nameEn: 'Ham', emoji: '🥓', defaultUnit: 'g', category: 'Carnes'),
    CulinaryIngredientItem(name: 'Jamón crudo / Serrano', nameEn: 'Prosciutto / Cured ham', emoji: '🥓', defaultUnit: 'g', category: 'Carnes'),
    CulinaryIngredientItem(name: 'Chorizo', nameEn: 'Sausage / Chorizo', emoji: '🌭', defaultUnit: 'u', category: 'Carnes'),

    // Pescados & Mariscos
    CulinaryIngredientItem(name: 'Salmón fresco', nameEn: 'Salmon fillet', emoji: '🐟', defaultUnit: 'g', category: 'Pescados'),
    CulinaryIngredientItem(name: 'Atún en lata', nameEn: 'Canned tuna', emoji: '🐟', defaultUnit: 'lata', category: 'Pescados'),
    CulinaryIngredientItem(name: 'Atún fresco', nameEn: 'Fresh tuna', emoji: '🐟', defaultUnit: 'g', category: 'Pescados'),
    CulinaryIngredientItem(name: 'Merluza / Pescado blanco', nameEn: 'Hake / White fish', emoji: '🐟', defaultUnit: 'g', category: 'Pescados'),
    CulinaryIngredientItem(name: 'Langostinos / Camarones', nameEn: 'Shrimp / Prawns', emoji: '🦐', defaultUnit: 'g', category: 'Pescados'),
    CulinaryIngredientItem(name: 'Calamares', nameEn: 'Squid', emoji: '🦑', defaultUnit: 'g', category: 'Pescados'),
    CulinaryIngredientItem(name: 'Mejillones', nameEn: 'Mussels', emoji: '🦪', defaultUnit: 'g', category: 'Pescados'),

    // Lácteos & Huevos
    CulinaryIngredientItem(name: 'Huevo / Huevos', nameEn: 'Eggs', emoji: '🥚', defaultUnit: 'u', category: 'Lácteos'),
    CulinaryIngredientItem(name: 'Leche entera', nameEn: 'Whole milk', emoji: '🥛', defaultUnit: 'ml', category: 'Lácteos'),
    CulinaryIngredientItem(name: 'Leche descremada', nameEn: 'Skim milk', emoji: '🥛', defaultUnit: 'ml', category: 'Lácteos'),
    CulinaryIngredientItem(name: 'Leche de almendras / vegetal', nameEn: 'Almond milk', emoji: '🥛', defaultUnit: 'ml', category: 'Lácteos'),
    CulinaryIngredientItem(name: 'Leche de coco', nameEn: 'Coconut milk', emoji: '🥥', defaultUnit: 'ml', category: 'Lácteos'),
    CulinaryIngredientItem(name: 'Crema de leche / Nata', nameEn: 'Heavy cream', emoji: '🥛', defaultUnit: 'ml', category: 'Lácteos'),
    CulinaryIngredientItem(name: 'Manteca / Mantequilla', nameEn: 'Butter', emoji: '🧈', defaultUnit: 'g', category: 'Lácteos'),
    CulinaryIngredientItem(name: 'Queso Parmesano / Rallado', nameEn: 'Parmesan cheese', emoji: '🧀', defaultUnit: 'g', category: 'Lácteos'),
    CulinaryIngredientItem(name: 'Queso Mozzarella', nameEn: 'Mozzarella cheese', emoji: '🧀', defaultUnit: 'g', category: 'Lácteos'),
    CulinaryIngredientItem(name: 'Queso Cheddar', nameEn: 'Cheddar cheese', emoji: '🧀', defaultUnit: 'g', category: 'Lácteos'),
    CulinaryIngredientItem(name: 'Queso crema / Philadelphia', nameEn: 'Cream cheese', emoji: '🧀', defaultUnit: 'g', category: 'Lácteos'),
    CulinaryIngredientItem(name: 'Queso Ricotta', nameEn: 'Ricotta cheese', emoji: '🧀', defaultUnit: 'g', category: 'Lácteos'),
    CulinaryIngredientItem(name: 'Queso Feta', nameEn: 'Feta cheese', emoji: '🧀', defaultUnit: 'g', category: 'Lácteos'),
    CulinaryIngredientItem(name: 'Queso Azul / Roquefort', nameEn: 'Blue cheese', emoji: '🧀', defaultUnit: 'g', category: 'Lácteos'),
    CulinaryIngredientItem(name: 'Yogur natural / Griego', nameEn: 'Greek yogurt', emoji: '🥛', defaultUnit: 'g', category: 'Lácteos'),

    // Granos, Cereales & Pastas
    CulinaryIngredientItem(name: 'Arroz blanco', nameEn: 'White rice', emoji: '🍚', defaultUnit: 'g', category: 'Granos'),
    CulinaryIngredientItem(name: 'Arroz Carnaroli / Arborio', nameEn: 'Risotto rice', emoji: '🍚', defaultUnit: 'g', category: 'Granos'),
    CulinaryIngredientItem(name: 'Arroz integral', nameEn: 'Brown rice', emoji: '🍚', defaultUnit: 'g', category: 'Granos'),
    CulinaryIngredientItem(name: 'Avena en copos', nameEn: 'Rolled oats', emoji: '🌾', defaultUnit: 'g', category: 'Granos'),
    CulinaryIngredientItem(name: 'Quinoa', nameEn: 'Quinoa', emoji: '🌾', defaultUnit: 'g', category: 'Granos'),
    CulinaryIngredientItem(name: 'Pasta / Fideos / Spaghetti', nameEn: 'Pasta / Spaghetti', emoji: '🍝', defaultUnit: 'g', category: 'Granos'),
    CulinaryIngredientItem(name: 'Lasaña (placas)', nameEn: 'Lasagna sheets', emoji: '🍝', defaultUnit: 'u', category: 'Granos'),
    CulinaryIngredientItem(name: 'Fideos de arroz / Noodles', nameEn: 'Rice noodles', emoji: '🍜', defaultUnit: 'g', category: 'Granos'),
    CulinaryIngredientItem(name: 'Pan rallado', nameEn: 'Breadcrumbs', emoji: '🍞', defaultUnit: 'g', category: 'Granos'),
    CulinaryIngredientItem(name: 'Pan / Tostadas', nameEn: 'Bread / Toast', emoji: '🍞', defaultUnit: 'rebanadas', category: 'Granos'),
    CulinaryIngredientItem(name: 'Tortillas de trigo / maíz', nameEn: 'Tortillas', emoji: '🫓', defaultUnit: 'u', category: 'Granos'),

    // Legumbres
    CulinaryIngredientItem(name: 'Garbanzos', nameEn: 'Chickpeas', emoji: '🧆', defaultUnit: 'g', category: 'Legumbres'),
    CulinaryIngredientItem(name: 'Lentejas', nameEn: 'Lentils', emoji: '🍲', defaultUnit: 'g', category: 'Legumbres'),
    CulinaryIngredientItem(name: 'Porotos / Frijoles negros', nameEn: 'Black beans', emoji: '🫘', defaultUnit: 'g', category: 'Legumbres'),
    CulinaryIngredientItem(name: 'Porotos rojos / Alubias', nameEn: 'Red kidney beans', emoji: '🫘', defaultUnit: 'g', category: 'Legumbres'),
    CulinaryIngredientItem(name: 'Arvejas / Guisantes', nameEn: 'Green peas', emoji: '🟢', defaultUnit: 'g', category: 'Legumbres'),
    CulinaryIngredientItem(name: 'Tofu', nameEn: 'Tofu', emoji: '🧊', defaultUnit: 'g', category: 'Legumbres'),

    // Aceites, Vinagres, Líquidos & Condimentos
    CulinaryIngredientItem(name: 'Aceite de oliva virgen extra', nameEn: 'Extra virgin olive oil', emoji: '🫒', defaultUnit: 'cda', category: 'Despensa'),
    CulinaryIngredientItem(name: 'Aceite de girasol / vegetal', nameEn: 'Vegetable oil', emoji: '🌻', defaultUnit: 'cda', category: 'Despensa'),
    CulinaryIngredientItem(name: 'Aceite de sésamo', nameEn: 'Sesame oil', emoji: '🫒', defaultUnit: 'cdta', category: 'Despensa'),
    CulinaryIngredientItem(name: 'Vino tinto', nameEn: 'Red wine', emoji: '🍷', defaultUnit: 'ml', category: 'Despensa'),
    CulinaryIngredientItem(name: 'Vino blanco', nameEn: 'White wine', emoji: '🍷', defaultUnit: 'ml', category: 'Despensa'),
    CulinaryIngredientItem(name: 'Vino / Vino de cocina', nameEn: 'Wine / Cooking wine', emoji: '🍷', defaultUnit: 'ml', category: 'Despensa'),
    CulinaryIngredientItem(name: 'Cerveza', nameEn: 'Beer', emoji: '🍺', defaultUnit: 'ml', category: 'Despensa'),
    CulinaryIngredientItem(name: 'Caldo de verduras / verdura', nameEn: 'Vegetable broth', emoji: '🍲', defaultUnit: 'ml', category: 'Despensa'),
    CulinaryIngredientItem(name: 'Caldo de carne / pollo', nameEn: 'Chicken / Beef broth', emoji: '🍲', defaultUnit: 'ml', category: 'Despensa'),
    CulinaryIngredientItem(name: 'Agua', nameEn: 'Water', emoji: '💧', defaultUnit: 'ml', category: 'Despensa'),
    CulinaryIngredientItem(name: 'Vinagre de manzana', nameEn: 'Apple cider vinegar', emoji: '🍶', defaultUnit: 'cda', category: 'Despensa'),
    CulinaryIngredientItem(name: 'Vinagre de vino / alcohol', nameEn: 'White / Wine vinegar', emoji: '🍶', defaultUnit: 'cda', category: 'Despensa'),
    CulinaryIngredientItem(name: 'Vinagre balsámico / Aceto', nameEn: 'Balsamic vinegar', emoji: '🍶', defaultUnit: 'cda', category: 'Despensa'),
    CulinaryIngredientItem(name: 'Salsa de soja', nameEn: 'Soy sauce', emoji: '🍶', defaultUnit: 'cda', category: 'Despensa'),
    CulinaryIngredientItem(name: 'Salsa de tomate / Passata', nameEn: 'Tomato sauce', emoji: '🥫', defaultUnit: 'g', category: 'Despensa'),
    CulinaryIngredientItem(name: 'Mostaza Dijon / Antigua', nameEn: 'Mustard', emoji: '🥫', defaultUnit: 'cda', category: 'Despensa'),
    CulinaryIngredientItem(name: 'Mayonesa', nameEn: 'Mayonnaise', emoji: '🥫', defaultUnit: 'cda', category: 'Despensa'),
    CulinaryIngredientItem(name: 'Ketchup', nameEn: 'Ketchup', emoji: '🥫', defaultUnit: 'cda', category: 'Despensa'),
    CulinaryIngredientItem(name: 'Miel', nameEn: 'Honey', emoji: '🍯', defaultUnit: 'cda', category: 'Despensa'),
    CulinaryIngredientItem(name: 'Jarabe de arce / Maple', nameEn: 'Maple syrup', emoji: '🍁', defaultUnit: 'cda', category: 'Despensa'),

    // Especias & Hierbas
    CulinaryIngredientItem(name: 'Sal fina / marina', nameEn: 'Salt', emoji: '🧂', defaultUnit: 'pizca', category: 'Especias'),
    CulinaryIngredientItem(name: 'Pimienta negra molida', nameEn: 'Black pepper', emoji: '🧂', defaultUnit: 'pizca', category: 'Especias'),
    CulinaryIngredientItem(name: 'Laurel (hojas)', nameEn: 'Bay leaves', emoji: '🌿', defaultUnit: 'hojas', category: 'Especias'),
    CulinaryIngredientItem(name: 'Orégano seco', nameEn: 'Oregano', emoji: '🌿', defaultUnit: 'cdta', category: 'Especias'),
    CulinaryIngredientItem(name: 'Albahaca fresca', nameEn: 'Fresh basil', emoji: '🌿', defaultUnit: 'hojas', category: 'Especias'),
    CulinaryIngredientItem(name: 'Romero fresco', nameEn: 'Rosemary', emoji: '🌿', defaultUnit: 'ramita', category: 'Especias'),
    CulinaryIngredientItem(name: 'Tomillo', nameEn: 'Thyme', emoji: '🌿', defaultUnit: 'cdta', category: 'Especias'),
    CulinaryIngredientItem(name: 'Cilantro fresco', nameEn: 'Cilantro / Coriander', emoji: '🌿', defaultUnit: 'atado', category: 'Especias'),
    CulinaryIngredientItem(name: 'Perejil fresco', nameEn: 'Parsley', emoji: '🌿', defaultUnit: 'cda', category: 'Especias'),
    CulinaryIngredientItem(name: 'Pimentón dulce / Ahumado', nameEn: 'Paprika', emoji: '🌶️', defaultUnit: 'cdta', category: 'Especias'),
    CulinaryIngredientItem(name: 'Comino molido', nameEn: 'Cumin', emoji: '🧂', defaultUnit: 'cdta', category: 'Especias'),
    CulinaryIngredientItem(name: 'Curry en polvo', nameEn: 'Curry powder', emoji: '🍛', defaultUnit: 'cda', category: 'Especias'),
    CulinaryIngredientItem(name: 'Cúrcuma', nameEn: 'Turmeric', emoji: '🫚', defaultUnit: 'cdta', category: 'Especias'),
    CulinaryIngredientItem(name: 'Jengibre fresco / en polvo', nameEn: 'Ginger', emoji: '🫚', defaultUnit: 'g', category: 'Especias'),
    CulinaryIngredientItem(name: 'Canela en polvo / en rama', nameEn: 'Cinnamon', emoji: '🪵', defaultUnit: 'cdta', category: 'Especias'),
    CulinaryIngredientItem(name: 'Nuez moscada', nameEn: 'Nutmeg', emoji: '🌰', defaultUnit: 'pizca', category: 'Especias'),
    CulinaryIngredientItem(name: 'Clavo de olor', nameEn: 'Cloves', emoji: '🪵', defaultUnit: 'u', category: 'Especias'),
    CulinaryIngredientItem(name: 'Ají molido / Chili flakes', nameEn: 'Chili flakes', emoji: '🌶️', defaultUnit: 'pizca', category: 'Especias'),

    // Repostería & Frutos Secos
    CulinaryIngredientItem(name: 'Harina 0000 / de trigo', nameEn: 'All-purpose flour', emoji: '🌾', defaultUnit: 'g', category: 'Repostería'),
    CulinaryIngredientItem(name: 'Harina de almendras', nameEn: 'Almond flour', emoji: '🌰', defaultUnit: 'g', category: 'Repostería'),
    CulinaryIngredientItem(name: 'Polvo para hornear / Levadura química', nameEn: 'Baking powder', emoji: '🥄', defaultUnit: 'cdta', category: 'Repostería'),
    CulinaryIngredientItem(name: 'Bicarbonato de sodio', nameEn: 'Baking soda', emoji: '🥄', defaultUnit: 'cdta', category: 'Repostería'),
    CulinaryIngredientItem(name: 'Levadura fresca / seca', nameEn: 'Yeast', emoji: '🍞', defaultUnit: 'g', category: 'Repostería'),
    CulinaryIngredientItem(name: 'Azúcar blanco', nameEn: 'Sugar', emoji: '🍬', defaultUnit: 'g', category: 'Repostería'),
    CulinaryIngredientItem(name: 'Azúcar mascabo / morena', nameEn: 'Brown sugar', emoji: '🍬', defaultUnit: 'g', category: 'Repostería'),
    CulinaryIngredientItem(name: 'Esencia de vainilla', nameEn: 'Vanilla extract', emoji: '🌼', defaultUnit: 'cdta', category: 'Repostería'),
    CulinaryIngredientItem(name: 'Chocolate amargo / Chips', nameEn: 'Dark chocolate', emoji: '🍫', defaultUnit: 'g', category: 'Repostería'),
    CulinaryIngredientItem(name: 'Cacao amargo en polvo', nameEn: 'Cocoa powder', emoji: '🍫', defaultUnit: 'cda', category: 'Repostería'),
    CulinaryIngredientItem(name: 'Dulce de leche', nameEn: 'Dulce de leche / Caramel', emoji: '🍯', defaultUnit: 'g', category: 'Repostería'),
    CulinaryIngredientItem(name: 'Nueces', nameEn: 'Walnuts', emoji: '🥜', defaultUnit: 'g', category: 'Frutos Secos'),
    CulinaryIngredientItem(name: 'Almendras', nameEn: 'Almonds', emoji: '🌰', defaultUnit: 'g', category: 'Frutos Secos'),
    CulinaryIngredientItem(name: 'Castañas de cajú / Anacardos', nameEn: 'Cashews', emoji: '🥜', defaultUnit: 'g', category: 'Frutos Secos'),
    CulinaryIngredientItem(name: 'Maní / Cacahuates', nameEn: 'Peanuts', emoji: '🥜', defaultUnit: 'g', category: 'Frutos Secos'),
    CulinaryIngredientItem(name: 'Semillas de chía', nameEn: 'Chia seeds', emoji: '🌱', defaultUnit: 'cda', category: 'Frutos Secos'),
    CulinaryIngredientItem(name: 'Semillas de girasol / sésamo', nameEn: 'Sesame seeds', emoji: '🌱', defaultUnit: 'cda', category: 'Frutos Secos'),
  ];

  static const List<String> units = [
    'unidades',
    'g',
    'kg',
    'ml',
    'l',
    'cda',
    'cdta',
    'taza',
    'dientes',
    'pizca',
    'rebanadas',
    'fetas',
    'atado',
    'lata',
    'paquete',
    'hojas',
    'ramita',
  ];

  static String normalizeUnit(String? unit) {
    if (unit == null || unit.trim().isEmpty) return 'unidades';
    final lower = unit.trim().toLowerCase();
    if (lower == 'u' || lower == 'unidad' || lower == 'unidades' || lower == 'unit' || lower == 'units') return 'unidades';
    if (lower == 'gr' || lower == 'grs' || lower == 'gramos' || lower == 'g' || lower == 'gram') return 'g';
    if (lower == 'kilo' || lower == 'kilos' || lower == 'kg') return 'kg';
    if (lower == 'mililitros' || lower == 'ml') return 'ml';
    if (lower == 'litro' || lower == 'litros' || lower == 'lt' || lower == 'l' || lower == 'liter') return 'l';
    if (lower == 'cda' || lower == 'cdas' || lower == 'cucharada' || lower == 'cucharadas' || lower == 'tbsp') return 'cda';
    if (lower == 'cdta' || lower == 'cdtas' || lower == 'cucharadita' || lower == 'cucharaditas' || lower == 'tsp') return 'cdta';
    if (lower == 'taza' || lower == 'tazas' || lower == 'cup' || lower == 'cups') return 'taza';
    if (lower == 'diente' || lower == 'dientes' || lower == 'clove' || lower == 'cloves') return 'dientes';
    if (lower == 'pizca' || lower == 'pizcas' || lower == 'pinch') return 'pizca';
    if (lower == 'rebanada' || lower == 'rebanadas' || lower == 'slice' || lower == 'slices') return 'rebanadas';
    if (lower == 'feta' || lower == 'fetas') return 'fetas';
    if (lower == 'atado' || lower == 'atados' || lower == 'bunch') return 'atado';
    if (lower == 'lata' || lower == 'latas' || lower == 'can' || lower == 'cans') return 'lata';
    if (lower == 'paquete' || lower == 'paquetes' || lower == 'pack') return 'paquete';
    if (lower == 'hoja' || lower == 'hojas' || lower == 'leaf' || lower == 'leaves') return 'hojas';
    if (lower == 'ramita' || lower == 'ramitas' || lower == 'sprig') return 'ramita';
    if (units.contains(lower)) return lower;
    return 'unidades';
  }

  static String getCategory(String ingredientName) {
    if (ingredientName.trim().isEmpty) return 'General';
    final lower = ingredientName.toLowerCase();
    for (var item in ingredients) {
      if (lower.contains(item.name.toLowerCase()) || lower.contains(item.nameEn.toLowerCase())) {
        return item.category;
      }
    }
    if (lower.contains('carne') || lower.contains('pollo') || lower.contains('bife') || lower.contains('cerdo') || lower.contains('panceta') || lower.contains('jamón')) return 'Carnes';
    if (lower.contains('pescado') || lower.contains('salmón') || lower.contains('atún') || lower.contains('merluza') || lower.contains('langostino')) return 'Pescados';
    if (lower.contains('queso') || lower.contains('leche') || lower.contains('crema') || lower.contains('yogur') || lower.contains('manteca') || lower.contains('huevo')) return 'Lácteos';
    if (lower.contains('cebolla') || lower.contains('tomate') || lower.contains('papa') || lower.contains('zanahoria') || lower.contains('lechuga') || lower.contains('ajo') || lower.contains('espinaca') || lower.contains('palta') || lower.contains('morron') || lower.contains('morrón') || lower.contains('pimiento')) return 'Verduras';
    if (lower.contains('manzana') || lower.contains('banana') || lower.contains('limón') || lower.contains('naranja') || lower.contains('frutilla')) return 'Frutas';
    if (lower.contains('arroz') || lower.contains('fideo') || lower.contains('pasta') || lower.contains('pan') || lower.contains('avena')) return 'Granos';
    if (lower.contains('harina') || lower.contains('azúcar') || lower.contains('chocolate') || lower.contains('vainilla') || lower.contains('polvo para hornear')) return 'Repostería';
    if (lower.contains('sal') || lower.contains('pimienta') || lower.contains('orégano') || lower.contains('pimentón') || lower.contains('comino') || lower.contains('laurel') || lower.contains('tomillo') || lower.contains('romero') || lower.contains('albahaca') || lower.contains('perejil') || lower.contains('cilantro')) return 'Especias';
    if (lower.contains('aceite') || lower.contains('vinagre') || lower.contains('vino') || lower.contains('caldo') || lower.contains('soja') || lower.contains('salsa') || lower.contains('mostaza') || lower.contains('mayonesa')) return 'Despensa';
    return 'General';
  }

  static bool isPantryStaple(String ingredientName) {
    final lower = removeDiacritics(ingredientName.toLowerCase().trim());
    return lower.contains('sal') ||
        lower.contains('pimienta') ||
        lower.contains('aceite') ||
        lower.contains('vinagre') ||
        lower.contains('azucar') ||
        lower.contains('harina') ||
        lower.contains('oregano') ||
        lower.contains('comino') ||
        lower.contains('pimenton') ||
        lower.contains('laurel') ||
        lower.contains('agua');
  }

  static String removeDiacritics(String str) {
    var withDia = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
    var withoutDia = 'AAAAAAaaaaaaOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';
    for (int i = 0; i < withDia.length; i++) {
      str = str.replaceAll(withDia[i], withoutDia[i]);
    }
    return str;
  }

  static String getEmoji(String ingredientName) {
    if (ingredientName.trim().isEmpty) return '🥗';
    final normalized = removeDiacritics(ingredientName.toLowerCase());

    // Check specific red pepper first
    if ((normalized.contains('morron') || normalized.contains('pimiento') || normalized.contains('aji')) &&
        (normalized.contains('rojo') || normalized.contains('red'))) {
      return '🌶️';
    }

    for (var item in ingredients) {
      final nameNorm = removeDiacritics(item.name.toLowerCase());
      final enNorm = removeDiacritics(item.nameEn.toLowerCase());

      final parts = nameNorm.split('/');
      for (var p in parts) {
        final cleanP = p.trim();
        if (cleanP.length > 2 && normalized.contains(cleanP)) {
          return item.emoji;
        }
      }

      final enParts = enNorm.split('/');
      for (var p in enParts) {
        final cleanP = p.trim();
        if (cleanP.length > 2 && normalized.contains(cleanP)) {
          return item.emoji;
        }
      }
    }

    // Fallback based on keywords
    if (normalized.contains('morron') || normalized.contains('pimiento') || normalized.contains('aji') || normalized.contains('pepper')) return '🫑';
    if (normalized.contains('vino') || normalized.contains('wine')) return '🍷';
    if (normalized.contains('cerveza') || normalized.contains('beer')) return '🍺';
    if (normalized.contains('caldo') || normalized.contains('broth') || normalized.contains('sopa')) return '🍲';
    if (normalized.contains('carne') || normalized.contains('beef') || normalized.contains('bife') || normalized.contains('lomo')) return '🥩';
    if (normalized.contains('pollo') || normalized.contains('chicken') || normalized.contains('ave')) return '🍗';
    if (normalized.contains('pescado') || normalized.contains('fish') || normalized.contains('salmon') || normalized.contains('atun')) return '🐟';
    if (normalized.contains('queso') || normalized.contains('cheese')) return '🧀';
    if (normalized.contains('huevo') || normalized.contains('egg')) return '🥚';
    if (normalized.contains('leche') || normalized.contains('milk') || normalized.contains('crema')) return '🥛';
    if (normalized.contains('aceite') || normalized.contains('oil')) return '🫒';
    if (normalized.contains('harina') || normalized.contains('flour') || normalized.contains('pan')) return '🌾';
    if (normalized.contains('fruta') || normalized.contains('fruit') || normalized.contains('manzana') || normalized.contains('pera')) return '🍎';
    if (normalized.contains('pasta') || normalized.contains('fideo') || normalized.contains('spaghetti')) return '🍝';
    if (normalized.contains('arroz') || normalized.contains('rice')) return '🍚';
    if (normalized.contains('sal') || normalized.contains('pimienta') || normalized.contains('especia') || normalized.contains('laurel') || normalized.contains('oregano')) return '🧂';
    if (normalized.contains('albahaca') || normalized.contains('perejil') || normalized.contains('cilantro') || normalized.contains('romero') || normalized.contains('tomillo')) return '🌿';

    return '🥗';
  }
}
