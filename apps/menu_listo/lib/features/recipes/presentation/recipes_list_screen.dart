import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../models/recipe_model.dart';
import '../providers/recipe_provider.dart';
import 'recipe_detail_screen.dart';
import 'recipe_form_screen.dart';
import 'widgets/recipe_card.dart';
import 'widgets/recipe_import_url_dialog.dart';

class RecipesListScreen extends ConsumerWidget {
  const RecipesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final filter = ref.watch(recipeFilterProvider);
    final filterNotifier = ref.read(recipeFilterProvider.notifier);
    final recipesAsync = ref.watch(recipesListProvider);
    final recipesNotifier = ref.read(recipesListProvider.notifier);

    final categories = [
      strings.allCategories,
      strings.catBreakfast,
      strings.catLunch,
      strings.catSnack,
      strings.catDinner,
      strings.catDessert,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.appName),
        actions: [
          IconButton(
            icon: Icon(
              filter.onlyFavorites ? Icons.favorite : Icons.favorite_border,
              color: filter.onlyFavorites ? Colors.redAccent : null,
            ),
            tooltip: strings.favoritesOnly,
            onPressed: () => filterNotifier.toggleOnlyFavorites(),
          ),
          IconButton(
            icon: const Icon(Icons.link),
            tooltip: strings.importUrl,
            onPressed: () => RecipeImportUrlDialog.show(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: strings.searchRecipes,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: filter.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => filterNotifier.setSearchQuery(''),
                      )
                    : null,
              ),
              onChanged: (val) => filterNotifier.setSearchQuery(val),
            ),
          ),
          // Category Filter Chips
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = filter.selectedCategory == cat || (index == 0 && filter.selectedCategory == 'Todas');

                return FilterChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (_) {
                    filterNotifier.setCategory(index == 0 ? 'Todas' : cat);
                  },
                  showCheckmark: false,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Recipes Grid
          Expanded(
            child: recipesAsync.when(
              data: (recipes) {
                if (recipes.isEmpty) {
                  return EmptyStateView(
                    icon: Icons.menu_book,
                    title: strings.noRecipesYet,
                    subtitle: strings.noRecipesSubtitle,
                    action: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FilledButton.icon(
                          icon: const Icon(Icons.add),
                          label: Text(strings.newRecipe),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (ctx) => const RecipeFormScreen()),
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.link),
                          label: Text(strings.importUrl),
                          onPressed: () => RecipeImportUrlDialog.show(context),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.76,
                  ),
                  itemCount: recipes.length,
                  itemBuilder: (context, index) {
                    final recipe = recipes[index];
                    return RecipeCard(
                      recipe: recipe,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (ctx) => RecipeDetailScreen(recipeId: recipe.id),
                          ),
                        );
                      },
                      onToggleFavorite: () {
                        recipesNotifier.toggleFavorite(recipe.id, recipe.isFavorite);
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(strings.emptyTitle),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () => recipesNotifier.loadRecipes(),
                      child: Text(strings.retry),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (ctx) => const RecipeFormScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: Text(strings.newRecipe),
      ),
    );
  }
}
