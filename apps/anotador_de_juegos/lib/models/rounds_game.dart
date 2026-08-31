import 'player.dart';

class GameRound {
  final int roundNumber;
  final Map<String, int> playerPoints; // playerId -> points in this round
  final String? notes;

  GameRound({
    required this.roundNumber,
    required this.playerPoints,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'roundNumber': roundNumber,
        'playerPoints': playerPoints,
        'notes': notes,
      };

  factory GameRound.fromJson(Map<String, dynamic> json) => GameRound(
        roundNumber: json['roundNumber'] as int,
        playerPoints: Map<String, int>.from(json['playerPoints'] as Map),
        notes: json['notes'] as String?,
      );
}

class RoundsGame {
  final String title;
  List<Player> players;
  List<GameRound> rounds;
  int eliminationScore; // e.g. 100
  bool allowRehook; // Reenganche
  int dealerIndex;
  bool isFinished;
  String? winnerId;

  RoundsGame({
    required this.title,
    required this.players,
    List<GameRound>? rounds,
    this.eliminationScore = 100,
    this.allowRehook = true,
    this.dealerIndex = 0,
    this.isFinished = false,
    this.winnerId,
  }) : rounds = rounds ?? [];

  void addRound(Map<String, int> roundPoints) {
    if (isFinished) return;

    final newRoundNumber = rounds.length + 1;
    rounds.add(GameRound(
      roundNumber: newRoundNumber,
      playerPoints: Map.from(roundPoints),
    ));

    // Update player scores
    for (var p in players) {
      final pts = roundPoints[p.id] ?? 0;
      p.score += pts;

      if (p.score >= eliminationScore) {
        p.isEliminated = true;
      }
    }

    // Dealer rotates
    dealerIndex = (dealerIndex + 1) % players.length;

    checkGameOver();
  }

  bool canRehook(String playerId) {
    if (!allowRehook || isFinished) return false;
    final p = players.firstWhere((element) => element.id == playerId);
    return p.isEliminated;
  }

  void rehookPlayer(String playerId) {
    if (!canRehook(playerId)) return;
    final p = players.firstWhere((element) => element.id == playerId);

    // Score becomes the highest score of non-eliminated players
    final activePlayers = players.where((player) => !player.isEliminated);
    if (activePlayers.isEmpty) return;

    int maxScore = activePlayers.first.score;
    for (var active in activePlayers) {
      if (active.score > maxScore) {
        maxScore = active.score;
      }
    }

    p.score = maxScore;
    p.isEliminated = false;
    p.rehookCount++;

    checkGameOver();
  }

  void checkGameOver() {
    final activePlayers = players.where((p) => !p.isEliminated).toList();
    if (activePlayers.length == 1) {
      isFinished = true;
      winnerId = activePlayers.first.id;
    } else if (activePlayers.isEmpty) {
      isFinished = true;
      // Lowest score among all players
      Player best = players.first;
      for (var p in players) {
        if (p.score < best.score) best = p;
      }
      winnerId = best.id;
    }
  }

  void removeLastRound() {
    if (rounds.isEmpty) return;
    final lastRound = rounds.removeLast();

    for (var p in players) {
      final pts = lastRound.playerPoints[p.id] ?? 0;
      p.score -= pts;
      p.isEliminated = p.score >= eliminationScore;
    }

    if (dealerIndex > 0) {
      dealerIndex--;
    } else {
      dealerIndex = players.length - 1;
    }

    isFinished = false;
    winnerId = null;
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'players': players.map((p) => p.toJson()).toList(),
        'rounds': rounds.map((r) => r.toJson()).toList(),
        'eliminationScore': eliminationScore,
        'allowRehook': allowRehook,
        'dealerIndex': dealerIndex,
        'isFinished': isFinished,
        'winnerId': winnerId,
      };

  factory RoundsGame.fromJson(Map<String, dynamic> json) => RoundsGame(
        title: json['title'] as String? ?? 'Chinchón',
        players: (json['players'] as List<dynamic>)
            .map((e) => Player.fromJson(e as Map<String, dynamic>))
            .toList(),
        rounds: (json['rounds'] as List<dynamic>?)
            ?.map((e) => GameRound.fromJson(e as Map<String, dynamic>))
            .toList(),
        eliminationScore: json['eliminationScore'] as int? ?? 100,
        allowRehook: json['allowRehook'] as bool? ?? true,
        dealerIndex: json['dealerIndex'] as int? ?? 0,
        isFinished: json['isFinished'] as bool? ?? false,
        winnerId: json['winnerId'] as String?,
      );
}
