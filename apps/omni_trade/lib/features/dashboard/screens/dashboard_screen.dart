import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics_helper.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/trade_provider.dart';
import '../../operations/screens/trade_detail_screen.dart';
import '../../operations/screens/trade_form_screen.dart';
import '../../operations/widgets/trade_card.dart';
import '../../premium/screens/paywall_sheet.dart';
import '../widgets/kpi_card.dart';
import '../widgets/mini_equity_chart.dart';

class DashboardScreen extends StatelessWidget {
  final TradeProvider tradeProvider;
  final SettingsProvider settingsProvider;
  final VoidCallback onNavigateToOperations;

  const DashboardScreen({
    super.key,
    required this.tradeProvider,
    required this.settingsProvider,
    required this.onNavigateToOperations,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final currency = settingsProvider.currencySymbol;
    final numFormat = NumberFormat('#,##0.00', 'en_US');

    final netPnl = tradeProvider.totalRealizedPnl;
    final isPosPnl = netPnl >= 0;
    final pnlColor = isPosPnl ? colors.profit : colors.loss;
    final accountBalance = settingsProvider.accountBalance;
    final currentPortfolioVal = accountBalance + netPnl;
    final returnPercent = accountBalance > 0 ? (netPnl / accountBalance) * 100.0 : 0.0;

    final winRate = tradeProvider.winRate;
    final profitFactor = tradeProvider.profitFactor;
    final openCount = tradeProvider.openTrades.length;
    final closedCount = tradeProvider.closedTrades.length;

    final equitySpots = tradeProvider.getEquitySpots(baseCapital: accountBalance);
    final recentTrades = tradeProvider.trades.take(4).toList();

    final canAddMore = settingsProvider.isPro || tradeProvider.totalCount < AppConstants.maxFreeTrades;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors.centerFabGradient),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.show_chart_rounded, size: 18, color: Colors.white),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(l10n.t('appTitle')),
          ],
        ),
        actions: [
          if (settingsProvider.isPro)
            Container(
              margin: const EdgeInsets.only(right: AppSpacing.md),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: colors.proGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                border: Border.all(color: colors.proGold.withValues(alpha: 0.5)),
              ),
              child: Text(
                'PRO',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: colors.proGold,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: InkWell(
                onTap: () {
                  HapticsHelper.light();
                  PaywallSheet.show(
                    context,
                    settingsProvider: settingsProvider,
                    customReason: l10n.t('proBannerSubtitle'),
                  );
                },
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colors.proGold, const Color(0xFFE5A93C)],
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    boxShadow: [
                      BoxShadow(
                        color: colors.proGold.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stars_rounded, size: 14, color: Colors.black),
                      const SizedBox(width: 4),
                      Text(
                        'PRO',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: AppSpacing.paddingScreen,
        children: [
          // Bento Portfolio Overview Header with Ambient P&L Glow
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: AppSpacing.paddingCard,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors.cardGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: pnlColor.withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: pnlColor.withValues(alpha: 0.12),
                  blurRadius: 16,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.t('portfolioSummaryTitle'),
                      style: AppTypography.caption(colors.textSecondary, isMedium: true),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: pnlColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        border: Border.all(color: pnlColor.withValues(alpha: 0.4), width: 0.8),
                      ),
                      child: Text(
                        l10n.t('roiBadge', args: {'roi': '${isPosPnl ? '+' : ''}${returnPercent.toStringAsFixed(2)}'}),
                        style: AppTypography.caption(pnlColor, isBold: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '$currency${numFormat.format(currentPortfolioVal)}',
                  style: AppTypography.display(colors.textPrimary),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      l10n.t('realizedPnlLabel'),
                      style: AppTypography.caption(colors.textTertiary),
                    ),
                    Text(
                      '${isPosPnl ? '+' : ''}$currency${numFormat.format(netPnl)}',
                      style: AppTypography.caption(pnlColor, isBold: true),
                    ),
                    Text(
                      l10n.t('baseCapitalLabel', args: {'amount': '$currency${numFormat.format(accountBalance)}'}),
                      style: AppTypography.caption(colors.textTertiary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Mini Equity Curve Chart
          MiniEquityChart(
            spots: equitySpots,
            isPositive: isPosPnl,
            title: l10n.t('equityCurveTitle'),
            currentVal: '${isPosPnl ? '+' : ''}$currency${numFormat.format(netPnl)}',
          ),
          if (!settingsProvider.isPro) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: AppSpacing.paddingCard,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: colors.proGold.withValues(alpha: 0.45),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.proGold.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.proGold.withValues(alpha: 0.15),
                      border: Border.all(color: colors.proGold.withValues(alpha: 0.5)),
                    ),
                    child: Icon(Icons.workspace_premium_rounded, color: colors.proGold, size: 24),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.t('proBannerTitle'),
                          style: AppTypography.body(colors.textPrimary, isBold: true),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tradeProvider.totalCount >= 10
                              ? l10n.t('proTradesLimitWarning', args: {'count': AppConstants.maxFreeTrades - tradeProvider.totalCount})
                              : l10n.t('proBannerSubtitle'),
                          style: AppTypography.caption(
                            tradeProvider.totalCount >= 10 ? colors.loss : colors.textSecondary,
                            isMedium: tradeProvider.totalCount >= 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.proGold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                    ),
                    onPressed: () {
                      HapticsHelper.medium();
                      PaywallSheet.show(
                        context,
                        settingsProvider: settingsProvider,
                        customReason: l10n.t('proBannerSubtitle'),
                      );
                    },
                    child: Text(
                      l10n.t('proBannerCta'),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),

          // Bento KPI Grid (2x2)
          Row(
            children: [
              Expanded(
                child: KpiCard(
                  title: l10n.t('winRateTitle'),
                  value: '${winRate.toStringAsFixed(1)}%',
                  subtitle: l10n.t('closedTradesSubtitle', args: {'count': closedCount}),
                  icon: Icons.pie_chart_rounded,
                  valueColor: winRate >= 50 ? colors.profit : colors.loss,
                  accentColor: colors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: KpiCard(
                  title: l10n.t('profitFactorTitle'),
                  value: profitFactor.toStringAsFixed(2),
                  subtitle: l10n.t('profitFactorSubtitle'),
                  icon: Icons.trending_up_rounded,
                  valueColor: profitFactor >= 1.5 ? colors.profit : colors.textPrimary,
                  accentColor: colors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          Row(
            children: [
              Expanded(
                child: KpiCard(
                  title: l10n.t('activePositionsTitle'),
                  value: '$openCount',
                  subtitle: l10n.t('activePositionsSubtitle'),
                  icon: Icons.timelapse_rounded,
                  valueColor: colors.secondary,
                  accentColor: colors.secondary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: KpiCard(
                  title: l10n.t('totalTradesTitle'),
                  value: '${tradeProvider.totalCount}',
                  subtitle: settingsProvider.isPro
                      ? l10n.t('unlimitedProBadge')
                      : l10n.t('remainingBadge', args: {'count': AppConstants.maxFreeTrades - tradeProvider.totalCount}),
                  icon: Icons.receipt_long_rounded,
                  accentColor: colors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Recent Trades Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.t('recentOperationsTitle'),
                style: AppTypography.caption(colors.textSecondary, isMedium: true),
              ),
              TextButton(
                onPressed: () {
                  HapticsHelper.selection();
                  onNavigateToOperations();
                },
                child: Text(
                  l10n.t('seeAllAction'),
                  style: AppTypography.caption(colors.primary, isBold: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          if (recentTrades.isEmpty)
            Container(
              padding: AppSpacing.paddingCard,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: colors.outline),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_outlined, color: colors.textTertiary, size: 32),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.t('noTradesTitle'),
                      style: AppTypography.body(colors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextButton.icon(
                      onPressed: () => _openAddTrade(context, canAddMore, l10n),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(l10n.t('logFirstTradeAction')),
                    ),
                  ],
                ),
              ),
            )
          else
            ...recentTrades.map((t) {
              return TradeCard(
                trade: t,
                currencySymbol: currency,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => TradeDetailScreen(
                        trade: t,
                        currencySymbol: currency,
                        onUpdate: (up) => tradeProvider.updateTrade(up),
                        onCloseTrade: (id, price, date) =>
                            tradeProvider.closeTrade(id: id, exitPrice: price, exitDate: date),
                        onDelete: (id) => tradeProvider.deleteTrade(id),
                      ),
                    ),
                  );
                },
              );
            }),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  void _openAddTrade(BuildContext context, bool canAddMore, AppLocalizations l10n) {
    if (!canAddMore) {
      PaywallSheet.show(
        context,
        settingsProvider: settingsProvider,
        customReason: l10n.t('paywallLimitNotice'),
      );
      return;
    }

    HapticsHelper.medium();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => TradeFormScreen(
          currencySymbol: settingsProvider.currencySymbol,
          onSave: (trade) => tradeProvider.addTrade(trade),
        ),
      ),
    );
  }
}
