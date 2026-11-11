import 'dart:math' as math;

const double kBaselineDbfsOffset = 96.0;
const double kMinDbSpl = 0.0;
const double kMaxDbSpl = 130.0;
const double kMinCalibrationOffset = -15.0;
const double kMaxCalibrationOffset = 15.0;
const int kMaxSavedChecks = 30;
const int kSparklineCapacity = 36;

enum AppLocale {
  en('en', 'English'),
  es('es', 'Español');

  const AppLocale(this.code, this.label);

  final String code;
  final String label;

  static AppLocale fromCode(String? code) {
    return AppLocale.values.firstWhere(
      (item) => item.code == code,
      orElse: () => AppLocale.en,
    );
  }
}

enum SafetyZone {
  safe,
  moderate,
  caution,
  damageRisk,
}

enum HapticThreshold {
  off(null),
  db85(85.0),
  db90(90.0),
  db95(95.0);

  const HapticThreshold(this.decibels);

  final double? decibels;

  static HapticThreshold fromStorage(String? value) {
    return HapticThreshold.values.firstWhere(
      (item) => item.name == value,
      orElse: () => HapticThreshold.db90,
    );
  }
}

/// NIOSH / WHO 3 dB exchange calculations for hearing-safety limits and cumulative dose.
abstract final class ExposureMath {
  static double convertDbfsToSpl(
    double dbfs, {
    double calibrationOffsetDb = 0.0,
  }) {
    final raw = dbfs + kBaselineDbfsOffset + calibrationOffsetDb;
    return raw.clamp(kMinDbSpl, kMaxDbSpl);
  }

  static SafetyZone classify(double dbSpl) {
    if (dbSpl < 70.0) return SafetyZone.safe;
    if (dbSpl < 85.0) return SafetyZone.moderate;
    if (dbSpl < 95.0) return SafetyZone.caution;
    return SafetyZone.damageRisk;
  }

  /// Returns safe exposure duration using NIOSH 3 dB exchange (85 dB = 8 hours).
  /// Returns `null` when below 75 dB (practically safe for 24h+ continuous listening).
  static Duration? safeExposureDuration(double dbSpl) {
    if (dbSpl < 75.0) return null;
    final safeHours = 8.0 * math.pow(2.0, (85.0 - dbSpl) / 3.0);
    if (safeHours >= 24.0) return null;
    final seconds = (safeHours * 3600.0).round().clamp(1, 86400);
    return Duration(seconds: seconds);
  }

  /// Returns incremental daily noise dose fraction (0.0..1.0+) for [elapsedSeconds] at [dbSpl].
  static double doseIncrementFraction(double dbSpl, double elapsedSeconds) {
    if (elapsedSeconds <= 0 || dbSpl < 75.0) return 0.0;
    final safeHours = 8.0 * math.pow(2.0, (85.0 - dbSpl) / 3.0);
    final safeSeconds = safeHours * 3600.0;
    if (safeSeconds <= 0) return 0.0;
    return elapsedSeconds / safeSeconds;
  }

  static String formatDurationCompact(Duration duration) {
    final totalSeconds = duration.inSeconds;
    if (totalSeconds < 60) {
      return '${totalSeconds}s';
    }
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    }
    if (minutes >= 10) {
      return '${minutes}m';
    }
    return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
  }
}

class SoundCheckLog {
  const SoundCheckLog({
    required this.id,
    required this.label,
    required this.avgDb,
    required this.peakDb,
    required this.minDb,
    required this.durationSeconds,
    required this.dosePercent,
    required this.createdAtMs,
  });

  final String id;
  final String label;
  final double avgDb;
  final double peakDb;
  final double minDb;
  final int durationSeconds;
  final double dosePercent;
  final int createdAtMs;

  SafetyZone get zone => ExposureMath.classify(avgDb);

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'avgDb': avgDb,
        'peakDb': peakDb,
        'minDb': minDb,
        'durationSeconds': durationSeconds,
        'dosePercent': dosePercent,
        'createdAtMs': createdAtMs,
      };

  factory SoundCheckLog.fromJson(Map<String, dynamic> json) {
    return SoundCheckLog(
      id: (json['id'] as String?) ?? '',
      label: (json['label'] as String?) ?? 'Sound Check',
      avgDb: ((json['avgDb'] as num?) ?? 0).toDouble(),
      peakDb: ((json['peakDb'] as num?) ?? 0).toDouble(),
      minDb: ((json['minDb'] as num?) ?? 0).toDouble(),
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      dosePercent: ((json['dosePercent'] as num?) ?? 0).toDouble(),
      createdAtMs: (json['createdAtMs'] as num?)?.toInt() ?? 0,
    );
  }
}
