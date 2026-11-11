import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_pocket/main.dart';
import 'package:pulse_pocket/models/pulse_models.dart';
import 'package:pulse_pocket/screens/splash_screen.dart';
import 'package:pulse_pocket/services/haptic_driver.dart';
import 'package:pulse_pocket/services/pulse_controller.dart';
import 'package:pulse_pocket/services/pulse_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<PulseController> createTestController() async {
    SharedPreferences.setMockInitialValues({});
    final storage = await PulseStorage.open();
    final controller = PulseController(
      storage: storage,
      hapticDriver: NoopHapticDriver(),
      onWakelockChanged: (_) async {},
    );
    await controller.initialize();
    return controller;
  }

  testWidgets('SplashScreen displays while loading and transitions immediately',
      (WidgetTester tester) async {
    final completer = Completer<PulseController>();

    await tester.pumpWidget(
      PulsePocketBootstrap(loader: () => completer.future),
    );

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('PulsePocket'), findsOneWidget);

    final controller = await createTestController();
    completer.complete(controller);
    await tester.pumpAndSettle();

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.text('SETLIST SLOTS'), findsOneWidget);
  });

  testWidgets(
      'Stage Console, Setlist Slots, Pocket Lock guard, and Settings page work cleanly',
      (WidgetTester tester) async {
    final controller = await createTestController();

    await tester.pumpWidget(PulsePocketApp(controller: controller));
    await tester.pumpAndSettle();

    // Header has clean title without subtitle
    expect(find.text('PulsePocket'), findsOneWidget);
    expect(find.byKey(const ValueKey('bpm-display')), findsOneWidget);
    expect(find.text('120'), findsOneWidget);

    // Step BPM & select 6/8 meter
    await tester.tap(find.text('+5'));
    await tester.pumpAndSettle();
    expect(find.text('125'), findsOneWidget);

    await tester.tap(find.text('6/8'));
    await tester.pumpAndSettle();
    expect(controller.signature, TimeSignatureOption.sixEight);

    // Save current tempo into 1-Tap Setlist Slot
    await tester.tap(find.text('Save Slot'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Soundcheck');
    await tester.tap(find.text('Save Slot').last);
    await tester.pumpAndSettle();
    expect(controller.slots.any((s) => s.name == 'Soundcheck'), isTrue);

    // Engage Pocket Lock -> single stray tap does NOT unlock -> 1.2s continuous hold unlocks
    await tester.tap(find.text('POCKET LOCK'));
    await tester.pump();
    expect(find.text('POCKET LOCKED'), findsOneWidget);
    expect(controller.isPocketLocked, isTrue);

    // Stray brief tap resets without unlocking
    await tester.tap(find.text('POCKET LOCKED'));
    await tester.pump(const Duration(milliseconds: 150));
    expect(controller.isPocketLocked, isTrue);

    // Continuous 1.25s pointer hold unlocks cleanly
    final holdPoint = tester.getCenter(find.text('POCKET LOCKED'));
    final gesture = await tester.startGesture(holdPoint);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 1300));
    await gesture.up();
    await tester.pump();
    expect(controller.isPocketLocked, isFalse);

    // Stop metronome cleanly before settling widget tree
    await controller.stop();
    await tester.pumpAndSettle();

    // Open Settings screen -> verify Theme, Language, Haptic Strength, Contact Us, Omniverse Labs card
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(controller.themeMode, ThemeMode.light);

    await tester.tap(find.text('Stage Max'));
    await tester.pumpAndSettle();
    expect(controller.hapticStrength, HapticStrength.stageMax);

    await tester.tap(find.text('Español'));
    await tester.pumpAndSettle();
    expect(find.text('Ajustes'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('OMNIVERSE LABS'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('com.omniverselabs.pulse_pocket'), findsOneWidget);

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

    controller.dispose();
  });
}
