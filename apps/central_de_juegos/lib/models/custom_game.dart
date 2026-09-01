import 'player.dart';

class CustomGame {
  List<Player> players;
  int step;
  int? targetScore;
  bool isFinished;
  String? winnerId;

  CustomGame({
    required this.players,
    this.step = 1,
    this.targetScore,
    this.isFinished = false,
    this.winnerId,
  });

  void addScore(String playerId, int amount) {
    for (var p in players) {
      if (p.id == playerId) {
        p.score += amount;
        if (targetScore != null && p.score >= targetScore!) {
          isFinished = true;
          winnerId = p.id;
        }
        break;
      }
    }
  }

  void resetScores() {
    for (var p in players) {
      p.score = 0;
    }
    isFinished = false;
    winnerId = null;
  }

  Map<String, dynamic> toJson() => {
        'players': players.map((p) => p.toJson()).toList(),
        'step': step,
        'targetScore': targetScore,
        'isFinished': isFinished,
        'winnerId': winnerId,
      };

  factory CustomGame.fromJson(Map<String, dynamic> json) => CustomGame(
        players: (json['players'] as List<dynamic>)
            .map((e) => Player.fromJson(e as Map<String, dynamic>))
            .toList(),
        step: json['step'] as int? ?? 1,
        targetScore: json['targetScore'] as int?,
        isFinished: json['isFinished'] as bool? ?? false,
        winnerId: json['winnerId'] as String?,
      );
}
