import '../models/pulse_models.dart';

/// Rolling tap-tempo calculator with idle timeout reset and BPM clamping.
class TapTempoCalculator {
  TapTempoCalculator({
    this.maxSamples = 6,
    this.resetGapMs = 2000,
    this.minBpm = kMinBpm,
    this.maxBpm = kMaxBpm,
  });

  final int maxSamples;
  final int resetGapMs;
  final int minBpm;
  final int maxBpm;

  final List<int> _tapTimestampsMs = [];

  int get tapCount => _tapTimestampsMs.length;

  void reset() => _tapTimestampsMs.clear();

  /// Registers a tap at [timestampMs] and returns a new BPM once >= 2 consecutive taps exist.
  int? registerTap(int timestampMs) {
    if (_tapTimestampsMs.isNotEmpty) {
      final delta = timestampMs - _tapTimestampsMs.last;
      if (delta <= 0 || delta > resetGapMs) {
        _tapTimestampsMs.clear();
      }
    }

    _tapTimestampsMs.add(timestampMs);
    if (_tapTimestampsMs.length > maxSamples) {
      _tapTimestampsMs.removeAt(0);
    }

    if (_tapTimestampsMs.length < 2) {
      return null;
    }

    final intervals = <int>[];
    for (var i = 1; i < _tapTimestampsMs.length; i++) {
      intervals.add(_tapTimestampsMs[i] - _tapTimestampsMs[i - 1]);
    }

    final avgIntervalMs =
        intervals.reduce((a, b) => a + b) / intervals.length;
    if (avgIntervalMs <= 0) return null;

    final rawBpm = (60000.0 / avgIntervalMs).round();
    return rawBpm.clamp(minBpm, maxBpm);
  }
}
