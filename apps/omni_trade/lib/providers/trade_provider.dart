import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import '../core/database/trade_database.dart';
import '../core/models/trade_operation.dart';

class TradeProvider extends ChangeNotifier {
  final TradeDatabase _database = TradeDatabase.instance;

  List<TradeOperation> _trades = [];
  bool _isLoading = false;
  String? _selectedAssetClass;
  String _searchQuery = '';

  List<TradeOperation> get trades => _trades;
  bool get isLoading => _isLoading;
  String? get selectedAssetClass => _selectedAssetClass;
  String get searchQuery => _searchQuery;

  int get totalCount => _trades.length;

  List<TradeOperation> get openTrades {
    return _applyFilters(_trades.where((t) => t.status == TradeStatus.open).toList());
  }

  List<TradeOperation> get closedTrades {
    return _applyFilters(_trades.where((t) => t.status == TradeStatus.closed).toList());
  }

  List<TradeOperation> get allFilteredTrades {
    return _applyFilters(_trades);
  }

  List<TradeOperation> _applyFilters(List<TradeOperation> inputList) {
    return inputList.where((trade) {
      if (_selectedAssetClass != null && _selectedAssetClass != 'All') {
        if (trade.assetClass.toLowerCase() != _selectedAssetClass!.toLowerCase()) {
          return false;
        }
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchSymbol = trade.symbol.toLowerCase().contains(q);
        final matchStrategy = trade.strategyTag?.toLowerCase().contains(q) ?? false;
        final matchNotes = trade.notes?.toLowerCase().contains(q) ?? false;
        if (!matchSymbol && !matchStrategy && !matchNotes) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void setAssetClassFilter(String? assetClass) {
    _selectedAssetClass = (assetClass == 'All' || assetClass == null) ? null : assetClass;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    notifyListeners();
  }

  Future<void> loadTrades() async {
    _isLoading = true;
    notifyListeners();

    try {
      _trades = await _database.getAllTrades();
    } catch (e) {
      debugPrint('Error loading trades: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTrade(TradeOperation trade) async {
    await _database.insertTrade(trade);
    _trades.insert(0, trade);
    notifyListeners();
  }

  Future<void> updateTrade(TradeOperation trade) async {
    await _database.updateTrade(trade);
    final index = _trades.indexWhere((t) => t.id == trade.id);
    if (index != -1) {
      _trades[index] = trade;
      notifyListeners();
    }
  }

  Future<void> closeTrade({
    required String id,
    required double exitPrice,
    required DateTime exitDate,
  }) async {
    final index = _trades.indexWhere((t) => t.id == id);
    if (index != -1) {
      final updated = _trades[index].copyWith(
        status: TradeStatus.closed,
        exitPrice: exitPrice,
        exitDate: exitDate,
      );
      await _database.updateTrade(updated);
      _trades[index] = updated;
      notifyListeners();
    }
  }

  Future<void> deleteTrade(String id) async {
    await _database.deleteTrade(id);
    _trades.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  Future<void> clearAll() async {
    await _database.clearAll();
    _trades.clear();
    notifyListeners();
  }

  // --- KPI & PERFORMANCE CALCULATIONS ---

  double get totalRealizedPnl {
    return _trades
        .where((t) => t.status == TradeStatus.closed && t.realizedPnl != null)
        .fold(0.0, (acc, t) => acc + t.realizedPnl!);
  }

  int get winningTradesCount {
    return _trades
        .where((t) => t.status == TradeStatus.closed && t.isWinner)
        .length;
  }

  int get losingTradesCount {
    return _trades
        .where((t) => t.status == TradeStatus.closed && t.isLoser)
        .length;
  }

  int get breakEvenTradesCount {
    return _trades
        .where((t) => t.status == TradeStatus.closed && t.isBreakEven)
        .length;
  }

  double get winRate {
    final closed = _trades.where((t) => t.status == TradeStatus.closed).toList();
    if (closed.isEmpty) return 0.0;
    return (winningTradesCount / closed.length) * 100.0;
  }

  double get totalGrossProfit {
    return _trades
        .where((t) => t.status == TradeStatus.closed && t.isWinner)
        .fold(0.0, (acc, t) => acc + (t.realizedPnl ?? 0.0));
  }

  double get totalGrossLoss {
    return _trades
        .where((t) => t.status == TradeStatus.closed && t.isLoser)
        .fold(0.0, (acc, t) => acc + (t.realizedPnl ?? 0.0).abs());
  }

  double get profitFactor {
    if (totalGrossLoss == 0.0) {
      return totalGrossProfit > 0.0 ? 9.99 : 0.0;
    }
    return totalGrossProfit / totalGrossLoss;
  }

  double get averageWin {
    if (winningTradesCount == 0) return 0.0;
    return totalGrossProfit / winningTradesCount;
  }

  double get averageLoss {
    if (losingTradesCount == 0) return 0.0;
    return totalGrossLoss / losingTradesCount;
  }

  double get expectancy {
    final totalClosed = winningTradesCount + losingTradesCount + breakEvenTradesCount;
    if (totalClosed == 0) return 0.0;
    final winProb = winningTradesCount / totalClosed;
    final lossProb = losingTradesCount / totalClosed;
    return (winProb * averageWin) - (lossProb * averageLoss);
  }

  double? get bestTradePnl {
    final closed = _trades.where((t) => t.status == TradeStatus.closed && t.realizedPnl != null).toList();
    if (closed.isEmpty) return null;
    return closed.map((t) => t.realizedPnl!).reduce((a, b) => a > b ? a : b);
  }

  double? get worstTradePnl {
    final closed = _trades.where((t) => t.status == TradeStatus.closed && t.realizedPnl != null).toList();
    if (closed.isEmpty) return null;
    return closed.map((t) => t.realizedPnl!).reduce((a, b) => a < b ? a : b);
  }

  /// Chronological equity curve data points for fl_chart
  List<FlSpot> getEquitySpots({double baseCapital = 0.0}) {
    final closed = _trades
        .where((t) => t.status == TradeStatus.closed && t.realizedPnl != null && t.exitDate != null)
        .toList()
      ..sort((a, b) => a.exitDate!.compareTo(b.exitDate!));

    if (closed.isEmpty) {
      return [
        FlSpot(0, baseCapital),
        FlSpot(1, baseCapital),
      ];
    }

    final spots = <FlSpot>[FlSpot(0, baseCapital)];
    double running = baseCapital;

    for (int i = 0; i < closed.length; i++) {
      running += closed[i].realizedPnl!;
      spots.add(FlSpot((i + 1).toDouble(), running));
    }

    return spots;
  }

  /// Breakdown of win rate by strategy tag
  Map<String, Map<String, dynamic>> getStrategyBreakdown() {
    final Map<String, Map<String, dynamic>> map = {};
    final closed = _trades.where((t) => t.status == TradeStatus.closed).toList();

    for (final trade in closed) {
      final tag = (trade.strategyTag == null || trade.strategyTag!.isEmpty)
          ? 'General'
          : trade.strategyTag!;

      if (!map.containsKey(tag)) {
        map[tag] = {'total': 0, 'wins': 0, 'pnl': 0.0};
      }

      map[tag]!['total'] = (map[tag]!['total'] as int) + 1;
      if (trade.isWinner) {
        map[tag]!['wins'] = (map[tag]!['wins'] as int) + 1;
      }
      map[tag]!['pnl'] = (map[tag]!['pnl'] as double) + (trade.realizedPnl ?? 0.0);
    }

    return map;
  }
}
