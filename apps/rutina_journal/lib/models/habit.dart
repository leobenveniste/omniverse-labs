import 'habit_category.dart';

enum HabitType {
  boolean,
  counter,
  negative;

  String get localizationKey {
    switch (this) {
      case HabitType.boolean:
        return 'habitTypeBoolean';
      case HabitType.counter:
        return 'habitTypeCounter';
      case HabitType.negative:
        return 'habitTypeNegative';
    }
  }

  static HabitType fromString(String? val) {
    return HabitType.values.firstWhere(
      (t) => t.name == val,
      orElse: () => HabitType.boolean,
    );
  }
}

enum HabitFrequencyType {
  daily,
  weekly,
  monthly;

  String get localizationKey {
    switch (this) {
      case HabitFrequencyType.daily:
        return 'freqDaily';
      case HabitFrequencyType.weekly:
        return 'freqWeekly';
      case HabitFrequencyType.monthly:
        return 'freqMonthly';
    }
  }

  static HabitFrequencyType fromString(String? val) {
    return HabitFrequencyType.values.firstWhere(
      (f) => f.name == val,
      orElse: () => HabitFrequencyType.daily,
    );
  }
}

class Habit {
  final String id;
  final String title;
  final HabitCategory category;
  final HabitType type;
  final double targetValue;
  final String unit;
  final HabitFrequencyType frequencyType;
  final int frequencyTarget; // Target times per period (e.g. 3 times/week or 1 time/month)
  final List<int> frequencyDays; // 1 = Monday .. 7 = Sunday
  final String? reminderTime; // e.g. "08:00"
  final bool reminderEnabled;
  final DateTime createdAt;
  final bool archived;

  const Habit({
    required this.id,
    required this.title,
    required this.category,
    this.type = HabitType.boolean,
    this.targetValue = 1.0,
    this.unit = '',
    this.frequencyType = HabitFrequencyType.daily,
    this.frequencyTarget = 7,
    this.frequencyDays = const [1, 2, 3, 4, 5, 6, 7],
    this.reminderTime,
    this.reminderEnabled = false,
    required this.createdAt,
    this.archived = false,
  });

  bool isScheduledForWeekday(int weekday) {
    if (frequencyType != HabitFrequencyType.daily) return true;
    return frequencyDays.contains(weekday);
  }

  Habit copyWith({
    String? id,
    String? title,
    HabitCategory? category,
    HabitType? type,
    double? targetValue,
    String? unit,
    HabitFrequencyType? frequencyType,
    int? frequencyTarget,
    List<int>? frequencyDays,
    String? reminderTime,
    bool? reminderEnabled,
    DateTime? createdAt,
    bool? archived,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      unit: unit ?? this.unit,
      frequencyType: frequencyType ?? this.frequencyType,
      frequencyTarget: frequencyTarget ?? this.frequencyTarget,
      frequencyDays: frequencyDays ?? this.frequencyDays,
      reminderTime: reminderTime ?? this.reminderTime,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      createdAt: createdAt ?? this.createdAt,
      archived: archived ?? this.archived,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category.name,
        'type': type.name,
        'targetValue': targetValue,
        'unit': unit,
        'frequencyType': frequencyType.name,
        'frequencyTarget': frequencyTarget,
        'frequencyDays': frequencyDays,
        'reminderTime': reminderTime,
        'reminderEnabled': reminderEnabled,
        'createdAt': createdAt.toIso8601String(),
        'archived': archived,
      };

  factory Habit.fromJson(Map<String, dynamic> json) {
    final parsedFreqType = HabitFrequencyType.fromString(json['frequencyType'] as String?);
    final parsedDays = (json['frequencyDays'] as List<dynamic>?)
            ?.map((e) => e as int)
            .toList() ??
        const [1, 2, 3, 4, 5, 6, 7];
    final defaultTarget = parsedFreqType == HabitFrequencyType.daily
        ? parsedDays.length
        : (parsedFreqType == HabitFrequencyType.weekly ? 3 : 1);

    return Habit(
      id: json['id'] as String,
      title: json['title'] as String,
      category: HabitCategory.fromString(json['category'] as String?),
      type: HabitType.fromString(json['type'] as String?),
      targetValue: (json['targetValue'] as num?)?.toDouble() ?? 1.0,
      unit: json['unit'] as String? ?? '',
      frequencyType: parsedFreqType,
      frequencyTarget: (json['frequencyTarget'] as num?)?.toInt() ?? defaultTarget,
      frequencyDays: parsedDays,
      reminderTime: json['reminderTime'] as String?,
      reminderEnabled: json['reminderEnabled'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      archived: json['archived'] as bool? ?? false,
    );
  }
}
