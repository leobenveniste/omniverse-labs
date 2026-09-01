import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'widgets/global_timer_banner.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CentralDeJuegosApp());
}

class CentralDeJuegosApp extends StatefulWidget {
  const CentralDeJuegosApp({super.key});

  @override
  State<CentralDeJuegosApp> createState() => _CentralDeJuegosAppState();
}

class _CentralDeJuegosAppState extends State<CentralDeJuegosApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Central de Juegos',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      builder: (context, child) {
        return Scaffold(
          body: Column(
            children: [
              const SafeArea(bottom: false, child: GlobalTimerBanner()),
              Expanded(child: child ?? const SizedBox.shrink()),
            ],
          ),
        );
      },
      home: SplashScreen(
        onToggleTheme: _toggleTheme,
        isDarkMode: _themeMode == ThemeMode.dark,
      ),
    );
  }
}
