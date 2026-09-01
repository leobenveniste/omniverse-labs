import 'player.dart';

class BurakoRoundTeamScore {
  final int base;
  final int puntos;

  BurakoRoundTeamScore({
    this.base = 0,
    this.puntos = 0,
  });

  int get total => base + puntos;

  Map<String, dynamic> toJson() => {
        'base': base,
        'puntos': puntos,
      };

  factory BurakoRoundTeamScore.fromJson(Map<String, dynamic> json) => BurakoRoundTeamScore(
        base: json['base'] as int? ?? 0,
        puntos: json['puntos'] as int? ?? 0,
      );
}

class BurakoRound {
  final int roundNumber;
  final String? starterTeamId; // ID of the team that started/lead this round
  final Map<String, BurakoRoundTeamScore> teamScores; // teamId -> score

  BurakoRound({
    required this.roundNumber,
    this.starterTeamId,
    required this.teamScores,
  });

  Map<String, dynamic> toJson() => {
        'roundNumber': roundNumber,
        'starterTeamId': starterTeamId,
        'teamScores': teamScores.map((k, v) => MapEntry(k, v.toJson())),
      };

  factory BurakoRound.fromJson(Map<String, dynamic> json) {
    final raw = json['teamScores'] as Map<String, dynamic>? ?? {};
    final scores = <String, BurakoRoundTeamScore>{};
    raw.forEach((k, v) {
      scores[k] = BurakoRoundTeamScore.fromJson(v as Map<String, dynamic>);
    });
    return BurakoRound(
      roundNumber: json['roundNumber'] as int,
      starterTeamId: json['starterTeamId'] as String?,
      teamScores: scores,
    );
  }
}

class BurakoGame {
  List<Player> teams;
  List<BurakoRound> rounds;
  int targetScore;
  bool isFinished;
  String? winnerId;

  BurakoGame({
    required this.teams,
    List<BurakoRound>? rounds,
    this.targetScore = 3000,
    this.isFinished = false,
    this.winnerId,
  }) : rounds = rounds ?? [];

  void addRound({
    required String? starterTeamId,
    required Map<String, BurakoRoundTeamScore> scores,
  }) {
    if (isFinished) return;
    final rNum = rounds.length + 1;
    rounds.add(BurakoRound(
      roundNumber: rNum,
      starterTeamId: starterTeamId,
      teamScores: scores,
    ));

    _recalculateTotals();
  }

  void undoLastRound() {
    if (rounds.isNotEmpty) {
      rounds.removeLast();
      isFinished = false;
      winnerId = null;
      _recalculateTotals();
    }
  }

  void _recalculateTotals() {
    for (var team in teams) {
      team.score = 0;
    }

    for (var r in rounds) {
      for (var team in teams) {
        final sc = r.teamScores[team.id];
        if (sc != null) {
          team.score += sc.total;
        }
      }
    }

    // Check if finished
    for (var team in teams) {
      if (team.score >= targetScore) {
        isFinished = true;
      }
    }

    if (isFinished) {
      Player best = teams.first;
      for (var t in teams) {
        if (t.score > best.score) best = t;
      }
      winnerId = best.id;
    }
  }

  Map<String, dynamic> toJson() => {
        'teams': teams.map((t) => t.toJson()).toList(),
        'rounds': rounds.map((r) => r.toJson()).toList(),
        'targetScore': targetScore,
        'isFinished': isFinished,
        'winnerId': winnerId,
      };

  factory BurakoGame.fromJson(Map<String, dynamic> json) => BurakoGame(
        teams: (json['teams'] as List<dynamic>)
            .map((e) => Player.fromJson(e as Map<String, dynamic>))
            .toList(),
        rounds: (json['rounds'] as List<dynamic>?)
            ?.map((e) => BurakoRound.fromJson(e as Map<String, dynamic>))
            .toList(),
        targetScore: json['targetScore'] as int? ?? 3000,
        isFinished: json['isFinished'] as bool? ?? false,
        winnerId: json['winnerId'] as String?,
      );
}
