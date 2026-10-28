import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_delta/main.dart';
import 'package:mi_delta/app_shell.dart';
import 'package:mi_delta/features/auth/auth_screen.dart';
import 'package:mi_delta/features/beneficios/beneficios_screen.dart';
import 'package:mi_delta/features/profile/profile_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Mi Delta App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MiDeltaApp()));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.byType(MiDeltaApp), findsOneWidget);
  });

  testWidgets('AuthScreen renders simplified registration link and toggles mode', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AuthScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify words vecinal and ciudadana are not present on screen
    expect(find.textContaining('vecinal'), findsNothing);
    expect(find.textContaining('ciudadana'), findsNothing);

    // Verify registration link is present
    expect(find.textContaining('¿No tenés cuenta?'), findsOneWidget);
    expect(find.textContaining('Registrate'), findsOneWidget);

    // Tap on the registration link to switch to register mode
    await tester.tap(find.textContaining('Registrate'));
    await tester.pumpAndSettle();

    // Verify register mode fields and link to switch back
    expect(find.text('Nombre y Apellido'), findsOneWidget);
    expect(find.textContaining('¿Ya tenés cuenta?'), findsOneWidget);
    expect(find.textContaining('Iniciá sesión'), findsOneWidget);
  });

  testWidgets('AppShell renders correct bottom navigation tabs and Acceso Rápido', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AppShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify 4-button quick access row on Home
    expect(find.text('Acceso Rápido'), findsOneWidget);
    expect(find.text('Turnos'), findsWidgets);
    expect(find.text('Reportes'), findsWidgets);
    expect(find.text('Trámites'), findsOneWidget);
    expect(find.text('Comunidad'), findsWidgets);

    // Verify bottom navigation bar items
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('SOS'), findsOneWidget);
  });

  testWidgets('Comunidad screen displays digital ID card with QR and two sections', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: BeneficiosScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify ID card details
    expect(find.text('CREDENCIAL SOY DELTA'), findsOneWidget);
    expect(find.text('TITULAR DE LA CUENTA'), findsOneWidget);
    expect(find.text('ESCANEAR'), findsOneWidget);

    // Verify 2 sections segmented control
    expect(find.text('Beneficios & Comercios'), findsOneWidget);
    expect(find.text('Agenda Comunitaria'), findsOneWidget);

    // Switch to Agenda tab
    await tester.tap(find.text('Agenda Comunitaria'));
    await tester.pumpAndSettle();

    // Verify agenda content is displayed
    expect(find.text('Festival Náutico del Delta'), findsOneWidget);
    expect(find.text('Agendar Actividad'), findsWidgets);
  });

  testWidgets('ProfileScreen renders appearance theme options', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify theme selector
    expect(find.text('APARIENCIA DEL SISTEMA'), findsOneWidget);
    expect(find.text('Automático'), findsOneWidget);
    expect(find.text('Claro'), findsOneWidget);
    expect(find.text('Oscuro'), findsOneWidget);

    // Tap on Claro theme option
    await tester.tap(find.text('Claro'));
    await tester.pumpAndSettle();
  });
}

