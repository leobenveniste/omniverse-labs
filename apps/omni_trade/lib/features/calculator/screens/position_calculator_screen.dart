import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics_helper.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/trade_provider.dart';
import '../../operations/screens/trade_form_screen.dart';

class PositionCalculatorScreen extends StatefulWidget {
  final SettingsProvider settingsProvider;
  final TradeProvider tradeProvider;

  const PositionCalculatorScreen({
    super.key,
    required this.settingsProvider,
    required this.tradeProvider,
  });

  @override
  State<PositionCalculatorScreen> createState() => _PositionCalculatorScreenState();
}

class _PositionCalculatorScreenState extends State<PositionCalculatorScreen> {
  late TextEditingController _balanceController;
  late TextEditingController _riskPercentController;
  late TextEditingController _entryPriceController;
  late TextEditingController _stopLossController;

  double _selectedRiskPreset = 1.0; // 1% default

  @override
  void initState() {
    super.initState();
    final balance = widget.settingsProvider.accountBalance;
    _balanceController = TextEditingController(text: balance.toStringAsFixed(0));
    _riskPercentController = TextEditingController(text: '1.0');
    _entryPriceController = TextEditingController();
    _stopLossController = TextEditingController();

    _balanceController.addListener(_onChanged);
    _riskPercentController.addListener(_onChanged);
    _entryPriceController.addListener(_onChanged);
    _stopLossController.addListener(_onChanged);
  }

  void _onChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _balanceController.dispose();
    _riskPercentController.dispose();
    _entryPriceController.dispose();
    _stopLossController.dispose();
    super.dispose();
  }

  void _setRiskPreset(double percent) {
    HapticsHelper.selection();
    setState(() {
      _selectedRiskPreset = percent;
      _riskPercentController.text = percent.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final symbol = widget.settingsProvider.currencySymbol;
    final numFormat = NumberFormat('#,##0.00', 'en_US');

    final balance = double.tryParse(_balanceController.text.trim()) ?? 0.0;
    final riskPercent = double.tryParse(_riskPercentController.text.trim()) ?? 0.0;
    final entryPrice = double.tryParse(_entryPriceController.text.trim()) ?? 0.0;
    final stopLoss = double.tryParse(_stopLossController.text.trim()) ?? 0.0;

    // Calculation
    final dollarRisk = balance * (riskPercent / 100.0);
    double priceDiff = (entryPrice - stopLoss).abs();
    double units = 0.0;
    double totalPositionValue = 0.0;
    double stopLossPercent = 0.0;

    if (entryPrice > 0 && priceDiff > 0) {
      units = dollarRisk / priceDiff;
      totalPositionValue = units * entryPrice;
      stopLossPercent = (priceDiff / entryPrice) * 100.0;
    }

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(l10n.t('calculatorTitle')),
      ),
      body: ListView(
        padding: AppSpacing.paddingScreen,
        children: [
          // Bento Summary Card: Recommended Position Size
          Container(
            padding: AppSpacing.paddingCard,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors.cardGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: colors.secondary.withValues(alpha: 0.4), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.t('recommendedSizeTitle'),
                      style: AppTypography.caption(colors.textSecondary, isMedium: true),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Text(
                        l10n.t('riskManagementBadge', args: {'percent': _selectedRiskPreset}),
                        style: AppTypography.caption(colors.secondary, isBold: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  units > 0 ? units.toStringAsFixed(units < 1 ? 4 : 2) : '0.00',
                  style: AppTypography.display(colors.secondary),
                ),
                Text(
                  l10n.t('unitsCalculatedSubtitle'),
                  style: AppTypography.caption(colors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.t('maxDollarRiskLabel'), style: AppTypography.caption(colors.textTertiary)),
                        Text(
                          '$symbol${numFormat.format(dollarRisk)} ($riskPercent%)',
                          style: AppTypography.body(colors.loss, isBold: true),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(l10n.t('totalPositionValueLabel'), style: AppTypography.caption(colors.textTertiary)),
                        Text(
                          '$symbol${numFormat.format(totalPositionValue)}',
                          style: AppTypography.body(colors.textPrimary, isBold: true),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Inputs Section
          Container(
            padding: AppSpacing.paddingCard,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: colors.outline, width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.t('accountParamsTitle'),
                  style: AppTypography.caption(colors.textSecondary, isMedium: true),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Account Balance Input
                TextFormField(
                  controller: _balanceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: l10n.t('accountBalanceLabel'),
                    prefixText: '$symbol ',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Risk % Presets
                Text(
                  l10n.t('riskPerTradeTitle'),
                  style: AppTypography.caption(colors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    _buildRiskChip(0.5, colors),
                    const SizedBox(width: AppSpacing.xs),
                    _buildRiskChip(1.0, colors),
                    const SizedBox(width: AppSpacing.xs),
                    _buildRiskChip(2.0, colors),
                    const SizedBox(width: AppSpacing.xs),
                    _buildRiskChip(3.0, colors),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                TextFormField(
                  controller: _riskPercentController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: l10n.t('customPercentLabel'),
                    suffixText: '%',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                const Divider(),
                const SizedBox(height: AppSpacing.sm),

                Text(
                  l10n.t('tradeParamsTitle'),
                  style: AppTypography.caption(colors.textSecondary, isMedium: true),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Entry Price & Stop Loss
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _entryPriceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: l10n.t('entryPriceLabel'),
                          prefixText: '$symbol ',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextFormField(
                        controller: _stopLossController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: l10n.t('stopLossLabel'),
                          prefixText: '$symbol ',
                        ),
                      ),
                    ),
                  ],
                ),

                if (stopLossPercent > 0) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.t('slDistanceLabel', args: {'percent': stopLossPercent.toStringAsFixed(2)}),
                    style: AppTypography.caption(colors.textTertiary),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Action Button: Transfer directly into New Trade Form
          if (units > 0 && entryPrice > 0)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
              ),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(
                l10n.t('createTradeWithValuesAction'),
                style: AppTypography.body(colors.onPrimary, isBold: true),
              ),
              onPressed: () {
                HapticsHelper.medium();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => TradeFormScreen(
                      currencySymbol: symbol,
                      initialTrade: null,
                      onSave: (trade) => widget.tradeProvider.addTrade(trade),
                    ),
                  ),
                );
              },
            ),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildRiskChip(double percent, AppColors colors) {
    final isSelected = _selectedRiskPreset == percent;
    return Expanded(
      child: InkWell(
        onTap: () => _setRiskPreset(percent),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? colors.primary : colors.surfaceElevated,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(
              color: isSelected ? colors.primary : colors.outline,
              width: 1.0,
            ),
          ),
          child: Text(
            '$percent%',
            style: AppTypography.caption(
              isSelected ? colors.onPrimary : colors.textSecondary,
              isBold: isSelected,
            ),
          ),
        ),
      ),
    );
  }
}
