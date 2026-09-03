import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:menu_listo/core/localization/app_localizations.dart';
import 'package:menu_listo/core/widgets/app_header_title.dart';
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
  bool _isSearchOpen = false;

  final List<String> _categories = [
    'Desayuno',
    'Almuerzo',
    'Merienda',
    'Cena',
    'Postres',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final recipes = ref.read(recipesListProvider).valueOrNull ?? [];
      if (recipes.isEmpty) {
        await ref.read(recipesListProvider.notifier).loadRecipes();
      }
    });
  }

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
              padding: const EdgeInsets.fromLTRB(20, 14, 16, 4),
              child: Row(
                children: [
                  // App Logo and Screen Title
                  Expanded(
                    child: AppHeaderTitle(title: strings.tabRecipes),
                  ),
                  // Search Toggle
                  IconButton(
                    icon: Icon(_isSearchOpen ? Icons.close : Icons.search),
                    tooltip: strings.searchRecipesHint,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _isSearchOpen = !_isSearchOpen;
                        if (!_isSearchOpen) {
                          _searchController.clear();
                          ref.read(recipeFilterProvider.notifier).setSearchQuery('');
                        }
                      });
                    },
                  ),
                  // View Toggle (Grid / List)
                  IconButton(
                    icon: Icon(_isGridView ? Icons.view_agenda_outlined : Icons.grid_view_rounded),
                    tooltip: _isGridView ? 'Vista lista' : 'Vista cuadrícula',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _isGridView = !_isGridView);
                    },
                  ),
                ],
              ),
            ),

            // Collapsible Search Bar
            if (_isSearchOpen)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: (val) {
                    ref.read(recipeFilterProvider.notifier).setSearchQuery(val);
                  },
                  decoration: InputDecoration(
                    hintText: strings.searchRecipesHint,
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(recipeFilterProvider.notifier).setSearchQuery('');
                            },
                          )
                        : null,
                    filled: true,
                    isDense: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

            // Category Chips Row with Favorites button at the beginning
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  // Favorites Filter Button at the beginning
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      avatar: Icon(
                        filterState.onlyFavorites ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                        color: filterState.onlyFavorites ? Colors.redAccent : theme.colorScheme.onSurfaceVariant,
                      ),
                      label: Text(
                        strings.isSpanish ? 'Favoritos' : 'Favorites',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: filterState.onlyFavorites ? theme.colorScheme.primary : null,
                        ),
                      ),
                      selected: filterState.onlyFavorites,
                      showCheckmark: false,
                      onSelected: (_) {
                        HapticFeedback.selectionClick();
                        ref.read(recipeFilterProvider.notifier).toggleOnlyFavorites();
                      },
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  // Meal Time Filters (Multi-select enabled, no "Todas")
                  ..._categories.map((cat) {
                    final isSelected = filterState.selectedCategories.contains(cat);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(
                          cat,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        selected: isSelected,
                        showCheckmark: false,
                        onSelected: (_) {
                          HapticFeedback.selectionClick();
                          ref.read(recipeFilterProvider.notifier).toggleCategory(cat);
                        },
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Compact Slim Fridge Matcher Banner
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  PantryMatcherDialog.show(context);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.25), width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.kitchen_rounded,
                        size: 28,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          strings.isSpanish ? '¿Qué cocino hoy con mi heladera?' : 'What can I cook with my fridge?',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 13, color: theme.colorScheme.primary),
                    ],
                  ),
                ),
              ),
            ),

            // Scrollable Content
            Expanded(
              child: recipesAsync.when(
                data: (recipes) {
                  if (recipes.isEmpty) {
                    final isFiltering = _searchController.text.isNotEmpty || filterState.selectedCategories.isNotEmpty || filterState.onlyFavorites;
                    return isFiltering ? _buildNoResultsState(context, strings) : _buildEmptyState(context, strings);
                  }

                  return _isGridView ? _buildGridView(context, recipes) : _buildListView(context, recipes);
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 130),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.15,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
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
      borderRadius: BorderRadius.circular(16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 96,
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
                              size: 32,
                              color: theme.colorScheme.primary.withValues(alpha: 0.3),
                            ),
                          ),
                  ),
                ),
                // Time Tag Overlay on Image
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.schedule_rounded, size: 11, color: Colors.white),
                        const SizedBox(width: 3),
                        Text(
                          '${recipe.totalTimeMinutes}m',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Favorite Button Overlay
                Positioned(
                  top: 5,
                  right: 5,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.black.withValues(alpha: 0.4),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 16,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: SizedBox(
                height: 34,
                child: Text(
                  recipe.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 130),
      itemCount: recipes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
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
        elevation: 1.5,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 56,
                  height: 56,
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
                              size: 24,
                              color: theme.colorScheme.primary.withValues(alpha: 0.3),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      recipe.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Time Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.schedule_rounded, size: 12, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            '${recipe.totalTimeMinutes}m',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                iconSize: 20,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
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
