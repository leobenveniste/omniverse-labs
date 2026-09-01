import 'player.dart';

enum GeneralaCategory {
  ones,
  twos,
  threes,
  fours,
  fives,
  sixes,
  escalera,
  full,
  poker,
  generala,
  dobleGenerala,
}

extension GeneralaCategoryExtension on GeneralaCategory {
  String get displayName {
    switch (this) {
      case GeneralaCategory.ones:
        return '1 (Ases)';
      case GeneralaCategory.twos:
        return '2 (Dos)';
      case GeneralaCategory.threes:
        return '3 (Tres)';
      case GeneralaCategory.fours:
        return '4 (Cuatros)';
      case GeneralaCategory.fives:
        return '5 (Cincos)';
      case GeneralaCategory.sixes:
        return '6 (Seises)';
      case GeneralaCategory.escalera:
        return 'Escalera';
      case GeneralaCategory.full:
        return 'Full';
      case GeneralaCategory.poker:
        return 'Póker';
      case GeneralaCategory.generala:
        return 'Generala';
      case GeneralaCategory.dobleGenerala:
        return 'Doble Generala';
    }
  }

  int get standardPoints {
    switch (this) {
      case GeneralaCategory.escalera:
        return 20;
      case GeneralaCategory.full:
        return 30;
      case GeneralaCategory.poker:
        return 40;
      case GeneralaCategory.generala:
        return 50;
      case GeneralaCategory.dobleGenerala:
        return 60;
      default:
        return 0;
    }
  }

  int get servidaPoints {
    switch (this) {
      case GeneralaCategory.escalera:
        return 25;
      case GeneralaCategory.full:
        return 35;
      case GeneralaCategory.poker:
        return 45;
      case GeneralaCategory.generala:
        return 55;
      case GeneralaCategory.dobleGenerala:
        return 65;
      default:
        return 0;
    }
  }
}

class GeneralaPlayerSheet {
  final String playerId;
  // Category -> score (null = unplayed, 0 = crossed out, >0 = score)
  final Map<GeneralaCategory, int?> scores;
  final Map<GeneralaCategory, bool> isServida;

  GeneralaPlayerSheet({
    required this.playerId,
    Map<GeneralaCategory, int?>? scores,
    Map<GeneralaCategory, bool>? isServida,
  })  : scores = scores ?? {for (var c in GeneralaCategory.values) c: null},
        isServida = isServida ?? {for (var c in GeneralaCategory.values) c: false};

  int get totalScore {
    int sum = 0;
    scores.forEach((_, val) {
      if (val != null) sum += val;
    });
    return sum;
  }

  int get completedCategoriesCount {
    return scores.values.where((v) => v != null).length;
  }

  bool get isSheetComplete {
    return completedCategoriesCount == GeneralaCategory.values.length;
  }

  Map<String, dynamic> toJson() => {
        'playerId': playerId,
        'scores': scores.map((k, v) => MapEntry(k.name, v)),
        'isServida': isServida.map((k, v) => MapEntry(k.name, v)),
      };

  factory GeneralaPlayerSheet.fromJson(Map<String, dynamic> json) {
    final rawScores = json['scores'] as Map<String, dynamic>? ?? {};
    final rawServida = json['isServida'] as Map<String, dynamic>? ?? {};

    final scores = <GeneralaCategory, int?>{};
    final isServida = <GeneralaCategory, bool>{};

    for (var cat in GeneralaCategory.values) {
      scores[cat] = rawScores[cat.name] as int?;
      isServida[cat] = rawServida[cat.name] as bool? ?? false;
    }

    return GeneralaPlayerSheet(
      playerId: json['playerId'] as String,
      scores: scores,
      isServida: isServida,
    );
  }
}

class GeneralaGame {
  List<Player> players;
  Map<String, GeneralaPlayerSheet> sheets;
  int currentTurnIndex;
  bool isFinished;

  GeneralaGame({
    required this.players,
    Map<String, GeneralaPlayerSheet>? sheets,
    this.currentTurnIndex = 0,
    this.isFinished = false,
  }) : sheets = sheets ??
            {
              for (var p in players)
                p.id: GeneralaPlayerSheet(playerId: p.id)
            };

  bool get allSheetsComplete {
    return sheets.values.every((s) => s.isSheetComplete);
  }

  void setScore(String playerId, GeneralaCategory category, int? score, {bool servida = false}) {
    if (!sheets.containsKey(playerId)) return;
    sheets[playerId]!.scores[category] = score;
    sheets[playerId]!.isServida[category] = servida;

    // Update Player overall score
    final p = players.firstWhere((element) => element.id == playerId);
    p.score = sheets[playerId]!.totalScore;

    if (allSheetsComplete) {
      isFinished = true;
    }
  }

  Player? get winner {
    if (players.isEmpty) return null;
    Player best = players.first;
    for (var p in players) {
      if (p.score > best.score) {
        best = p;
      }
    }
    return best;
  }

  Map<String, dynamic> toJson() => {
        'players': players.map((p) => p.toJson()).toList(),
        'sheets': sheets.map((k, v) => MapEntry(k, v.toJson())),
        'currentTurnIndex': currentTurnIndex,
        'isFinished': isFinished,
      };

  factory GeneralaGame.fromJson(Map<String, dynamic> json) {
    final players = (json['players'] as List<dynamic>)
        .map((e) => Player.fromJson(e as Map<String, dynamic>))
        .toList();
    final rawSheets = json['sheets'] as Map<String, dynamic>? ?? {};
    final sheets = <String, GeneralaPlayerSheet>{};

    rawSheets.forEach((k, v) {
      sheets[k] = GeneralaPlayerSheet.fromJson(v as Map<String, dynamic>);
    });

    return GeneralaGame(
      players: players,
      sheets: sheets,
      currentTurnIndex: json['currentTurnIndex'] as int? ?? 0,
      isFinished: json['isFinished'] as bool? ?? false,
    );
  }
}
