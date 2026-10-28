import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'providers/app_providers.dart';
import 'features/splash/splash_screen.dart';
import 'features/auth/auth_screen.dart';
import 'app_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const ProviderScope(child: MiDeltaApp()));
}

class MiDeltaApp extends ConsumerWidget {
  const MiDeltaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watches the authentic asynchronous initialization pipeline.
    // Zero artificial delay: transitions as soon as real services & session checks are ready.
    final initAsync = ref.watch(appInitializationProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Mi Delta',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: initAsync.when(
        data: (_) => const _AuthGate(),
        loading: () => const SplashScreen(),
        error: (error, stack) => Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_rounded, size: 54, color: Color(0xFFBA1A1A)),
                  const SizedBox(height: 16),
                  const Text(
                    'No se pudo conectar con el portal municipal',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => ref.refresh(appInitializationProvider),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Reintentar conexión'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);

    if (user == null) {
      return const AuthScreen();
    }

    return const AppShell();
  }
}
