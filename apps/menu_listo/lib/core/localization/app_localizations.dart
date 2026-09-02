import 'package:flutter/widgets.dart';

enum AppLanguage {
  system,
  es,
  en;

  Locale? get locale {
    switch (this) {
      case AppLanguage.es:
        return const Locale('es');
      case AppLanguage.en:
        return const Locale('en');
      case AppLanguage.system:
        return null;
    }
  }
}

class AppStrings {
  final Locale locale;

  AppStrings(this.locale);

  static AppStrings of(BuildContext context) {
    final loc = Localizations.localeOf(context);
    return AppStrings(loc);
  }

  bool get isSpanish => locale.languageCode == 'es';


  // Meal slots getters
  String get confirm => isSpanish ? 'Confirmar' : 'Confirm';
  String get noRecipeAssigned => isSpanish ? 'Sin receta asignada' : 'No recipe assigned';
  String get removeMealSlot => isSpanish ? 'Quitar comida' : 'Remove meal';
  String get mealBreakfast => isSpanish ? 'Desayuno' : 'Breakfast';
  String get mealLunch => isSpanish ? 'Almuerzo' : 'Lunch';
  String get mealSnack => isSpanish ? 'Merienda' : 'Snack';
  String get mealDinner => isSpanish ? 'Cena' : 'Dinner';

  // Navigation Tabs
  String get tabRecipes => isSpanish ? 'Recetas' : 'Recipes';
  String get tabPlanner => isSpanish ? 'Planificador' : 'Meal Planner';
  String get tabShopping => isSpanish ? 'Compras' : 'Shopping List';
  String get tabSettings => isSpanish ? 'Ajustes' : 'Settings';

  // App General
  String get appTitle => 'Menú Listo';
  String get appTagline => isSpanish 
      ? 'Recetas, Planificador Semanal y Compras Inteligentes' 
      : 'Recipes, Weekly Meal Planner & Smart Grocery';

  // Common Actions & Badges
  String get minutes => isSpanish ? 'min' : 'min';
  String get persons => isSpanish ? 'porc.' : 'servings';
  String get close => isSpanish ? 'Cerrar' : 'Close';
  String get save => isSpanish ? 'Guardar' : 'Save';
  String get cancel => isSpanish ? 'Cancelar' : 'Cancel';
  String get delete => isSpanish ? 'Eliminar' : 'Delete';

  // Empty States
  String get emptyTitle => isSpanish ? 'Sin elementos' : 'No items';
  String get emptyRecipesTitle => isSpanish ? '¡Bienvenido a tu cocina!' : 'Welcome to your kitchen!';
  String get emptyRecipesSubtitle => isSpanish 
      ? 'Aún no tienes recetas guardadas. Comienza agregando tu primera receta casera, escaneando una foto de un libro o importando desde la web.'
      : 'You have no saved recipes yet. Start by creating a homemade dish, scanning a photo from a cookbook, or importing from a web link.';
  String get createFirstRecipe => isSpanish ? 'Crear mi primera receta' : 'Create my first recipe';
  String get scanRecipePhoto => isSpanish ? 'Escanear con Cámara / Foto' : 'Scan from Photo / Camera';
  String get importWebRecipe => isSpanish ? 'Importar desde enlace web' : 'Import from web URL';

  // Recipe List Screen
  String get searchRecipes => isSpanish ? 'Buscar recetas...' : 'Search recipes...';
  String get searchRecipesHint => isSpanish ? 'Buscar por título o ingrediente...' : 'Search by title or ingredient...';
  String get filterAll => isSpanish ? 'Todas' : 'All';
  String get filterBreakfast => isSpanish ? 'Desayuno' : 'Breakfast';
  String get filterLunch => isSpanish ? 'Almuerzo' : 'Lunch';
  String get filterSnack => isSpanish ? 'Merienda' : 'Snack';
  String get filterDinner => isSpanish ? 'Cena' : 'Dinner';
  String get filterDessert => isSpanish ? 'Postres' : 'Dessert';
  String get onlyFavorites => isSpanish ? 'Solo Favoritas' : 'Only Favorites';
  String get viewGrid => isSpanish ? 'Vista Cuadrícula' : 'Grid View';
  String get viewList => isSpanish ? 'Vista Lista' : 'List View';
  String get noResultsTitle => isSpanish ? 'Sin resultados' : 'No recipes found';
  String get noResultsSubtitle => isSpanish ? 'Prueba con otra palabra clave o categoría.' : 'Try another search term or filter.';

