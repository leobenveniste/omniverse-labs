import 'game_type.dart';

class GameSession {
  final String id;
  final GameType gameType;
  final String title;
  final DateTime dateStarted;
  DateTime? dateFinished;
  bool isFinished;
  String? winnerName;
  String stateJson; // Serialized game-specific state

  GameSession({
    required this.id,
    required this.gameType,
    required this.title,
    required this.dateStarted,
    this.dateFinished,
    this.isFinished = false,
    this.winnerName,
    required this.stateJson,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'gameType': gameType.name,
        'title': title,
        'dateStarted': dateStarted.toIso8601String(),
        'dateFinished': dateFinished?.toIso8601String(),
        'isFinished': isFinished,
        'winnerName': winnerName,
        'stateJson': stateJson,
      };

  factory GameSession.fromJson(Map<String, dynamic> json) => GameSession(
        id: json['id'] as String,
        gameType: GameType.values.firstWhere(
          (e) => e.name == json['gameType'],
          orElse: () => GameType.custom,
        ),
        title: json['title'] as String? ?? 'Partida',
        dateStarted: DateTime.parse(json['dateStarted'] as String),
        dateFinished: json['dateFinished'] != null
            ? DateTime.parse(json['dateFinished'] as String)
            : null,
        isFinished: json['isFinished'] as bool? ?? false,
        winnerName: json['winnerName'] as String?,
        stateJson: json['stateJson'] as String? ?? '{}',
      );
}
