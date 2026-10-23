import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vuelo_controlado_staff/services/storage_service.dart';
import 'package:vuelo_controlado_staff/services/auth_service.dart';
import 'package:vuelo_controlado_staff/services/event_service.dart';
import 'package:vuelo_controlado_staff/services/case_service.dart';
import 'package:vuelo_controlado_staff/theme/app_theme.dart';
import 'package:vuelo_controlado_staff/screens/login_screen.dart';

void main() {
  testWidgets('Login screen smoke test renders branding and fields', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storageService = StorageService(prefs);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthService(storageService)),
          ChangeNotifierProvider(create: (_) => EventService(storageService)),
          ChangeNotifierProvider(create: (_) => CaseService(storageService)),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const LoginScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verificar presencia de elementos clave
    expect(find.text('PORTAL DE STAFF'), findsOneWidget);
    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('INGRESAR AL SISTEMA'), findsOneWidget);
    expect(find.text('Superadmin (Leo)'), findsOneWidget);
  });
}
