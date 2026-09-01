import 'package:flutter/material.dart';

enum AppLanguage {
  system,
  spanish,
  english;

  Locale? get locale {
    switch (this) {
      case AppLanguage.spanish:
        return const Locale('es');
      case AppLanguage.english:
        return const Locale('en');
      case AppLanguage.system:
        return null;
    }
  }

  String get displayName {
    switch (this) {
      case AppLanguage.spanish:
        return 'Español';
      case AppLanguage.english:
        return 'English';
      case AppLanguage.system:
        return 'Automático (Sistema)';
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

  bool get isSpanish => locale.languageCode.startsWith('es');

  // App General
  String get appName => isSpanish ? 'Menú Listo' : 'Menu Listo';
  String get appTagline => isSpanish ? 'Recetas y Planificador' : 'Recipes & Meal Planner';

  // Navigation Tabs
  String get navRecipes => isSpanish ? 'Recetas' : 'Recipes';
  String get navPlanner => isSpanish ? 'Plan Semanal' : 'Meal Planner';
  String get navShopping => isSpanish ? 'Compras' : 'Shopping List';
  String get navSettings => isSpanish ? 'Ajustes' : 'Settings';

  // Common
  String get save => isSpanish ? 'Guardar' : 'Save';
  String get cancel => isSpanish ? 'Cancelar' : 'Cancel';
  String get delete => isSpanish ? 'Eliminar' : 'Delete';
  String get edit => isSpanish ? 'Editar' : 'Edit';
  String get close => isSpanish ? 'Cerrar' : 'Close';
  String get confirm => isSpanish ? 'Confirmar' : 'Confirm';
  String get search => isSpanish ? 'Buscar...' : 'Search...';
  String get emptyTitle => isSpanish ? 'No hay elementos' : 'No items found';
  String get retry => isSpanish ? 'Reintentar' : 'Retry';
  String get servings => isSpanish ? 'porciones' : 'servings';
  String get forPersons => isSpanish ? 'Para' : 'Serves';
  String get persons => isSpanish ? 'personas' : 'people';
  String get minutes => isSpanish ? 'min' : 'min';
  String get totalTime => isSpanish ? 'Tiempo Total' : 'Total Time';

  // Recipes Screen
  String get searchRecipes => isSpanish ? 'Buscar recetas o ingredientes...' : 'Search recipes or ingredients...';
  String get allCategories => isSpanish ? 'Todas' : 'All';
  String get newRecipe => isSpanish ? 'Nueva Receta' : 'New Recipe';
  String get importUrl => isSpanish ? 'Importar Web' : 'Import URL';
  String get favoritesOnly => isSpanish ? 'Solo Favoritas' : 'Favorites Only';
  String get noRecipesYet => isSpanish ? 'Aún no tienes recetas guardadas' : 'No recipes saved yet';
  String get noRecipesSubtitle => isSpanish 
      ? 'Crea tu primera receta o importa un enlace de tu blog de cocina favorito.' 
      : 'Create your first recipe or import a link from your favorite food blog.';
  String get recipeCreatedSuccess => isSpanish ? '¡Receta guardada con éxito!' : 'Recipe saved successfully!';
  String get recipeUpdatedSuccess => isSpanish ? '¡Receta actualizada con éxito!' : 'Recipe updated successfully!';
  String get recipeDeletedSuccess => isSpanish ? 'Receta eliminada' : 'Recipe deleted';
  String get confirmDeleteRecipe => isSpanish ? '¿Estás seguro de eliminar esta receta?' : 'Are you sure you want to delete this recipe?';

  // Categories
  String get catBreakfast => isSpanish ? 'Desayuno' : 'Breakfast';
  String get catLunch => isSpanish ? 'Almuerzo' : 'Lunch';
  String get catSnack => isSpanish ? 'Merienda' : 'Snack';
  String get catDinner => isSpanish ? 'Cena' : 'Dinner';
  String get catDessert => isSpanish ? 'Postre' : 'Dessert';
  String get catOther => isSpanish ? 'Otros' : 'Other';

  // Recipe Detail & Cook Mode
  String get ingredientsTitle => isSpanish ? 'Ingredientes' : 'Ingredients';
  String get instructionsTitle => isSpanish ? 'Preparación paso a paso' : 'Instructions';
  String get startCooking => isSpanish ? 'Comenzar a Cocinar' : 'Start Cooking';
  String get cookModeTitle => isSpanish ? 'Modo Cocina' : 'Cook Mode';
  String get cookModeWakeLockNotice => isSpanish ? 'Pantalla siempre activa' : 'Screen stay awake active';
  String get step => isSpanish ? 'Paso' : 'Step';
  String get ofSteps => isSpanish ? 'de' : 'of';
  String get nextStep => isSpanish ? 'Siguiente' : 'Next';
  String get previousStep => isSpanish ? 'Anterior' : 'Previous';
  String get finishCooking => isSpanish ? '¡Listo, a comer!' : 'Finished Cooking!';
  String get finishCookingMessage => isSpanish 
      ? '¡Felicitaciones! Has completado todos los pasos de la receta.' 
      : 'Congratulations! You completed all steps of the recipe.';
  String get adjustServings => isSpanish ? 'Ajustar Porciones:' : 'Adjust Servings:';
  String get viewOriginalSource => isSpanish ? 'Ver receta original' : 'View original source';

  // Recipe Form
  String get formTitleNew => isSpanish ? 'Crear Receta' : 'Create Recipe';
  String get formTitleEdit => isSpanish ? 'Editar Receta' : 'Edit Recipe';
  String get fieldTitle => isSpanish ? 'Título de la receta *' : 'Recipe Title *';
  String get fieldDescription => isSpanish ? 'Breve descripción' : 'Short description';
  String get fieldCategory => isSpanish ? 'Categoría' : 'Category';
  String get fieldPrepTime => isSpanish ? 'Tiempo de preparación (min)' : 'Prep time (min)';
  String get fieldCookTime => isSpanish ? 'Tiempo de cocción (min)' : 'Cook time (min)';
  String get fieldBaseServings => isSpanish ? 'Comensales base (personas) *' : 'Base servings (people) *';
  String get fieldTags => isSpanish ? 'Etiquetas (separadas por comas)' : 'Tags (comma separated)';
  String get addIngredient => isSpanish ? '+ Agregar Ingrediente' : '+ Add Ingredient';
  String get addStep => isSpanish ? '+ Agregar Paso' : '+ Add Step';
  String get ingredientAmount => isSpanish ? 'Cant.' : 'Qty.';
  String get ingredientUnit => isSpanish ? 'Unidad (g, ml, cda)' : 'Unit (g, ml, tbsp)';
  String get ingredientName => isSpanish ? 'Nombre del ingrediente *' : 'Ingredient name *';
  String get ingredientNotes => isSpanish ? 'Nota / detalle opcional' : 'Optional note';
  String get selectPhoto => isSpanish ? 'Cambiar foto de portada' : 'Change cover photo';
  String get fromGallery => isSpanish ? 'Galería' : 'Gallery';
  String get fromCamera => isSpanish ? 'Cámara' : 'Camera';
  String get removePhoto => isSpanish ? 'Quitar foto' : 'Remove photo';
  String get validationTitleRequired => isSpanish ? 'Por favor ingresa un título' : 'Please enter a title';
  String get validationServingsRequired => isSpanish ? 'Ingresa comensales válidos' : 'Enter valid servings';
  String get validationIngredientsRequired => isSpanish ? 'Añade al menos un ingrediente' : 'Add at least one ingredient';
  String get validationStepsRequired => isSpanish ? 'Añade al menos un paso' : 'Add at least one step';

  // Import Dialog
  String get importUrlTitle => isSpanish ? 'Importar Receta Web' : 'Import Web Recipe';
  String get importUrlDescription => isSpanish 
      ? 'Pega el enlace de cualquier blog de recetas. Menú Listo extraerá automáticamente ingredientes y pasos descartando anuncios.' 
      : 'Paste the URL of any recipe blog. Menú Listo will automatically extract ingredients and steps.';
  String get pasteUrlHint => isSpanish ? 'https://misrecetas.com/plato-delicioso' : 'https://recipes.com/delicious-dish';
  String get extractRecipe => isSpanish ? 'Analizar Receta' : 'Extract Recipe';
  String get scrapingProgress => isSpanish ? 'Extrayendo ingredientes y pasos...' : 'Extracting recipe content...';
  String get scrapingFailed => isSpanish 
      ? 'No pudimos extraer la receta completa automáticamente. Puedes completarla manualmente.' 
      : 'Could not extract full recipe automatically. You can edit it manually.';
  String get editAndSave => isSpanish ? 'Revisar y Guardar' : 'Review & Save';

  // Meal Planner
  String get plannerTitle => isSpanish ? 'Planificador Semanal' : 'Weekly Meal Planner';
  String get today => isSpanish ? 'Hoy' : 'Today';
  String get fillRandom => isSpanish ? 'Completar al Azar' : 'Random Fill';
  String get clearWeek => isSpanish ? 'Vaciar Semana' : 'Clear Week';
  String get clearWeekConfirm => isSpanish ? '¿Seguro que deseas vaciar todas las comidas de esta semana?' : 'Clear all meals for this week?';
  String get selectRecipeForSlot => isSpanish ? 'Asignar Receta a:' : 'Assign Recipe to:';
  String get noRecipeAssigned => isSpanish ? 'Toca para agregar comida' : 'Tap to add meal';
  String get weekDays => isSpanish ? 'Lun,Mar,Mié,Jue,Vie,Sáb,Dom' : 'Mon,Tue,Wed,Thu,Fri,Sat,Sun';
  String get mealBreakfast => isSpanish ? 'Desayuno' : 'Breakfast';
  String get mealLunch => isSpanish ? 'Almuerzo' : 'Lunch';
  String get mealSnack => isSpanish ? 'Merienda' : 'Snack';
  String get mealDinner => isSpanish ? 'Cena' : 'Dinner';
  String get removeMealSlot => isSpanish ? 'Quitar comida' : 'Remove meal';

  // Shopping List
  String get shoppingTitle => isSpanish ? 'Lista de Compras' : 'Shopping List';
  String get generateFromPlanner => isSpanish ? 'Generar desde el Menú Semanal' : 'Generate from Weekly Menu';
  String get generateSuccess => isSpanish ? '¡Lista consolidada generada con éxito!' : 'Consolidated shopping list created!';
  String get addCustomItem => isSpanish ? 'Agregar ítem manual' : 'Add custom item';
  String get clearCompleted => isSpanish ? 'Limpiar tachados' : 'Clear completed';
  String get clearAll => isSpanish ? 'Vaciar lista' : 'Clear all';
  String get shareList => isSpanish ? 'Compartir Lista' : 'Share List';
  String get shareListHeader => isSpanish ? '🛒 *Lista de Compras - Menú Listo*' : '🛒 *Shopping List - Menu Listo*';
  String get shoppingEmpty => isSpanish ? 'Tu lista de compras está vacía' : 'Your shopping list is empty';
  String get shoppingEmptySubtitle => isSpanish 
      ? 'Genera los ingredientes necesarios desde tu menú semanal o añade ítems manualmente.' 
      : 'Generate needed ingredients from your weekly menu or add items manually.';
  String get itemNameHint => isSpanish ? 'Ej. Leche descremada' : 'E.g. Skim milk';
  String get itemAmountHint => isSpanish ? 'Cant. (ej. 2)' : 'Qty (e.g. 2)';
  String get itemUnitHint => isSpanish ? 'Unidad (ej. l, kg)' : 'Unit (e.g. l, kg)';
  String get swipeToDeleteNotice => isSpanish ? 'Desliza un elemento para eliminarlo' : 'Swipe an item to delete it';

  // Settings & Theme
  String get settingsTitle => isSpanish ? 'Ajustes y Personalización' : 'Settings & Preferences';
  String get visualTheme => isSpanish ? 'Estilo de Diseño Visual' : 'Visual Design Style';
  String get themeMode => isSpanish ? 'Modo de Color' : 'Color Mode';
  String get themeSystem => isSpanish ? 'Automático (Sistema)' : 'System Default';
  String get themeLight => isSpanish ? 'Modo Claro' : 'Light Mode';
  String get themeDark => isSpanish ? 'Modo Oscuro' : 'Dark Mode';
  String get styleModernBotanical => isSpanish ? '🌿 Modern Botanical Kitchen' : '🌿 Modern Botanical Kitchen';
  String get styleEditorialGourmet => isSpanish ? '🏛️ Editorial Gourmet (Serif)' : '🏛️ Editorial Gourmet (Serif)';
  String get styleMaterialBento => isSpanish ? '⚡ Material You Tech-Craft (Bento)' : '⚡ Material You Tech-Craft (Bento)';
  String get languageTitle => isSpanish ? 'Idioma / Language' : 'Language / Idioma';
  String get dataBackup => isSpanish ? 'Copia de Seguridad y Datos' : 'Backup & Data';
  String get exportBackup => isSpanish ? 'Exportar Copia de Seguridad (.json)' : 'Export Full Backup (.json)';
  String get importBackup => isSpanish ? 'Restaurar Copia de Seguridad (.json)' : 'Restore Backup (.json)';
  String get restoreSampleRecipes => isSpanish ? 'Restablecer Recetas de Ejemplo' : 'Load Sample Recipes';
  String get restoreSampleRecipesConfirm => isSpanish 
      ? '¿Deseas recargar las recetas iniciales de ejemplo?' 
      : 'Reload initial starter sample recipes?';
  String get aboutOmniverseLabs => isSpanish ? 'Acerca de Omniverse Labs' : 'About Omniverse Labs';
  String get privacyNotice => isSpanish 
      ? '100% Offline y Privado: Tus recetas, planes y compras nunca salen de tu dispositivo.' 
      : '100% Offline & Private: Your recipes, plans, and shopping list never leave your device.';
  String get backupExportSuccess => isSpanish ? 'Copia de seguridad exportada con éxito' : 'Backup exported successfully';
  String get backupImportSuccess => isSpanish ? 'Copia de seguridad restaurada con éxito' : 'Backup restored successfully';
  String get backupError => isSpanish ? 'Error al procesar el archivo de copia de seguridad' : 'Error processing backup file';
}
