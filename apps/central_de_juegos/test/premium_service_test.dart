import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:central_de_juegos/services/premium_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PremiumService Tests for Central de Juegos', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Initial free state is not pro', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = PremiumService(prefs);

      expect(service.isPro, isFalse);
      expect(service.isLoading, isFalse);
      expect(service.errorMessage, isNull);
    });

    test('Testing toggle successfully unlocks Pro mode', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = PremiumService(prefs);

      expect(service.isPro, isFalse);

      await service.setProForTesting(true);
      expect(service.isPro, isTrue);

      await service.setProForTesting(false);
      expect(service.isPro, isFalse);
    });

    test('Pro status persists across service instances in SharedPreferences', () async {
      final prefs = await SharedPreferences.getInstance();
      final service1 = PremiumService(prefs);

      await service1.setProForTesting(true);
      expect(service1.isPro, isTrue);

      // Create brand new instance with same prefs
      final service2 = PremiumService(prefs);
      expect(service2.isPro, isTrue);
    });
  });
}
