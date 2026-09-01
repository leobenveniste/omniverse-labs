import 'package:flutter/material.dart';
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
