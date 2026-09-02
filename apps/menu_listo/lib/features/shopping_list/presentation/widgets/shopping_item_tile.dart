import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:menu_listo/core/utils/culinary_catalog.dart';
import 'package:menu_listo/core/utils/portion_calculator.dart';
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
    final formattedAmount = item.amount > 0 ? PortionCalculator.formatAmount(item.amount) : '';
    final emoji = CulinaryCatalog.getEmoji(item.name);

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: Colors.green.shade600,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text('Completar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Eliminar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            SizedBox(width: 8),
            Icon(Icons.delete_outline, color: Colors.white, size: 24),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          HapticFeedback.lightImpact();
          onToggle(!item.isCompleted);
          return false; // Don't remove from tree, just toggle
        } else {
          HapticFeedback.mediumImpact();
          return true; // Dismiss and delete
        }
      },
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onToggle(!item.isCompleted);
          },
          borderRadius: BorderRadius.circular(16),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: item.isCompleted ? 0.55 : 1.0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // Checkbox
                  Checkbox(
                    value: item.isCompleted,
                    onChanged: (val) {
                      HapticFeedback.lightImpact();
                      onToggle(val);
                    },
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                  ),
                  const SizedBox(width: 4),

                  // Emoji
                  Text(emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),

                  // Title and Source
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                            color: item.isCompleted ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6) : null,
                          ),
                        ),
                        if (item.sourceRecipeTitle.isNotEmpty)
                          Text(
                            item.sourceRecipeTitle,
                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),

                  // Amount & Unit Badge
                  if (formattedAmount.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$formattedAmount ${item.unit}'.trim(),
                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