  // Recipe Detail Screen
  String get servings => isSpanish ? 'Porciones' : 'Servings';
  String get diners => isSpanish ? 'comensales' : 'diners';
  String get adjustServings => isSpanish ? 'Ajustar porciones' : 'Adjust servings';
  String get prepTime => isSpanish ? 'Preparación' : 'Prep';
  String get cookTime => isSpanish ? 'Cocción' : 'Cook';
  String get ingredientsTitle => isSpanish ? 'Ingredientes' : 'Ingredients';
  String get instructionsTitle => isSpanish ? 'Instrucciones paso a paso' : 'Step-by-Step Instructions';
  String get stepsTitle => isSpanish ? 'Instrucciones paso a paso' : 'Step-by-Step Instructions';
  String get startCooking => isSpanish ? 'Comenzar a Cocinar (Modo Cocina)' : 'Start Cooking (Kitchen Mode)';
  String get startCookingMode => isSpanish ? 'Comenzar a Cocinar (Modo Cocina)' : 'Start Cooking (Kitchen Mode)';
  String get editRecipe => isSpanish ? 'Editar Receta' : 'Edit Recipe';
  String get deleteRecipe => isSpanish ? 'Eliminar Receta' : 'Delete Recipe';
  String get confirmDeleteRecipe => isSpanish ? '¿Estás seguro de que deseas eliminar esta receta?' : 'Are you sure you want to delete this recipe?';
  String get deleteRecipeConfirm => isSpanish ? '¿Estás seguro de que deseas eliminar esta receta?' : 'Are you sure you want to delete this recipe?';

  // Cook Mode Screen
  String get cookModeTitle => isSpanish ? 'Modo Cocina' : 'Cook Mode';
  String get cookModeWakeLockNotice => isSpanish ? 'Pantalla siempre encendida para cocinar cómodo' : 'Screen kept awake for cooking';
  String get screenAwakeNotice => isSpanish ? 'Pantalla siempre encendida' : 'Screen kept awake';
  String get step => isSpanish ? 'Paso' : 'Step';
  String get stepOf => isSpanish ? 'Paso' : 'Step';
  String get ofWord => isSpanish ? 'de' : 'of';
  String get ofSteps => isSpanish ? 'de' : 'of';
  String get viewIngredients => isSpanish ? 'Ver Ingredientes' : 'View Ingredients';
  String get previousStep => isSpanish ? 'Anterior' : 'Previous';
  String get nextStep => isSpanish ? 'Siguiente' : 'Next';
  String get finishCooking => isSpanish ? '¡Terminar y Listo!' : 'Finish Cooking!';
  String get finishCookingMessage => isSpanish ? '¡Felicitaciones! Has completado todos los pasos de la receta.' : 'Congratulations! You completed all steps of the recipe.';
  String get allStepsCompleted => isSpanish ? '¡Felicitaciones! Has completado la receta.' : 'Congratulations! You completed the recipe.';

