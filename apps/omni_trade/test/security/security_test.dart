import 'package:flutter_test/flutter_test.dart';
import 'package:omni_trade/core/security/security_service.dart';
import 'package:omni_trade/core/subscription/subscription_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Subscription & Freemium Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('Free tier limit enforcement and remaining trades', () {
      final service = SubscriptionService(prefs);

      expect(service.isPro, isFalse);
      expect(service.canLogTrade(0), isTrue);
      expect(service.canLogTrade(14), isTrue);
      expect(service.canLogTrade(15), isFalse);
      expect(service.remainingFreeTrades(10), equals(5));
      expect(service.remainingFreeTrades(15), equals(0));
    });

    test('Test Pro toggle override unlocks everything', () async {
      final service = SubscriptionService(prefs);

      expect(service.isPro, isFalse);
      await service.setTestProOverride(true);

      expect(service.isPro, isTrue);
      expect(service.isTestProOverride, isTrue);
      // Can log beyond 15 trades
      expect(service.canLogTrade(100), isTrue);
      expect(service.remainingFreeTrades(100), equals(999999));
    });
  });

  group('Security & PIN Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('PIN setup, verification, and removal', () async {
      final service = SecurityService(prefs);

      expect(service.hasPinCode, isFalse);
      expect(service.isLocked, isFalse);

      await service.setPinCode('1234');
      expect(service.hasPinCode, isTrue);

      expect(service.verifyPin('0000'), isFalse);
      expect(service.verifyPin('1234'), isTrue);

      await service.removePinCode();
      expect(service.hasPinCode, isFalse);
    });
  });
}
