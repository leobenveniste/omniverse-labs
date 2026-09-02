import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/recipe_model.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Cover Image Header
            Stack(
              children: [
                Container(
                  height: 140,
                  width: double.infinity,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Hero(
                    tag: 'recipe_image_${recipe.id}',
                    child: _buildImage(theme),
                  ),
                ),
                // Category Chip (Top Left)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      recipe.categories.take(2).join(' • ') + (recipe.categories.length > 2 ? ' +' : ''),
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                // Time Tag (Bottom Left)
                Positioned(
                  bottom: 8,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.schedule_rounded, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.totalTimeMinutes}m',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Favorite Button (Top Right)
                Positioned(
                  top: 6,
                  right: 6,
                  child: IconButton(
                    icon: Icon(
                      recipe.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: recipe.isFavorite ? Colors.redAccent : theme.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      onToggleFavorite();
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
            // Info Body
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (recipe.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      recipe.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(ThemeData theme) {
    if (recipe.imageUrl.isNotEmpty) {
      if (recipe.imageUrl.startsWith('http')) {
        return Image.network(
          recipe.imageUrl,
          cacheWidth: 600,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildPlaceholder(theme),
        );
      } else {
        final file = File(recipe.imageUrl);
        if (file.existsSync()) {
          return Image.file(
            file,
            cacheWidth: 600,
            fit: BoxFit.cover,
          );
        }
      }
    }
    return _buildPlaceholder(theme);
  }

  Widget _buildPlaceholder(ThemeData theme) {
    IconData icon = Icons.restaurant_menu;
    if (recipe.category.toLowerCase().contains('desayuno')) icon = Icons.bakery_dining;
    if (recipe.category.toLowerCase().contains('almuerzo')) icon = Icons.dinner_dining;
    if (recipe.category.toLowerCase().contains('cena')) icon = Icons.ramen_dining;
    if (recipe.category.toLowerCase().contains('postre')) icon = Icons.cake;

    return Center(
      child: Icon(icon, size: 48, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
    );
  }
}
