import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_trade/core/security/security_service.dart';
import 'package:omni_trade/core/subscription/subscription_service.dart';
import 'package:omni_trade/main.dart';
import 'package:omni_trade/providers/security_provider.dart';
import 'package:omni_trade/providers/settings_provider.dart';
import 'package:omni_trade/providers/trade_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('OmniTradeApp initial smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final subscriptionService = SubscriptionService(prefs);
    final settingsProvider = SettingsProvider(prefs, subscriptionService);
    final securityService = SecurityService(prefs);
    final securityProvider = SecurityProvider(securityService);
    final tradeProvider = TradeProvider();

    await tester.pumpWidget(
      OmniTradeApp(
        settingsProvider: settingsProvider,
        securityProvider: securityProvider,
        tradeProvider: tradeProvider,
      ),
    );

    await tester.pump();

    // Verify initial load in Spanish
    await settingsProvider.setLocale('es');
    await tester.pumpAndSettle();

    expect(find.text('OmniTrade Cockpit'), findsOneWidget);
    expect(find.byIcon(Icons.insights_rounded), findsOneWidget);
    expect(find.text('Operaciones'), findsOneWidget);
    expect(find.text('Calculadora'), findsOneWidget);
    expect(find.text('Analíticas'), findsOneWidget);
    expect(find.text('Ajustes'), findsOneWidget);

    // Verify dynamic locale switch to English
    await settingsProvider.setLocale('en');
    await tester.pumpAndSettle();

    expect(find.text('Operations'), findsOneWidget);
    expect(find.text('Calculator'), findsOneWidget);
    expect(find.text('Analytics'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
