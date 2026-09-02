import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_shell.dart';
import 'core/database/app_database.dart';
import 'core/localization/locale_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize and seed SQLite database
  await AppDatabase.instance.seedInitialDataIfEmpty();

  // Check if user has seen onboarding
  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

  runApp(
    ProviderScope(
      child: MenuListoApp(hasSeenOnboarding: hasSeenOnboarding),
    ),
  );
}

class MenuListoApp extends ConsumerWidget {
  final bool hasSeenOnboarding;

  const MenuListoApp({super.key, required this.hasSeenOnboarding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final designTheme = ref.watch(designThemeProvider);
    final language = ref.watch(localeProvider);

    return MaterialApp(
      title: 'Menú Listo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(designTheme, Brightness.light),
      darkTheme: AppTheme.buildTheme(designTheme, Brightness.dark),
      themeMode: themeMode,
      locale: language.locale,
      supportedLocales: const [
        Locale('es'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: hasSeenOnboarding ? const AppShell() : const OnboardingScreen(),
    );
  }
}