  // Recipe Form Screen
  String get newRecipeTitle => isSpanish ? 'Nueva Receta' : 'New Recipe';
  String get editRecipeTitle => isSpanish ? 'Editar Receta' : 'Edit Recipe';
  String get basicInfoSection => isSpanish ? 'Información Principal' : 'General Info';
  String get titleLabel => isSpanish ? 'Nombre de la Receta *' : 'Recipe Title *';
  String get titleRequired => isSpanish ? 'Por favor ingresa un título' : 'Please enter a title';
  String get categoryLabel => isSpanish ? 'Categoría' : 'Category';
  String get descriptionLabel => isSpanish ? 'Breve descripción o notas' : 'Short description or notes';
  String get prepTimeMinutesLabel => isSpanish ? 'Tiempo de Prep. (min)' : 'Prep Time (mins)';
  String get cookTimeMinutesLabel => isSpanish ? 'Tiempo de Cocción (min)' : 'Cook Time (mins)';
  String get baseServingsLabel => isSpanish ? 'Porciones base (comensales)' : 'Base Servings (diners)';
  String get prepLabel => isSpanish ? 'Prep (min)' : 'Prep (min)';
  String get cookLabel => isSpanish ? 'Cocción (min)' : 'Cook (min)';
  String get servingsLabel => isSpanish ? 'Porciones' : 'Servings';
  String get addIngredient => isSpanish ? 'Agregar Ingrediente' : 'Add Ingredient';
  String get addStep => isSpanish ? 'Agregar Paso' : 'Add Step';
  String get amountHeader => isSpanish ? 'Cant.' : 'Qty';
  String get unitHeader => isSpanish ? 'Unidad' : 'Unit';
  String get nameHeader => isSpanish ? 'Ingrediente *' : 'Ingredient *';
  String get notesHeader => isSpanish ? 'Notas (opc.)' : 'Notes (opt.)';
  String get instructionHint => isSpanish ? 'Describe el paso de preparación...' : 'Describe this preparation step...';
  String get ingredientsQuickInputHint => isSpanish 
      ? 'Un ingrediente por línea, ej:\n500g pechuga de pollo\n2 cebollas picadas\n1/2 taza de leche\n1 pizca de sal' 
      : 'One ingredient per line, e.g.:\n500g chicken breast\n2 onions, chopped\n1/2 cup milk\n1 pinch of salt';
  String get ingredientsDetected => isSpanish ? 'ingredientes detectados' : 'ingredients detected';
  String get stepsQuickInputHint => isSpanish 
      ? 'Escribe o pega los pasos de preparación, ej:\n1. Picar la cebolla y dorar en sartén.\n2. Agregar el pollo y cocinar 15 minutos.\n3. Servir caliente con salsa.' 
      : 'Write or paste preparation steps, e.g.:\n1. Chop onion and brown in pan.\n2. Add chicken and cook 15 minutes.\n3. Serve hot with sauce.';
  String get stepsDetected => isSpanish ? 'pasos detectados' : 'steps detected';
  String get insertNextStep => isSpanish ? '+ Siguiente paso' : '+ Next step';
  String get saveRecipe => isSpanish ? 'Guardar Receta' : 'Save Recipe';
  String get changePhoto => isSpanish ? 'Cambiar Foto' : 'Change Photo';
  String get addPhoto => isSpanish ? 'Agregar Foto' : 'Add Cover Photo';
  String get takePhoto => isSpanish ? 'Tomar Foto' : 'Take Photo';
  String get chooseFromGallery => isSpanish ? 'Elegir de Galería' : 'Choose from Gallery';

  // Photo OCR Scanner
  String get scanningRecipe => isSpanish ? 'Escaneando receta...' : 'Scanning recipe...';
  String get scanningSuccess => isSpanish ? '¡Receta escaneada con éxito!' : 'Recipe scanned successfully!';
  String get scanningFailed => isSpanish ? 'No se detectó texto claro en la imagen. Intenta con mejor iluminación.' : 'No clear text detected. Try with better lighting.';

