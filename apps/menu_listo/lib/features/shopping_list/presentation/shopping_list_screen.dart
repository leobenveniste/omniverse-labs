import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:menu_listo/core/localization/app_localizations.dart';
import 'package:menu_listo/core/utils/culinary_catalog.dart';
import 'package:menu_listo/core/widgets/empty_state_view.dart';
import '../models/shopping_item_model.dart';
import '../providers/shopping_provider.dart';
import 'supermarket_mode_screen.dart';
import 'widgets/add_item_dialog.dart';
import 'widgets/shopping_item_tile.dart';

class ShoppingListScreen extends ConsumerStatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  ConsumerState<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends ConsumerState<ShoppingListScreen> {
  bool _isCategorizedView = true;

  void _showPantryReviewModal(BuildContext context, List<ShoppingItem> items) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final selectedItems = Set<ShoppingItem>.from(items);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.8,
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
                          color: theme.colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.playlist_add_check_rounded, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.isSpanish ? 'Revisar Lista del Menú' : 'Review Shopping List',
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              strings.isSpanish
                                  ? 'Desmarca los ingredientes que ya tienes en casa'
                                  : 'Uncheck items you already have at home',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isChecked = selectedItems.contains(item);
                        final isStaple = CulinaryCatalog.isPantryStaple(item.name);
                        final emoji = CulinaryCatalog.getEmoji(item.name);

                        return Container(
                          decoration: BoxDecoration(
                            color: isChecked ? theme.colorScheme.surface : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isChecked ? theme.colorScheme.outline.withValues(alpha: 0.3) : Colors.transparent,
                            ),
                          ),
                          child: CheckboxListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            value: isChecked,
                            onChanged: (val) {
                              setSheetState(() {
                                if (val == true) {
                                  selectedItems.add(item);
                                } else {
                                  selectedItems.remove(item);
                                }
                              });
                            },
                            title: Row(
                              children: [
                                Text(emoji, style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      decoration: !isChecked ? TextDecoration.lineThrough : null,
                                      color: !isChecked ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5) : null,
                                    ),
                                  ),
                                ),
                                if (isStaple)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blueGrey.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      strings.isSpanish ? 'Alacena' : 'Pantry',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Text(
                              '${item.amount > 0 ? item.amount.toString() : ""} ${item.unit}'.trim(),
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.add_shopping_cart),
                      label: Text(
                        strings.isSpanish
                            ? 'Agregar ${selectedItems.length} seleccionados a la lista'
                            : 'Add ${selectedItems.length} selected items',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: selectedItems.isEmpty
                          ? null
                          : () async {
                              Navigator.of(ctx).pop();
                              await ref.read(shoppingListProvider.notifier).addConsolidatedItems(selectedItems.toList());
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      strings.isSpanish
                                          ? '¡${selectedItems.length} productos agregados a la lista!'
                                          : '${selectedItems.length} items added to shopping list!',
                                    ),
                                  ),
                                );
                              }
                            },
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
    final itemsAsync = ref.watch(shoppingListProvider);
    final notifier = ref.read(shoppingListProvider.notifier);

    final items = itemsAsync.valueOrNull ?? [];
    final hasItems = items.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.shoppingTitle),
        actions: [
          if (hasItems) ...[
            IconButton(
              icon: const Icon(Icons.shopping_cart_checkout),
              tooltip: strings.isSpanish ? 'Modo Súper' : 'Supermarket Mode',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SupermarketModeScreen()),
                );
              },
            ),
            IconButton(
              icon: Icon(_isCategorizedView ? Icons.view_agenda_outlined : Icons.category_outlined),
              tooltip: _isCategorizedView
                  ? (strings.isSpanish ? 'Ver lista plana' : 'View flat list')
                  : (strings.isSpanish ? 'Agrupar por góndola' : 'Group by aisle'),
              onPressed: () => setState(() => _isCategorizedView = !_isCategorizedView),
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: strings.shareList,
              onPressed: () {
                final text = notifier.buildShareableText(header: strings.shareListHeader);
                if (text.isNotEmpty) {
                  Share.share(text);
                }
              },
            ),
            PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'clear_completed') {
                  notifier.clearCompleted();
                } else if (val == 'clear_all') {
                  notifier.clearAll();
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(value: 'clear_completed', child: Text(strings.clearCompleted)),
                PopupMenuItem(value: 'clear_all', child: Text(strings.clearAll)),
              ],
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.tonalIcon(
                onPressed: () async {
                  final consolidated = await notifier.getWeeklyConsolidatedItems();
                  if (consolidated.isEmpty) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No hay recetas en la semana actual.')),
                      );
                    }
                  } else {
                    if (context.mounted) {
                      _showPantryReviewModal(context, consolidated);
                    }
                  }
                },
                icon: const Icon(Icons.auto_awesome),
                label: Text(strings.generateFromPlanner, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          Expanded(
            child: itemsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return EmptyStateView(
                    icon: Icons.shopping_basket_outlined,
                    title: strings.shoppingEmpty,
                    subtitle: strings.shoppingEmptySubtitle,
                    action: FilledButton.icon(
                      icon: const Icon(Icons.add),
                      label: Text(strings.addCustomItem),
                      onPressed: () {
                        AddShoppingItemDialog.show(
                          context,
                          onAdd: (name, amount, unit) => notifier.addItem(name: name, amount: amount, unit: unit),
                        );
                      },
                    ),
                  );
                }

                if (!_isCategorizedView) {
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ShoppingItemTile(
                        item: item,
                        onToggle: (_) => notifier.toggleItem(item),
                        onDelete: () => notifier.deleteItem(item.id),
                      );
                    },
                  );
                }

                // Categorized Grouping View (without dividers)
                final Map<String, List<ShoppingItem>> grouped = {};
                for (var item in items) {
                  final cat = item.category.isNotEmpty && item.category != 'General'
                      ? item.category
                      : CulinaryCatalog.getCategory(item.name);
                  grouped.putIfAbsent(cat, () => []).add(item);
                }

                final groupKeys = grouped.keys.toList();

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: groupKeys.length,
                  itemBuilder: (context, gIndex) {
                    final category = groupKeys[gIndex];
                    final categoryItems = grouped[category]!;

                    String catIcon = '🛒';
                    if (category.contains('Verd') || category.contains('Frut')) catIcon = '🥬';
                    if (category.contains('Carn') || category.contains('Pesc')) catIcon = '🥩';
                    if (category.contains('Láct')) catIcon = '🧀';
                    if (category.contains('Gran') || category.contains('Past')) catIcon = '🌾';
                    if (category.contains('Desp') || category.contains('Almac')) catIcon = '🥫';
                    if (category.contains('Espec')) catIcon = '🧂';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category Header Card
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(catIcon, style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 6),
                                Text(
                                  category,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${categoryItems.length}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...categoryItems.map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 6.0),
                                child: ShoppingItemTile(
                                  item: item,
                                  onToggle: (_) => notifier.toggleItem(item),
                                  onDelete: () => notifier.deleteItem(item.id),
                                ),
                              )),
                        ],
                      ),
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
    );
  }
}

