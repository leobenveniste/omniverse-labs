import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../models/meal_plan_model.dart';

class MealSlotCard extends StatelessWidget {
  final String mealType;
  final MealPlanItem? item;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const MealSlotCard({
    super.key,
    required this.mealType,
    required this.item,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);

    final mealTitle = _getMealTypeName(mealType, strings);
    final mealIcon = _getMealTypeIcon(mealType);

    final hasMeal = item != null && item!.recipeTitle.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: hasMeal
              ? theme.colorScheme.surface
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasMeal
                ? theme.colorScheme.primary.withValues(alpha: 0.4)
                : theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (hasMeal ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                mealIcon,
                size: 18,
                color: hasMeal ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mealTitle,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasMeal ? item!.recipeTitle : strings.noRecipeAssigned,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: hasMeal ? FontWeight.bold : FontWeight.normal,
                      color: hasMeal ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                  if (hasMeal && item!.servings > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${item!.servings} ${strings.persons}',
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary),
                    ),
                  ],
                ],
              ),
            ),
            if (hasMeal)
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                onPressed: onRemove,
                tooltip: strings.removeMealSlot,
              )
            else
              Icon(Icons.add_circle_outline, size: 20, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }

  String _getMealTypeName(String type, AppStrings strings) {
    switch (type.toLowerCase()) {
      case 'breakfast':
        return strings.mealBreakfast;
      case 'lunch':
        return strings.mealLunch;
      case 'snack':
        return strings.mealSnack;
      case 'dinner':
        return strings.mealDinner;
      default:
        return type;
    }
  }

  IconData _getMealTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'breakfast':
        return Icons.wb_twilight;
      case 'lunch':
        return Icons.wb_sunny_outlined;
      case 'snack':
        return Icons.coffee_outlined;
      case 'dinner':
        return Icons.nightlight_outlined;
      default:
        return Icons.restaurant;
    }
  }
}
