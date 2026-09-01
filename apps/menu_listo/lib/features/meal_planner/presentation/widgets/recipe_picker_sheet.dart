import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../recipes/models/recipe_model.dart';
import '../../../recipes/providers/recipe_provider.dart';

class RecipePickerSheet extends ConsumerStatefulWidget {
  final String slotTitle;
  final ValueChanged<Recipe> onRecipeSelected;
  final ValueChanged<String> onCustomEntered;

  const RecipePickerSheet({
    super.key,
    required this.slotTitle,
    required this.onRecipeSelected,
    required this.onCustomEntered,
  });

  static void show(
    BuildContext context, {
    required String slotTitle,
    required ValueChanged<Recipe> onRecipeSelected,
    required ValueChanged<String> onCustomEntered,
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
                    if (_query.isEmpty) return true;
                    return r.title.toLowerCase().contains(_query) ||
                        r.category.toLowerCase().contains(_query);
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
                                Navigator.of(context).pop();
                                widget.onCustomEntered(_searchController.text.trim());
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
                    separatorBuilder: (_, __) => const Divider(height: 1),
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
                          Navigator.of(context).pop();
                          widget.onRecipeSelected(recipe);
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(child: Text(strings.emptyTitle)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
