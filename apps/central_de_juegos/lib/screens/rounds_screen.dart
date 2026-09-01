import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/game_type.dart';
import '../models/game_session.dart';
import '../models/player.dart';
import '../models/rounds_game.dart';
import '../services/storage_service.dart';
import '../services/sound_haptics_service.dart';
import '../theme/app_theme.dart';
import '../widgets/winner_dialog.dart';

class RoundsScreen extends StatefulWidget {
  final GameType gameType; // Chinchon or Uno
  final GameSession? existingSession;

  const RoundsScreen({
    super.key,
    required this.gameType,
    this.existingSession,
  });

  @override
  State<RoundsScreen> createState() => _RoundsScreenState();
}

class _RoundsScreenState extends State<RoundsScreen> {
  late String _sessionId;
  late DateTime _dateStarted;
  late RoundsGame _game;

  @override
  void initState() {
    super.initState();
    if (widget.existingSession != null &&
        widget.existingSession!.gameType == widget.gameType) {
      _sessionId = widget.existingSession!.id;
      _dateStarted = widget.existingSession!.dateStarted;
      try {
        final map = jsonDecode(widget.existingSession!.stateJson) as Map<String, dynamic>;
        _game = RoundsGame.fromJson(map);
      } catch (_) {
        _game = _defaultGame();
      }
    } else {
      _sessionId = const Uuid().v4();
      _dateStarted = DateTime.now();
      _game = _defaultGame();
    }
  }

  RoundsGame _defaultGame() {
    final title = widget.gameType == GameType.chinchon ? 'Chinchón' : 'Uno / Rummy';
    final target = widget.gameType == GameType.chinchon ? 100 : 500;
    return RoundsGame(
      title: title,
      eliminationScore: target,
      allowRehook: widget.gameType == GameType.chinchon,
      players: [
        Player(id: 'p1', name: 'Jugador 1', colorValue: AppTheme.playerColors[0].value),
        Player(id: 'p2', name: 'Jugador 2', colorValue: AppTheme.playerColors[1].value),
        Player(id: 'p3', name: 'Jugador 3', colorValue: AppTheme.playerColors[2].value),
      ],
    );
  }

