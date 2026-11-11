import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loud_guard/main.dart';
import 'package:loud_guard/services/audio_meter_driver.dart';
import 'package:loud_guard/services/loud_controller.dart';
import 'package:loud_guard/services/loud_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<LoudController> _makeController({
  bool permissionGranted = true,
}) async {
  SharedPreferences.setMockInitialValues({});
  final storage = await LoudStorage.open();
  final driver = FakeAudioMeterDriver(permissionGranted: permissionGranted);
  final controller = LoudController(
    storage: storage,
    driver: driver,
    wakelockHandler: (_) async {},
    thresholdHapticHandler: () async {},
  );
  await controller.initialize();
  return controller;
}

void main() {
  testWidgets('SoundConsole starts, streams dB, logs check, and opens Settings & Contact Us',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LoudStorage.open();
    final driver = FakeAudioMeterDriver();
    final controller = LoudController(
      storage: storage,
      driver: driver,
      wakelockHandler: (_) async {},
      thresholdHapticHandler: () async {},
    );
    await controller.initialize();

    await tester.pumpWidget(LoudGuardApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('LoudGuard'), findsOneWidget);
    expect(find.text('START METER'), findsOneWidget);
    expect(find.text('WHO / NIOSH SAFE EXPOSURE'), findsOneWidget);

    await tester.tap(find.text('START METER'));
    await tester.pump();
    expect(find.text('LIVE IN RAM'), findsOneWidget);

    driver.emitSplForBaseline(94.0);
    await tester.pump();
    expect(find.text('94.0'), findsOneWidget);
    expect(find.text('1h 00m'), findsOneWidget);

    // Pause before opening modal so periodic timer does not outlive test cleanly.
    await tester.tap(find.text('PAUSE'));
    await tester.pump();

    await tester.tap(find.text('LOG CHECK'));
    await tester.pumpAndSettle();
    expect(find.text('Save Current Check'), findsOneWidget);

    await tester.tap(find.text('Nursery'));
    await tester.pump();
    await tester.tap(find.text('Save Check'));
    await tester.pumpAndSettle();
    expect(find.text('Nursery'), findsWidgets);

    // Close modal sheet
    await tester.tap(find.byTooltip('Got it'));
    await tester.pumpAndSettle();

    // Dismiss snackbar and navigate to Settings
    ScaffoldMessenger.of(tester.element(find.byType(Scaffold))).clearSnackBars();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Microphone Calibration'), findsOneWidget);

    await tester.tap(find.text('+1.0'));
    await tester.pump();
    expect(find.text('+1.0 dB'), findsOneWidget);

    // Open Contact Us modal
    await tester.scrollUntilVisible(
      find.text('Contact Us'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Contact Us'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Contact Us'));
    await tester.pumpAndSettle();
    expect(find.text('leo.benveniste@gmail.com'), findsWidgets);

    controller.dispose();
  });

  testWidgets('Shows non-blocking permission banner when microphone permission is denied',
      (WidgetTester tester) async {
    final controller = await _makeController(permissionGranted: false);

    await tester.pumpWidget(LoudGuardApp(controller: controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('START METER'));
    await tester.pumpAndSettle();

    expect(find.text('ALLOW MIC'), findsOneWidget);

    controller.dispose();
  });
}
