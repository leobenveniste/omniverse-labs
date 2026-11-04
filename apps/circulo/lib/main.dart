import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'theme/app_theme.dart';
import 'services/settings_service.dart';
import 'services/biometric_service.dart';
import 'services/online_firestore_service.dart';
import 'services/auth_service.dart';
import 'services/billing_service.dart';
import 'services/ad_service.dart';
import 'services/match_engine_service.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/welcome_guide_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/onboarding_wizard_screen.dart';
import 'screens/home_shell_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Global FlutterError: ${details.exception}');
  };

  try {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  } catch (e) {
    debugPrint('SystemUI edgeToEdge notice: $e');
  }

  final prefs = await SharedPreferences.getInstance();

  runApp(CirculoAppBootstrap(prefs: prefs));
}

class _CirculoDependencies {
  final SettingsService settingsService;
  final BiometricService biometricService;
  final OnlineFirestoreService firestoreService;
  final AuthService authService;
  final BillingService billingService;
  final AdService adService;
  final MatchEngineService matchEngineService;

  const _CirculoDependencies({
    required this.settingsService,
    required this.biometricService,
    required this.firestoreService,
    required this.authService,
    required this.billingService,
    required this.adService,
    required this.matchEngineService,
  });
}

class CirculoAppBootstrap extends StatefulWidget {
  final SharedPreferences prefs;

  const CirculoAppBootstrap({super.key, required this.prefs});

  @override
  State<CirculoAppBootstrap> createState() => _CirculoAppBootstrapState();
}

class _CirculoAppBootstrapState extends State<CirculoAppBootstrap> {
  _CirculoDependencies? _dependencies;
  String _statusText = 'Conectando de forma segura...';

  @override
  void initState() {
    super.initState();
    _initDependencies();
  }

  Future<void> _safeInitFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint('Firebase init notice: $e');
    }
  }

  Future<void> _initDependencies() async {
    try {
      // 1. Inicialización de formatos de fecha e infraestructura
      await Future.wait([
        initializeDateFormatting('es', null),
        initializeDateFormatting('en', null),
        initializeDateFormatting('pt', null),
        initializeDateFormatting('fr', null),
        initializeDateFormatting('it', null),
        initializeDateFormatting('de', null),
        _safeInitFirebase(),
      ]);

      // 2. Servicios
      final settingsService = SettingsService(widget.prefs);
      final biometricService = BiometricService();
      final firestoreService = OnlineFirestoreService();

      if (mounted) {
        setState(() => _statusText = 'Sincronizando perfiles en la nube...');
      }

      await firestoreService.init();

      final authService = AuthService(firestoreService, widget.prefs);
      final billingService = BillingService(firestoreService);
      final adService = AdService();
      final matchEngineService = MatchEngineService(firestoreService);

      // Inicialización asíncrona no bloqueante
      unawaited(billingService.initialize().catchError((e) {
        debugPrint('BillingService init error: $e');
      }));
      unawaited(adService.initialize().catchError((e) {
        debugPrint('AdService init error: $e');
      }));

      if (!mounted) return;
      setState(() {
        _dependencies = _CirculoDependencies(
          settingsService: settingsService,
          biometricService: biometricService,
          firestoreService: firestoreService,
          authService: authService,
          billingService: billingService,
          adService: adService,
          matchEngineService: matchEngineService,
        );
      });
    } catch (e, stack) {
      debugPrint('Fatal error during _initDependencies: $e\n$stack');
      // Resiliencia total ante cualquier fallo imprevisto
      final settingsService = SettingsService(widget.prefs);
      final firestoreService = OnlineFirestoreService();
      await firestoreService.init();
      if (!mounted) return;
      setState(() {
        _dependencies = _CirculoDependencies(
          settingsService: settingsService,
          biometricService: BiometricService(),
          firestoreService: firestoreService,
          authService: AuthService(firestoreService, widget.prefs),
          billingService: BillingService(firestoreService),
          adService: AdService(),
          matchEngineService: MatchEngineService(firestoreService),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final deps = _dependencies;
    if (deps == null) {
      return MaterialApp(
        title: 'Círculo',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: SplashScreen(statusText: _statusText),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: deps.settingsService),
        ChangeNotifierProvider.value(value: deps.authService),
        ChangeNotifierProvider.value(value: deps.billingService),
        ChangeNotifierProvider.value(value: deps.adService),
        ChangeNotifierProvider.value(value: deps.matchEngineService),
        Provider.value(value: deps.firestoreService),
        Provider.value(value: deps.biometricService),
      ],
      child: const CirculoAppRoot(),
    );
  }
}

class CirculoAppRoot extends StatelessWidget {
  const CirculoAppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final auth = context.watch<AuthService>();

    return MaterialApp(
      title: 'Círculo',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      locale: settings.explicitLocale,
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        return settings.resolveEffectiveLocale(deviceLocale);
      },
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final brightness = Theme.of(context).brightness;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: AppTheme.systemOverlayStyleFor(brightness),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: _resolveInitialScreen(settings, auth),
    );
  }

  Widget _resolveInitialScreen(SettingsService settings, AuthService auth) {
    // 1. Si no vio la Guía de Bienvenida nunca, mostrarla primero
    if (!settings.welcomeGuideSeen) {
      return const WelcomeGuideScreen(key: ValueKey('welcome_screen'));
    }

    // 2. Si no está autenticado, mostrar Login
    if (!auth.isAuthenticated) {
      return const LoginScreen(key: ValueKey('login_screen'));
    }

    // 3. Si está autenticado pero no completó onboarding, mostrar Wizard
    if (auth.currentUser?.onboardingCompleted != true) {
      return const OnboardingWizardScreen(key: ValueKey('onboarding_screen'));
    }

    // 4. Shell principal
    return const HomeShellScreen(key: ValueKey('home_shell_screen'));
  }
}
