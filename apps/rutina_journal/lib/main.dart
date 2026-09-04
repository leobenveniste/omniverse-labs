import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'screens/splash_screen.dart';
import 'services/app_services.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final services = await AppServices.init();
  runApp(RitmoApp(services: services));
}

class RitmoApp extends StatelessWidget {
  final AppServices services;

  const RitmoApp({super.key, required this.services});

  @override
  Widget build(BuildContext context) {
    return AppServicesScope(
      services: services,
      child: AnimatedBuilder(
        animation: services.preferencesService,
        builder: (context, _) {
          final prefs = services.preferencesService;

          return MaterialApp(
            title: 'Ritmo',
            debugShowCheckedModeBanner: false,
            locale: prefs.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            themeMode: prefs.themeMode,
            theme: AppTheme.buildTheme(
              preset: prefs.themePreset,
              isDark: false,
            ),
            darkTheme: AppTheme.buildTheme(
              preset: prefs.themePreset,
              isDark: true,
            ),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
