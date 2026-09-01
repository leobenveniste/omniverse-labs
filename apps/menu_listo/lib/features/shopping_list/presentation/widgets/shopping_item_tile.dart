import 'package:flutter/material.dart';
import '../../../../core/utils/portion_calculator.dart';
import '../../models/shopping_item_model.dart';

class ShoppingItemTile extends StatelessWidget {
  final ShoppingItem item;
  final ValueChanged<bool?> onToggle;
  final VoidCallback onDelete;

  const ShoppingItemTile({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final amountText = item.amount > 0 ? '${PortionCalculator.formatAmount(item.amount)} ' : '';
    final unitText = item.unit.isNotEmpty ? '${item.unit} ' : '';
    final fullTitle = '$amountText$unitText${item.name}';

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: item.isCompleted
                ? theme.colorScheme.outline.withValues(alpha: 0.1)
                : theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: CheckboxListTile(
          value: item.isCompleted,
          onChanged: onToggle,
          controlAffinity: ListTileControlAffinity.leading,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            fullTitle,
            style: TextStyle(
              fontSize: 15,
              fontWeight: item.isCompleted ? FontWeight.normal : FontWeight.w600,
              decoration: item.isCompleted ? TextDecoration.lineThrough : null,
              color: item.isCompleted ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6) : null,
            ),
          ),
          subtitle: item.sourceRecipeTitle.isNotEmpty
              ? Text(
                  item.sourceRecipeTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary.withValues(alpha: 0.8),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
