enum TradeDirection { long, short }

enum TradeStatus { open, closed, cancelled }

class TradeOperation {
  final String id;
  final String symbol;
  final String assetClass;
  final TradeDirection direction;
  final TradeStatus status;
  final double entryPrice;
  final double? exitPrice;
  final double quantity;
  final double multiplier;
  final double fees;
  final double? stopLoss;
  final double? takeProfit;
  final DateTime entryDate;
  final DateTime? exitDate;
  final String? strategyTag;
  final String? emotionTag;
  final String? notes;

  const TradeOperation({
    required this.id,
    required this.symbol,
    required this.assetClass,
    required this.direction,
    this.status = TradeStatus.open,
    required this.entryPrice,
    this.exitPrice,
    required this.quantity,
    this.multiplier = 1.0,
    this.fees = 0.0,
    this.stopLoss,
    this.takeProfit,
    required this.entryDate,
    this.exitDate,
    this.strategyTag,
    this.emotionTag,
    this.notes,
  });

  /// Total capital deployed / position value at entry
  double get investedCapital => entryPrice * quantity * multiplier;

  /// Absolute dollar/currency P&L for a given exit price
  double calculatePnl(double closePrice) {
    final rawProfit = direction == TradeDirection.long
        ? (closePrice - entryPrice) * quantity * multiplier
        : (entryPrice - closePrice) * quantity * multiplier;
    return rawProfit - fees;
  }

  /// Realized P&L if the trade is closed
  double? get realizedPnl {
    if (status != TradeStatus.closed || exitPrice == null) return null;
    return calculatePnl(exitPrice!);
  }

  /// Realized return percentage
  double? get realizedReturnPercentage {
    final pnl = realizedPnl;
    if (pnl == null || investedCapital == 0.0) return null;
    return (pnl / investedCapital) * 100.0;
  }

  /// Risk to Reward Ratio calculated from Stop Loss and Take Profit targets
  double? get riskRewardRatio {
    if (stopLoss == null || takeProfit == null) return null;

    double risk;
    double reward;

    if (direction == TradeDirection.long) {
      risk = entryPrice - stopLoss!;
      reward = takeProfit! - entryPrice;
    } else {
      risk = stopLoss! - entryPrice;
      reward = entryPrice - takeProfit!;
    }

    if (risk <= 0 || reward <= 0) return null;
    return reward / risk;
  }

  /// Dollar risk if stop loss is hit
  double? get potentialRiskAmount {
    if (stopLoss == null) return null;
    final lossPerUnit = direction == TradeDirection.long
        ? (entryPrice - stopLoss!).abs()
        : (stopLoss! - entryPrice).abs();
    return (lossPerUnit * quantity * multiplier) + fees;
  }

  /// Dollar potential profit if take profit is hit
  double? get potentialRewardAmount {
    if (takeProfit == null) return null;
    final gainPerUnit = direction == TradeDirection.long
        ? (takeProfit! - entryPrice).abs()
        : (entryPrice - takeProfit!).abs();
    return (gainPerUnit * quantity * multiplier) - fees;
  }

  bool get isWinner => (realizedPnl ?? 0.0) > 0.0;
  bool get isLoser => (realizedPnl ?? 0.0) < 0.0;
  bool get isBreakEven => (realizedPnl ?? 0.0) == 0.0;

  TradeOperation copyWith({
    String? id,
    String? symbol,
    String? assetClass,
    TradeDirection? direction,
    TradeStatus? status,
    double? entryPrice,
    double? exitPrice,
    double? quantity,
    double? multiplier,
    double? fees,
    double? stopLoss,
    double? takeProfit,
    DateTime? entryDate,
    DateTime? exitDate,
    String? strategyTag,
    String? emotionTag,
    String? notes,
  }) {
    return TradeOperation(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      assetClass: assetClass ?? this.assetClass,
      direction: direction ?? this.direction,
      status: status ?? this.status,
      entryPrice: entryPrice ?? this.entryPrice,
      exitPrice: exitPrice ?? this.exitPrice,
      quantity: quantity ?? this.quantity,
      multiplier: multiplier ?? this.multiplier,
      fees: fees ?? this.fees,
      stopLoss: stopLoss ?? this.stopLoss,
      takeProfit: takeProfit ?? this.takeProfit,
      entryDate: entryDate ?? this.entryDate,
      exitDate: exitDate ?? this.exitDate,
      strategyTag: strategyTag ?? this.strategyTag,
      emotionTag: emotionTag ?? this.emotionTag,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'symbol': symbol.toUpperCase().trim(),
      'asset_class': assetClass,
      'direction': direction == TradeDirection.long ? 'long' : 'short',
      'status': status.name,
      'entry_price': entryPrice,
      'exit_price': exitPrice,
      'quantity': quantity,
      'multiplier': multiplier,
      'fees': fees,
      'stop_loss': stopLoss,
      'take_profit': takeProfit,
      'entry_date': entryDate.toIso8601String(),
      'exit_date': exitDate?.toIso8601String(),
      'strategy_tag': strategyTag,
      'emotion_tag': emotionTag,
      'notes': notes,
    };
  }

  factory TradeOperation.fromMap(Map<String, dynamic> map) {
    return TradeOperation(
      id: map['id'] as String,
      symbol: (map['symbol'] as String).toUpperCase().trim(),
      assetClass: map['asset_class'] as String? ?? 'Crypto',
      direction: (map['direction'] as String? ?? 'long') == 'short'
          ? TradeDirection.short
          : TradeDirection.long,
      status: TradeStatus.values.firstWhere(
        (e) => e.name == (map['status'] as String? ?? 'open'),
        orElse: () => TradeStatus.open,
      ),
      entryPrice: (map['entry_price'] as num).toDouble(),
      exitPrice: (map['exit_price'] as num?)?.toDouble(),
      quantity: (map['quantity'] as num).toDouble(),
      multiplier: (map['multiplier'] as num?)?.toDouble() ?? 1.0,
      fees: (map['fees'] as num?)?.toDouble() ?? 0.0,
      stopLoss: (map['stop_loss'] as num?)?.toDouble(),
      takeProfit: (map['take_profit'] as num?)?.toDouble(),
      entryDate: DateTime.parse(map['entry_date'] as String),
      exitDate: map['exit_date'] != null ? DateTime.parse(map['exit_date'] as String) : null,
      strategyTag: map['strategy_tag'] as String?,
      emotionTag: map['emotion_tag'] as String?,
      notes: map['notes'] as String?,
    );
  }
}
