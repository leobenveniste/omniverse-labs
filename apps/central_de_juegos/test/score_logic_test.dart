import 'package:flutter_test/flutter_test.dart';
import 'package:central_de_juegos/models/truco_game.dart';
import 'package:central_de_juegos/models/generala_game.dart';
import 'package:central_de_juegos/models/rounds_game.dart';
import 'package:central_de_juegos/models/burako_game.dart';
import 'package:central_de_juegos/models/diez_mil_game.dart';
import 'package:central_de_juegos/models/player.dart';

void main() {
  group('TrucoGame Logic Tests', () {
    test('Initializes with 30 target points and 0 score', () {
      final game = TrucoGame(targetPoints: 30);
      expect(game.team1Score, 0);
      expect(game.team2Score, 0);
      expect(game.isFinished, false);
      expect(game.isBuenas(10), false); // Malas
      expect(game.isBuenas(16), true); // Buenas
    });

    test('Adding points updates scores and triggers winner at 30', () {
      final game = TrucoGame(targetPoints: 30);
      game.addPoints(0, 2, label: 'Envido');
      expect(game.team1Score, 2);
      expect(game.history.length, 1);

      game.addPoints(0, 28, label: 'Falta Envido');
      expect(game.team1Score, 30);
      expect(game.isFinished, true);
      expect(game.winnerName, 'Nosotros');
    });

    test('Undo reverses the last point action', () {
      final game = TrucoGame(targetPoints: 30);
      game.addPoints(1, 3, label: 'Real Envido');
      expect(game.team2Score, 3);

      final success = game.undo();
      expect(success, true);
      expect(game.team2Score, 0);
      expect(game.history.isEmpty, true);
    });
  });

  group('GeneralaGame Logic Tests', () {
    test('Calculates number categories and servida bonuses correctly', () {
      final p1 = Player(id: 'p1', name: 'Ana', colorValue: 0xFF2196F3);
      final game = GeneralaGame(players: [p1]);

      // 4 fives = 20 pts
      game.setScore('p1', GeneralaCategory.fives, 20);
      expect(p1.score, 20);

      // Escalera servida = 25 pts
      game.setScore('p1', GeneralaCategory.escalera, GeneralaCategory.escalera.servidaPoints, servida: true);
      expect(p1.score, 45);

      // Tachar generala = 0 pts
      game.setScore('p1', GeneralaCategory.generala, 0);
      expect(p1.score, 45);
    });
  });

  group('RoundsGame (Chinchón / Uno) Logic Tests', () {
    test('Accumulates rounds and handles elimination and rehook', () {
      final p1 = Player(id: 'p1', name: 'Lucas', colorValue: 0xFF2196F3);
      final p2 = Player(id: 'p2', name: 'Sofia', colorValue: 0xFFE53935);
      final p3 = Player(id: 'p3', name: 'Martin', colorValue: 0xFF43A047);

      final game = RoundsGame(
        title: 'Chinchón',
        eliminationScore: 100,
        allowRehook: true,
        players: [p1, p2, p3],
      );

      // Round 1
      game.addRound({'p1': 10, 'p2': 40, 'p3': 105});
      expect(p1.score, 10);
      expect(p2.score, 40);
      expect(p3.score, 105);
      expect(p3.isEliminated, true);

      // Rehook p3 to max active score (p2 with 40)
      expect(game.canRehook('p3'), true);
      game.rehookPlayer('p3');
      expect(p3.score, 40);
      expect(p3.isEliminated, false);
      expect(p3.rehookCount, 1);
    });
  });

  group('BurakoGame Logic Tests', () {
    test('Calculates Base and Puntos totals and manages starter team', () {
      final t1 = Player(id: 't1', name: 'Nosotros', colorValue: 0xFF2196F3);
      final t2 = Player(id: 't2', name: 'Ellos', colorValue: 0xFFE53935);
      final game = BurakoGame(teams: [t1, t2], targetScore: 3000);

      game.addRound(
        starterTeamId: 't1',
        scores: {
          't1': BurakoRoundTeamScore(base: 300, puntos: 150), // 450
          't2': BurakoRoundTeamScore(base: 100, puntos: 40),  // 140
        },
      );

      expect(t1.score, 450);
      expect(t2.score, 140);
      expect(game.rounds.first.starterTeamId, 't1');
      expect(game.isFinished, false);
    });
  });

  group('DiezMilGame Logic Tests', () {
    test('Calculates turn points, entry requirements, and reaches 10000 winner', () {
      final p1 = Player(id: 'p1', name: 'Jugador 1', colorValue: 0xFF2196F3);
      final p2 = Player(id: 'p2', name: 'Jugador 2', colorValue: 0xFFE53935);
      final game = DiezMilGame(players: [p1, p2], targetScore: 10000, entryScore: 750);

      expect(game.hasPlayerEntered('p1'), false);

      // Round 1: p1 gets 800 (enters), p2 gets 400 (not entered yet)
      game.addRound({'p1': 800, 'p2': 0});
      expect(game.hasPlayerEntered('p1'), true);
      expect(p1.score, 800);
      expect(game.isFinished, false);

      // Round 2: p1 scores 9200 and wins!
      game.addRound({'p1': 9200, 'p2': 1000});
      expect(p1.score, 10000);
      expect(game.isFinished, true);
      expect(game.winnerId, 'p1');
    });
  });
}