  void _saveState() {
    final winner = _game.winnerId != null
        ? _game.players.firstWhere((p) => p.id == _game.winnerId).name
        : null;

    final session = GameSession(
      id: _sessionId,
      gameType: widget.gameType,
      title: '${_game.title} (${_game.players.length} jugadores)',
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

  void _openAddRoundModal() {
    final pointsControllers = <String, TextEditingController>{};
    for (var p in _game.players) {
      pointsControllers[p.id] = TextEditingController(text: p.isEliminated ? '-' : '0');
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Anotar Ronda ${_game.rounds.length + 1}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ..._game.players.map((p) {
                if (p.isEliminated) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Text(
                      '${p.name}: Eliminado (${p.score} pts)',
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      CircleAvatar(backgroundColor: p.color, radius: 12),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          p.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                      SizedBox(
                        width: 90,
                        child: TextField(
                          controller: pointsControllers[p.id],
                          keyboardType: const TextInputType.numberWithOptions(signed: true),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  final roundMap = <String, int>{};
                  for (var p in _game.players) {
                    if (!p.isEliminated) {
                      final val = int.tryParse(pointsControllers[p.id]?.text ?? '0') ?? 0;
                      roundMap[p.id] = val;
                    }
                  }
                  Navigator.of(ctx).pop();
                  _applyRound(roundMap);
                },
                child: const Text('Confirmar Ronda'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _applyRound(Map<String, int> roundMap) {
    SoundHapticsService.pointAdded();
    setState(() {
      _game.addRound(roundMap);
    });
    _saveState();

    if (_game.isFinished) {
      final winner = _game.players.firstWhere((p) => p.id == _game.winnerId);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => WinnerDialog(
          winnerName: winner.name,
          subtitle: '¡Ganó la partida con ${winner.score} puntos en ${_game.rounds.length} rondas!',
          onRematch: () {
            setState(() {
              _game = _defaultGame();
              _sessionId = const Uuid().v4();
              _dateStarted = DateTime.now();
            });
            _saveState();
          },
          onNewGame: _editSettingsDialog,
          onExit: () => Navigator.of(context).pop(),
        ),
      );
    }
  }

  void _rehook(String playerId) {
    SoundHapticsService.pointSubtracted();
    setState(() {
      _game.rehookPlayer(playerId);
    });
    _saveState();
  }

  void _undoRound() {
    SoundHapticsService.click();
    setState(() {
      _game.removeLastRound();
    });
    _saveState();
  }

  void _editSettingsDialog() {
    final controllers = _game.players.map((p) => TextEditingController(text: p.name)).toList();
    final targetController = TextEditingController(text: _game.eliminationScore.toString());
    bool rehook = _game.allowRehook;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Text('Configurar ${_game.title}'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: [
                  TextField(
                    controller: targetController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Límite de Eliminación (Puntos)',
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (widget.gameType == GameType.chinchon)
                    SwitchListTile(
                      title: const Text('Permitir Reenganche'),
                      value: rehook,
                      onChanged: (v) => setModalState(() => rehook = v),
                    ),
                  const SizedBox(height: 12),
                  const Text('Jugadores:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...List.generate(controllers.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppTheme.playerColors[i % AppTheme.playerColors.length],
                            radius: 12,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: controllers[i],
                              decoration: InputDecoration(
                                labelText: 'Jugador ${i + 1}',
                                isDense: true,
                              ),
                            ),
                          ),
                          if (controllers.length > 2)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setModalState(() => controllers.removeAt(i));
                              },
                            ),
                        ],
                      ),
                    );
                  }),
                  if (controllers.length < 8)
                    TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar Jugador'),
                      onPressed: () {
                        setModalState(() {
                          controllers.add(TextEditingController(text: 'Jugador ${controllers.length + 1}'));
                        });
                      },
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  final newPlayers = <Player>[];
                  for (int i = 0; i < controllers.length; i++) {
                    final name = controllers[i].text.trim().isEmpty ? 'Jugador ${i + 1}' : controllers[i].text.trim();
                    newPlayers.add(Player(
                      id: 'p${i + 1}',
                      name: name,
                      colorValue: AppTheme.playerColors[i % AppTheme.playerColors.length].value,
                    ));
                  }
                  final target = int.tryParse(targetController.text) ?? 100;
                  setState(() {
                    _game = RoundsGame(
                      title: widget.gameType == GameType.chinchon ? 'Chinchón' : 'Uno / Rummy',
                      players: newPlayers,
                      eliminationScore: target,
                      allowRehook: rehook,
                    );
                    _sessionId = const Uuid().v4();
                    _dateStarted = DateTime.now();
                  });
                  _saveState();
                  Navigator.of(ctx).pop();
                },
                child: const Text('Comenzar'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${_game.title} (Límite: ${_game.eliminationScore})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Deshacer Última Ronda',
            onPressed: _game.rounds.isEmpty ? null : _undoRound,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configuración',
            onPressed: _editSettingsDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Player header cards
          Container(
            padding: const EdgeInsets.all(12),
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
            child: Row(
              children: [
                const SizedBox(
                  width: 70,
                  child: Text('Ronda', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ..._game.players.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final p = entry.value;
                  final isDealer = idx == _game.dealerIndex;

                  return Expanded(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isDealer)
                              const Icon(Icons.star, size: 14, color: Colors.amber),
                            Flexible(
                              child: Text(
                                p.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: p.color,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${p.score}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: p.isEliminated ? Colors.red : theme.colorScheme.onSurface,
                            decoration: p.isEliminated ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        if (p.isEliminated && _game.allowRehook)
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(50, 24),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () => _rehook(p.id),
                            child: const Text('Reenganchar', style: TextStyle(fontSize: 10)),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable list of rounds
          Expanded(
            child: _game.rounds.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.format_list_numbered, size: 64, color: theme.disabledColor),
                        const SizedBox(height: 12),
                        const Text('No hay rondas anotadas todavía'),
                        const SizedBox(height: 4),
                        const Text('Presiona el botón "+ Anotar Ronda" abajo', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _game.rounds.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, index) {
                      final round = _game.rounds[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 70,
                              child: Text(
                                'Ronda ${round.roundNumber}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            ..._game.players.map((p) {
                              final pts = round.playerPoints[p.id];
                              return Expanded(
                                child: Text(
                                  pts != null ? '+$pts' : '-',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: pts == 0 ? Colors.green : null,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
            ),
            child: FilledButton.icon(
              onPressed: _game.isFinished ? null : _openAddRoundModal,
              icon: const Icon(Icons.add),
              label: const Text('Anotar Ronda', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
