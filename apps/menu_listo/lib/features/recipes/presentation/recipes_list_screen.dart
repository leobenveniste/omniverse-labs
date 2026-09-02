import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:menu_listo/core/localization/app_localizations.dart';
import '../models/recipe_model.dart';
import '../providers/recipe_provider.dart';
import 'recipe_detail_screen.dart';
import 'widgets/pantry_matcher_dialog.dart';
import 'widgets/recipe_creation_options_sheet.dart';

class RecipesListScreen extends ConsumerStatefulWidget {
  const RecipesListScreen({super.key});

  @override
  ConsumerState<RecipesListScreen> createState() => _RecipesListScreenState();
}

class _RecipesListScreenState extends ConsumerState<RecipesListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isGridView = true;

  final List<String> _categories = [
    'Todas',
    'Desayuno',
    'Almuerzo',
    'Merienda',
    'Cena',
    'Postres',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final recipesAsync = ref.watch(recipesListProvider);
    final filterState = ref.watch(recipeFilterProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Fixed Header Row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  // App Logo in Header
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Image.asset(
                      'assets/images/app_icon.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.restaurant_menu_rounded,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      strings.appTitle,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),

                  // Pantry Matcher Shortcut Button
                  IconButton(
                    tooltip: strings.isSpanish ? '¿Qué cocino hoy?' : 'Pantry Matcher',
                    onPressed: () => PantryMatcherDialog.show(context),
                    icon: const Icon(Icons.kitchen_outlined),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Grid / List View Toggle
                  IconButton(
                    tooltip: _isGridView ? strings.viewList : strings.viewGrid,
                    onPressed: () => setState(() => _isGridView = !_isGridView),
                    icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      foregroundColor: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),

            // Fixed Search Bar & Favorites Filter
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        ref.read(recipeFilterProvider.notifier).setSearchQuery(val);
                      },
                      decoration: InputDecoration(
                        hintText: strings.searchRecipesHint,
                        prefixIcon: const Icon(Icons.search, size: 22),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  ref.read(recipeFilterProvider.notifier).setSearchQuery('');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilterChip(
                    selected: filterState.onlyFavorites,
                    showCheckmark: false,
                    avatar: Icon(
                      filterState.onlyFavorites ? Icons.favorite : Icons.favorite_border,
                      size: 18,
                      color: filterState.onlyFavorites ? Colors.redAccent : theme.colorScheme.onSurfaceVariant,
                    ),
                    label: const SizedBox.shrink(),
                    padding: const EdgeInsets.all(8),
                    onSelected: (val) {
                      ref.read(recipeFilterProvider.notifier).toggleOnlyFavorites();
                    },
                  ),
                ],
              ),
            ),

            // Fixed Categories Filter Chips
            SizedBox(
              height: 48,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                children: [
                  ..._categories.map((cat) {
                    final isSelected = (cat == 'Todas' && filterState.selectedCategory == 'Todas') || (cat == filterState.selectedCategory);

                    String catLabel;
                    switch (cat) {
                      case 'Desayuno':
                        catLabel = strings.filterBreakfast;
                        break;
                      case 'Almuerzo':
                        catLabel = strings.filterLunch;
                        break;
                      case 'Merienda':
                        catLabel = strings.filterSnack;
                        break;
                      case 'Cena':
                        catLabel = strings.filterDinner;
                        break;
                      case 'Postres':
                        catLabel = strings.filterDessert;
                        break;
                      default:
                        catLabel = strings.filterAll;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(catLabel),
                        selected: isSelected,
                        onSelected: (val) {
                          ref.read(recipeFilterProvider.notifier).setCategory(cat);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Hero Pantry Matcher Card Banner
            InkWell(
              onTap: () => PantryMatcherDialog.show(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primaryContainer.withValues(alpha: 0.8),
                      theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        shape: BoxShape.circle,
                      ),
                      child: const Text('🍳', style: TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.isSpanish ? '¿Qué cocino hoy con mi heladera?' : 'What can I cook with my fridge?',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            strings.isSpanish
                                ? 'Toca para buscar por ingredientes que ya tienes'
                                : 'Tap to match recipes with ingredients on hand',
                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 14, color: theme.colorScheme.primary),
                  ],
                ),
              ),
            ),

            // Scrollable Content
            Expanded(
              child: recipesAsync.when(
                data: (recipes) {
                  if (recipes.isEmpty) {
                    final isFiltering = _searchController.text.isNotEmpty || filterState.selectedCategory != 'Todas' || filterState.onlyFavorites;
                    return isFiltering ? _buildNoResultsState(context, strings) : _buildEmptyState(context, strings);
                  }

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    child: _isGridView ? _buildGridView(context, recipes) : _buildListView(context, recipes),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- EMPTY STATE ---
  Widget _buildEmptyState(BuildContext context, AppStrings strings) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 120),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(20),
              child: Image.asset(
                'assets/images/app_icon.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.restaurant_menu_rounded,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              strings.emptyRecipesTitle,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              strings.emptyRecipesSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Single Main Action
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: () => showRecipeCreationOptions(context),
                icon: const Icon(Icons.add_rounded, size: 22),
                label: Text(strings.createFirstRecipe, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState(BuildContext context, AppStrings strings) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 56, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 14),
          Text(strings.noResultsTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(strings.noResultsSubtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  // --- GRID VIEW ---
  Widget _buildGridView(BuildContext context, List<Recipe> recipes) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        return _buildGridCard(context, recipe);
      },
    );
  }

  Widget _buildGridCard(BuildContext context, Recipe recipe) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipeId: recipe.id)),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 112,
                  width: double.infinity,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Hero(
                    tag: 'recipe_image_${recipe.id}',
                    child: recipe.imageUrl.isNotEmpty
                        ? (recipe.imageUrl.startsWith('http')
                            ? Image.network(recipe.imageUrl, cacheWidth: 600, fit: BoxFit.cover)
                            : Image.file(File(recipe.imageUrl), cacheWidth: 600, fit: BoxFit.cover))
                        : Center(
                            child: Icon(
                              Icons.restaurant_menu_rounded,
                              size: 38,
                              color: theme.colorScheme.primary.withValues(alpha: 0.3),
                            ),
                          ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.black.withValues(alpha: 0.4),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 18,
                      icon: Icon(
                        recipe.isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: recipe.isFavorite ? Colors.redAccent : Colors.white,
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        ref.read(recipesListProvider.notifier).toggleFavorite(recipe.id, recipe.isFavorite);
                      },
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recipe.category,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 13, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.totalTimeMinutes}m',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.people_alt_outlined, size: 13, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.baseServings}p',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- LIST VIEW ---
  Widget _buildListView(BuildContext context, List<Recipe> recipes) {
    return ListView.separated(
      itemCount: recipes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        return _buildListCard(context, recipe);
      },
    );
  }

  Widget _buildListCard(BuildContext context, Recipe recipe) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipeId: recipe.id)),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 72,
                  height: 72,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Hero(
                    tag: 'recipe_image_${recipe.id}',
                    child: recipe.imageUrl.isNotEmpty
                        ? (recipe.imageUrl.startsWith('http')
                            ? Image.network(recipe.imageUrl, cacheWidth: 300, fit: BoxFit.cover)
                            : Image.file(File(recipe.imageUrl), cacheWidth: 300, fit: BoxFit.cover))
                        : Center(
                            child: Icon(
                              Icons.restaurant_menu_rounded,
                              size: 28,
                              color: theme.colorScheme.primary.withValues(alpha: 0.3),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recipe.category,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.totalTimeMinutes} min',
                          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.people_alt_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.baseServings} porc.',
                          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  recipe.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: recipe.isFavorite ? Colors.redAccent : theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ref.read(recipesListProvider.notifier).toggleFavorite(recipe.id, recipe.isFavorite);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
