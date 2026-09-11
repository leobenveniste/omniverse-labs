import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Position Sizing Risk Calculator Tests', () {
    test('Calculates units based on percentage risk and stop loss', () {
      const accountBalance = 10000.0;
      const riskPercentage = 1.0; // 1% = $100
      const entryPrice = 250.0;
      const stopLoss = 240.0;

      final dollarRisk = accountBalance * (riskPercentage / 100.0);
      expect(dollarRisk, equals(100.0));

      final priceDiff = (entryPrice - stopLoss).abs();
      expect(priceDiff, equals(10.0));

      // Units = 100 / 10 = 10 shares
      final units = dollarRisk / priceDiff;
      expect(units, equals(10.0));

      final totalCapitalRequired = units * entryPrice;
      expect(totalCapitalRequired, equals(2500.0));
    });

    test('Crypto fractional position sizing', () {
      const accountBalance = 5000.0;
      const riskPercentage = 2.0; // 2% = $100
      const entryPrice = 60000.0;
      const stopLoss = 58000.0;

      final dollarRisk = accountBalance * (riskPercentage / 100.0);
      expect(dollarRisk, equals(100.0));

      final priceDiff = (entryPrice - stopLoss).abs(); // 2000
      final btcUnits = dollarRisk / priceDiff;

      // 100 / 2000 = 0.05 BTC
      expect(btcUnits, equals(0.05));
    });
  });
}
