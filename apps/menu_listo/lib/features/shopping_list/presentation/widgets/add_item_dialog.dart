import 'package:flutter/material.dart';
import 'package:menu_listo/core/localization/app_localizations.dart';
import 'package:menu_listo/core/utils/culinary_catalog.dart';

class AddShoppingItemDialog extends StatefulWidget {
  final Function(String name, double amount, String unit) onAdd;

  const AddShoppingItemDialog({super.key, required this.onAdd});

  static void show(BuildContext context, {required Function(String name, double amount, String unit) onAdd}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: AddShoppingItemDialog(onAdd: onAdd),
      ),
    );
  }

  @override
  State<AddShoppingItemDialog> createState() => _AddShoppingItemDialogState();
}

class _AddShoppingItemDialogState extends State<AddShoppingItemDialog> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _selectedUnit = 'unidades';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    final amount = double.tryParse(_amountCtrl.text.trim().replaceAll(',', '.')) ?? 0.0;
    final unit = _selectedUnit.isNotEmpty ? _selectedUnit : 'unidades';

    widget.onAdd(name, amount, unit);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final currentEmoji = CulinaryCatalog.getEmoji(_nameCtrl.text);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                strings.addCustomItem,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Text(currentEmoji, style: const TextStyle(fontSize: 20)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Autocomplete for ingredient name
          Autocomplete<CulinaryIngredientItem>(
            displayStringForOption: (option) => option.name,
            optionsBuilder: (textEditingValue) {
              if (textEditingValue.text.trim().isEmpty) {
                return const Iterable<CulinaryIngredientItem>.empty();
              }
              final query = CulinaryCatalog.removeDiacritics(textEditingValue.text.toLowerCase().trim());
              return CulinaryCatalog.ingredients.where(
                (ing) =>
                    CulinaryCatalog.removeDiacritics(ing.name.toLowerCase()).contains(query) ||
                    CulinaryCatalog.removeDiacritics(ing.nameEn.toLowerCase()).contains(query),
              );
            },
            onSelected: (selection) {
              _nameCtrl.text = selection.name;
              _selectedUnit = CulinaryCatalog.normalizeUnit(selection.defaultUnit);
              setState(() {});
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 280,
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, i) {
                        final opt = options.elementAt(i);
                        return ListTile(
                          dense: true,
                          leading: Text(opt.emoji, style: const TextStyle(fontSize: 18)),
                          title: Text(opt.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: Text(opt.category, style: const TextStyle(fontSize: 11)),
                          onTap: () => onSelected(opt),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              controller.addListener(() {
                _nameCtrl.text = controller.text;
                setState(() {});
              });
              return TextField(
                controller: controller,
                focusNode: focusNode,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: strings.itemNameHint,
                  prefixIcon: const Icon(Icons.shopping_bag_outlined),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                flex: 4,
                child: TextField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: strings.itemAmountHint,
                    prefixIcon: const Icon(Icons.numbers),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 5,
                child: DropdownButtonFormField<String>(
                  initialValue: CulinaryCatalog.units.contains(_selectedUnit) ? _selectedUnit : 'unidades',
                  isExpanded: true,
                  decoration: InputDecoration(
                    hintText: strings.itemUnitHint,
                    prefixIcon: const Icon(Icons.scale_outlined),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  ),
                  items: CulinaryCatalog.units
                      .map((u) => DropdownMenuItem(
                            value: u,
                            child: Text(u, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedUnit = val);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.add),
              label: Text(strings.save),
            ),
          ),
        ],
      ),
    );
  }
}
