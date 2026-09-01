import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/game_type.dart';
import '../models/game_session.dart';
import '../models/player.dart';
import '../models/diez_mil_game.dart';
import '../services/storage_service.dart';
import '../services/sound_haptics_service.dart';
import '../theme/app_theme.dart';
import '../widgets/winner_dialog.dart';
import '../widgets/player_name_dialog.dart';

class DiezMilScreen extends StatefulWidget {
  final GameSession? existingSession;
  final List<Player>? configuredPlayers;
  final int entryScore;
  final int minRoundScore;

  const DiezMilScreen({
    super.key,
    this.existingSession,
    this.configuredPlayers,
    this.entryScore = 750,
    this.minRoundScore = 350,
  });

  @override
  State<DiezMilScreen> createState() => _DiezMilScreenState();
}

class _DiezMilScreenState extends State<DiezMilScreen> {
  late String _sessionId;
  late DateTime _dateStarted;
  late DiezMilGame _game;
  int _currentTurnIndex = 0;
  int _turnPoints = 0;

  @override
  void initState() {
    super.initState();
    if (widget.existingSession != null &&
        widget.existingSession!.gameType == GameType.diezMil) {
      _sessionId = widget.existingSession!.id;
      _dateStarted = widget.existingSession!.dateStarted;
      try {
        final map = jsonDecode(widget.existingSession!.stateJson) as Map<String, dynamic>;
        _game = DiezMilGame.fromJson(map);
        _currentTurnIndex = (map['currentTurnIndex'] as int?) ?? 0;
      } catch (_) {
        _game = _defaultGame();
      }
    } else if (widget.configuredPlayers != null && widget.configuredPlayers!.isNotEmpty) {
      _sessionId = const Uuid().v4();
      _dateStarted = DateTime.now();
      _game = DiezMilGame(
        players: widget.configuredPlayers!
            .map((p) => Player(id: p.id, name: p.name, colorValue: p.colorValue, score: 0))
            .toList(),
        targetScore: 10000,
        entryScore: widget.entryScore,
      );
    } else {
      _sessionId = const Uuid().v4();
      _dateStarted = DateTime.now();
      _game = _defaultGame();
    }
  }

  DiezMilGame _defaultGame() {
    return DiezMilGame(
      players: [
        Player(id: 'p1', name: 'Jugador 1', colorValue: AppTheme.playerColors[0].value),
        Player(id: 'p2', name: 'Jugador 2', colorValue: AppTheme.playerColors[1].value),
      ],
      targetScore: 10000,
      entryScore: widget.entryScore,
    );
  }

  void _saveState() {
    final winner = _game.winnerId != null
        ? _game.players.firstWhere((p) => p.id == _game.winnerId).name
        : null;

    final stateMap = _game.toJson();
    stateMap['currentTurnIndex'] = _currentTurnIndex;

    final session = GameSession(
      id: _sessionId,
      gameType: GameType.diezMil,
      title: 'Diez Mil - ${_game.players.map((p) => p.name).join(' vs ')}',
      dateStarted: _dateStarted,
      dateFinished: _game.isFinished ? DateTime.now() : null,
      isFinished: _game.isFinished,
      winnerName: winner,
      stateJson: jsonEncode(stateMap),
    );

    if (_game.isFinished) {
      StorageService.saveToHistory(session);
      StorageService.clearActiveSession();
    } else {
      StorageService.saveActiveSession(session);
    }
  }

