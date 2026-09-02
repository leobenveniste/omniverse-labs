import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:menu_listo/core/localization/app_localizations.dart';
import 'package:menu_listo/core/utils/culinary_catalog.dart';
import '../../models/recipe_model.dart';
import '../../providers/recipe_provider.dart';
import '../recipe_detail_screen.dart';

class PantryMatcherDialog extends ConsumerStatefulWidget {
  const PantryMatcherDialog({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const PantryMatcherDialog(),
    );
  }

  @override
  ConsumerState<PantryMatcherDialog> createState() => _PantryMatcherDialogState();
}

class _PantryMatcherDialogState extends ConsumerState<PantryMatcherDialog> {
  final Set<String> _selectedIngredients = {};
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final recipesAsync = ref.watch(recipesListProvider);

    final popularPantryItems = [
      'Huevos',
      'Queso',
      'Leche',
      'Cebolla',
      'Tomate',
      'Papa',
      'Zanahoria',
      'Pollo',
      'Carne picada',
      'Arroz',
      'Fideos',
      'Espinaca',
      'Atún en lata',
      'Ajo',
      'Pimiento rojo',
      'Manteca',
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollController) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('🍳', style: TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.isSpanish ? '¿Qué cocino hoy?' : 'What can I cook today?',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        strings.isSpanish
                            ? 'Selecciona los ingredientes que tienes a mano'
                            : 'Select ingredients you have in your fridge',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Quick Ingredient Selector Chips
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: popularPantryItems.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final name = popularPantryItems[index];
                  final isSelected = _selectedIngredients.contains(name);
                  final emoji = CulinaryCatalog.getEmoji(name);

                  return FilterChip(
                    avatar: Text(emoji, style: const TextStyle(fontSize: 14)),
                    label: Text(name),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedIngredients.add(name);
                        } else {
                          _selectedIngredients.remove(name);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Search/Add custom ingredient
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: strings.isSpanish ? 'Buscar otro ingrediente...' : 'Search another ingredient...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              onSubmitted: (val) {
                if (val.trim().isNotEmpty) {
                  setState(() {
                    _selectedIngredients.add(val.trim());
                    _searchCtrl.clear();
                    _searchQuery = '';
                  });
                }
              },
            ),

            if (_selectedIngredients.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _selectedIngredients
                    .map((item) => Chip(
                          label: Text(item, style: const TextStyle(fontSize: 12)),
                          avatar: Text(CulinaryCatalog.getEmoji(item)),
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () => setState(() => _selectedIngredients.remove(item)),
                        ))
                    .toList(),
              ),
            ],

            const SizedBox(height: 16),
            Text(
              strings.isSpanish ? 'Recetas sugeridas' : 'Suggested Recipes',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Match Results
            Expanded(
              child: recipesAsync.when(
                data: (recipes) {
                  if (recipes.isEmpty) {
                    return Center(child: Text(strings.emptyTitle));
                  }

                  final scored = recipes.map((recipe) {
                    final actualIngredients = recipe.ingredients.where((i) => !i.isSectionHeader).toList();
                    if (actualIngredients.isEmpty) {
                      return RecipeMatch(recipe: recipe, matchPercent: 0, matchedCount: 0, missing: []);
                    }

                    int matches = 0;
                    List<String> missing = [];

                    for (var ing in actualIngredients) {
                      final ingLower = ing.name.toLowerCase();
                      final isMatched = _selectedIngredients.any((sel) =>
                          ingLower.contains(sel.toLowerCase()) || sel.toLowerCase().contains(ingLower));

                      if (isMatched) {
                        matches++;
                      } else {
                        missing.add(ing.name);
                      }
                    }

                    final percent = (matches / actualIngredients.length * 100).round();
                    return RecipeMatch(
                      recipe: recipe,
                      matchPercent: percent,
                      matchedCount: matches,
                      missing: missing,
                    );
                  }).toList();

                  // Sort by highest match percent
                  scored.sort((a, b) => b.matchPercent.compareTo(a.matchPercent));

                  return ListView.separated(
                    controller: scrollController,
                    itemCount: scored.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final match = scored[index];
                      final recipe = match.recipe;

                      Color badgeColor = Colors.grey;
                      String badgeText = '${match.matchPercent}%';
                      if (match.matchPercent == 100) {
                        badgeColor = Colors.green;
                        badgeText = '100% Listo';
                      } else if (match.matchPercent >= 60) {
                        badgeColor = Colors.orange;
                        badgeText = '${match.matchPercent}% (${match.matchedCount}/${recipe.ingredients.length})';
                      }

                      return InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RecipeDetailScreen(recipeId: recipe.id),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Icon(Icons.restaurant_menu, color: theme.colorScheme.onPrimaryContainer),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      recipe.title,
                                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${recipe.category} • ${recipe.totalTimeMinutes} ${strings.minutes}',
                                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                    ),
                                    if (match.missing.isNotEmpty && match.matchPercent > 0) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Falta: ${match.missing.take(2).join(", ")}${match.missing.length > 2 ? "..." : ""}',
                                        style: TextStyle(fontSize: 11, color: Colors.orange.shade800),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: badgeColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  badgeText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: badgeColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
}

class RecipeMatch {
  final Recipe recipe;
  final int matchPercent;
  final int matchedCount;
  final List<String> missing;

  RecipeMatch({
    required this.recipe,
    required this.matchPercent,
    required this.matchedCount,
    required this.missing,
  });
}
