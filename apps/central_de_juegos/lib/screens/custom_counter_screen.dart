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
        Player(id: 'p1', name: 'Jugador 1', colorValue: AppTheme.playerColors[0].value),
        Player(id: 'p2', name: 'Jugador 2', colorValue: AppTheme.playerColors[1].value),
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
  }

  Player? _getLeader() {
    if (_game.players.isEmpty) return null;
    Player leader = _game.players.first;
    int maxScore = leader.score;
    bool hasTie = false;

    for (int i = 1; i < _game.players.length; i++) {
      final p = _game.players[i];
      if (p.score > maxScore) {
        leader = p;
        maxScore = p.score;
        hasTie = false;
      } else if (p.score == maxScore && maxScore > 0) {
        hasTie = true;
      }
    }

    if (maxScore <= 0 || hasTie) return null;
    return leader;
  }

  void _finishGame() {
    final leader = _getLeader() ?? _game.players.first;
    setState(() {
      _game.winnerId = leader.id;
      _game.isFinished = true;
    });
    _saveState();
    SoundHapticsService.victory();
    WinnerDialog.show(
      context,
      winnerName: leader.name,
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

  void _resetAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Reiniciar Puntajes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    final leader = _getLeader();

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo_dark.png',
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'CONTADOR_LIBRE',
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
            // List of full-height/stacked player sections
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _game.players.length,
                itemBuilder: (ctx, idx) {
                  final player = _game.players[idx];
                  final isLeader = leader?.id == player.id;

                  return Container(
                    height: 145,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      border: Border(
                        top: BorderSide(
                          color: isLeader ? AppTheme.cyberGold : player.color,
                          width: isLeader ? 4 : 3,
                        ),
                        bottom: const BorderSide(color: AppTheme.bgDark, width: 4),
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
                                style: TextStyle(
                                  fontSize: 64,
                                  fontWeight: FontWeight.w900,
                                  color: isLeader ? AppTheme.cyberGold : Colors.white,
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
                                title: 'Editar Nombre',
                              );
                              if (newName != null && newName.isNotEmpty) {
                                setState(() => player.name = newName);
                                _saveState();
                              }
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
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
                                if (isLeader) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.cyberGold,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.emoji_events, size: 12, color: Colors.black),
                                        SizedBox(width: 4),
                                        Text(
                                          'LÍDER',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 10,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
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
                      ],
                    ),
                  );
                },
              ),
            ),

            // Fixed floating-style bottom bar with Leader status & "FINALIZAR JUEGO"
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                border: const Border(top: BorderSide(color: AppTheme.borderDark, width: 1.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.emoji_events, color: AppTheme.cyberGold, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            leader != null
                                ? 'Ganando: ${leader.name} (${leader.score} pts)'
                                : 'Empate o sin puntajes',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _finishGame,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.cyberGold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text(
                      'FINALIZAR JUEGO',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
