import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/trade_operation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics_helper.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/trade_provider.dart';
import '../../premium/screens/paywall_sheet.dart';
import '../widgets/trade_card.dart';
import 'trade_detail_screen.dart';
import 'trade_form_screen.dart';

class OperationsListScreen extends StatefulWidget {
  final TradeProvider tradeProvider;
  final SettingsProvider settingsProvider;

  const OperationsListScreen({
    super.key,
    required this.tradeProvider,
    required this.settingsProvider,
  });

  @override
  State<OperationsListScreen> createState() => _OperationsListScreenState();
}

class _OperationsListScreenState extends State<OperationsListScreen> {
  int _selectedTabIndex = 0; // 0: Open, 1: Closed, 2: All

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final tradeProvider = widget.tradeProvider;
    final settings = widget.settingsProvider;
    final isPro = settings.isPro;

    List<TradeOperation> displayedTrades;
    if (_selectedTabIndex == 0) {
      displayedTrades = tradeProvider.openTrades;
    } else if (_selectedTabIndex == 1) {
      displayedTrades = tradeProvider.closedTrades;
    } else {
      displayedTrades = tradeProvider.allFilteredTrades;
    }

    final totalTrades = tradeProvider.totalCount;
    final canAddMore = isPro || totalTrades < AppConstants.maxFreeTrades;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(l10n.t('operationsTitle')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: l10n.t('newTradeTooltip'),
            onPressed: () => _openNewTradeForm(context, canAddMore, l10n),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: Column(
        children: [
          // Free Tier limit banner (if not Pro)
          if (!isPro)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: colors.surfaceElevated,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(
                  color: totalTrades >= AppConstants.maxFreeTrades
                      ? colors.loss.withValues(alpha: 0.5)
                      : colors.outline,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    totalTrades >= AppConstants.maxFreeTrades
                        ? Icons.lock_outline_rounded
                        : Icons.info_outline_rounded,
                    color: totalTrades >= AppConstants.maxFreeTrades
                        ? colors.loss
                        : colors.proGold,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      l10n.t('freePlanBanner', args: {'count': totalTrades, 'max': AppConstants.maxFreeTrades}),
                      style: AppTypography.caption(colors.textSecondary, isMedium: true),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () {
                      PaywallSheet.show(
                        context,
                        settingsProvider: settings,
                        customReason: l10n.t('paywallDefaultSubtitle'),
                      );
                    },
                    child: Text(
                      l10n.t('unlockProAction'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: colors.proGold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            child: TextField(
              onChanged: (val) => tradeProvider.setSearchQuery(val),
              decoration: InputDecoration(
                hintText: l10n.t('searchHint'),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                suffixIcon: tradeProvider.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () => tradeProvider.setSearchQuery(''),
                      )
                    : null,
              ),
            ),
          ),

          // Segmented Tabs: Open / Closed / All
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            child: Row(
              children: [
                Expanded(
                  child: _buildSegmentButton(
                    l10n.t('tabOpen', args: {'count': tradeProvider.openTrades.length}),
                    0,
                    colors,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _buildSegmentButton(
                    l10n.t('tabClosed', args: {'count': tradeProvider.closedTrades.length}),
                    1,
                    colors,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _buildSegmentButton(
                    l10n.t('tabAll', args: {'count': tradeProvider.allFilteredTrades.length}),
                    2,
                    colors,
                  ),
                ),
              ],
            ),
          ),

          // Asset Class Filter Chips
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
              children: [
                _buildAssetChip('All', l10n.t('allMarketsChip'), tradeProvider.selectedAssetClass == null, colors),
                ...AppConstants.assetClasses.map((ac) {
                  return _buildAssetChip(
                    ac,
                    ac,
                    tradeProvider.selectedAssetClass?.toLowerCase() == ac.toLowerCase(),
                    colors,
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Trades Feed
          Expanded(
            child: displayedTrades.isEmpty
                ? _buildEmptyState(colors, canAddMore, l10n)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    itemCount: displayedTrades.length,
                    itemBuilder: (context, index) {
                      final trade = displayedTrades[index];
                      return TradeCard(
                        trade: trade,
                        currencySymbol: settings.currencySymbol,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (ctx) => TradeDetailScreen(
                                trade: trade,
                                currencySymbol: settings.currencySymbol,
                                onUpdate: (updated) => tradeProvider.updateTrade(updated),
                                onCloseTrade: (id, price, date) =>
                                    tradeProvider.closeTrade(id: id, exitPrice: price, exitDate: date),
                                onDelete: (id) => tradeProvider.deleteTrade(id),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        elevation: 4,
        onPressed: () => _openNewTradeForm(context, canAddMore, l10n),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  void _openNewTradeForm(BuildContext context, bool canAddMore, AppLocalizations l10n) {
    if (!canAddMore) {
      PaywallSheet.show(
        context,
        settingsProvider: widget.settingsProvider,
        customReason: l10n.t('paywallLimitNotice'),
      );
      return;
    }

    HapticsHelper.medium();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => TradeFormScreen(
          currencySymbol: widget.settingsProvider.currencySymbol,
          onSave: (trade) => widget.tradeProvider.addTrade(trade),
        ),
      ),
    );
  }

  Widget _buildSegmentButton(String label, int index, AppColors colors) {
    final isSelected = _selectedTabIndex == index;
    return InkWell(
      onTap: () {
        HapticsHelper.selection();
        setState(() => _selectedTabIndex = index);
      },
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
          label,
          style: AppTypography.caption(
            isSelected ? colors.onPrimary : colors.textSecondary,
            isBold: isSelected,
          ),
        ),
      ),
    );
  }

  Widget _buildAssetChip(String key, String label, bool isSelected, AppColors colors) {
    return Container(
      margin: const EdgeInsets.only(right: AppSpacing.xs),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            HapticsHelper.selection();
            widget.tradeProvider.setAssetClassFilter(key);
          }
        },
        selectedColor: colors.secondary.withValues(alpha: 0.2),
        backgroundColor: colors.surface,
        side: BorderSide(
          color: isSelected ? colors.secondary : colors.outline,
          width: isSelected ? 1.2 : 0.8,
        ),
        labelStyle: AppTypography.caption(
          isSelected ? colors.secondary : colors.textSecondary,
          isBold: isSelected,
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppColors colors, bool canAddMore, AppLocalizations l10n) {
    return Center(
      child: SingleChildScrollView(
        padding: AppSpacing.paddingDialog,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.surfaceElevated,
                border: Border.all(color: colors.outline),
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: colors.textTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.t('emptyOperationsTitle'),
              style: AppTypography.title(colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.t('emptyOperationsSubtitle'),
              textAlign: TextAlign.center,
              style: AppTypography.body(colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () => _openNewTradeForm(context, canAddMore, l10n),
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.t('addTradeButton')),
            ),
          ],
        ),
      ),
    );
  }
}
