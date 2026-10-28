import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/trade_operation.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/haptics_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/trade_provider.dart';
import '../../operations/screens/trade_detail_screen.dart';

class PnlCalendarWidget extends StatefulWidget {
  final TradeProvider tradeProvider;
  final String currencySymbol;

  const PnlCalendarWidget({
    super.key,
    required this.tradeProvider,
    required this.currencySymbol,
  });

  @override
  State<PnlCalendarWidget> createState() => _PnlCalendarWidgetState();
}

class _PnlCalendarWidgetState extends State<PnlCalendarWidget> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
  }

  void _prevMonth() {
    HapticsHelper.selection();
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    HapticsHelper.selection();
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    });
  }

  void _showDayTradesSheet(DateTime day, List<TradeOperation> dayTrades, double netPnl) {
    HapticsHelper.light();
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final dateStr = DateFormat('EEEE, dd MMMM yyyy').format(day);
    final numFormat = NumberFormat('#,##0.00', 'en_US');
    final isPos = netPnl >= 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dateStr, style: AppTypography.title(colors.textPrimary)),
                      Text(
                        l10n.t('dayTradesDetailTitle'),
                        style: AppTypography.caption(colors.textSecondary),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isPos ? colors.profit : colors.loss).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      border: Border.all(color: (isPos ? colors.profit : colors.loss).withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      '${isPos ? '+' : ''}${widget.currencySymbol}${numFormat.format(netPnl)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isPos ? colors.profit : colors.loss,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.45,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: dayTrades.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
                  itemBuilder: (ctx, idx) {
                    final t = dayTrades[idx];
                    final tPnl = t.realizedPnl ?? 0.0;
                    final isTPos = tPnl >= 0;
                    return InkWell(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TradeDetailScreen(
                              trade: t,
                              currencySymbol: widget.currencySymbol,
                              onUpdate: widget.tradeProvider.updateTrade,
                              onCloseTrade: (id, price, date) =>
                                  widget.tradeProvider.closeTrade(id: id, exitPrice: price, exitDate: date),
                              onDelete: widget.tradeProvider.deleteTrade,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: colors.surfaceElevated,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          border: Border.all(color: colors.outline.withValues(alpha: 0.6)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (t.direction == TradeDirection.long ? colors.profit : colors.loss)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    t.direction == TradeDirection.long ? 'LONG' : 'SHORT',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: t.direction == TradeDirection.long ? colors.profit : colors.loss,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(t.symbol, style: AppTypography.body(colors.textPrimary, isBold: true)),
                                if (t.hasScreenshots) ...[
                                  const SizedBox(width: AppSpacing.xxs),
                                  Icon(Icons.image_rounded, size: 12, color: colors.secondary),
                                ],
                              ],
                            ),
                            Text(
                              '${isTPos ? '+' : ''}${widget.currencySymbol}${numFormat.format(tPnl)}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isTPos ? colors.profit : colors.loss,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final monthHeader = DateFormat('MMMM yyyy').format(_selectedMonth);
    final numFormat = NumberFormat('#,##0.00', 'en_US');

    // 1. Group closed trades by calendar day for selected month
    final Map<int, List<TradeOperation>> monthTradesMap = {};
    double totalMonthNet = 0.0;
    int greenDays = 0;
    int redDays = 0;

    for (final t in widget.tradeProvider.closedTrades) {
      final date = t.exitDate ?? t.entryDate;
      if (date.year == _selectedMonth.year && date.month == _selectedMonth.month) {
        monthTradesMap.putIfAbsent(date.day, () => []).add(t);
      }
    }

    monthTradesMap.forEach((day, trades) {
      double dayPnl = 0.0;
      for (final t in trades) {
        dayPnl += t.realizedPnl ?? 0.0;
      }
      totalMonthNet += dayPnl;
      if (dayPnl > 0) greenDays++;
      if (dayPnl < 0) redDays++;
    });

    final isMonthPos = totalMonthNet >= 0;
    final daysInMonth = DateUtils.getDaysInMonth(_selectedMonth.year, _selectedMonth.month);
    // Weekday of 1st day (1=Mon, 7=Sun in ISO)
    final firstWeekday = DateTime(_selectedMonth.year, _selectedMonth.month, 1).weekday;
    final leadingBlanks = firstWeekday - 1; // 0 for Monday

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
          // Header: Title & Month Nav
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_month_rounded, size: 18, color: colors.secondary),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    l10n.t('pnlCalendarTitle'),
                    style: AppTypography.title(colors.textPrimary),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: colors.textSecondary,
                    onPressed: _prevMonth,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    monthHeader,
                    style: AppTypography.body(colors.textPrimary, isBold: true),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: colors.textSecondary,
                    onPressed: _nextMonth,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Monthly Metrics Summary Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(color: colors.outline.withValues(alpha: 0.6)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.t('calendarMonthlyNet'), style: AppTypography.caption(colors.textTertiary)),
                    Text(
                      '${isMonthPos ? '+' : ''}${widget.currencySymbol}${numFormat.format(totalMonthNet)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isMonthPos ? colors.profit : colors.loss,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.profit.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '🟢 $greenDays',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.profit),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.loss.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '🔴 $redDays',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.loss),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Weekday Labels (Mon - Sun)
          Row(
            children: ['L', 'M', 'M', 'J', 'V', 'S', 'D'].map((dayLabel) {
              return Expanded(
                child: Center(
                  child: Text(
                    dayLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colors.textTertiary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.xs),

          // 7-Column Grid of Month Days
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: leadingBlanks + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (ctx, index) {
              if (index < leadingBlanks) {
                return const SizedBox.shrink();
              }

              final dayNum = index - leadingBlanks + 1;
              final tradesForDay = monthTradesMap[dayNum];
              final hasTrades = tradesForDay != null && tradesForDay.isNotEmpty;

              double dayPnl = 0.0;
              if (hasTrades) {
                for (final t in tradesForDay) {
                  dayPnl += t.realizedPnl ?? 0.0;
                }
              }

              final isGreen = hasTrades && dayPnl > 0;
              final isRed = hasTrades && dayPnl < 0;

              final now = DateTime.now();
              final isToday = now.year == _selectedMonth.year &&
                  now.month == _selectedMonth.month &&
                  now.day == dayNum;

              Color cellBg = colors.background;
              Color borderColor = colors.outline.withValues(alpha: 0.5);

              if (isGreen) {
                cellBg = colors.profit.withValues(alpha: 0.18);
                borderColor = colors.profit.withValues(alpha: 0.6);
              } else if (isRed) {
                cellBg = colors.loss.withValues(alpha: 0.18);
                borderColor = colors.loss.withValues(alpha: 0.6);
              } else if (isToday) {
                borderColor = colors.secondary;
              }

              return InkWell(
                onTap: hasTrades
                    ? () => _showDayTradesSheet(
                          DateTime(_selectedMonth.year, _selectedMonth.month, dayNum),
                          tradesForDay,
                          dayPnl,
                        )
                    : null,
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  decoration: BoxDecoration(
                    color: cellBg,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: borderColor, width: hasTrades || isToday ? 1.0 : 0.6),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNum',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isToday || hasTrades ? FontWeight.bold : FontWeight.normal,
                          color: isToday
                              ? colors.secondary
                              : (hasTrades ? colors.textPrimary : colors.textTertiary),
                        ),
                      ),
                      if (hasTrades) ...[
                        Text(
                          '${isGreen ? '+' : ''}${dayPnl.abs() >= 1000 ? '${(dayPnl / 1000).toStringAsFixed(1)}k' : dayPnl.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: isGreen ? colors.profit : colors.loss,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
