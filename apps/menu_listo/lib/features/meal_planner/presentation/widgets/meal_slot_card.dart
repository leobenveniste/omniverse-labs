import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../models/meal_plan_model.dart';

class MealSlotCard extends StatelessWidget {
  final String mealType;
  final MealPlanItem? item;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final ValueChanged<int>? onAdjustServings;

  const MealSlotCard({
    super.key,
    required this.mealType,
    required this.item,
    required this.onTap,
    required this.onRemove,
    this.onAdjustServings,
  });

  void _showServingsSheet(BuildContext context) {
    if (item == null || onAdjustServings == null) return;
    int current = item!.servings > 0 ? item!.servings : 2;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final theme = Theme.of(context);
          final strings = AppStrings.of(context);
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item!.recipeTitle,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    strings.adjustServings,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filledTonal(
                        icon: const Icon(Icons.remove),
                        onPressed: current > 1 ? () => setSheetState(() => current--) : null,
                      ),
                      const SizedBox(width: 20),
                      Text(
                        '$current',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        current == 1
                            ? (strings.isSpanish ? 'porción' : 'serving')
                            : (strings.isSpanish ? 'porciones' : 'servings'),
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(width: 20),
                      IconButton.filled(
                        icon: const Icon(Icons.add),
                        onPressed: () => setSheetState(() => current++),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        onAdjustServings!(current);
                      },
                      child: Text(strings.save),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);

    final mealTitle = _getMealTypeName(mealType, strings);
    final mealIcon = _getMealTypeIcon(mealType);

    final hasMeal = item != null && item!.recipeTitle.isNotEmpty;
    final isLeftover = hasMeal && (item!.customNote.toLowerCase().contains('tupper') || item!.customNote.toLowerCase().contains('sobras'));

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
                  Row(
                    children: [
                      Text(
                        mealTitle,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isLeftover) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '🍱 Tupper',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                          ),
                        ),
                      ],
                    ],
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
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: onAdjustServings != null ? () => _showServingsSheet(context) : null,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people_alt_outlined, size: 12, color: theme.colorScheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              '${item!.servings} ${strings.persons}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(Icons.edit, size: 10, color: theme.colorScheme.primary),
                          ],
                        ),
                      ),
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
