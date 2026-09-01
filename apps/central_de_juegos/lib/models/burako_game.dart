import 'player.dart';

class BurakoRoundEntry {
  final int pureCanastas; // 200 pts c/u
  final int impureCanastas; // 100 pts c/u
  final bool hasClosed; // 100 pts
  final bool tookDead; // Muerto tomado (si no, -100)
  final int tableCardPoints;
  final int handCardPenalty; // Restan

  BurakoRoundEntry({
    this.pureCanastas = 0,
    this.impureCanastas = 0,
    this.hasClosed = false,
    this.tookDead = true,
    this.tableCardPoints = 0,
    this.handCardPenalty = 0,
  });

  int calculateTotal() {
    int score = (pureCanastas * 200) + (impureCanastas * 100);
    if (hasClosed) score += 100;
    if (!tookDead) score -= 100;
    score += tableCardPoints;
    score -= handCardPenalty;
    return score;
  }

  Map<String, dynamic> toJson() => {
        'pureCanastas': pureCanastas,
        'impureCanastas': impureCanastas,
        'hasClosed': hasClosed,
        'tookDead': tookDead,
        'tableCardPoints': tableCardPoints,
        'handCardPenalty': handCardPenalty,
      };

  factory BurakoRoundEntry.fromJson(Map<String, dynamic> json) => BurakoRoundEntry(
        pureCanastas: json['pureCanastas'] as int? ?? 0,
        impureCanastas: json['impureCanastas'] as int? ?? 0,
        hasClosed: json['hasClosed'] as bool? ?? false,
        tookDead: json['tookDead'] as bool? ?? true,
        tableCardPoints: json['tableCardPoints'] as int? ?? 0,
        handCardPenalty: json['handCardPenalty'] as int? ?? 0,
      );
}

class BurakoRound {
  final int roundNumber;
  final Map<String, BurakoRoundEntry> teamEntries; // teamId -> entry

  BurakoRound({
    required this.roundNumber,
    required this.teamEntries,
  });

  Map<String, dynamic> toJson() => {
        'roundNumber': roundNumber,
        'teamEntries': teamEntries.map((k, v) => MapEntry(k, v.toJson())),
      };

  factory BurakoRound.fromJson(Map<String, dynamic> json) {
    final raw = json['teamEntries'] as Map<String, dynamic>? ?? {};
    final entries = <String, BurakoRoundEntry>{};
    raw.forEach((k, v) {
      entries[k] = BurakoRoundEntry.fromJson(v as Map<String, dynamic>);
    });
    return BurakoRound(
      roundNumber: json['roundNumber'] as int,
      teamEntries: entries,
    );
  }
}

class BurakoGame {
  List<Player> teams;
  List<BurakoRound> rounds;
  int targetScore; // e.g. 2000, 3000
  bool isFinished;
  String? winnerId;

  BurakoGame({
    required this.teams,
    List<BurakoRound>? rounds,
    this.targetScore = 3000,
    this.isFinished = false,
    this.winnerId,
  }) : rounds = rounds ?? [];

  void addRound(Map<String, BurakoRoundEntry> entries) {
    if (isFinished) return;
    final rNum = rounds.length + 1;
    rounds.add(BurakoRound(roundNumber: rNum, teamEntries: entries));

    for (var team in teams) {
      final entry = entries[team.id];
      if (entry != null) {
        team.score += entry.calculateTotal();
        if (team.score >= targetScore) {
          isFinished = true;
        }
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
