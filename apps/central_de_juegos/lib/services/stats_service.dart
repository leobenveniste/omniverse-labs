import '../models/game_session.dart';
import '../models/game_type.dart';

class PlayerStats {
  final String name;
  final int totalGamesPlayed;
  final int totalWins;
  final Map<GameType, int> winsByGame;
  final double winRate;

  const PlayerStats({
    required this.name,
    required this.totalGamesPlayed,
    required this.totalWins,
    required this.winsByGame,
    required this.winRate,
  });
}

class GameGlobalStats {
  final int totalMatches;
  final GameType? mostPlayedGame;
  final String? overallChampion;
  final List<PlayerStats> leaderboard;

  const GameGlobalStats({
    required this.totalMatches,
    this.mostPlayedGame,
    this.overallChampion,
    required this.leaderboard,
  });
}

class StatsService {
  static GameGlobalStats computeStats(List<GameSession> sessions) {
    if (sessions.isEmpty) {
      return const GameGlobalStats(
        totalMatches: 0,
        leaderboard: [],
      );
    }

    final finishedSessions = sessions.where((s) => s.isFinished).toList();
    final totalMatches = sessions.length;

    // Count games by type
    final gameCounts = <GameType, int>{};
    for (final s in sessions) {
      gameCounts[s.gameType] = (gameCounts[s.gameType] ?? 0) + 1;
    }

    GameType? mostPlayed;
    int maxGameCount = -1;
    gameCounts.forEach((type, count) {
      if (count > maxGameCount) {
        maxGameCount = count;
        mostPlayed = type;
      }
    });

    // Player wins and games
    final wins = <String, int>{};
    final winsByGame = <String, Map<GameType, int>>{};
    final gamesPlayed = <String, int>{};

    for (final s in finishedSessions) {
      final winner = s.winnerName?.trim();
      if (winner != null && winner.isNotEmpty) {
        wins[winner] = (wins[winner] ?? 0) + 1;
        winsByGame.putIfAbsent(winner, () => {})[s.gameType] =
            (winsByGame[winner]?[s.gameType] ?? 0) + 1;
      }
    }

    // Estimate games played: at least total wins, or count if winner was recorded
    for (final entry in wins.entries) {
      gamesPlayed[entry.key] = entry.value;
    }

    final leaderboard = wins.entries.map((e) {
      final pWins = e.value;
      final pPlayed = gamesPlayed[e.key] ?? pWins;
      final rate = finishedSessions.isEmpty ? 0.0 : (pWins / finishedSessions.length) * 100;

      return PlayerStats(
        name: e.key,
        totalGamesPlayed: pPlayed,
        totalWins: pWins,
        winsByGame: winsByGame[e.key] ?? {},
        winRate: double.parse(rate.toStringAsFixed(1)),
      );
    }).toList()
      ..sort((a, b) {
        final winDiff = b.totalWins.compareTo(a.totalWins);
        if (winDiff != 0) return winDiff;
        return b.winRate.compareTo(a.winRate);
      });

    final champion = leaderboard.isNotEmpty ? leaderboard.first.name : null;

    return GameGlobalStats(
      totalMatches: totalMatches,
      mostPlayedGame: mostPlayed,
      overallChampion: champion,
      leaderboard: leaderboard,
    );
  }
}
