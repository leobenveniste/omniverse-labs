import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';

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
  final _unitCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    final amount = double.tryParse(_amountCtrl.text.trim().replaceAll(',', '.')) ?? 0.0;
    final unit = _unitCtrl.text.trim();

    widget.onAdd(name, amount, unit);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.addCustomItem,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            decoration: InputDecoration(
              hintText: strings.itemNameHint,
              prefixIcon: const Icon(Icons.shopping_bag_outlined),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: strings.itemAmountHint,
                    prefixIcon: const Icon(Icons.numbers),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _unitCtrl,
                  decoration: InputDecoration(
                    hintText: strings.itemUnitHint,
                    prefixIcon: const Icon(Icons.scale_outlined),
                  ),
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
