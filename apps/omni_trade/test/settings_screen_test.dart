import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_trade/core/security/security_service.dart';
import 'package:omni_trade/core/subscription/subscription_service.dart';
import 'package:omni_trade/core/theme/app_theme.dart';
import 'package:omni_trade/features/settings/screens/settings_screen.dart';
import 'package:omni_trade/l10n/app_localizations.dart';
import 'package:omni_trade/providers/security_provider.dart';
import 'package:omni_trade/providers/settings_provider.dart';
import 'package:omni_trade/providers/trade_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late SubscriptionService subscriptionService;
  late SettingsProvider settingsProvider;
  late SecurityService securityService;
  late SecurityProvider securityProvider;
  late TradeProvider tradeProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    subscriptionService = SubscriptionService(prefs);
    settingsProvider = SettingsProvider(prefs, subscriptionService);
    securityService = SecurityService(prefs);
    securityProvider = SecurityProvider(securityService);
    tradeProvider = TradeProvider();
  });

  Widget buildSettingsApp() {
    return MaterialApp(
      theme: AppTheme.buildTheme(isDark: true),
      locale: const Locale('es'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: SettingsScreen(
        settingsProvider: settingsProvider,
        securityProvider: securityProvider,
        tradeProvider: tradeProvider,
      ),
    );
  }

  testWidgets('SettingsScreen dev mode is hidden by default and opens Privacy dialog', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSettingsApp());
    await tester.pumpAndSettle();

    // Dev mode toggle section should NOT be visible by default
    expect(find.text('MODO DE PRUEBAS / TESTING'), findsNothing);

    // Privacy policy tile should be visible
    final privacyTile = find.text('Política de Privacidad');
    expect(privacyTile, findsOneWidget);

    await tester.tap(privacyTile);
    await tester.pumpAndSettle();

    // Verify privacy dialog opened
    expect(find.text('Privacidad y Protección de Datos'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Privacidad y Protección de Datos'), findsNothing);
  });

  testWidgets('SettingsScreen shows Clear Data confirmation dialog', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSettingsApp());
    await tester.pumpAndSettle();

    final clearTile = find.text('Eliminar Todos los Datos');
    expect(clearTile, findsOneWidget);

    await tester.tap(clearTile);
    await tester.pumpAndSettle();

    expect(find.text('¿Eliminar todos los datos?'), findsOneWidget);
    expect(find.text('Sí, Borrar Todo'), findsOneWidget);

    // Cancel dismissal
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.text('¿Eliminar todos los datos?'), findsNothing);
  });
}
