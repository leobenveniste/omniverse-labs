import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/constants/app_constants.dart';
import 'core/security/security_service.dart';
import 'core/subscription/subscription_service.dart';
import 'core/theme/app_theme.dart';
import 'features/security/screens/lock_screen.dart';
import 'features/splash/screens/splash_screen.dart';
import 'l10n/app_localizations.dart';
import 'providers/security_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/trade_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Edge-to-Edge System Bar Configuration
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  final prefs = await SharedPreferences.getInstance();

  late final SettingsProvider settingsProvider;
  final subscriptionService = SubscriptionService(
    prefs,
    iap: InAppPurchase.instance,
    onEntitlementChanged: () {
      // Trigger update when IAP or test toggle changes
      settingsProvider.refreshEntitlement();
    },
  );

  settingsProvider = SettingsProvider(prefs, subscriptionService);
  final securityService = SecurityService(prefs);
  final securityProvider = SecurityProvider(securityService);
  final tradeProvider = TradeProvider();

  // Preload local trades
  await tradeProvider.loadTrades();

  runApp(
    OmniTradeApp(
      settingsProvider: settingsProvider,
      securityProvider: securityProvider,
      tradeProvider: tradeProvider,
    ),
  );
}

class OmniTradeApp extends StatefulWidget {
  final SettingsProvider settingsProvider;
  final SecurityProvider securityProvider;
  final TradeProvider tradeProvider;

  const OmniTradeApp({
    super.key,
    required this.settingsProvider,
    required this.securityProvider,
    required this.tradeProvider,
  });

  @override
  State<OmniTradeApp> createState() => _OmniTradeAppState();
}

class _OmniTradeAppState extends State<OmniTradeApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.settingsProvider.addListener(_onStateChanged);
    widget.securityProvider.addListener(_onStateChanged);
    widget.tradeProvider.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.settingsProvider.removeListener(_onStateChanged);
    widget.securityProvider.removeListener(_onStateChanged);
    widget.tradeProvider.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      widget.securityProvider.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      widget.securityProvider.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settingsProvider;
    final security = widget.securityProvider;

    final isLocked = security.isLocked && security.hasPinCode;

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(isDark: false),
      darkTheme: AppTheme.buildTheme(isDark: true),
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localeListResolutionCallback: (locales, supportedLocales) {
        // If user explicitly picked a language in Settings, use it
        if (settings.locale != null) return settings.locale;

        // Check user locales from device list
        if (locales != null && locales.isNotEmpty) {
          for (final userLocale in locales) {
            for (final supported in supportedLocales) {
              if (supported.languageCode.toLowerCase() == userLocale.languageCode.toLowerCase()) {
                return supported;
              }
            }
          }
        }

        // Secondary check via platform dispatcher
        final platformLocales = WidgetsBinding.instance.platformDispatcher.locales;
        for (final platformLocale in platformLocales) {
          for (final supported in supportedLocales) {
            if (supported.languageCode.toLowerCase() == platformLocale.languageCode.toLowerCase()) {
              return supported;
            }
          }
        }

        // Global default fallback
        return const Locale('en');
      },
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: isLocked
          ? LockScreen(
              canUseBiometrics: security.isBiometricsEnabled,
              onPinVerify: (pin) => security.verifyPin(pin),
              onBiometricRequested: () => security.authenticateBiometrics(),
              onUnlocked: () => security.unlock(),
            )
          : SplashScreen(
              tradeProvider: widget.tradeProvider,
              settingsProvider: widget.settingsProvider,
              securityProvider: widget.securityProvider,
            ),
    );
  }
}
