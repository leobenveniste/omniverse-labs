import 'package:flutter/material.dart';

class Player {
  final String id;
  String name;
  int score;
  int colorValue;
  bool isEliminated;
  int rehookCount; // Reenganches en Chinchon

  Player({
    required this.id,
    required this.name,
    this.score = 0,
    required this.colorValue,
    this.isEliminated = false,
    this.rehookCount = 0,
  });

  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'score': score,
        'colorValue': colorValue,
        'isEliminated': isEliminated,
        'rehookCount': rehookCount,
      };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        id: json['id'] as String,
        name: json['name'] as String,
        score: json['score'] as int? ?? 0,
        colorValue: json['colorValue'] as int? ?? 0xFF2196F3,
        isEliminated: json['isEliminated'] as bool? ?? false,
        rehookCount: json['rehookCount'] as int? ?? 0,
      );

  Player copyWith({
    String? id,
    String? name,
    int? score,
    int? colorValue,
    bool? isEliminated,
    int? rehookCount,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      score: score ?? this.score,
      colorValue: colorValue ?? this.colorValue,
      isEliminated: isEliminated ?? this.isEliminated,
      rehookCount: rehookCount ?? this.rehookCount,
    );
  }
}
