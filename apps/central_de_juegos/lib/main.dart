import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/timer_service.dart';
import 'widgets/global_timer_banner.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CentralDeJuegosApp());
}

class CentralDeJuegosApp extends StatefulWidget {
  const CentralDeJuegosApp({super.key});

  @override
  State<CentralDeJuegosApp> createState() => _CentralDeJuegosAppState();

  static _CentralDeJuegosAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_CentralDeJuegosAppState>()!;
}

class _CentralDeJuegosAppState extends State<CentralDeJuegosApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  Locale? _locale;

  ThemeMode get themeMode => _themeMode;
  Locale? get locale => _locale;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final code = await StorageService.getLanguageCode();
    final themeStr = await StorageService.getThemeMode();
    setState(() {
      if (code != null) {
        _locale = Locale(code);
      }
      if (themeStr == 'light') {
        _themeMode = ThemeMode.light;
      } else if (themeStr == 'dark') {
        _themeMode = ThemeMode.dark;
      } else if (themeStr == 'system') {
        _themeMode = ThemeMode.system;
      }
    });
  }

  void setLocale(Locale newLocale) async {
    setState(() {
      _locale = newLocale;
    });
    await StorageService.setLanguageCode(newLocale.languageCode);
  }

  void setThemeMode(ThemeMode mode) async {
    setState(() {
      _themeMode = mode;
    });
    final modeStr = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.dark
            ? 'dark'
            : 'system';
    await StorageService.setThemeMode(modeStr);
  }

  void _toggleTheme() {
    final next = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setThemeMode(next);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Game Night Hub',
      debugShowCheckedModeBanner: false,
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      builder: (context, child) {
        return AnimatedBuilder(
          animation: TimerService(),
          builder: (context, _) {
            final hasTimer = TimerService().hasActiveTimer || TimerService().isFinished;
            return Stack(
              children: [
                child ?? const SizedBox.shrink(),
                if (hasTimer)
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      bottom: false,
                      child: Material(
                        elevation: 8,
                        color: Colors.transparent,
                        child: GlobalTimerBanner(),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
      home: SplashScreen(
        onToggleTheme: _toggleTheme,
        isDarkMode: _themeMode == ThemeMode.dark,
      ),
    );
  }
}
