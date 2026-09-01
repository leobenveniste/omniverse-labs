import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/game_type.dart';
import '../models/game_session.dart';
import '../models/player.dart';
import '../models/custom_game.dart';
import '../services/storage_service.dart';
import '../services/sound_haptics_service.dart';
import '../theme/app_theme.dart';
import '../widgets/winner_dialog.dart';
import '../widgets/player_name_dialog.dart';

class CustomCounterScreen extends StatefulWidget {
  final GameSession? existingSession;
  final List<Player>? configuredPlayers;

  const CustomCounterScreen({
    super.key,
    this.existingSession,
    this.configuredPlayers,
  });

  @override
  State<CustomCounterScreen> createState() => _CustomCounterScreenState();
}

class _CustomCounterScreenState extends State<CustomCounterScreen> {
  late String _sessionId;
  late DateTime _dateStarted;
  late CustomGame _game;

  @override
  void initState() {
    super.initState();
    if (widget.existingSession != null &&
        widget.existingSession!.gameType == GameType.custom) {
      _sessionId = widget.existingSession!.id;
      _dateStarted = widget.existingSession!.dateStarted;
      try {
        final map = jsonDecode(widget.existingSession!.stateJson) as Map<String, dynamic>;
        _game = CustomGame.fromJson(map);
      } catch (_) {
        _game = _defaultGame();
      }
    } else if (widget.configuredPlayers != null && widget.configuredPlayers!.isNotEmpty) {
      _sessionId = const Uuid().v4();
      _dateStarted = DateTime.now();
      _game = CustomGame(
        players: widget.configuredPlayers!
            .map((p) => Player(id: p.id, name: p.name, colorValue: p.colorValue, score: 0))
            .toList(),
        step: 1,
      );
    } else {
      _sessionId = const Uuid().v4();
      _dateStarted = DateTime.now();
      _game = _defaultGame();
    }
  }

  CustomGame _defaultGame() {
    return CustomGame(
      players: [
        Player(id: 'p1', name: 'RED', colorValue: AppTheme.playerColors[0].value),
        Player(id: 'p2', name: 'BLUE', colorValue: AppTheme.playerColors[1].value),
        Player(id: 'p3', name: 'GREEN', colorValue: AppTheme.playerColors[2].value),
        Player(id: 'p4', name: 'YELLOW', colorValue: AppTheme.playerColors[3].value),
      ],
      step: 1,
    );
  }

  void _saveState() {
    final winner = _game.winnerId != null
        ? _game.players.firstWhere((p) => p.id == _game.winnerId).name
        : null;

    final session = GameSession(
      id: _sessionId,
      gameType: GameType.custom,
      title: 'Contador - ${_game.players.map((p) => p.name).join(' vs ')}',
      dateStarted: _dateStarted,
      dateFinished: _game.isFinished ? DateTime.now() : null,
      isFinished: _game.isFinished,
      winnerName: winner,
      stateJson: jsonEncode(_game.toJson()),
    );

    if (_game.isFinished) {
      StorageService.saveToHistory(session);
      StorageService.clearActiveSession();
    } else {
      StorageService.saveActiveSession(session);
    }
  }

  void _addPoints(Player p, int amount) {
    setState(() {
      _game.addScore(p.id, amount);
    });
    if (amount > 0) {
      SoundHapticsService.pointAdded();
    } else {
      SoundHapticsService.pointSubtracted();
    }
    _saveState();

    if (_game.isFinished) {
      SoundHapticsService.victory();
      WinnerDialog.show(
        context,
        winnerName: p.name,
        gameTitle: 'Contador Libre',
        scores: _game.players,
        onRematch: () {
          setState(() {
            _game.resetScores();
            _sessionId = const Uuid().v4();
            _dateStarted = DateTime.now();
          });
          _saveState();
        },
        onNewGame: () => Navigator.of(context).pop(),
      );
    }
  }

  void _resetAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Reiniciar Puntajes', style: TextStyle(color: Colors.white)),
        content: const Text('¿Deseas poner todos los contadores a 0?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reiniciar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() {
        _game.resetScores();
      });
      SoundHapticsService.undo();
      _saveState();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        title: const Row(
          children: [
            Icon(Icons.arrow_right_alt, color: AppTheme.cyberGold, size: 20),
            SizedBox(width: 4),
            Text(
              'SCORE_KEEPER',
              style: TextStyle(
                color: AppTheme.cyberGold,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            tooltip: 'Reiniciar Puntajes',
            onPressed: _resetAll,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // List of full-height/stacked player sections matching reference
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _game.players.length,
                itemBuilder: (ctx, idx) {
                  final player = _game.players[idx];

                  return Container(
                    height: 145,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      border: Border(
                        top: BorderSide(color: player.color, width: 3),
                        bottom: BorderSide(color: AppTheme.bgDark, width: 4),
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Tap anywhere on card to add points
                        Positioned.fill(
                          child: InkWell(
                            onTap: () => _addPoints(player, _game.step),
                            child: Center(
                              child: Text(
                                '${player.score}',
                                style: const TextStyle(
                                  fontSize: 64,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Top Left Player Pill Badge (editable on tap)
                        Positioned(
                          top: 12,
                          left: 16,
                          child: GestureDetector(
                            onTap: () async {
                              final newName = await PlayerNameDialog.show(
                                context,
                                currentName: player.name,
                                title: 'Editar Jugador',
                              );
                              if (newName != null && newName.isNotEmpty) {
                                setState(() => player.name = newName);
                                _saveState();
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Text(
                                'P${idx + 1} : ${player.name.toUpperCase()}',
                                style: TextStyle(
                                  color: player.color,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Bottom Left Subtract Button
                        Positioned(
                          bottom: 14,
                          left: 16,
                          child: GestureDetector(
                            onTap: () => _addPoints(player, -_game.step),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: const Center(
                                child: Icon(Icons.remove, color: Colors.white70, size: 22),
                              ),
                            ),
                          ),
                        ),

                        // Bottom Right Quick Win / Victory flag button
                        Positioned(
                          bottom: 14,
                          right: 16,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _game.winnerId = player.id;
                                _game.isFinished = true;
                              });
                              _saveState();
                              SoundHapticsService.victory();
                              WinnerDialog.show(
                                context,
                                winnerName: player.name,
                                gameTitle: 'Contador Libre',
                                scores: _game.players,
                                onRematch: () {
                                  setState(() {
                                    _game.resetScores();
                                    _sessionId = const Uuid().v4();
                                    _dateStarted = DateTime.now();
                                  });
                                  _saveState();
                                },
                                onNewGame: () => Navigator.of(context).pop(),
                              );
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppTheme.cyberGold,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Center(
                                child: Icon(Icons.flag, color: Colors.black, size: 22),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
