/// Allowed BPM bounds across tap tempo, sliders, and setlists.
const int kMinBpm = 30;
const int kMaxBpm = 260;
const int kDefaultBpm = 120;
const int kMaxSetlistSlots = 12;

/// Musical meter options supported on the Stage Console.
enum TimeSignatureOption {
  twoFour('2/4', 2),
  threeFour('3/4', 3),
  fourFour('4/4', 4),
  fiveFour('5/4', 5),
  sixEight('6/8', 6),
  sevenEight('7/8', 7);

  const TimeSignatureOption(this.label, this.beatsPerBar);

  final String label;
  final int beatsPerBar;

  static TimeSignatureOption fromName(String? value) {
    return TimeSignatureOption.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TimeSignatureOption.fourFour,
    );
  }
}

/// Three-stage motor strength calibration for pocket or stage mounting.
enum HapticStrength {
  normal(accentMs: 32, accentAmp: 175, regularMs: 18, regularAmp: 110),
  strong(accentMs: 52, accentAmp: 230, regularMs: 28, regularAmp: 165),
  stageMax(accentMs: 78, accentAmp: 255, regularMs: 42, regularAmp: 225);

  const HapticStrength({
    required this.accentMs,
    required this.accentAmp,
    required this.regularMs,
    required this.regularAmp,
  });

  final int accentMs;
  final int accentAmp;
  final int regularMs;
  final int regularAmp;

  static HapticStrength fromName(String? value) {
    return HapticStrength.values.firstWhere(
      (e) => e.name == value,
      orElse: () => HapticStrength.strong,
    );
  }
}

/// 1-Tap setlist song slot storing song label, tempo, and meter.
class SetlistSlot {
  const SetlistSlot({
    required this.id,
    required this.name,
    required this.bpm,
    required this.signature,
  });

  final String id;
  final String name;
  final int bpm;
  final TimeSignatureOption signature;

  SetlistSlot copyWith({
    String? id,
    String? name,
    int? bpm,
    TimeSignatureOption? signature,
  }) {
    return SetlistSlot(
      id: id ?? this.id,
      name: name ?? this.name,
      bpm: (bpm ?? this.bpm).clamp(kMinBpm, kMaxBpm),
      signature: signature ?? this.signature,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'bpm': bpm,
        'signature': signature.name,
      };

  static SetlistSlot? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final bpm = json['bpm'];
    if (id is! String || id.isEmpty || name is! String || name.trim().isEmpty) {
      return null;
    }
    final parsedBpm = bpm is int ? bpm : int.tryParse(bpm?.toString() ?? '');
    if (parsedBpm == null) return null;
    return SetlistSlot(
      id: id,
      name: name.trim(),
      bpm: parsedBpm.clamp(kMinBpm, kMaxBpm),
      signature: TimeSignatureOption.fromName(json['signature'] as String?),
    );
  }
}