  // URL Importer Dialog
  String get importUrlTitle => isSpanish ? 'Importar Receta desde la Web' : 'Import Recipe from Web';
  String get importUrlDescription => isSpanish ? 'Pega el enlace de cualquier blog o sitio gastronómico:' : 'Paste any food blog or recipe URL:';
  String get importUrlSubtitle => isSpanish ? 'Pega el enlace de cualquier blog o sitio gastronómico:' : 'Paste any food blog or recipe URL:';
  String get pasteUrlHint => 'https://...';
  String get urlInputHint => 'https://...';
  String get extractRecipe => isSpanish ? 'Extraer Receta' : 'Extract Recipe';
  String get importButton => isSpanish ? 'Extraer Receta' : 'Extract Recipe';
  String get scrapingProgress => isSpanish ? 'Extrayendo ingredientes y pasos limpios...' : 'Extracting ingredients & instructions...';
  String get importingProgress => isSpanish ? 'Extrayendo ingredientes y pasos limpios...' : 'Extracting ingredients & instructions...';
  String get scrapingFailed => isSpanish ? 'No se pudo extraer la receta automáticamente de este sitio.' : 'Could not automatically extract recipe from this site.';
  String get importSuccess => isSpanish ? '¡Receta extraída con éxito!' : 'Recipe extracted successfully!';
  String get importError => isSpanish ? 'No se pudo extraer la receta automáticamente de este sitio.' : 'Could not automatically extract recipe from this site.';

  // Weekly Planner Screen
  String get plannerTitle => isSpanish ? 'Planificador Semanal' : 'Weekly Meal Planner';
  String get weeklyPlannerTitle => isSpanish ? 'Planificador Semanal' : 'Weekly Meal Planner';
  String get fillRandom => isSpanish ? 'Completar al Azar' : 'Random Fill';
  String get clearWeek => isSpanish ? 'Limpiar Semana' : 'Clear Week';
  String get clearWeekConfirm => isSpanish ? '¿Deseas limpiar todos los menús de esta semana?' : 'Do you want to clear all meals for this week?';
  String get thisWeek => isSpanish ? 'Esta Semana' : 'This Week';
  String get today => isSpanish ? 'Hoy' : 'Today';
  String get randomFill => isSpanish ? 'Completar al Azar' : 'Random Fill';
  String get randomFillConfirm => isSpanish 
      ? '¿Deseas autocompletar los espacios vacíos de esta semana con recetas de tu recetario?' 
      : 'Do you want to fill empty slots this week with recipes from your library?';
  String get fill => isSpanish ? 'Completar' : 'Fill';
  String get clear => isSpanish ? 'Limpiar' : 'Clear';
  String get monday => isSpanish ? 'Lunes' : 'Monday';
  String get tuesday => isSpanish ? 'Martes' : 'Tuesday';
  String get wednesday => isSpanish ? 'Miércoles' : 'Wednesday';
  String get thursday => isSpanish ? 'Jueves' : 'Thursday';
  String get friday => isSpanish ? 'Viernes' : 'Friday';
  String get saturday => isSpanish ? 'Sábado' : 'Saturday';
  String get sunday => isSpanish ? 'Domingo' : 'Sunday';
  String get breakfast => isSpanish ? 'Desayuno' : 'Breakfast';
  String get lunch => isSpanish ? 'Almuerzo' : 'Lunch';
  String get snack => isSpanish ? 'Merienda' : 'Snack';
  String get dinner => isSpanish ? 'Cena' : 'Dinner';
  String get emptySlot => isSpanish ? '+ Asignar comida' : '+ Assign meal';
  String get changeMeal => isSpanish ? 'Cambiar' : 'Change';
  String get removeMeal => isSpanish ? 'Quitar' : 'Remove';
  String get selectRecipeForSlot => isSpanish ? 'Seleccionar Receta para' : 'Select Recipe for';
  String get customMealTitle => isSpanish ? 'O ingresar comida libre:' : 'Or enter custom meal:';
  String get customMealHint => isSpanish ? 'ej. Pizza con amigos' : 'e.g. Pizza night';
  String get assignButton => isSpanish ? 'Asignar' : 'Assign';