  void _confirmTurn() {
    final currentPlayer = _game.players[_currentTurnIndex];
    final hasEntered = _game.hasPlayerEntered(currentPlayer.id);

    // Rule 1: Must score >= entryScore to enter
    if (!hasEntered && _turnPoints > 0 && _turnPoints < _game.entryScore) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Para entrar se requiere un mínimo de ${_game.entryScore} puntos en la tirada'),
          backgroundColor: Colors.orange.shade800,
        ),
      );
      return;
    }

    // Rule 2: Minimum round points to plant
    if (hasEntered && widget.minRoundScore > 0 && _turnPoints > 0 && _turnPoints < widget.minRoundScore) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('El mínimo para plantarse es de ${widget.minRoundScore} puntos (o 0 si perdiste)'),
          backgroundColor: Colors.orange.shade800,
        ),
      );
      return;
    }

    final roundMap = <String, int>{};
    for (var p in _game.players) {
      roundMap[p.id] = (p.id == currentPlayer.id) ? _turnPoints : 0;
    }

    setState(() {
      _game.addRound(roundMap);
      _turnPoints = 0;
      _currentTurnIndex = (_currentTurnIndex + 1) % _game.players.length;
    });

    SoundHapticsService.pointAdded();
    _saveState();

    if (_game.isFinished) {
      SoundHapticsService.victory();
      WinnerDialog.show(
        context,
        winnerName: currentPlayer.name,
        gameTitle: 'Diez Mil',
        scores: _game.players,
        onRematch: () {
          setState(() {
            _game.rounds.clear();
            for (var p in _game.players) {
              p.score = 0;
            }
            _game.isFinished = false;
            _game.winnerId = null;
            _currentTurnIndex = 0;
            _turnPoints = 0;
            _sessionId = const Uuid().v4();
            _dateStarted = DateTime.now();
          });
          _saveState();
        },
        onNewGame: () => Navigator.of(context).pop(),
      );
    }
  }

  void _undoTurn() {
    if (_game.rounds.isEmpty) return;
    setState(() {
      _game.undoLastRound();
      _currentTurnIndex = (_currentTurnIndex - 1 + _game.players.length) % _game.players.length;
      _turnPoints = 0;
    });
    SoundHapticsService.undo();
    _saveState();
  }

  void _addTurnPoints(int amount) {
    setState(() {
      _turnPoints += amount;
      if (_turnPoints < 0) _turnPoints = 0;
    });
    SoundHapticsService.click();
  }

  @override
  Widget build(BuildContext context) {
    final currentPlayer = _game.players[_currentTurnIndex];
    final hasEntered = _game.hasPlayerEntered(currentPlayer.id);

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
              'DIEZ_MIL',
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
            icon: const Icon(Icons.undo, color: Colors.white70),
            tooltip: 'Deshacer Último Turno',
            onPressed: _game.rounds.isEmpty ? null : _undoTurn,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            tooltip: 'Reiniciar Partida',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppTheme.surfaceDark,
                  title: const Text('Reiniciar Partida', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  content: const Text('¿Deseas reiniciar todos los puntajes a 0?', style: TextStyle(color: Colors.white70)),
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
                  _game.rounds.clear();
                  for (var p in _game.players) {
                    p.score = 0;
                  }
                  _game.isFinished = false;
                  _game.winnerId = null;
                  _currentTurnIndex = 0;
                  _turnPoints = 0;
                });
                _saveState();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Players Score Strip
            Container(
              height: 105,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _game.players.length,
                itemBuilder: (ctx, idx) {
                  final p = _game.players[idx];
                  final isTurn = idx == _currentTurnIndex;
                  final entered = _game.hasPlayerEntered(p.id);

                  return GestureDetector(
                    onTap: () async {
                      final newName = await PlayerNameDialog.show(
                        context,
                        currentName: p.name,
                        title: 'Editar Nombre',
                      );
                      if (newName != null && newName.isNotEmpty) {
                        setState(() => p.name = newName);
                        _saveState();
                      }
                    },
                    child: Container(
                      width: 140,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isTurn ? AppTheme.surfaceElevated : AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isTurn ? AppTheme.cyberGold : p.color.withOpacity(0.4),
                          width: isTurn ? 2.2 : 1.0,
                        ),
                        boxShadow: isTurn
                            ? [
                                BoxShadow(
                                  color: AppTheme.cyberGold.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: p.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  p.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isTurn ? FontWeight.w900 : FontWeight.bold,
                                    color: isTurn ? AppTheme.cyberGold : Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${p.score}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.0,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: entered ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  entered ? 'ENTRÓ' : '0/${_game.entryScore}',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: entered ? Colors.greenAccent : Colors.redAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const Divider(color: AppTheme.borderDark, height: 1),

            // Active Turn Card & Calculator
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  children: [
                    // Turn Indicator Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.cyberGold, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.casino, color: currentPlayer.color, size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TURNO DE:',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                    color: Colors.white.withOpacity(0.6),
                                  ),
                                ),
                                Text(
                                  currentPlayer.name.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: currentPlayer.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!hasEntered)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.orange, width: 1),
                              ),
                              child: Text(
                                'Apertura: ${_game.entryScore}+',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orangeAccent,
                                ),
                              ),
                            )
                          else if (widget.minRoundScore > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.blue, width: 1),
                              ),
                              child: Text(
                                'Mín: ${widget.minRoundScore}+',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.lightBlueAccent,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Turn Points Display
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderDark),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'PUNTOS DE ESTA TIRADA',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '+$_turnPoints',
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.cyberGold,
                                  height: 1.0,
                                ),
                              ),
                              if (_turnPoints > 0) ...[
                                const SizedBox(width: 12),
                                IconButton(
                                  icon: const Icon(Icons.backspace, color: Colors.white54, size: 22),
                                  tooltip: 'Limpiar',
                                  onPressed: () => setState(() => _turnPoints = 0),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Clean Score Math Buttons without text explanations
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1.7,
                        children: [
                          _buildMathBtn('+50', 50),
                          _buildMathBtn('+100', 100),
                          _buildMathBtn('+200', 200),
                          _buildMathBtn('+300', 300),
                          _buildMathBtn('+400', 400),
                          _buildMathBtn('+500', 500),
                          _buildMathBtn('+600', 600),
                          _buildMathBtn('+1.000', 1000),
                          _buildMathBtn('+1.500', 1500),
                        ],
                      ),
                    ),

                    // Confirm & Next Player Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        onPressed: _confirmTurn,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.cyberGold,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _turnPoints == 0 ? '0 PUNTOS (PASAR TURNO)' : 'CONFIRMAR (+$_turnPoints PTS) Y SIGUIENTE',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward, color: Colors.black, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMathBtn(String label, int amount) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: AppTheme.surfaceDark,
        side: const BorderSide(color: AppTheme.borderDark),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () => _addTurnPoints(amount),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
      ),
    );
  }
}
