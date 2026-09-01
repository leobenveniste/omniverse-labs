import 'player.dart';

class DiezMilRound {
  final int roundNumber;
  final Map<String, int> turnScores; // playerId -> points scored in this turn

  DiezMilRound({
    required this.roundNumber,
    required this.turnScores,
  });

  Map<String, dynamic> toJson() => {
        'roundNumber': roundNumber,
        'turnScores': turnScores,
      };

  factory DiezMilRound.fromJson(Map<String, dynamic> json) => DiezMilRound(
        roundNumber: json['roundNumber'] as int,
        turnScores: (json['turnScores'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, v as int)),
      );
}

class DiezMilGame {
  List<Player> players;
  List<DiezMilRound> rounds;
  int targetScore;
  int entryScore; // Minimum points required in a turn to "open/enter" (e.g. 750 or 0)
  bool isFinished;
  String? winnerId;

  DiezMilGame({
    required this.players,
    List<DiezMilRound>? rounds,
    this.targetScore = 10000,
    this.entryScore = 750,
    this.isFinished = false,
    this.winnerId,
  }) : rounds = rounds ?? [];

  bool hasPlayerEntered(String playerId) {
    if (entryScore <= 0) return true;
    for (var r in rounds) {
      final score = r.turnScores[playerId] ?? 0;
      if (score >= entryScore) return true;
    }
    return false;
  }

  void addRound(Map<String, int> scores) {
    if (isFinished) return;
    final rNum = rounds.length + 1;
    rounds.add(DiezMilRound(roundNumber: rNum, turnScores: scores));

    _recalculateScores();
  }

  void undoLastRound() {
    if (rounds.isNotEmpty) {
      rounds.removeLast();
      isFinished = false;
      winnerId = null;
      _recalculateScores();
    }
  }

  void _recalculateScores() {
    for (var p in players) {
      p.score = 0;
    }

    for (var r in rounds) {
      for (var p in players) {
        final pts = r.turnScores[p.id] ?? 0;
        p.score += pts;
      }
    }

    // Check winner
    for (var p in players) {
      if (p.score >= targetScore) {
        isFinished = true;
      }
    }

    if (isFinished) {
      Player best = players.first;
      for (var p in players) {
        if (p.score > best.score) best = p;
      }
      winnerId = best.id;
    }
  }

  Map<String, dynamic> toJson() => {
        'players': players.map((p) => p.toJson()).toList(),
        'rounds': rounds.map((r) => r.toJson()).toList(),
        'targetScore': targetScore,
        'entryScore': entryScore,
        'isFinished': isFinished,
        'winnerId': winnerId,
      };

  factory DiezMilGame.fromJson(Map<String, dynamic> json) => DiezMilGame(
        players: (json['players'] as List<dynamic>)
            .map((e) => Player.fromJson(e as Map<String, dynamic>))
            .toList(),
        rounds: (json['rounds'] as List<dynamic>?)
            ?.map((e) => DiezMilRound.fromJson(e as Map<String, dynamic>))
            .toList(),
        targetScore: json['targetScore'] as int? ?? 10000,
        entryScore: json['entryScore'] as int? ?? 750,
        isFinished: json['isFinished'] as bool? ?? false,
        winnerId: json['winnerId'] as String?,
      );
}
