import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/storage_service.dart';
import 'services/auth_service.dart';
import 'services/event_service.dart';
import 'services/case_service.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar almacenamiento local y seed inicial
  final storageService = await StorageService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService(storageService)),
        ChangeNotifierProvider(create: (_) => EventService(storageService)),
        ChangeNotifierProvider(create: (_) => CaseService(storageService)),
      ],
      child: const VueloControladoStaffApp(),
    ),
  );
}

class VueloControladoStaffApp extends StatelessWidget {
  const VueloControladoStaffApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    return MaterialApp(
      title: 'Vuelo Controlado Staff',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: authService.isAuthenticated
          ? const HomeScreen()
          : const LoginScreen(),
    );
  }
}
