import 'dart:async';

import '../models/pulse_models.dart';
import 'haptic_driver.dart';

typedef BeatCallback = void Function(int beatIndex, bool isAccent);

/// Drift-compensated beat scheduler built on monotonic [Stopwatch] timing.
class MetronomeEngine {
  MetronomeEngine({
    required this._hapticDriver,
    required this._onBeat,
  });

  final HapticDriver _hapticDriver;
  final BeatCallback _onBeat;

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _nextTimer;

  bool _isRunning = false;
  int _bpm = kDefaultBpm;
  int _beatsPerBar = TimeSignatureOption.fourFour.beatsPerBar;
  HapticStrength _strength = HapticStrength.strong;
  int _beatIndex = 0;
  int _nextDeadlineUs = 0;

  bool get isRunning => _isRunning;
  int get bpm => _bpm;
  int get beatsPerBar => _beatsPerBar;

  int get intervalUs => (60000000 / _bpm).round();

  void configure({
    required int bpm,
    required int beatsPerBar,
    required HapticStrength strength,
  }) {
    final clampedBpm = bpm.clamp(kMinBpm, kMaxBpm);
    final bpmChanged = clampedBpm != _bpm;
    _bpm = clampedBpm;
    _beatsPerBar = beatsPerBar.clamp(1, 16);
    _strength = strength;
    if (_beatIndex >= _beatsPerBar) {
      _beatIndex = 0;
    }

    if (_isRunning && bpmChanged) {
      // Re-anchor next beat from current monotonic clock to avoid sudden burst or lag.
      _nextTimer?.cancel();
      _nextDeadlineUs = _stopwatch.elapsedMicroseconds + intervalUs;
      _scheduleNextBeat();
    }
  }

  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _beatIndex = 0;
    _stopwatch
      ..reset()
      ..start();
    _nextDeadlineUs = 0;
    _fireBeatAndSchedule();
  }

  void stop() {
    if (!_isRunning) return;
    _isRunning = false;
    _nextTimer?.cancel();
    _nextTimer = null;
    _stopwatch.stop();
  }

  void _fireBeatAndSchedule() {
    if (!_isRunning) return;
    final currentBeat = _beatIndex % _beatsPerBar;
    final isAccent = currentBeat == 0;

    unawaited(_hapticDriver.pulse(isAccent: isAccent, strength: _strength));
    _onBeat(currentBeat, isAccent);

    _beatIndex = (currentBeat + 1) % _beatsPerBar;
    _nextDeadlineUs += intervalUs;
    _scheduleNextBeat();
  }

  void _scheduleNextBeat() {
    if (!_isRunning) return;
    final remainingUs = _nextDeadlineUs - _stopwatch.elapsedMicroseconds;
    final delayUs = remainingUs < 0 ? 0 : remainingUs;
    _nextTimer = Timer(Duration(microseconds: delayUs), _fireBeatAndSchedule);
  }

  void dispose() {
    stop();
  }
}
