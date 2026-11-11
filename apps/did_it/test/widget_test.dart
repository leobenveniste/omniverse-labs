import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:did_it/main.dart';
import 'package:did_it/screens/splash_screen.dart';
import 'package:did_it/services/did_it_controller.dart';
import 'package:did_it/services/did_it_scheduler.dart';
import 'package:did_it/services/did_it_storage.dart';

Future<DidItController> _createTestController(DateTime now) async {
  final storage = await DidItStorage.open();
  final controller = DidItController(
    storage: storage,
    scheduler: NoopDidItScheduler(),
    clock: () => now,
  );
  await controller.initialize();
  return controller;
}

void main() {
  testWidgets('SplashScreen displays while loading and transitions immediately', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final now = DateTime(2026, 11, 11, 12, 0);

    await tester.pumpWidget(
      DidItBootstrap(
        loader: () async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return _createTestController(now);
        },
      ),
    );

    expect(find.byType(SplashScreen), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.text('DidIt'), findsOneWidget);
  });

  testWidgets('DID IT button confirms proof, respects cooldown guard, Flows & Settings work', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final now = DateTime(2026, 11, 11, 14, 0);
    final controller = await _createTestController(now);

    await tester.pumpWidget(DidItApp(controller: controller));
    await tester.pumpAndSettle();

    // Starter dose guard item is visible in Queue tab with DID IT button
    expect(find.text('Take Dose / Supplement'), findsOneWidget);
    await tester.tap(find.text('DID IT').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('Done 0m ago'), findsOneWidget);

    // Tapping DID IT again inside cooldown triggers safety confirmation dialog
    await tester.tap(find.text('DID IT').first);
    await tester.pumpAndSettle();
    expect(find.text('Already done recently?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Switch to Flows tab & import a starter template (scroll above FAB first)
    await tester.tap(find.text('Flows'));
    await tester.pumpAndSettle();
    expect(find.text('Leaving Home Check'), findsWidgets);
    await tester.drag(find.byType(ListView).last, const Offset(0, -240));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Import').first);
    await tester.pumpAndSettle();

    // Open Confirmation Logbook & verify recorded proof
    await tester.tap(find.byTooltip('Confirmation logbook'));
    await tester.pumpAndSettle();
    expect(find.text('Confirmation Logbook'), findsOneWidget);
    expect(find.text('Take Dose / Supplement'), findsWidgets);

    Navigator.of(tester.element(find.text('Confirmation Logbook'))).pop();
    await tester.pumpAndSettle();

    // Open Settings & toggle theme + Spanish locale cleanly
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ES'));
    await tester.pumpAndSettle();
    expect(find.text('Ajustes'), findsOneWidget);

    controller.dispose();
  });
}
