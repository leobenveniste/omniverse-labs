import 'package:flutter/material.dart';

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
  final String iconName;
  final List<RoutineStep> steps;
  final List<String> tiedHabitIds;
  final String? reminderTime;
  final bool reminderEnabled;

  const Routine({
    required this.id,
    required this.title,
    required this.description,
    this.iconName = 'wb_sunny',
    required this.steps,
    this.tiedHabitIds = const [],
    this.reminderTime,
    this.reminderEnabled = false,
  });

  int get totalMinutes {
    final totalSec = steps.fold<int>(0, (sum, s) => sum + s.durationSeconds);
    return (totalSec / 60).ceil();
  }

  IconData get icon {
    switch (iconName) {
      case 'nightlight_round':
      case 'bedtime':
        return Icons.bedtime_rounded;
      case 'laptop_mac':
      case 'work':
        return Icons.laptop_mac_rounded;
      case 'fitness_center':
        return Icons.fitness_center_rounded;
      case 'directions_run':
        return Icons.directions_run_rounded;
      case 'coffee':
        return Icons.coffee_rounded;
      case 'menu_book':
        return Icons.menu_book_rounded;
      case 'spa':
        return Icons.spa_rounded;
      case 'self_improvement':
        return Icons.self_improvement_rounded;
      case 'center_focus_strong':
        return Icons.center_focus_strong_rounded;
      case 'timer':
        return Icons.timer_rounded;
      case 'wb_sunny':
      default:
        return Icons.wb_sunny_rounded;
    }
  }

  Routine copyWith({
    String? id,
    String? title,
    String? description,
    String? iconName,
    List<RoutineStep>? steps,
    List<String>? tiedHabitIds,
    String? reminderTime,
    bool? reminderEnabled,
  }) {
    return Routine(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
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
        'iconName': iconName,
        'steps': steps.map((s) => s.toJson()).toList(),
        'tiedHabitIds': tiedHabitIds,
        'reminderTime': reminderTime,
        'reminderEnabled': reminderEnabled,
      };

  factory Routine.fromJson(Map<String, dynamic> json) => Routine(
        id: json['id'] as String,
        title: json['title'] as String,
        description: (json['description'] as String?) ?? '',
        iconName: (json['iconName'] as String?) ?? 'wb_sunny',
        steps: (json['steps'] as List<dynamic>?)
                ?.map((s) => RoutineStep.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
        tiedHabitIds: (json['tiedHabitIds'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        reminderTime: json['reminderTime'] as String?,
        reminderEnabled: (json['reminderEnabled'] as bool?) ?? false,
      );
}
