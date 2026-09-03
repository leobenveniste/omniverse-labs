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
      shadowColor: Colors.black.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
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
                  height: 115,
                  width: double.infinity,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Hero(
                    tag: 'recipe_image_${recipe.id}',
                    child: _buildImage(theme),
                  ),
                ),
                // Time Tag (Bottom Left)
                Positioned(
                  bottom: 6,
                  left: 8,
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
                // Favorite Button with Spring Pop Animation (Top Right)
                Positioned(
                  top: 5,
                  right: 5,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.9),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 19,
                      tooltip: recipe.isFavorite ? 'Quitar de favoritos' : 'Guardar en favoritos',
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                        child: Icon(
                          recipe.isFavorite ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                          key: ValueKey(recipe.isFavorite),
                          color: recipe.isFavorite ? Colors.redAccent : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        onToggleFavorite();
                      },
                    ),
                  ),
                ),
              ],
            ),
            // Info Body
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      height: 1.25,
                    ),
                  ),
                  if (recipe.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      recipe.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
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
