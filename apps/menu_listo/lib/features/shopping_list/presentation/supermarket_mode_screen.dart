import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:menu_listo/core/localization/app_localizations.dart';
import 'package:menu_listo/core/utils/culinary_catalog.dart';
import 'package:menu_listo/core/utils/portion_calculator.dart';
import 'package:menu_listo/core/widgets/feature_guide_dialog.dart';
import '../providers/shopping_provider.dart';

class SupermarketModeScreen extends ConsumerStatefulWidget {
  const SupermarketModeScreen({super.key});

  @override
  ConsumerState<SupermarketModeScreen> createState() => _SupermarketModeScreenState();
}

class _SupermarketModeScreenState extends ConsumerState<SupermarketModeScreen> {
  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkFirstTimeGuide());
  }

  Future<void> _checkFirstTimeGuide() async {
    final strings = AppStrings.of(context);
    await FeatureGuideDialog.showIfFirstTime(
      context: context,
      prefKey: 'has_seen_guide_supermarket',
      headerIcon: Icons.shopping_cart_checkout,
      headerColor: Colors.deepOrange,
      title: strings.isSpanish ? '¡Bienvenido al Modo Súper!' : 'Welcome to Supermarket Mode!',
      subtitle: strings.isSpanish
          ? 'Tu asistente de compras en tienda: rápido, claro y sin bloqueos.'
          : 'Your in-store shopping assistant: fast, clear, and distraction-free.',
      features: [
        FeatureGuideItem(
          icon: Icons.touch_app_outlined,
          iconColor: Colors.green,
          title: strings.isSpanish ? 'Tachado con 1 Toque' : '1-Tap Strike-Through',
          description: strings.isSpanish
              ? 'Toca cualquier producto para marcarlo como comprado y enviarlo al final de la lista con vibración suave.'
              : 'Tap any product to mark it as purchased and move it to the bottom with gentle haptic feedback.',
        ),
        FeatureGuideItem(
          icon: Icons.lightbulb_outline,
          iconColor: Colors.amber,
          title: strings.isSpanish ? 'Pantalla Siempre Encendida' : 'Screen Always On',
          description: strings.isSpanish
              ? 'El teléfono no se apagará mientras recorres las góndolas para que no tengas que desbloquearlo constantemente.'
              : 'Your phone screen will stay on while walking through the aisles so you never have to unlock it.',
        ),
        FeatureGuideItem(
          icon: Icons.format_size_rounded,
          iconColor: Colors.blueAccent,
          title: strings.isSpanish ? 'Tipografía de Alto Contraste' : 'High-Contrast Typography',
          description: strings.isSpanish
              ? 'Diseñado con letras grandes e iconos claros para leer fácilmente con el celular en una mano o en el carrito.'
              : 'Designed with large text and clear emojis for easy one-handed reading in the store.',
        ),
      ],
    );
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final itemsAsync = ref.watch(shoppingListProvider);
    final notifier = ref.read(shoppingListProvider.notifier);

    return itemsAsync.when(
      data: (items) {
        final total = items.length;
        final completed = items.where((i) => i.isCompleted).length;
        final progress = total > 0 ? (completed / total) : 0.0;

        // Sort items so uncompleted come first
        final sortedItems = [...items];
        sortedItems.sort((a, b) {
          if (a.isCompleted == b.isCompleted) return 0;
          return a.isCompleted ? 1 : -1;
        });

        return Scaffold(
          backgroundColor: theme.colorScheme.surface,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              strings.isSpanish ? 'Modo Súper 🛒' : 'Supermarket Mode 🛒',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(40),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$completed de $total comprados (${(progress * 100).toInt()}%)',
                          style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (completed == total && total > 0)
                          const Text('🎉 ¡Todo listo!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(
                          progress == 1.0 ? Colors.green : theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: sortedItems.isEmpty
              ? Center(
                  child: Text(
                    strings.shoppingEmpty,
                    style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                  itemCount: sortedItems.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = sortedItems[index];
                    final emoji = CulinaryCatalog.getEmoji(item.name);
                    final formattedAmount = item.amount > 0 ? PortionCalculator.formatAmount(item.amount) : '';
                    final unitStr = item.unit.isNotEmpty ? ' ${item.unit}' : '';

                    return InkWell(
                      onTap: () => notifier.toggleItem(item),
                      borderRadius: BorderRadius.circular(18),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: item.isCompleted
                              ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35)
                              : theme.colorScheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: item.isCompleted
                                ? Colors.transparent
                                : theme.colorScheme.outline.withValues(alpha: 0.25),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: item.isCompleted ? Colors.green : Colors.transparent,
                                border: Border.all(
                                  color: item.isCompleted ? Colors.green : theme.colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                              child: item.isCompleted
                                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Text(emoji, style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                                      color: item.isCompleted
                                          ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                                          : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  if (formattedAmount.isNotEmpty || unitStr.isNotEmpty)
                                    Text(
                                      '$formattedAmount$unitStr',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: item.isCompleted
                                            ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
                                            : theme.colorScheme.primary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}
