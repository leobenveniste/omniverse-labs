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

class Habit {
  final String id;
  final String title;
  final HabitCategory category;
  final HabitType type;
  final double targetValue;
  final String unit;
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
    this.frequencyDays = const [1, 2, 3, 4, 5, 6, 7],
    this.reminderTime,
    this.reminderEnabled = false,
    required this.createdAt,
    this.archived = false,
  });

  bool isScheduledForWeekday(int weekday) {
    return frequencyDays.contains(weekday);
  }

  Habit copyWith({
    String? id,
    String? title,
    HabitCategory? category,
    HabitType? type,
    double? targetValue,
    String? unit,
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
        'frequencyDays': frequencyDays,
        'reminderTime': reminderTime,
        'reminderEnabled': reminderEnabled,
        'createdAt': createdAt.toIso8601String(),
        'archived': archived,
      };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
        id: json['id'] as String,
        title: json['title'] as String,
        category: HabitCategory.fromString(json['category'] as String?),
        type: HabitType.fromString(json['type'] as String?),
        targetValue: (json['targetValue'] as num?)?.toDouble() ?? 1.0,
        unit: json['unit'] as String? ?? '',
        frequencyDays: (json['frequencyDays'] as List<dynamic>?)
                ?.map((e) => e as int)
                .toList() ??
            const [1, 2, 3, 4, 5, 6, 7],
        reminderTime: json['reminderTime'] as String?,
        reminderEnabled: json['reminderEnabled'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        archived: json['archived'] as bool? ?? false,
      );
}
