import 'dart:async';

import 'package:cancel_guard/main.dart';
import 'package:cancel_guard/screens/splash_screen.dart';
import 'package:cancel_guard/services/alert_scheduler.dart';
import 'package:cancel_guard/services/vault_controller.dart';
import 'package:cancel_guard/services/vault_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<VaultController> createTestController() async {
    SharedPreferences.setMockInitialValues({});
    final storage = await VaultStorage.open();
    final scheduler = NoopAlertScheduler();
    final controller = VaultController(
      storage: storage,
      scheduler: scheduler,
    );
    await controller.initialize();
    return controller;
  }

  testWidgets('SplashScreen displays while loading and transitions immediately',
      (WidgetTester tester) async {
    final completer = Completer<VaultController>();

    await tester.pumpWidget(
      CancelGuardBootstrap(loader: () => completer.future),
    );

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('CancelGuard'), findsOneWidget);

    final controller = await createTestController();
    completer.complete(controller);
    await tester.pumpAndSettle();

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.text('Your Guardian Vault is clear'), findsOneWidget);
  });

  testWidgets(
      'Filterable dropdown, empty cancel link, ROI banking, and Settings page work cleanly',
      (WidgetTester tester) async {
    final controller = await createTestController();

    await tester.pumpWidget(CancelGuardApp(controller: controller));
    await tester.pumpAndSettle();

    // Header has no subtitle and empty state has only the bottom-right FAB
    expect(find.text('100% offline • Zero accounts'), findsNothing);
    expect(find.text('Guard Trial'), findsOneWidget);

    // Open entry sheet
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('QUICK PRESETS'), findsNothing);

    // Type into the filterable 50-service dropdown and select Adobe Creative Cloud
    final serviceField = find.byType(TextFormField).first;
    await tester.enterText(serviceField, 'Adobe');
    await tester.pumpAndSettle();

    expect(find.text('Adobe Creative Cloud'), findsOneWidget);
    await tester.tap(find.text('Adobe Creative Cloud'));
    await tester.pumpAndSettle();

    // Enter renewal price (cancel link left blank intentionally)
    await tester.enterText(find.byType(TextFormField).at(1), '54.99');
    await tester.tap(find.text('Activate Shield'));
    await tester.pumpAndSettle();

    // Card renders without Open Cancel Link since no link was entered
    expect(find.text('Adobe Creative Cloud'), findsOneWidget);
    expect(find.text('Open Cancel Link'), findsNothing);
    expect(find.text('Mark Cancelled'), findsOneWidget);

    // Mark cancelled -> banks ROI
    await tester.tap(find.text('Mark Cancelled'));
    await tester.pumpAndSettle();
    expect(find.text('37x ROI'), findsOneWidget);

    // Open Settings screen -> verify theme, language, currency, notifications, Contact Us, Omniverse Labs info
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    // Switch to Light theme and Español
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(controller.themeMode, ThemeMode.light);

    await tester.tap(find.text('Español'));
    await tester.pumpAndSettle();
    expect(find.text('Ajustes'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('OMNIVERSE LABS'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('OMNIVERSE LABS'), findsOneWidget);
    expect(find.text('com.omniverselabs.cancel_guard'), findsOneWidget);

    // Open Contact & Suggestions modal and verify email
    await tester.scrollUntilVisible(
      find.text('leo.benveniste@gmail.com'),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('leo.benveniste@gmail.com'));
    await tester.pumpAndSettle();
    expect(find.text('Enviar Correo'), findsOneWidget);
    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();
  });
}
