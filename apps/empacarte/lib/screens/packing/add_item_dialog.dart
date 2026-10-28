import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/packing_item.dart';

class AddItemDialog extends StatefulWidget {
  final String tripId;
  final BagCompartment initialBag;

  const AddItemDialog({
    super.key,
    required this.tripId,
    required this.initialBag,
  });

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final _nameController = TextEditingController();
  late BagCompartment _selectedBag;
  PackingCategory _selectedCategory = PackingCategory.clothing;
  int _quantity = 1;
  double _weightKg = 0.2;
  bool _isAlwaysPack = false;

  @override
  void initState() {
    super.initState();
    _selectedBag = widget.initialBag;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = isDark ? AppColors.darkCard : AppColors.parchmentCard;
    final textSecondary = isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary;
    final primaryAccent = isDark ? AppColors.goldFoil : AppColors.burgundyBase;

    return AlertDialog(
      backgroundColor: cardBg,
      title: Text(
        t.t('add_item_title'),
        style: AppTypography.subheadSerif(color: primaryAccent),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: t.t('add_item_name'),
                hintText: t.t('add_item_name_hint'),
                labelStyle: AppTypography.caption(color: textSecondary),
              ),
            ),
            const SizedBox(height: 16),

            // Bag Selector
            Text(t.t('add_item_bag'), style: AppTypography.caption(color: textSecondary)),
            const SizedBox(height: 6),
            DropdownButtonFormField<BagCompartment>(
              initialValue: _selectedBag,
              decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12)),
              items: [
                DropdownMenuItem(
                  value: BagCompartment.personalItem,
                  child: Text(t.t('pack_bag_personal'), style: AppTypography.body(color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary)),
                ),
                DropdownMenuItem(
                  value: BagCompartment.carryOn,
                  child: Text(t.t('pack_bag_carryon'), style: AppTypography.body(color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary)),
                ),
                DropdownMenuItem(
                  value: BagCompartment.checked,
                  child: Text(t.t('pack_bag_checked'), style: AppTypography.body(color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary)),
                ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedBag = val);
              },
            ),
            const SizedBox(height: 16),

            // Category Selector
            Text(t.t('add_item_category'), style: AppTypography.caption(color: textSecondary)),
            const SizedBox(height: 6),
            DropdownButtonFormField<PackingCategory>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12)),
              items: PackingCategory.values.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Text(
                    cat.name.toUpperCase(),
                    style: AppTypography.body(color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCategory = val);
              },
            ),
            const SizedBox(height: 16),

            // Quantity & Weight
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.t('add_item_qty'), style: AppTypography.caption(color: textSecondary)),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline_rounded),
                            onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                          ),
                          Text('$_quantity', style: AppTypography.subheadSans(color: isDark ? Colors.white : Colors.black, bold: true)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline_rounded),
                            onPressed: () => setState(() => _quantity++),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${t.t('add_item_weight')} (kg)', style: AppTypography.caption(color: textSecondary)),
                      const SizedBox(height: 4),
                      TextFormField(
                        initialValue: _weightKg.toString(),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (val) {
                          final parsed = double.tryParse(val);
                          if (parsed != null) _weightKg = parsed;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Always Pack switch
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(
                t.locale.languageCode == 'es'
                    ? 'Siempre llevo esto en mis viajes'
                    : 'Always pack this in future trips',
                style: AppTypography.bodySmall(
                  color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                  medium: true,
                ),
              ),
              subtitle: Text(
                t.locale.languageCode == 'es'
                    ? 'Se sugerirá automáticamente en todos tus próximos viajes'
                    : 'Will be automatically included in all future trips',
                style: AppTypography.caption(color: textSecondary),
              ),
              value: _isAlwaysPack,
              activeTrackColor: primaryAccent,
              onChanged: (val) => setState(() => _isAlwaysPack = val),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.t('btn_cancel')),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryAccent,
            foregroundColor: isDark ? AppColors.darkBackground : Colors.white,
          ),
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) return;

            final newItem = PackingItem(
              id: const Uuid().v4(),
              tripId: widget.tripId,
              name: name,
              compartment: _selectedBag,
              category: _selectedCategory,
              quantity: _quantity,
              weightKg: _weightKg * _quantity,
              isAlwaysPack: _isAlwaysPack,
            );

            Navigator.of(context).pop(newItem);
          },
          child: Text(t.t('btn_save')),
        ),
      ],
    );
  }
}
