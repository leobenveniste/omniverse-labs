import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_pocket/l10n/app_strings.dart';
import 'package:pulse_pocket/models/pulse_models.dart';
import 'package:pulse_pocket/services/haptic_driver.dart';
import 'package:pulse_pocket/services/metronome_engine.dart';
import 'package:pulse_pocket/services/pulse_controller.dart';
import 'package:pulse_pocket/services/pulse_storage.dart';
import 'package:pulse_pocket/services/tap_tempo_calculator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('TapTempoCalculator', () {
    test('requires at least 2 taps and averages interval accurately', () {
      final calc = TapTempoCalculator();
      expect(calc.registerTap(1000), isNull);
      expect(calc.registerTap(1500), 120); // 500ms -> 120 BPM
      expect(calc.registerTap(2000), 120);
      expect(calc.registerTap(2500), 120);
    });

    test('clamps extreme speeds and resets after >2000ms pause', () {
      final calc = TapTempoCalculator();
      calc.registerTap(1000);
      expect(calc.registerTap(1100), kMaxBpm); // 100ms -> 600 BPM clamped to 260

      // Idle gap > 2000ms resets window
      expect(calc.registerTap(5000), isNull);
      expect(calc.tapCount, 1);
      expect(calc.registerTap(7000), 30); // 2000ms -> 30 BPM
    });
  });

  group('SetlistSlot & MetronomeEngine', () {
    test('SetlistSlot JSON round-trip clamps BPM safely', () {
      final slot = SetlistSlot.fromJson({
        'id': 'slot-1',
        'name': 'Chorus',
        'bpm': 999,
        'signature': 'sixEight',
      });
      expect(slot, isNotNull);
      expect(slot!.bpm, kMaxBpm);
      expect(slot.signature, TimeSignatureOption.sixEight);
      expect(slot.toJson()['name'], 'Chorus');
    });

    test('MetronomeEngine emits Beat 1 accent on start and wraps meter', () async {
      final haptic = NoopHapticDriver();
      final beats = <({int beat, bool accent})>[];
      final engine = MetronomeEngine(
        hapticDriver: haptic,
        onBeat: (beat, isAccent) => beats.add((beat: beat, accent: isAccent)),
      )..configure(
          bpm: 240, // 250ms per beat
          beatsPerBar: 3,
          strength: HapticStrength.stageMax,
        );

      engine.start();
      await Future<void>.delayed(const Duration(milliseconds: 560));
      engine.stop();
      engine.dispose();

      expect(beats.length, greaterThanOrEqualTo(2));
      expect(beats.first.beat, 0);
      expect(beats.first.accent, isTrue);
      expect(beats[1].beat, 1);
      expect(beats[1].accent, isFalse);
      expect(haptic.pulses.first.isAccent, isTrue);
      expect(haptic.pulses.first.strength, HapticStrength.stageMax);
    });
  });

  group('PulseController persistence & Pocket Lock lifecycle', () {
    test('saves setlist slots, settings, and toggles wakelock across Pocket Lock', () async {
      SharedPreferences.setMockInitialValues({});
      final wakelockLog = <bool>[];
      final haptic = NoopHapticDriver();
      final storage = await PulseStorage.open();
      final controller = PulseController(
        storage: storage,
        hapticDriver: haptic,
        onWakelockChanged: (enabled) async => wakelockLog.add(enabled),
      );

      await controller.initialize();
      expect(controller.slots.length, 3); // Seeded starter slots on first install
      expect(controller.bpm, kDefaultBpm);

      final saved = await controller.saveSlot(
        name: 'Bridge',
        bpm: 145,
        signature: TimeSignatureOption.threeFour,
      );
      expect(saved, isTrue);
      expect(controller.slots.length, 4);
      expect(controller.bpm, 145);
      expect(controller.signature, TimeSignatureOption.threeFour);

      await controller.setThemeMode(ThemeMode.light);
      await controller.setLocale(AppLocale.es);
      await controller.setHapticStrength(HapticStrength.stageMax);
      await controller.setVisualFlashEnabled(false);

      await controller.engagePocketLock();
      expect(controller.isPocketLocked, isTrue);
      expect(controller.isRunning, isTrue);
      expect(wakelockLog.last, isTrue);

      await controller.unlockPocketLock();
      expect(controller.isPocketLocked, isFalse);
      expect(haptic.unlockPulses, 1);
      expect(controller.isRunning, isTrue);

      await controller.stop();
      expect(wakelockLog.last, isFalse);
      controller.dispose();

      // Re-open storage to verify persistence
      final storage2 = await PulseStorage.open();
      final controller2 = PulseController(
        storage: storage2,
        hapticDriver: NoopHapticDriver(),
        onWakelockChanged: (_) async {},
      );
      await controller2.initialize();
      expect(controller2.bpm, 145);
      expect(controller2.signature, TimeSignatureOption.threeFour);
      expect(controller2.slots.length, 4);
      expect(controller2.themeMode, ThemeMode.light);
      expect(controller2.locale, AppLocale.es);
      expect(controller2.hapticStrength, HapticStrength.stageMax);
      expect(controller2.visualFlashEnabled, isFalse);
      controller2.dispose();
    });
  });
}
