import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'services/storage_service.dart';
import 'services/firestore_sync_service.dart';
import 'services/auth_service.dart';
import 'services/event_service.dart';
import 'services/case_service.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Habilitar modo Edge-to-Edge real para toda la aplicación
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final prefs = await SharedPreferences.getInstance();
  final savedTheme = prefs.getString('app_theme_mode');
  final ThemeMode initialThemeMode;
  if (savedTheme == 'light') {
    initialThemeMode = ThemeMode.light;
  } else if (savedTheme == 'dark') {
    initialThemeMode = ThemeMode.dark;
  } else if (savedTheme == 'system') {
    initialThemeMode = ThemeMode.system;
  } else {
    initialThemeMode = ThemeMode.dark;
  }

  final isLight = initialThemeMode == ThemeMode.light ||
      (initialThemeMode == ThemeMode.system &&
          WidgetsBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.light);

  SystemChrome.setSystemUIOverlayStyle(
    AppTheme.systemOverlayStyleFor(
      isLight ? Brightness.light : Brightness.dark,
    ),
  );

  runApp(AppBootstrap(
    initialThemeMode: initialThemeMode,
    prefs: prefs,
  ));
}

class _AppDependencies {
  final AuthService authService;
  final EventService eventService;
  final CaseService caseService;
  final SettingsService settingsService;
  final FirestoreSyncService syncService;

  const _AppDependencies({
    required this.authService,
    required this.eventService,
    required this.caseService,
    required this.settingsService,
    required this.syncService,
  });
}

class AppBootstrap extends StatefulWidget {
  final ThemeMode? initialThemeMode;
  final SharedPreferences? prefs;

  const AppBootstrap({
    super.key,
    this.initialThemeMode,
    this.prefs,
  });

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  _AppDependencies? _dependencies;

  @override
  void initState() {
    super.initState();
    _initRealDependencies();
  }

  Future<void> _initRealDependencies() async {
    // 1. Inicializar formateo de fechas en español y Firebase en paralelo
    await Future.wait([
      initializeDateFormatting('es', null),
      initializeDateFormatting('es_AR', null),
      Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).catchError((Object e) {
        debugPrint('Firebase initialization notice: $e');
        return Firebase.app();
      }),
    ]);

    // 2. Inicializar almacenamiento local y seed inicial
    final storageService = widget.prefs != null
        ? await StorageService.initWithPrefs(widget.prefs!)
        : await StorageService.init();
    final settingsService = SettingsService(storageService.prefs);

    // 3. Inicializar servicio de sincronización en la nube (Firestore)
    final syncService = FirestoreSyncService(storageService);
    final authService = AuthService(storageService, firestoreSync: syncService);
    final eventService =
        EventService(storageService, firestoreSync: syncService);
    final caseService = CaseService(storageService, firestoreSync: syncService);

    syncService.onUsersUpdated = authService.reloadUsersFromStorage;
    syncService.onEventsUpdated = eventService.reloadEventsFromStorage;
    syncService.onCasesUpdated = caseService.reloadCasesFromStorage;

    // Iniciar sincronización en segundo plano (no bloquea el arranque)
    unawaited(syncService.init());

    if (!mounted) return;
    setState(() {
      _dependencies = _AppDependencies(
        authService: authService,
        eventService: eventService,
        caseService: caseService,
        settingsService: settingsService,
        syncService: syncService,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final deps = _dependencies;
    if (deps == null) {
      final mode = widget.initialThemeMode ?? ThemeMode.dark;
      return MaterialApp(
        title: 'Vuelo Controlado Staff',
        debugShowCheckedModeBanner: false,
        themeMode: mode,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        builder: (context, child) {
          final brightness = Theme.of(context).brightness;
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: AppTheme.systemOverlayStyleFor(brightness),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const SplashScreen(),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: deps.authService),
        ChangeNotifierProvider.value(value: deps.eventService),
        ChangeNotifierProvider.value(value: deps.caseService),
        ChangeNotifierProvider.value(value: deps.settingsService),
        Provider.value(value: deps.syncService),
      ],
      child: const VueloControladoStaffApp(),
    );
  }
}

class VueloControladoStaffApp extends StatelessWidget {
  const VueloControladoStaffApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final settingsService = context.watch<SettingsService>();

    return MaterialApp(
      title: 'Vuelo Controlado Staff',
      debugShowCheckedModeBanner: false,
      themeMode: settingsService.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'AR'),
        Locale('es', ''),
        Locale('en', ''),
      ],
      locale: settingsService.locale,
      builder: (context, child) {
        final brightness = Theme.of(context).brightness;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: AppTheme.systemOverlayStyleFor(brightness),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: authService.isAuthenticated
            ? const HomeScreen(key: ValueKey('home_screen'))
            : const LoginScreen(key: ValueKey('login_screen')),
      ),
    );
  }
}
