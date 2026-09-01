import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../models/shopping_item_model.dart';
import '../providers/shopping_provider.dart';
import 'widgets/add_item_dialog.dart';
import 'widgets/shopping_item_tile.dart';

class ShoppingListScreen extends ConsumerWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final itemsAsync = ref.watch(shoppingListProvider);
    final notifier = ref.read(shoppingListProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.shoppingTitle),
        actions: [
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
      ),
      body: Column(
        children: [
          // Banner button: Generate from Weekly Meal Plan
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.tonalIcon(
                onPressed: () async {
                  final count = await notifier.generateFromWeeklyMealPlan();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(count > 0 ? strings.generateSuccess : 'No hay recetas en la semana actual.')),
                    );
                  }
                },
                icon: const Icon(Icons.auto_awesome),
                label: Text(strings.generateFromPlanner, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          // Items List
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

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ShoppingItemTile(
                      item: item,
                      onToggle: (_) => notifier.toggleItem(item),
                      onDelete: () => notifier.deleteItem(item.id),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          AddShoppingItemDialog.show(
            context,
            onAdd: (name, amount, unit) => notifier.addItem(name: name, amount: amount, unit: unit),
          );
        },
        tooltip: strings.addCustomItem,
        child: const Icon(Icons.add),
      ),
    );
  }
}
