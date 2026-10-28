import 'package:flutter/foundation.dart';
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
import '../../dashboard/widgets/kpi_card.dart';
import '../../dashboard/widgets/mini_equity_chart.dart';
import '../../premium/screens/paywall_sheet.dart';
import '../widgets/pnl_calendar_widget.dart';

class AnalyticsScreen extends StatelessWidget {
  final TradeProvider tradeProvider;
  final SettingsProvider settingsProvider;

  const AnalyticsScreen({
    super.key,
    required this.tradeProvider,
    required this.settingsProvider,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final isPro = settingsProvider.isPro;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(l10n.t('analyticsTitle')),
        actions: [
          if (isPro)
            Container(
              margin: const EdgeInsets.only(right: AppSpacing.md),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colors.proGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                border: Border.all(color: colors.proGold.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.stars_rounded, color: colors.proGold, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    l10n.t('proActiveBadge'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: colors.proGold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: isPro
          ? _buildProAnalytics(context, colors, l10n)
          : _buildLockedFreemiumView(context, colors, l10n),
    );
  }

  Widget _buildLockedFreemiumView(BuildContext context, AppColors colors, AppLocalizations l10n) {
    return Center(
      child: SingleChildScrollView(
        padding: AppSpacing.paddingDialog,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.proGold.withValues(alpha: 0.12),
                border: Border.all(color: colors.proGold.withValues(alpha: 0.5), width: 1.5),
              ),
              child: Icon(
                Icons.analytics_rounded,
                size: 40,
                color: colors.proGold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.t('analyticsProTitle'),
              style: AppTypography.display(colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.t('analyticsProSubtitle'),
              textAlign: TextAlign.center,
              style: AppTypography.body(colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.proGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
              ),
              onPressed: () {
                HapticsHelper.medium();
                PaywallSheet.show(
                  context,
                  settingsProvider: settingsProvider,
                  customReason: l10n.t('analyticsProSubtitle'),
                );
              },
              child: Text(
                l10n.t('upgradeToProAction'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Quick developer test toggle helper button (Strictly debug mode only)
            if (kDebugMode) ...[
              const SizedBox(height: AppSpacing.sm),
              TextButton.icon(
                onPressed: () async {
                  HapticsHelper.medium();
                  await settingsProvider.toggleTestPro(true);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.t('activatingTestProToast'))),
                    );
                  }
                },
                icon: Icon(Icons.science_rounded, size: 16, color: colors.secondary),
                label: Text(
                  l10n.t('testProShortcut'),
                  style: AppTypography.caption(colors.secondary, isBold: true),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProAnalytics(BuildContext context, AppColors colors, AppLocalizations l10n) {
    final currency = settingsProvider.currencySymbol;
    final numFormat = NumberFormat('#,##0.00', 'en_US');

    final winRate = tradeProvider.winRate;
    final profitFactor = tradeProvider.profitFactor;
    final expectancy = tradeProvider.expectancy;
    final avgWin = tradeProvider.averageWin;
    final avgLoss = tradeProvider.averageLoss;
    final bestPnl = tradeProvider.bestTradePnl;
    final worstPnl = tradeProvider.worstTradePnl;
    final strategies = tradeProvider.getStrategyBreakdown();

    final equitySpots = tradeProvider.getEquitySpots(
      baseCapital: settingsProvider.accountBalance,
    );
    final netPnl = tradeProvider.totalRealizedPnl;

    return ListView(
      padding: AppSpacing.paddingScreen,
      children: [
        // Equity Curve Chart
        MiniEquityChart(
          spots: equitySpots,
          isPositive: netPnl >= 0,
          title: l10n.t('equityCurveTitle'),
          currentVal: '${netPnl >= 0 ? '+' : ''}$currency${numFormat.format(netPnl)}',
        ),
        const SizedBox(height: AppSpacing.md),

        // P&L Calendar Heatmap
        PnlCalendarWidget(
          tradeProvider: tradeProvider,
          currencySymbol: currency,
        ),
        const SizedBox(height: AppSpacing.md),

        // Key KPI Bento Grid
        Row(
          children: [
            Expanded(
              child: KpiCard(
                title: l10n.t('winRateTitle'),
                value: '${winRate.toStringAsFixed(1)}%',
                subtitle: '${tradeProvider.winningTradesCount}W • ${tradeProvider.losingTradesCount}L',
                icon: Icons.pie_chart_rounded,
                valueColor: winRate >= 50.0 ? colors.profit : colors.loss,
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
                valueColor: profitFactor >= 1.5 ? colors.profit : (profitFactor >= 1.0 ? colors.warning : colors.loss),
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
                title: l10n.t('avgWinTitle'),
                value: '+$currency${numFormat.format(avgWin)}',
                subtitle: l10n.t('avgWinSubtitle'),
                icon: Icons.arrow_upward_rounded,
                valueColor: colors.profit,
                accentColor: colors.profit,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: KpiCard(
                title: l10n.t('avgLossTitle'),
                value: '-$currency${numFormat.format(avgLoss)}',
                subtitle: l10n.t('avgLossSubtitle'),
                icon: Icons.arrow_downward_rounded,
                valueColor: colors.loss,
                accentColor: colors.loss,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        Row(
          children: [
            Expanded(
              child: KpiCard(
                title: l10n.t('expectancyTitle'),
                value: '${expectancy >= 0 ? '+' : ''}$currency${numFormat.format(expectancy)}',
                subtitle: l10n.t('expectancySubtitle'),
                icon: Icons.functions_rounded,
                valueColor: expectancy >= 0 ? colors.profit : colors.loss,
                accentColor: colors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: KpiCard(
                title: l10n.t('bestTradeTitle'),
                value: bestPnl != null ? '+$currency${numFormat.format(bestPnl)}' : '-',
                subtitle: worstPnl != null ? l10n.t('worstTradeSubtitle', args: {'amount': '$currency${numFormat.format(worstPnl)}'}) : '',
                icon: Icons.emoji_events_rounded,
                valueColor: colors.proGold,
                accentColor: colors.proGold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Performance by Strategy Section
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
                l10n.t('strategyPerformanceTitle'),
                style: AppTypography.caption(colors.textSecondary, isMedium: true),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (strategies.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Center(
                    child: Text(
                      l10n.t('noStrategyDataSubtitle'),
                      style: AppTypography.caption(colors.textTertiary),
                    ),
                  ),
                )
              else
                ...strategies.entries.map((entry) {
                  final tag = entry.key;
                  final total = entry.value['total'] as int;
                  final wins = entry.value['wins'] as int;
                  final pnl = entry.value['pnl'] as double;
                  final wr = total > 0 ? (wins / total) * 100.0 : 0.0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(tag, style: AppTypography.body(colors.textPrimary, isBold: true)),
                            Text(
                              '${pnl >= 0 ? '+' : ''}$currency${numFormat.format(pnl)}',
                              style: AppTypography.body(
                                pnl >= 0 ? colors.profit : colors.loss,
                                isMedium: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.t('winRateAbbr', args: {'wins': wins, 'total': total, 'wr': wr.toStringAsFixed(0)}),
                              style: AppTypography.caption(colors.textTertiary),
                            ),
                            // Micro progress bar
                            SizedBox(
                              width: 80,
                              child: LinearProgressIndicator(
                                value: total > 0 ? wins / total : 0,
                                backgroundColor: colors.surfaceElevated,
                                color: wr >= 50 ? colors.profit : colors.loss,
                                minHeight: 4,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Divider(),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}
