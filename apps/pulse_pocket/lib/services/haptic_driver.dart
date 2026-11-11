import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

import '../models/pulse_models.dart';

/// Abstraction for hardware haptic output so unit and widget tests remain deterministic.
abstract interface class HapticDriver {
  Future<void> initialize();
  Future<void> pulse({required bool isAccent, required HapticStrength strength});
  Future<void> pulseUnlock();
}

/// Platform haptic driver preferring custom-amplitude Vibration on Android with HapticFeedback fallback.
class PlatformHapticDriver implements HapticDriver {
  bool _hasVibrator = false;
  bool _hasAmplitude = false;
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      _hasVibrator = await Vibration.hasVibrator();
      if (_hasVibrator) {
        _hasAmplitude = await Vibration.hasAmplitudeControl();
      }
    } on MissingPluginException {
      _hasVibrator = false;
    } on PlatformException {
      _hasVibrator = false;
    }
  }

  @override
  Future<void> pulse({
    required bool isAccent,
    required HapticStrength strength,
  }) async {
    if (!_initialized) {
      await initialize();
    }
    if (_hasVibrator) {
      final duration = isAccent ? strength.accentMs : strength.regularMs;
      final amplitude = isAccent ? strength.accentAmp : strength.regularAmp;
      try {
        if (_hasAmplitude) {
          await Vibration.vibrate(duration: duration, amplitude: amplitude);
        } else {
          await Vibration.vibrate(duration: duration);
        }
        return;
      } on MissingPluginException {
        // Fall through to Flutter HapticFeedback.
      } on PlatformException {
        // Fall through to Flutter HapticFeedback.
      }
    }

    if (isAccent) {
      await HapticFeedback.heavyImpact();
    } else if (strength == HapticStrength.normal) {
      await HapticFeedback.lightImpact();
    } else {
      await HapticFeedback.mediumImpact();
    }
  }

  @override
  Future<void> pulseUnlock() async {
    await pulse(isAccent: true, strength: HapticStrength.strong);
  }
}

/// No-op haptic driver for deterministic testing.
class NoopHapticDriver implements HapticDriver {
  final List<({bool isAccent, HapticStrength strength})> pulses = [];
  int unlockPulses = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> pulse({
    required bool isAccent,
    required HapticStrength strength,
  }) async {
    pulses.add((isAccent: isAccent, strength: strength));
  }

  @override
  Future<void> pulseUnlock() async {
    unlockPulses++;
  }
}
