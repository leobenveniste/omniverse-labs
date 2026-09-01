import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_shell.dart';
import 'core/database/app_database.dart';
import 'core/localization/locale_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize and seed SQLite database
  await AppDatabase.instance.seedInitialDataIfEmpty();

  runApp(const ProviderScope(child: MenuListoApp()));
}

class MenuListoApp extends ConsumerWidget {
  const MenuListoApp({super.key});

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
      home: const AppShell(),
    );
  }
}
