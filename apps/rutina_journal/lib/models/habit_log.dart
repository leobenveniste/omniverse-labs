class HabitLog {
  final String id;
  final String habitId;
  final String dateKey; // Format: "yyyy-MM-dd"
  final double currentValue;
  final bool completed;
  final DateTime? completedAt;
  final String? note;

  const HabitLog({
    required this.id,
    required this.habitId,
    required this.dateKey,
    required this.currentValue,
    required this.completed,
    this.completedAt,
    this.note,
  });

  HabitLog copyWith({
    String? id,
    String? habitId,
    String? dateKey,
    double? currentValue,
    bool? completed,
    DateTime? completedAt,
    String? note,
  }) {
    return HabitLog(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      dateKey: dateKey ?? this.dateKey,
      currentValue: currentValue ?? this.currentValue,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'habitId': habitId,
        'dateKey': dateKey,
        'currentValue': currentValue,
        'completed': completed,
        'completedAt': completedAt?.toIso8601String(),
        'note': note,
      };

  factory HabitLog.fromJson(Map<String, dynamic> json) => HabitLog(
        id: json['id'] as String,
        habitId: json['habitId'] as String,
        dateKey: json['dateKey'] as String,
        currentValue: (json['currentValue'] as num?)?.toDouble() ?? 0.0,
        completed: json['completed'] as bool? ?? false,
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
        note: json['note'] as String?,
      );
}
