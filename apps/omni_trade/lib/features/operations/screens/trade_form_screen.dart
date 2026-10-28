import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/trade_operation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics_helper.dart';
import '../../../core/utils/image_storage_helper.dart';
import '../../../l10n/app_localizations.dart';

class TradeFormScreen extends StatefulWidget {
  final TradeOperation? initialTrade;
  final String currencySymbol;
  final void Function(TradeOperation trade) onSave;

  const TradeFormScreen({
    super.key,
    this.initialTrade,
    required this.currencySymbol,
    required this.onSave,
  });

  @override
  State<TradeFormScreen> createState() => _TradeFormScreenState();
}

class _TradeFormScreenState extends State<TradeFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _symbolController;
  late TextEditingController _entryPriceController;
  late TextEditingController _quantityController;
  late TextEditingController _stopLossController;
  late TextEditingController _takeProfitController;
  late TextEditingController _feesController;
  late TextEditingController _multiplierController;
  late TextEditingController _notesController;

  late TradeDirection _direction;
  late String _assetClass;
  String? _selectedStrategy;
  String? _selectedEmotion;
  String? _entryScreenshotPath;
  String? _exitScreenshotPath;

  @override
  void initState() {
    super.initState();
    final trade = widget.initialTrade;

    _symbolController = TextEditingController(text: trade?.symbol ?? '');
    _entryPriceController = TextEditingController(
      text: trade != null ? trade.entryPrice.toString() : '',
    );
    _quantityController = TextEditingController(
      text: trade != null ? trade.quantity.toString() : '',
    );
    _stopLossController = TextEditingController(
      text: trade?.stopLoss != null ? trade!.stopLoss.toString() : '',
    );
    _takeProfitController = TextEditingController(
      text: trade?.takeProfit != null ? trade!.takeProfit.toString() : '',
    );
    _feesController = TextEditingController(
      text: trade != null && trade.fees > 0 ? trade.fees.toString() : '0.00',
    );
    _multiplierController = TextEditingController(
      text: trade != null ? trade.multiplier.toString() : '1.0',
    );
    _notesController = TextEditingController(text: trade?.notes ?? '');

    _direction = trade?.direction ?? TradeDirection.long;
    _assetClass = trade?.assetClass ?? AppConstants.assetClasses.first;
    _selectedStrategy = trade?.strategyTag;
    _selectedEmotion = trade?.emotionTag;
    _entryScreenshotPath = trade?.entryScreenshotPath;
    _exitScreenshotPath = trade?.exitScreenshotPath;

    // Real-time recalculation on target changes
    _entryPriceController.addListener(_onFieldChanged);
    _quantityController.addListener(_onFieldChanged);
    _stopLossController.addListener(_onFieldChanged);
    _takeProfitController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _symbolController.dispose();
    _entryPriceController.dispose();
    _quantityController.dispose();
    _stopLossController.dispose();
    _takeProfitController.dispose();
    _feesController.dispose();
    _multiplierController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImageSlot({required bool isEntry}) async {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusMd)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEntry ? l10n.t('entryChartTitle') : l10n.t('exitChartTitle'),
                style: AppTypography.display(colors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                leading: Icon(Icons.photo_library_rounded, color: colors.secondary),
                title: Text(l10n.t('chooseGalleryAction'), style: AppTypography.body(colors.textPrimary)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: Icon(Icons.camera_alt_rounded, color: colors.primary),
                title: Text(l10n.t('takePhotoAction'), style: AppTypography.body(colors.textPrimary)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final savedPath = await ImageStorageHelper.pickAndSaveImage(source: source);
    if (savedPath != null) {
      HapticsHelper.selection();
      setState(() {
        if (isEntry) {
          _entryScreenshotPath = savedPath;
        } else {
          _exitScreenshotPath = savedPath;
        }
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      HapticsHelper.error();
      return;
    }

    final entryPrice = double.tryParse(_entryPriceController.text.trim()) ?? 0.0;
    final quantity = double.tryParse(_quantityController.text.trim()) ?? 0.0;
    final stopLoss = double.tryParse(_stopLossController.text.trim());
    final takeProfit = double.tryParse(_takeProfitController.text.trim());
    final fees = double.tryParse(_feesController.text.trim()) ?? 0.0;
    final multiplier = double.tryParse(_multiplierController.text.trim()) ?? 1.0;

    final trade = TradeOperation(
      id: widget.initialTrade?.id ?? const Uuid().v4(),
      symbol: _symbolController.text.trim().toUpperCase(),
      assetClass: _assetClass,
      direction: _direction,
      status: widget.initialTrade?.status ?? TradeStatus.open,
      entryPrice: entryPrice,
      exitPrice: widget.initialTrade?.exitPrice,
      quantity: quantity,
      multiplier: multiplier,
      fees: fees,
      stopLoss: stopLoss,
      takeProfit: takeProfit,
      entryDate: widget.initialTrade?.entryDate ?? DateTime.now(),
      exitDate: widget.initialTrade?.exitDate,
      strategyTag: _selectedStrategy,
      emotionTag: _selectedEmotion,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      entryScreenshotPath: _entryScreenshotPath,
      exitScreenshotPath: _exitScreenshotPath,
    );

    HapticsHelper.medium();
    widget.onSave(trade);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final isEditing = widget.initialTrade != null;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(isEditing ? l10n.t('editTradeTitle') : l10n.t('newTradeTitle')),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: ElevatedButton.icon(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.secondary,
                foregroundColor: colors.onSecondary,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusFull)),
                elevation: 0,
              ),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: Text(
                l10n.t('saveAction'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.paddingScreen,
          children: [
            // 1. Bento Card: Active & Direction
            _buildBentoSection(
              colors: colors,
              title: l10n.t('basicInfoCardTitle'),
              icon: Icons.alt_route_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Direction Selector (LONG vs SHORT)
                  Row(
                    children: [
                      Expanded(
                        child: _buildDirectionButton(
                          direction: TradeDirection.long,
                          label: l10n.t('buyLongButton'),
                          icon: Icons.trending_up_rounded,
                          activeColor: colors.profit,
                          colors: colors,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _buildDirectionButton(
                          direction: TradeDirection.short,
                          label: l10n.t('sellShortButton'),
                          icon: Icons.trending_down_rounded,
                          activeColor: colors.loss,
                          colors: colors,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Asset Class Chips
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: AppConstants.assetClasses.length,
                      separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
                      itemBuilder: (context, index) {
                        final cat = AppConstants.assetClasses[index];
                        final isSelected = _assetClass == cat;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              HapticsHelper.selection();
                              setState(() => _assetClass = cat);
                            }
                          },
                          selectedColor: colors.primary,
                          labelStyle: AppTypography.caption(
                            isSelected ? colors.onPrimary : colors.textSecondary,
                            isMedium: true,
                          ),
                          backgroundColor: colors.surface,
                          side: BorderSide(
                            color: isSelected ? colors.primary : colors.outline,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Symbol / Ticker input
                  TextFormField(
                    controller: _symbolController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: l10n.t('tickerLabel'),
                      hintText: l10n.t('tickerHint'),
                      prefixIcon: const Icon(Icons.tag_rounded),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? l10n.t('requiredValidation') : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 2. Bento Card: Risk Management & Targets
            _buildBentoSection(
              colors: colors,
              title: l10n.t('riskManagementCardTitle'),
              icon: Icons.calculate_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Entry Price & Quantity Row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _entryPriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: l10n.t('entryPriceLabel'),
                            prefixText: '${widget.currencySymbol} ',
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return l10n.t('requiredValidation');
                            if (double.tryParse(v.trim()) == null) return l10n.t('invalidNumberValidation');
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextFormField(
                          controller: _quantityController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: l10n.t('quantityLabel'),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return l10n.t('requiredValidation');
                            if (double.tryParse(v.trim()) == null) return l10n.t('invalidNumberValidation');
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Stop Loss & Take Profit Row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _stopLossController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: l10n.t('stopLossLabel'),
                            prefixText: '${widget.currencySymbol} ',
                            helperText: l10n.t('stopLossHelper'),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextFormField(
                          controller: _takeProfitController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: l10n.t('takeProfitLabel'),
                            prefixText: '${widget.currencySymbol} ',
                            helperText: l10n.t('takeProfitHelper'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Live Risk/Reward Preview Pill
                  _buildRiskRewardPreview(colors, l10n),
                  const SizedBox(height: AppSpacing.md),

                  // Fees & Multiplier
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _feesController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: l10n.t('feesLabel'),
                            prefixText: '${widget.currencySymbol} ',
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextFormField(
                          controller: _multiplierController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: l10n.t('multiplierLabel'),
                            helperText: l10n.t('multiplierHelper'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 3. Bento Card: Chart Screenshots (Setup / Result)
            _buildBentoSection(
              colors: colors,
              title: l10n.t('chartAttachmentsTitle'),
              icon: Icons.image_rounded,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildChartSlot(
                          title: l10n.t('entryChartTitle'),
                          path: _entryScreenshotPath,
                          colors: colors,
                          l10n: l10n,
                          onPick: () => _pickImageSlot(isEntry: true),
                          onRemove: () {
                            HapticsHelper.light();
                            setState(() => _entryScreenshotPath = null);
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _buildChartSlot(
                          title: l10n.t('exitChartTitle'),
                          path: _exitScreenshotPath,
                          colors: colors,
                          l10n: l10n,
                          onPick: () => _pickImageSlot(isEntry: false),
                          onRemove: () {
                            HapticsHelper.light();
                            setState(() => _exitScreenshotPath = null);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 4. Bento Card: Strategy & Psychology
            _buildBentoSection(
              colors: colors,
              title: l10n.t('journalTitle'),
              icon: Icons.psychology_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Strategy Setup Selection
                  Text(
                    l10n.t('strategyTitle'),
                    style: AppTypography.caption(colors.textSecondary, isMedium: true),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xxs,
                    children: AppConstants.defaultStrategies.map((strat) {
                      final isSelected = _selectedStrategy == strat;
                      return ChoiceChip(
                        label: Text(strat),
                        selected: isSelected,
                        onSelected: (selected) {
                          HapticsHelper.selection();
                          setState(() {
                            _selectedStrategy = selected ? strat : null;
                          });
                        },
                        selectedColor: colors.secondary.withValues(alpha: 0.2),
                        side: BorderSide(color: isSelected ? colors.secondary : colors.outline),
                        labelStyle: AppTypography.caption(
                          isSelected ? colors.secondary : colors.textSecondary,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Mindset & Emotion Tag
                  Text(
                    l10n.t('mindsetTitle'),
                    style: AppTypography.caption(colors.textSecondary, isMedium: true),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xxs,
                    children: AppConstants.defaultEmotions.map((emo) {
                      final isSelected = _selectedEmotion == emo;
                      return ChoiceChip(
                        label: Text(emo),
                        selected: isSelected,
                        onSelected: (selected) {
                          HapticsHelper.selection();
                          setState(() {
                            _selectedEmotion = selected ? emo : null;
                          });
                        },
                        selectedColor: colors.primary.withValues(alpha: 0.2),
                        side: BorderSide(color: isSelected ? colors.primary : colors.outline),
                        labelStyle: AppTypography.caption(
                          isSelected ? colors.primary : colors.textSecondary,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Notes
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: l10n.t('notesInputLabel'),
                      hintText: l10n.t('notesHint'),
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildBentoSection({
    required AppColors colors,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: AppSpacing.paddingCard,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: colors.outline.withValues(alpha: 0.8), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: colors.secondary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                title,
                style: AppTypography.caption(colors.textSecondary, isBold: true),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }

  Widget _buildChartSlot({
    required String title,
    required String? path,
    required AppColors colors,
    required AppLocalizations l10n,
    required VoidCallback onPick,
    required VoidCallback onRemove,
  }) {
    final hasImage = path != null && File(path).existsSync();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.caption(colors.textSecondary, isMedium: true),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xs),
        AspectRatio(
          aspectRatio: 16 / 10,
          child: InkWell(
            onTap: onPick,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: Container(
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(
                  color: hasImage ? colors.secondary : colors.outline,
                  width: hasImage ? 1.5 : 1.0,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: hasImage
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(File(path), fit: BoxFit.cover),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: InkWell(
                            onTap: onRemove,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black87,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_rounded, size: 24, color: colors.textTertiary),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            l10n.t('noChartAttached'),
                            style: TextStyle(fontSize: 10, color: colors.textTertiary),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDirectionButton({
    required TradeDirection direction,
    required String label,
    required IconData icon,
    required Color activeColor,
    required AppColors colors,
  }) {
    final isSelected = _direction == direction;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: InkWell(
        onTap: () {
          HapticsHelper.selection();
          setState(() => _direction = direction);
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withValues(alpha: 0.15) : colors.surfaceElevated,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(
              color: isSelected ? activeColor : colors.outline,
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.25),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? activeColor : colors.textSecondary, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: AppTypography.body(
                  isSelected ? activeColor : colors.textSecondary,
                  isBold: isSelected,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiskRewardPreview(AppColors colors, AppLocalizations l10n) {
    final entry = double.tryParse(_entryPriceController.text.trim()) ?? 0.0;
    final qty = double.tryParse(_quantityController.text.trim()) ?? 0.0;
    final sl = double.tryParse(_stopLossController.text.trim());
    final tp = double.tryParse(_takeProfitController.text.trim());

    if (entry <= 0 || qty <= 0) {
      return const SizedBox.shrink();
    }

    double? riskAmount;
    double? rewardAmount;
    double? rrRatio;

    if (sl != null && sl > 0) {
      final diff = _direction == TradeDirection.long ? (entry - sl) : (sl - entry);
      if (diff > 0) {
        riskAmount = diff * qty;
      }
    }

    if (tp != null && tp > 0) {
      final diff = _direction == TradeDirection.long ? (tp - entry) : (entry - tp);
      if (diff > 0) {
        rewardAmount = diff * qty;
      }
    }

    if (riskAmount != null && rewardAmount != null && riskAmount > 0) {
      rrRatio = rewardAmount / riskAmount;
    }

    final isGreatRatio = rrRatio != null && rrRatio >= 2.0;

    return Container(
      padding: AppSpacing.paddingCard,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: colors.outline.withValues(alpha: 0.8), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.t('realtimeRiskRewardTitle'),
                style: AppTypography.caption(colors.textSecondary, isMedium: true),
              ),
              if (rrRatio != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isGreatRatio
                        ? colors.profit.withValues(alpha: 0.2)
                        : colors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    border: Border.all(
                      color: isGreatRatio ? colors.profit : colors.primary,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'R:R 1 : ${rrRatio.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isGreatRatio ? colors.profit : colors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                riskAmount != null
                    ? l10n.t('maxRiskLabel', args: {'amount': '-${widget.currencySymbol}${riskAmount.toStringAsFixed(2)}'})
                    : l10n.t('maxRiskLabel', args: {'amount': l10n.t('notDefinedLabel')}),
                style: AppTypography.caption(
                  riskAmount != null ? colors.loss : colors.textTertiary,
                  isBold: riskAmount != null,
                ),
              ),
              Text(
                rewardAmount != null
                    ? l10n.t('maxRewardLabel', args: {'amount': '${widget.currencySymbol}${rewardAmount.toStringAsFixed(2)}'})
                    : l10n.t('maxRewardLabel', args: {'amount': l10n.t('notDefinedLabel')}),
                style: AppTypography.caption(
                  rewardAmount != null ? colors.profit : colors.textTertiary,
                  isBold: rewardAmount != null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
