import 'player.dart';

class EscobaHandEntry {
  final int escobas; // Puntos por escobas
  final bool hasMostCards; // 1 pt por mayoría de cartas
  final bool hasMostOros; // 1 pt por mayoría de oros
  final bool hasSieteDeOro; // 1 pt por el 7 de oro
  final bool hasSetenta; // 1 pt por la setenta

  EscobaHandEntry({
    this.escobas = 0,
    this.hasMostCards = false,
    this.hasMostOros = false,
    this.hasSieteDeOro = false,
    this.hasSetenta = false,
  });

  int calculateTotal() {
    int total = escobas;
    if (hasMostCards) total += 1;
    if (hasMostOros) total += 1;
    if (hasSieteDeOro) total += 1;
    if (hasSetenta) total += 1;
    return total;
  }

  Map<String, dynamic> toJson() => {
        'escobas': escobas,
        'hasMostCards': hasMostCards,
        'hasMostOros': hasMostOros,
        'hasSieteDeOro': hasSieteDeOro,
        'hasSetenta': hasSetenta,
      };

  factory EscobaHandEntry.fromJson(Map<String, dynamic> json) => EscobaHandEntry(
        escobas: json['escobas'] as int? ?? 0,
        hasMostCards: json['hasMostCards'] as bool? ?? false,
        hasMostOros: json['hasMostOros'] as bool? ?? false,
        hasSieteDeOro: json['hasSieteDeOro'] as bool? ?? false,
        hasSetenta: json['hasSetenta'] as bool? ?? false,
      );
}

class EscobaHand {
  final int handNumber;
  final Map<String, EscobaHandEntry> playerEntries;

  EscobaHand({
    required this.handNumber,
    required this.playerEntries,
  });

  Map<String, dynamic> toJson() => {
        'handNumber': handNumber,
        'playerEntries': playerEntries.map((k, v) => MapEntry(k, v.toJson())),
      };

  factory EscobaHand.fromJson(Map<String, dynamic> json) {
    final raw = json['playerEntries'] as Map<String, dynamic>? ?? {};
    final entries = <String, EscobaHandEntry>{};
    raw.forEach((k, v) {
      entries[k] = EscobaHandEntry.fromJson(v as Map<String, dynamic>);
    });
    return EscobaHand(
      handNumber: json['handNumber'] as int,
      playerEntries: entries,
    );
  }
}

class EscobaGame {
  List<Player> players;
  List<EscobaHand> hands;
  int targetScore; // 15, 21, 31
  bool isFinished;
  String? winnerId;

  EscobaGame({
    required this.players,
    List<EscobaHand>? hands,
    this.targetScore = 15,
    this.isFinished = false,
    this.winnerId,
  }) : hands = hands ?? [];

  void addHand(Map<String, EscobaHandEntry> entries) {
    if (isFinished) return;
    final hNum = hands.length + 1;
    hands.add(EscobaHand(handNumber: hNum, playerEntries: entries));

    for (var p in players) {
      final entry = entries[p.id];
      if (entry != null) {
        p.score += entry.calculateTotal();
        if (p.score >= targetScore) {
          isFinished = true;
        }
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
        'hands': hands.map((h) => h.toJson()).toList(),
        'targetScore': targetScore,
        'isFinished': isFinished,
        'winnerId': winnerId,
      };

  factory EscobaGame.fromJson(Map<String, dynamic> json) => EscobaGame(
        players: (json['players'] as List<dynamic>)
            .map((e) => Player.fromJson(e as Map<String, dynamic>))
            .toList(),
        hands: (json['hands'] as List<dynamic>?)
            ?.map((e) => EscobaHand.fromJson(e as Map<String, dynamic>))
            .toList(),
        targetScore: json['targetScore'] as int? ?? 15,
        isFinished: json['isFinished'] as bool? ?? false,
        winnerId: json['winnerId'] as String?,
      );
}
