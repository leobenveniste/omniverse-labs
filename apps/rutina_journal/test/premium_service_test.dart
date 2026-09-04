import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rutina_journal/services/premium_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PremiumService Tests', () {
    test('Initial free state allows exactly 1 focus session', () async {
      final prefs = await SharedPreferences.getInstance();
      final premium = PremiumService(prefs);

      expect(premium.isPro, isFalse);
      expect(premium.todayFocusSessionsCount, 0);
      expect(premium.canStartFocusSession, isTrue);

      // Record first session
      await premium.recordFocusSession();
      expect(premium.todayFocusSessionsCount, 1);
      expect(premium.canStartFocusSession, isFalse);
    });

    test('Pro user has unlimited focus sessions', () async {
      final prefs = await SharedPreferences.getInstance();
      final premium = PremiumService(prefs);

      // Record a session as free user first
      await premium.recordFocusSession();
      expect(premium.canStartFocusSession, isFalse);

      // Unlock Pro
      await premium.setProUser(true);
      expect(premium.isPro, isTrue);
      expect(premium.canStartFocusSession, isTrue);

      // Record another session
      await premium.recordFocusSession();
      expect(premium.todayFocusSessionsCount, 2);
      expect(premium.canStartFocusSession, isTrue);
    });

    test('Pro status persists in SharedPreferences', () async {
      final prefs = await SharedPreferences.getInstance();
      final premium1 = PremiumService(prefs);

      await premium1.setProUser(true);
      expect(premium1.isPro, isTrue);

      // Instantiate a new service instance with the same preferences
      final premium2 = PremiumService(prefs);
      expect(premium2.isPro, isTrue);

      // Toggle off
      await premium2.setProUser(false);
      expect(premium2.isPro, isFalse);

      final premium3 = PremiumService(prefs);
      expect(premium3.isPro, isFalse);
    });
  });
}
