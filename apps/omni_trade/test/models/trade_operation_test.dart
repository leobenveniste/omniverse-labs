import 'package:flutter_test/flutter_test.dart';
import 'package:omni_trade/core/models/trade_operation.dart';

void main() {
  group('TradeOperation Calculation Tests', () {
    test('Long trade profit and return calculation', () {
      final trade = TradeOperation(
        id: '1',
        symbol: 'BTC/USDT',
        assetClass: 'Crypto',
        direction: TradeDirection.long,
        status: TradeStatus.closed,
        entryPrice: 50000.0,
        exitPrice: 55000.0,
        quantity: 0.5,
        multiplier: 1.0,
        fees: 10.0,
        entryDate: DateTime(2026, 1, 1),
        exitDate: DateTime(2026, 1, 2),
      );

      // Invested Capital: 50,000 * 0.5 = 25,000
      expect(trade.investedCapital, equals(25000.0));

      // Raw gain: (55,000 - 50,000) * 0.5 = 2,500. Less fees (10) = 2,490
      expect(trade.realizedPnl, equals(2490.0));
      expect(trade.isWinner, isTrue);
      expect(trade.isLoser, isFalse);

      // Return %: (2490 / 25000) * 100 = 9.96%
      expect(trade.realizedReturnPercentage, closeTo(9.96, 0.01));
    });

    test('Short trade profit and return calculation', () {
      final trade = TradeOperation(
        id: '2',
        symbol: 'ETH/USDT',
        assetClass: 'Crypto',
        direction: TradeDirection.short,
        status: TradeStatus.closed,
        entryPrice: 3000.0,
        exitPrice: 2700.0,
        quantity: 2.0,
        multiplier: 1.0,
        fees: 5.0,
        entryDate: DateTime(2026, 1, 1),
        exitDate: DateTime(2026, 1, 2),
      );

      // Short gain: (3000 - 2700) * 2.0 = 600 - 5 = 595
      expect(trade.realizedPnl, equals(595.0));
      expect(trade.isWinner, isTrue);
    });

    test('Short trade loss calculation', () {
      final trade = TradeOperation(
        id: '3',
        symbol: 'TSLA',
        assetClass: 'Stocks',
        direction: TradeDirection.short,
        status: TradeStatus.closed,
        entryPrice: 200.0,
        exitPrice: 220.0,
        quantity: 10.0,
        multiplier: 1.0,
        fees: 2.0,
        entryDate: DateTime(2026, 1, 1),
        exitDate: DateTime(2026, 1, 2),
      );

      // Short loss: (200 - 220) * 10 = -200 - 2 = -202
      expect(trade.realizedPnl, equals(-202.0));
      expect(trade.isWinner, isFalse);
      expect(trade.isLoser, isTrue);
    });

    test('Risk to Reward Ratio (R:R) computation', () {
      final longTrade = TradeOperation(
        id: '4',
        symbol: 'NVDA',
        assetClass: 'Stocks',
        direction: TradeDirection.long,
        entryPrice: 100.0,
        stopLoss: 95.0,     // Risk = 5
        takeProfit: 115.0,  // Reward = 15
        quantity: 10.0,
        entryDate: DateTime(2026, 1, 1),
      );

      // R:R should be 15 / 5 = 3.0
      expect(longTrade.riskRewardRatio, equals(3.0));

      final shortTrade = TradeOperation(
        id: '5',
        symbol: 'EURUSD',
        assetClass: 'Forex',
        direction: TradeDirection.short,
        entryPrice: 1.1000,
        stopLoss: 1.1050,    // Risk = 0.0050
        takeProfit: 1.0850,  // Reward = 0.0150
        quantity: 1000.0,
        entryDate: DateTime(2026, 1, 1),
      );

      // R:R should be 0.0150 / 0.0050 = 3.0
      expect(shortTrade.riskRewardRatio, closeTo(3.0, 0.001));
    });

    test('SQLite serialization toMap and fromMap', () {
      final original = TradeOperation(
        id: 'uuid-123',
        symbol: 'AAPL',
        assetClass: 'Stocks',
        direction: TradeDirection.long,
        status: TradeStatus.open,
        entryPrice: 150.0,
        quantity: 20.0,
        multiplier: 1.0,
        fees: 1.5,
        stopLoss: 145.0,
        takeProfit: 165.0,
        entryDate: DateTime(2026, 1, 1, 12, 0),
        strategyTag: 'Breakout',
        emotionTag: 'Disciplined',
        notes: 'Clean daily candle breakout',
      );

      final map = original.toMap();
      final restored = TradeOperation.fromMap(map);

      expect(restored.id, equals(original.id));
      expect(restored.symbol, equals('AAPL'));
      expect(restored.direction, equals(TradeDirection.long));
      expect(restored.entryPrice, equals(150.0));
      expect(restored.stopLoss, equals(145.0));
      expect(restored.takeProfit, equals(165.0));
      expect(restored.strategyTag, equals('Breakout'));
      expect(restored.emotionTag, equals('Disciplined'));
    });
  });
}
