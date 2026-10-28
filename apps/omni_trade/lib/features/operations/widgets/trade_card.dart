import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/trade_operation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics_helper.dart';
import '../../../l10n/app_localizations.dart';

class TradeCard extends StatelessWidget {
  final TradeOperation trade;
  final String currencySymbol;
  final VoidCallback onTap;

  const TradeCard({
    super.key,
    required this.trade,
    required this.currencySymbol,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final isLong = trade.direction == TradeDirection.long;
    final isOpen = trade.status == TradeStatus.open;
    final dirColor = isLong ? colors.profit : colors.loss;
    final pnl = trade.realizedPnl;
    final isPositivePnl = (pnl ?? 0.0) >= 0.0;
    final pnlColor = isPositivePnl ? colors.profit : colors.loss;

    final numberFormat = NumberFormat('#,##0.00', 'en_US');
    final dateFormat = DateFormat('dd MMM, HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: colors.outline.withValues(alpha: 0.8),
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: () {
            HapticsHelper.light();
            onTap();
          },
          child: Padding(
            padding: AppSpacing.paddingCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Direction Pill, Symbol, Asset Class, Screenshots Badge & P/L Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // Direction pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: dirColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: dirColor.withValues(alpha: 0.5), width: 0.8),
                          ),
                          child: Text(
                            isLong ? l10n.t('longBadge') : l10n.t('shortBadge'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: dirColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          trade.symbol,
                          style: AppTypography.title(colors.textPrimary),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.surfaceElevated,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            trade.assetClass,
                            style: AppTypography.caption(colors.textTertiary),
                          ),
                        ),
                        if (trade.hasScreenshots) ...[
                          const SizedBox(width: AppSpacing.xxs),
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: colors.secondary.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.image_rounded,
                              size: 11,
                              color: colors.secondary,
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Status pill or P&L
                    if (isOpen)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                        child: Text(
                          l10n.t('openStatus'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: colors.primary,
                          ),
                        ),
                      )
                    else if (pnl != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${isPositivePnl ? '+' : ''}$currencySymbol${numberFormat.format(pnl)}',
                            style: AppTypography.body(pnlColor, isBold: true),
                          ),
                          if (trade.realizedReturnPercentage != null)
                            Text(
                              '${isPositivePnl ? '+' : ''}${trade.realizedReturnPercentage!.toStringAsFixed(2)}%',
                              style: AppTypography.caption(pnlColor, isMedium: true),
                            ),
                        ],
                      ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),
                const Divider(),
                const SizedBox(height: AppSpacing.xs),

                // Middle Row: Entry, Target, SL, R:R
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetric(
                      label: l10n.t('entryLabel'),
                      value: '$currencySymbol${numberFormat.format(trade.entryPrice)}',
                      colors: colors,
                    ),
                    if (isOpen && trade.stopLoss != null)
                      _buildMetric(
                        label: l10n.t('stopLossLabel'),
                        value: '$currencySymbol${numberFormat.format(trade.stopLoss!)}',
                        colors: colors,
                        valColor: colors.loss,
                      ),
                    if (isOpen && trade.takeProfit != null)
                      _buildMetric(
                        label: l10n.t('takeProfitLabel'),
                        value: '$currencySymbol${numberFormat.format(trade.takeProfit!)}',
                        colors: colors,
                        valColor: colors.profit,
                      ),
                    if (!isOpen && trade.exitPrice != null)
                      _buildMetric(
                        label: l10n.t('exitLabel'),
                        value: '$currencySymbol${numberFormat.format(trade.exitPrice!)}',
                        colors: colors,
                      ),
                    if (trade.riskRewardRatio != null)
                      _buildMetric(
                        label: l10n.t('rrRatioLabel'),
                        value: '1 : ${trade.riskRewardRatio!.toStringAsFixed(1)}',
                        colors: colors,
                        valColor: colors.secondary,
                      ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xs),

                // Bottom Row: Date and Tags
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateFormat.format(trade.entryDate),
                      style: AppTypography.caption(colors.textTertiary),
                    ),
                    Row(
                      children: [
                        if (trade.strategyTag != null && trade.strategyTag!.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: colors.surfaceElevated,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: colors.outline, width: 0.5),
                            ),
                            child: Text(
                              trade.strategyTag!,
                              style: AppTypography.caption(colors.textSecondary),
                            ),
                          ),
                        if (trade.emotionTag != null && trade.emotionTag!.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: colors.surfaceElevated,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: colors.outline, width: 0.5),
                            ),
                            child: Text(
                              trade.emotionTag!,
                              style: AppTypography.caption(colors.textSecondary),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetric({
    required String label,
    required String value,
    required AppColors colors,
    Color? valColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption(colors.textTertiary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.body(valColor ?? colors.textPrimary, isMedium: true),
        ),
      ],
    );
  }
}