  // Shopping List Screen
  String get shoppingTitle => isSpanish ? 'Lista de Compras' : 'Shopping List';
  String get shoppingListTitle => isSpanish ? 'Lista de Compras' : 'Shopping List';
  String get generateFromWeeklyPlan => isSpanish ? 'Generar desde el Menú Semanal' : 'Generate from Weekly Plan';
  String get generateFromPlanner => isSpanish ? 'Generar desde el Menú Semanal' : 'Generate from Weekly Plan';
  String get generateConfirm => isSpanish 
      ? '¿Generar lista a partir de las recetas del plan semanal? Los ingredientes repetidos se consolidarán automáticamente.' 
      : 'Generate grocery list from weekly plan? Matching ingredients will be automatically summed.';
  String get generate => isSpanish ? 'Generar' : 'Generate';
  String get generateSuccess => isSpanish ? 'Lista generada con éxito' : 'List generated successfully';
  String get shareList => isSpanish ? 'Compartir en WhatsApp' : 'Share List';
  String get shareListHeader => isSpanish ? '🛒 Lista de Compras - Menú Listo' : '🛒 Grocery Shopping List - Menú Listo';
  String get addManualItem => isSpanish ? 'Agregar ítem manual' : 'Add manual item';
  String get addCustomItem => isSpanish ? 'Agregar ítem manual' : 'Add manual item';
  String get itemNameHint => isSpanish ? 'Nombre del producto (ej. Leche)' : 'Item name (e.g. Milk)';
  String get itemAmountHint => isSpanish ? 'Cantidad (ej. 2)' : 'Amount (e.g. 2)';
  String get itemUnitHint => isSpanish ? 'Unidad (ej. litros)' : 'Unit (e.g. liters)';
  String get emptyShoppingTitle => isSpanish ? 'Tu lista está vacía' : 'Your shopping list is empty';
  String get shoppingEmpty => isSpanish ? 'Tu lista está vacía' : 'Your shopping list is empty';
  String get emptyShoppingSubtitle => isSpanish 
      ? 'Toca "Generar desde el Menú Semanal" o agrega productos manualmente con el botón +' 
      : 'Tap "Generate from Weekly Plan" or add items manually using the + button';
  String get shoppingEmptySubtitle => isSpanish 
      ? 'Toca "Generar desde el Menú Semanal" o agrega productos manualmente con el botón +' 
      : 'Tap "Generate from Weekly Plan" or add items manually using the + button';
  String get clearCompleted => isSpanish ? 'Limpiar comprados' : 'Clear completed';
  String get clearAll => isSpanish ? 'Vaciar lista' : 'Clear all';

  // Settings Screen
  String get settingsTitle => isSpanish ? 'Ajustes' : 'Settings';
  String get visualThemeTitle => isSpanish ? 'Estilo Visual Culinario' : 'Visual Culinary Theme';
  String get themeBotanical => 'Modern Botanical';
  String get themeGourmet => 'Editorial Gourmet';
  String get themeBento => 'Material Bento';
  String get appearanceTitle => isSpanish ? 'Modo de Color' : 'Color Mode';
  String get modeSystem => isSpanish ? 'Sistema' : 'System';
  String get modeLight => isSpanish ? 'Claro' : 'Light';
  String get modeDark => isSpanish ? 'Oscuro' : 'Dark';
  String get languageTitle => isSpanish ? 'Idioma de la Aplicación' : 'Language';
  String get langSystem => isSpanish ? 'Sistema' : 'System';
  String get langSpanish => 'Español';
  String get langEnglish => 'English';
  String get backupTitle => isSpanish ? 'Copia de Seguridad y Privacidad' : 'Backup & Privacy';
  String get exportBackup => isSpanish ? 'Exportar copia de seguridad' : 'Export backup';
  String get importBackup => isSpanish ? 'Restaurar copia de seguridad' : 'Restore backup';
  String get aboutApp => isSpanish ? 'Acerca de Menú Listo' : 'About Menú Listo';
  String get privacyPolicy => isSpanish ? 'Política de Privacidad' : 'Privacy Policy';
  String get version => isSpanish ? 'Versión' : 'Version';
}
