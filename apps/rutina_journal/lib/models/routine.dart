class RoutineStep {
  final String id;
  final String title;
  final int durationSeconds;
  final String? description;

  const RoutineStep({
    required this.id,
    required this.title,
    required this.durationSeconds,
    this.description,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'durationSeconds': durationSeconds,
        'description': description,
      };

  factory RoutineStep.fromJson(Map<String, dynamic> json) => RoutineStep(
        id: json['id'] as String,
        title: json['title'] as String,
        durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 300,
        description: json['description'] as String?,
      );
}

class Routine {
  final String id;
  final String title;
  final String description;
  final List<RoutineStep> steps;
  final List<String> tiedHabitIds;
  final String? reminderTime;
  final bool reminderEnabled;

  const Routine({
    required this.id,
    required this.title,
    required this.description,
    required this.steps,
    this.tiedHabitIds = const [],
    this.reminderTime,
    this.reminderEnabled = false,
  });

  int get totalMinutes {
    final totalSec = steps.fold<int>(0, (sum, s) => sum + s.durationSeconds);
    return (totalSec / 60).ceil();
  }

  Routine copyWith({
    String? id,
    String? title,
    String? description,
    List<RoutineStep>? steps,
    List<String>? tiedHabitIds,
    String? reminderTime,
    bool? reminderEnabled,
  }) {
    return Routine(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      steps: steps ?? this.steps,
      tiedHabitIds: tiedHabitIds ?? this.tiedHabitIds,
      reminderTime: reminderTime ?? this.reminderTime,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'steps': steps.map((s) => s.toJson()).toList(),
        'tiedHabitIds': tiedHabitIds,
        'reminderTime': reminderTime,
        'reminderEnabled': reminderEnabled,
      };

  factory Routine.fromJson(Map<String, dynamic> json) => Routine(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        steps: (json['steps'] as List<dynamic>?)
                ?.map((s) => RoutineStep.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
        tiedHabitIds: (json['tiedHabitIds'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        reminderTime: json['reminderTime'] as String?,
        reminderEnabled: json['reminderEnabled'] as bool? ?? false,
      );
}
