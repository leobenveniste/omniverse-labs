import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/trade_operation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics_helper.dart';
import '../../../l10n/app_localizations.dart';
import 'trade_form_screen.dart';

class TradeDetailScreen extends StatefulWidget {
  final TradeOperation trade;
  final String currencySymbol;
  final void Function(TradeOperation updated) onUpdate;
  final void Function(String id, double exitPrice, DateTime exitDate) onCloseTrade;
  final void Function(String id) onDelete;

  const TradeDetailScreen({
    super.key,
    required this.trade,
    required this.currencySymbol,
    required this.onUpdate,
    required this.onCloseTrade,
    required this.onDelete,
  });

  @override
  State<TradeDetailScreen> createState() => _TradeDetailScreenState();
}

class _TradeDetailScreenState extends State<TradeDetailScreen> {
  late TradeOperation _trade;

  @override
  void initState() {
    super.initState();
    _trade = widget.trade;
  }

  void _openFullScreenChart(String path, String title) {
    HapticsHelper.light();
    showDialog(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 5.0,
              child: Center(
                child: Image.file(File(path), fit: BoxFit.contain),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        title,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                      style: IconButton.styleFrom(backgroundColor: Colors.black54),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCloseTradeDialog() {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final exitPriceController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: colors.surface,
          title: Text(
            l10n.t('closeTradeDialogTitle', args: {'symbol': _trade.symbol}),
            style: AppTypography.title(colors.textPrimary),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.t('closeTradeDialogPrompt'),
                  style: AppTypography.body(colors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: exitPriceController,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: l10n.t('exitLabel'),
                    prefixText: '${widget.currencySymbol} ',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return l10n.t('requiredValidation');
                    if (double.tryParse(v.trim()) == null) return l10n.t('invalidNumberValidation');
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.t('cancelAction'), style: AppTypography.body(colors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: colors.primary),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final exitPrice = double.parse(exitPriceController.text.trim());
                  final exitDate = DateTime.now();
                  HapticsHelper.medium();
                  widget.onCloseTrade(_trade.id, exitPrice, exitDate);
                  Navigator.of(ctx).pop();
                  setState(() {
                    _trade = _trade.copyWith(
                      status: TradeStatus.closed,
                      exitPrice: exitPrice,
                      exitDate: exitDate,
                    );
                  });
                }
              },
              child: Text(
                l10n.t('confirmCloseAction'),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog() {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: colors.surface,
          title: Text(
            l10n.t('deleteTradeDialogTitle'),
            style: AppTypography.title(colors.loss),
          ),
          content: Text(
            l10n.t('deleteTradeDialogPrompt'),
            style: AppTypography.body(colors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.t('cancelAction'), style: AppTypography.body(colors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: colors.loss),
              onPressed: () {
                HapticsHelper.error();
                widget.onDelete(_trade.id);
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: Text(
                l10n.t('deleteAction'),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _navigateToEdit() {
    HapticsHelper.light();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TradeFormScreen(
          initialTrade: _trade,
          currencySymbol: widget.currencySymbol,
          onSave: (updated) {
            widget.onUpdate(updated);
            setState(() => _trade = updated);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final numFormat = NumberFormat('#,##0.00', 'en_US');
    final dateFormat = DateFormat('MMM dd, yyyy • HH:mm');

    final isLong = _trade.direction == TradeDirection.long;
    final isOpen = _trade.status == TradeStatus.open;
    final pnl = _trade.realizedPnl;
    final isPosPnl = (pnl ?? 0) >= 0;
    final pnlColor = isPosPnl ? colors.profit : colors.loss;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(_trade.symbol),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n.t('editTradeTitle'),
            onPressed: _navigateToEdit,
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: colors.loss),
            tooltip: l10n.t('deleteAction'),
            onPressed: _showDeleteDialog,
          ),
        ],
      ),
      body: ListView(
        padding: AppSpacing.paddingScreen,
        children: [
          // Bento Hero Card: P&L or Capital Deployed
          Container(
            padding: AppSpacing.paddingCard,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors.cardGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: !isOpen && pnl != null
                    ? (isPosPnl ? colors.profit : colors.loss).withValues(alpha: 0.35)
                    : colors.outline,
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isLong ? colors.profit : colors.loss).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isLong ? l10n.t('longBadge') : l10n.t('shortBadge'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isLong ? colors.profit : colors.loss,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isOpen
                            ? colors.primary.withValues(alpha: 0.15)
                            : colors.surfaceElevated,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Text(
                        isOpen ? l10n.t('openTradeHeader') : l10n.t('closedStatus'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isOpen ? colors.primary : colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (!isOpen && pnl != null) ...[
                  Text(
                    '${isPosPnl ? '+' : ''}${widget.currencySymbol}${numFormat.format(pnl)}',
                    style: AppTypography.display(pnlColor),
                  ),
                  if (_trade.realizedReturnPercentage != null)
                    Text(
                      '${isPosPnl ? '+' : ''}${l10n.t('netReturnPercent', args: {'percent': _trade.realizedReturnPercentage!.toStringAsFixed(2)})}',
                      style: AppTypography.body(pnlColor, isMedium: true),
                    ),
                ] else ...[
                  Text(
                    'Capital: ${widget.currencySymbol}${numFormat.format(_trade.investedCapital)}',
                    style: AppTypography.title(colors.textPrimary),
                  ),
                  if (_trade.riskRewardRatio != null)
                    Text(
                      '${l10n.t('rrRatioLabel')} 1 : ${_trade.riskRewardRatio!.toStringAsFixed(2)}',
                      style: AppTypography.body(colors.secondary, isMedium: true),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Price Execution Breakdown
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
                  l10n.t('executionDataTitle'),
                  style: AppTypography.caption(colors.textSecondary, isMedium: true),
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildRow(l10n.t('entryLabel'), '${widget.currencySymbol}${numFormat.format(_trade.entryPrice)}', colors),
                if (_trade.exitPrice != null)
                  _buildRow(l10n.t('exitLabel'), '${widget.currencySymbol}${numFormat.format(_trade.exitPrice!)}', colors),
                _buildRow(l10n.t('quantityLabel'), l10n.t('unitsLabel', args: {'qty': _trade.quantity}), colors),
                if (_trade.multiplier > 1.0)
                  _buildRow(l10n.t('multiplierLabel'), '${_trade.multiplier}x', colors),
                if (_trade.fees > 0)
                  _buildRow(l10n.t('feesLabel'), '${widget.currencySymbol}${numFormat.format(_trade.fees)}', colors),
                if (_trade.stopLoss != null)
                  _buildRow(l10n.t('stopLossLabel'), '${widget.currencySymbol}${numFormat.format(_trade.stopLoss!)}', colors, valColor: colors.loss),
                if (_trade.takeProfit != null)
                  _buildRow(l10n.t('takeProfitLabel'), '${widget.currencySymbol}${numFormat.format(_trade.takeProfit!)}', colors, valColor: colors.profit),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Chart Screenshots Section (If attached)
          if (_trade.hasScreenshots) ...[
            Container(
              padding: AppSpacing.paddingCard,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: colors.secondary.withValues(alpha: 0.3), width: 1.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.photo_size_select_actual_rounded, size: 16, color: colors.secondary),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        l10n.t('chartAttachmentsTitle'),
                        style: AppTypography.caption(colors.textSecondary, isBold: true),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      if (_trade.entryScreenshotPath != null && File(_trade.entryScreenshotPath!).existsSync())
                        Expanded(
                          child: _buildDetailChartCard(
                            title: l10n.t('entryChartTitle'),
                            path: _trade.entryScreenshotPath!,
                            colors: colors,
                            onTap: () => _openFullScreenChart(_trade.entryScreenshotPath!, l10n.t('entryChartTitle')),
                          ),
                        ),
                      if (_trade.entryScreenshotPath != null && _trade.exitScreenshotPath != null)
                        const SizedBox(width: AppSpacing.sm),
                      if (_trade.exitScreenshotPath != null && File(_trade.exitScreenshotPath!).existsSync())
                        Expanded(
                          child: _buildDetailChartCard(
                            title: l10n.t('exitChartTitle'),
                            path: _trade.exitScreenshotPath!,
                            colors: colors,
                            onTap: () => _openFullScreenChart(_trade.exitScreenshotPath!, l10n.t('exitChartTitle')),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Setup & Mindset Breakdown
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
                  l10n.t('journalTitle'),
                  style: AppTypography.caption(colors.textSecondary, isMedium: true),
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildRow(l10n.t('strategyLabel'), _trade.strategyTag ?? l10n.t('unassignedLabel'), colors),
                _buildRow(l10n.t('mindsetLabel'), _trade.emotionTag ?? l10n.t('unassignedLabel'), colors),
                _buildRow(l10n.t('entryDateLabel'), dateFormat.format(_trade.entryDate), colors),
                if (_trade.exitDate != null)
                  _buildRow(l10n.t('exitDateLabel'), dateFormat.format(_trade.exitDate!), colors),
                if (_trade.notes != null && _trade.notes!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  const Divider(),
                  const SizedBox(height: AppSpacing.xs),
                  Text(l10n.t('notesLabel'), style: AppTypography.caption(colors.textTertiary)),
                  const SizedBox(height: 4),
                  Text(_trade.notes!, style: AppTypography.body(colors.textPrimary)),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Close Trade CTA (if Open)
          if (isOpen)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.secondary,
                foregroundColor: colors.onSecondary,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
              ),
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: Text(
                l10n.t('closeTradeAction'),
                style: AppTypography.body(colors.onSecondary, isBold: true),
              ),
              onPressed: () {
                HapticsHelper.medium();
                _showCloseTradeDialog();
              },
            ),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildDetailChartCard({
    required String title,
    required String path,
    required AppColors colors,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.caption(colors.textSecondary, isMedium: true)),
        const SizedBox(height: AppSpacing.xs),
        AspectRatio(
          aspectRatio: 16 / 10,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(color: colors.outline),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(File(path), fit: BoxFit.cover),
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.fullscreen_rounded, size: 16, color: Colors.white),
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

  Widget _buildRow(String label, String value, AppColors colors, {Color? valColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.body(colors.textSecondary)),
          Text(value, style: AppTypography.body(valColor ?? colors.textPrimary, isMedium: true)),
        ],
      ),
    );
  }
}
