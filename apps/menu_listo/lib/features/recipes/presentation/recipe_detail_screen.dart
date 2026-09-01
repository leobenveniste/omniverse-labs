import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/portion_calculator.dart';
import '../models/recipe_model.dart';
import '../providers/recipe_provider.dart';
import 'recipe_cook_mode_screen.dart';
import 'recipe_form_screen.dart';

class RecipeDetailScreen extends ConsumerStatefulWidget {
  final String recipeId;

  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  int? _currentServings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final recipeAsync = ref.watch(recipesListProvider);

    return recipeAsync.when(
      data: (recipes) {
        final recipe = recipes.cast<Recipe?>().firstWhere(
              (r) => r?.id == widget.recipeId,
              orElse: () => null,
            );

        if (recipe == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(strings.emptyTitle)),
          );
        }

        final servings = _currentServings ?? recipe.baseServings;
        final scalingFactor = servings / (recipe.baseServings > 0 ? recipe.baseServings : 2);

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // Sliver App Bar with Hero Image
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildHeaderImage(recipe, theme),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      recipe.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: recipe.isFavorite ? Colors.redAccent : Colors.white,
                    ),
                    onPressed: () {
                      ref.read(recipesListProvider.notifier).toggleFavorite(recipe.id, recipe.isFavorite);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => RecipeFormScreen(initialRecipe: recipe),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                    onPressed: () => _confirmDelete(context, recipe),
                  ),
                ],
              ),
              // Body Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category and Time Badges
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              recipe.category,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.timer_outlined, size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            '${recipe.totalTimeMinutes} ${strings.minutes}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Title
                      Text(
                        recipe.title,
                        style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      if (recipe.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          recipe.description,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      // Dynamic Portion Scaler Box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.group_outlined, color: theme.colorScheme.primary, size: 26),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    strings.adjustServings,
                                    style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                  ),
                                  Text(
                                    '$servings ${strings.persons}',
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            IconButton.filledTonal(
                              icon: const Icon(Icons.remove),
                              onPressed: servings > 1
                                  ? () => setState(() => _currentServings = servings - 1)
                                  : null,
                            ),
                            const SizedBox(width: 6),
                            IconButton.filled(
                              icon: const Icon(Icons.add),
                              onPressed: () => setState(() => _currentServings = servings + 1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Ingredients List
                      Text(
                        strings.ingredientsTitle,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: recipe.ingredients.length,
                        separatorBuilder: (_, __) => const Divider(height: 16),
                        itemBuilder: (context, index) {
                          final ing = recipe.ingredients[index];
                          final scaledIng = ing.scale(scalingFactor);

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  PortionCalculator.formatIngredientDisplay(
                                    amount: scaledIng.amount,
                                    unit: scaledIng.unit,
                                    name: scaledIng.name,
                                    notes: scaledIng.notes,
                                  ),
                                  style: theme.textTheme.bodyLarge?.copyWith(fontSize: 15),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 28),
                      // Step by Step Instructions
                      Text(
                        strings.instructionsTitle,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 14),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: recipe.steps.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final step = recipe.steps[index];
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${step.stepNumber}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  step.instruction,
                                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomSheet: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => RecipeCookModeScreen(
                          recipe: recipe,
                          initialServings: servings,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.outdoor_grill),
                  label: Text(
                    strings.startCooking,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => Scaffold(body: Center(child: Text(strings.emptyTitle))),
    );
  }

  Widget _buildHeaderImage(Recipe recipe, ThemeData theme) {
    if (recipe.imageUrl.isNotEmpty) {
      if (recipe.imageUrl.startsWith('http')) {
        return Image.network(recipe.imageUrl, fit: BoxFit.cover);
      } else {
        final file = File(recipe.imageUrl);
        if (file.existsSync()) {
          return Image.file(file, fit: BoxFit.cover);
        }
      }
    }
    return Container(
      color: theme.colorScheme.primaryContainer,
      child: Center(
        child: Icon(Icons.restaurant_menu, size: 72, color: theme.colorScheme.primary),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Recipe recipe) {
    final strings = AppStrings.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.delete),
        content: Text(strings.confirmDeleteRecipe),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(strings.cancel)),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(recipesListProvider.notifier).deleteRecipe(recipe.id);
              Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text(strings.delete),
          ),
        ],
      ),
    );
  }
}
