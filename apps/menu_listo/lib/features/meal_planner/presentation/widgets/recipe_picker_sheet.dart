import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../recipes/models/recipe_model.dart';
import '../../../recipes/providers/recipe_provider.dart';

typedef RecipeSelectedWithServings = void Function(Recipe recipe, int servings);
typedef CustomMealWithServings = void Function(String customName, int servings);

class RecipePickerSheet extends ConsumerStatefulWidget {
  final String slotTitle;
  final RecipeSelectedWithServings onRecipeSelected;
  final CustomMealWithServings onCustomEntered;

  const RecipePickerSheet({
    super.key,
    required this.slotTitle,
    required this.onRecipeSelected,
    required this.onCustomEntered,
  });

  static void show(
    BuildContext context, {
    required String slotTitle,
    required RecipeSelectedWithServings onRecipeSelected,
    required CustomMealWithServings onCustomEntered,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => RecipePickerSheet(
        slotTitle: slotTitle,
        onRecipeSelected: onRecipeSelected,
        onCustomEntered: onCustomEntered,
      ),
    );
  }

  @override
  ConsumerState<RecipePickerSheet> createState() => _RecipePickerSheetState();
}

class _RecipePickerSheetState extends ConsumerState<RecipePickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showPortionDialog({
    required BuildContext context,
    required String title,
    required int initialServings,
    required void Function(int servings) onConfirm,
  }) async {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    int servings = initialServings > 0 ? initialServings : 2;

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    strings.isSpanish
                        ? '¿Cuántas porciones deseas planificar?'
                        : 'How many servings would you like to plan?',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton.filledTonal(
                          icon: const Icon(Icons.remove),
                          onPressed: servings > 1
                              ? () => setDialogState(() => servings--)
                              : null,
                        ),
                        const SizedBox(width: 20),
                        Column(
                          children: [
                            Text(
                              '$servings',
                              style: theme.textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            Text(
                              servings == 1
                                  ? (strings.isSpanish ? 'porción' : 'serving')
                                  : (strings.isSpanish ? 'porciones' : 'servings'),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        IconButton.filled(
                          icon: const Icon(Icons.add),
                          onPressed: () => setDialogState(() => servings++),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: Text(strings.cancel),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(dialogCtx).pop();
                    onConfirm(servings);
                  },
                  child: Text(strings.assignButton),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final recipesAsync = ref.watch(recipesListProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
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
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${strings.selectRecipeForSlot} ${widget.slotTitle}',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: strings.searchRecipes,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
              onChanged: (val) => setState(() => _query = val.trim().toLowerCase()),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: recipesAsync.when(
                data: (recipes) {
                  final filtered = recipes.where((r) {
                    return r.title.toLowerCase().contains(_query) ||
                        r.categories.any((c) => c.toLowerCase().contains(_query));
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(strings.emptyTitle),
                          const SizedBox(height: 8),
                          if (_query.isNotEmpty)
                            FilledButton.tonal(
                              onPressed: () {
                                final customName = _searchController.text.trim();
                                _showPortionDialog(
                                  context: context,
                                  title: customName,
                                  initialServings: 2,
                                  onConfirm: (servings) {
                                    Navigator.of(context).pop();
                                    widget.onCustomEntered(customName, servings);
                                  },
                                );
                              },
                              child: Text('Asignar "$_query" como comida personalizada'),
                            ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    controller: scrollController,
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final recipe = filtered[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Icon(Icons.restaurant, color: theme.colorScheme.onPrimaryContainer, size: 20),
                        ),
                        title: Text(recipe.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${recipe.category} • ${recipe.totalTimeMinutes} ${strings.minutes}'),
                        trailing: Text('${recipe.baseServings} ${strings.persons}', style: theme.textTheme.labelSmall),
                        onTap: () {
                          _showPortionDialog(
                            context: context,
                            title: recipe.title,
                            initialServings: recipe.baseServings,
                            onConfirm: (servings) {
                              Navigator.of(context).pop();
                              widget.onRecipeSelected(recipe, servings);
                            },
                          );
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => Center(child: Text(strings.emptyTitle)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
