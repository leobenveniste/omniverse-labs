import 'package:flutter_test/flutter_test.dart';
import 'package:central_de_juegos/models/game_session.dart';
import 'package:central_de_juegos/models/game_type.dart';
import 'package:central_de_juegos/services/stats_service.dart';

void main() {
  group('StatsService Tests', () {
    test('Empty sessions return empty stats', () {
      final stats = StatsService.computeStats([]);
      expect(stats.totalMatches, 0);
      expect(stats.leaderboard, isEmpty);
      expect(stats.overallChampion, isNull);
      expect(stats.mostPlayedGame, isNull);
    });

    test('Computes leaderboards, champion, and win rates accurately', () {
      final now = DateTime.now();
      final sessions = [
        GameSession(
          id: '1',
          gameType: GameType.truco,
          title: 'Truco con Amigos',
          dateStarted: now,
          isFinished: true,
          winnerName: 'Leo',
          stateJson: '{}',
        ),
        GameSession(
          id: '2',
          gameType: GameType.truco,
          title: 'Revancha Truco',
          dateStarted: now,
          isFinished: true,
          winnerName: 'Leo',
          stateJson: '{}',
        ),
        GameSession(
          id: '3',
          gameType: GameType.generala,
          title: 'Generala Nocturna',
          dateStarted: now,
          isFinished: true,
          winnerName: 'Mati',
          stateJson: '{}',
        ),
      ];

      final stats = StatsService.computeStats(sessions);

      expect(stats.totalMatches, 3);
      expect(stats.mostPlayedGame, GameType.truco);
      expect(stats.overallChampion, 'Leo');
      expect(stats.leaderboard.length, 2);

      final leoStats = stats.leaderboard.firstWhere((p) => p.name == 'Leo');
      expect(leoStats.totalWins, 2);
      expect(leoStats.winsByGame[GameType.truco], 2);
      expect(leoStats.winRate, closeTo(66.7, 0.5));

      final matiStats = stats.leaderboard.firstWhere((p) => p.name == 'Mati');
      expect(matiStats.totalWins, 1);
      expect(matiStats.winsByGame[GameType.generala], 1);
      expect(matiStats.winRate, closeTo(33.3, 0.5));
    });
  });
}
