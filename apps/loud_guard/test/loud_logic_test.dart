import 'package:flutter_test/flutter_test.dart';
import 'package:loud_guard/models/loud_models.dart';
import 'package:loud_guard/services/audio_meter_driver.dart';
import 'package:loud_guard/services/loud_controller.dart';
import 'package:loud_guard/services/loud_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ExposureMath', () {
    test('converts dBFS to SPL with calibration offset and clamps cleanly', () {
      expect(ExposureMath.convertDbfsToSpl(-30.0), 66.0);
      expect(
        ExposureMath.convertDbfsToSpl(-30.0, calibrationOffsetDb: 4.5),
        70.5,
      );
      expect(ExposureMath.convertDbfsToSpl(-96.0, calibrationOffsetDb: -5.0), 0.0);
      expect(ExposureMath.convertDbfsToSpl(0.0, calibrationOffsetDb: 40.0), 130.0);
    });

    test('classifies safety zones accurately', () {
      expect(ExposureMath.classify(45.0), SafetyZone.safe);
      expect(ExposureMath.classify(69.9), SafetyZone.safe);
      expect(ExposureMath.classify(70.0), SafetyZone.moderate);
      expect(ExposureMath.classify(84.9), SafetyZone.moderate);
      expect(ExposureMath.classify(85.0), SafetyZone.caution);
      expect(ExposureMath.classify(94.9), SafetyZone.caution);
      expect(ExposureMath.classify(95.0), SafetyZone.damageRisk);
    });

    test('computes WHO / NIOSH 3 dB exchange safe durations', () {
      expect(ExposureMath.safeExposureDuration(65.0), isNull);
      expect(ExposureMath.safeExposureDuration(85.0), const Duration(hours: 8));
      expect(ExposureMath.safeExposureDuration(88.0), const Duration(hours: 4));
      expect(ExposureMath.safeExposureDuration(94.0), const Duration(hours: 1));
      expect(
        ExposureMath.safeExposureDuration(100.0),
        const Duration(minutes: 15),
      );
    });

    test('computes noise dose fraction increment', () {
      expect(ExposureMath.doseIncrementFraction(60.0, 3600), 0.0);
      expect(
        ExposureMath.doseIncrementFraction(85.0, 3600),
        closeTo(0.125, 0.001),
      );
      expect(
        ExposureMath.doseIncrementFraction(94.0, 1800),
        closeTo(0.5, 0.001),
      );
    });
  });

  group('LoudController', () {
    test('tracks live samples, triggers haptic cooldown, and persists checks', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await LoudStorage.open();
      final driver = FakeAudioMeterDriver();
      var currentTime = DateTime(2026, 11, 11, 16, 0, 0);
      var hapticCount = 0;

      final controller = LoudController(
        storage: storage,
        driver: driver,
        wakelockHandler: (_) async {},
        thresholdHapticHandler: () async => hapticCount++,
        nowProvider: () => currentTime,
      );
      await controller.initialize();

      expect(await controller.startMeter(), isTrue);
      expect(controller.isRunning, isTrue);

      driver.emitSplForBaseline(60.0);
      await Future<void>.delayed(Duration.zero);
      expect(controller.minDb, 60.0);
      expect(controller.peakDb, 60.0);
      expect(hapticCount, 0);

      // Cross default 90 dB threshold -> triggers once, then respects 10s cooldown.
      driver.emitSplForBaseline(94.0);
      await Future<void>.delayed(Duration.zero);
      expect(hapticCount, 1);

      currentTime = currentTime.add(const Duration(seconds: 4));
      driver.emitSplForBaseline(96.0);
      await Future<void>.delayed(Duration.zero);
      expect(hapticCount, 1);

      currentTime = currentTime.add(const Duration(seconds: 12));
      driver.emitSplForBaseline(95.0);
      await Future<void>.delayed(Duration.zero);
      expect(hapticCount, 2);

      expect(controller.peakDb, 96.0);

      final saved = await controller.saveCurrentCheck('Main Stage');
      expect(saved, isNotNull);
      expect(controller.savedChecks.length, 1);
      expect(controller.savedChecks.first.label, 'Main Stage');

      await controller.adjustCalibrationOffset(1.5);
      expect(controller.calibrationOffsetDb, 1.5);

      await controller.pauseMeter();
      expect(controller.isRunning, isFalse);

      await controller.deleteSavedCheck(saved!.id);
      expect(controller.savedChecks, isEmpty);

      controller.dispose();
    });
  });
}
