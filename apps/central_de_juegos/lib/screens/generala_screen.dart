import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/game_type.dart';
import '../models/game_session.dart';
import '../models/player.dart';
import '../models/generala_game.dart';
import '../services/storage_service.dart';
import '../services/sound_haptics_service.dart';
import '../theme/app_theme.dart';
import '../widgets/winner_dialog.dart';
import '../widgets/player_name_dialog.dart';

class GeneralaScreen extends StatefulWidget {
  final GameSession? existingSession;
  final List<Player>? configuredPlayers;

  const GeneralaScreen({
    super.key,
    this.existingSession,
    this.configuredPlayers,
  });

  @override
  State<GeneralaScreen> createState() => _GeneralaScreenState();
}

class _GeneralaScreenState extends State<GeneralaScreen> {
  late String _sessionId;
  late DateTime _dateStarted;
  late GeneralaGame _game;

  @override
  void initState() {
    super.initState();
    if (widget.existingSession != null &&
        widget.existingSession!.gameType == GameType.generala) {
      _sessionId = widget.existingSession!.id;
      _dateStarted = widget.existingSession!.dateStarted;
      try {
        final map = jsonDecode(widget.existingSession!.stateJson) as Map<String, dynamic>;
        _game = GeneralaGame.fromJson(map);
      } catch (_) {
        _game = _defaultGame();
      }
    } else if (widget.configuredPlayers != null && widget.configuredPlayers!.isNotEmpty) {
      _sessionId = const Uuid().v4();
      _dateStarted = DateTime.now();
      _game = GeneralaGame(
        players: widget.configuredPlayers!
            .map((p) => Player(id: p.id, name: p.name, colorValue: p.colorValue, score: 0))
            .toList(),
      );
    } else {
      _sessionId = const Uuid().v4();
      _dateStarted = DateTime.now();
      _game = _defaultGame();
    }
  }

  GeneralaGame _defaultGame() {
    return GeneralaGame(
      players: [
        Player(id: 'p1', name: 'Jugador 1', colorValue: AppTheme.playerColors[0].value),
        Player(id: 'p2', name: 'Jugador 2', colorValue: AppTheme.playerColors[1].value),
      ],
    );
  }

  void _saveState() {
    final session = GameSession(
      id: _sessionId,
      gameType: GameType.generala,
      title: 'Generala (${_game.players.map((p) => p.name).join(' vs ')})',
      dateStarted: _dateStarted,
      dateFinished: _game.isFinished ? DateTime.now() : null,
      isFinished: _game.isFinished,
      winnerName: _game.winner?.name,
      stateJson: jsonEncode(_game.toJson()),
    );

    if (_game.isFinished) {
      StorageService.saveToHistory(session);
      StorageService.clearActiveSession();
    } else {
      StorageService.saveActiveSession(session);
    }
  }

  void _openScorePicker(String playerId, GeneralaCategory category) {
    final sheet = _game.sheets[playerId];
    if (sheet == null) return;
    final currentScore = sheet.scores[category];
    final isServida = sheet.isServida[category] ?? false;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Anotar ${category.displayName}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Number categories (1 to 6)
              if (category.index <= GeneralaCategory.sixes.index) ...[
                _buildNumberOptions(playerId, category),
              ] else ...[
                // Game categories (Escalera, Full, Poker, Generala, Doble Generala)
                _buildGameCategoryOptions(playerId, category),
              ],

              const SizedBox(height: 12),
              // Option to cross out (Tachar)
              OutlinedButton.icon(
                icon: const Icon(Icons.close, color: Colors.red),
                label: const Text('Tachar Casilla (0 pts)', style: TextStyle(color: Colors.red)),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _applyScore(playerId, category, 0, servida: false);
                },
              ),
              if (currentScore != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _applyScore(playerId, category, null);
                  },
                  child: const Text('Limpiar Casilla'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildNumberOptions(String playerId, GeneralaCategory category) {
    final faceValue = category.index + 1; // 1 to 6
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: List.generate(5, (i) {
        final count = i + 1; // 1 to 5 dice
        final total = count * faceValue;
        return FilledButton.tonal(
          onPressed: () {
            Navigator.of(context).pop();
            _applyScore(playerId, category, total, servida: false);
          },
          child: Text('$count dados = $total'),
        );
      }),
    );
  }

  Widget _buildGameCategoryOptions(String playerId, GeneralaCategory category) {
    final standardPts = category.standardPoints;
    final servidaPts = category.servidaPoints;

    return Row(
      children: [
        Expanded(
          child: FilledButton.tonal(
            onPressed: () {
              Navigator.of(context).pop();
              _applyScore(playerId, category, standardPts, servida: false);
            },
            child: Text('Armada ($standardPts pts)'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _applyScore(playerId, category, servidaPts, servida: true);
            },
            child: Text('Servida ($servidaPts pts)'),
          ),
        ),
      ],
    );
  }

  void _applyScore(String playerId, GeneralaCategory category, int? score, {bool servida = false}) {
    SoundHapticsService.pointAdded();
    setState(() {
      _game.setScore(playerId, category, score, servida: servida);
    });
    _saveState();

    if (_game.isFinished) {
      final w = _game.winner;
      if (w != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => WinnerDialog(
            winnerName: w.name,
            subtitle: '¡Puntaje final: ${w.score} puntos!',
            onRematch: () {
              setState(() {
                _game = _defaultGame();
                _sessionId = const Uuid().v4();
                _dateStarted = DateTime.now();
              });
              _saveState();
            },
            onNewGame: _managePlayersDialog,
            onExit: () => Navigator.of(context).pop(),
          ),
        );
      }
    }
  }

  void _managePlayersDialog() {
    final controllers = _game.players.map((p) => TextEditingController(text: p.name)).toList();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Text('Jugadores de Generala'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: [
                  ...List.generate(controllers.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppTheme.playerColors[i % AppTheme.playerColors.length],
                            radius: 14,
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
                                setModalState(() {
                                  controllers.removeAt(i);
                                });
                              },
                            ),
                        ],
                      ),
                    );
                  }),
                  if (controllers.length < 6)
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
                  setState(() {
                    _game = GeneralaGame(players: newPlayers);
                    _sessionId = const Uuid().v4();
                    _dateStarted = DateTime.now();
                  });
                  _saveState();
                  Navigator.of(ctx).pop();
                },
                child: const Text('Guardar'),
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
        title: const Text('Generala'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add),
            tooltip: 'Configurar Jugadores',
            onPressed: _managePlayersDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Table header: player avatars & live totals
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
            child: Row(
              children: [
                const SizedBox(
                  width: 110,
                  child: Text('Categoría', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ..._game.players.map((p) {
                  return Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final newName = await PlayerNameDialog.show(
                          context,
                          currentName: p.name,
                          title: 'Editar Jugador',
                        );
                        if (newName != null && newName.isNotEmpty) {
                          setState(() {
                            p.name = newName;
                          });
                          _saveState();
                        }
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
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
                              const SizedBox(width: 4),
                              Icon(Icons.edit, size: 12, color: p.color.withOpacity(0.7)),
                            ],
                          ),
                          Text(
                            '${p.score} pts',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable categories table
          Expanded(
            child: ListView.separated(
              itemCount: GeneralaCategory.values.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, index) {
                final category = GeneralaCategory.values[index];
                return Row(
                  children: [
                    // Category Name
                    Container(
                      width: 110,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      child: Text(
                        category.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                    // Cells for each player
                    ..._game.players.map((p) {
                      final sheet = _game.sheets[p.id];
                      final score = sheet?.scores[category];
                      final isServ = sheet?.isServida[category] ?? false;

                      return Expanded(
                        child: InkWell(
                          onTap: () => _openScorePicker(p.id, category),
                          child: Container(
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: score != null
                                  ? (score == 0 ? Colors.red.withOpacity(0.08) : p.color.withOpacity(0.08))
                                  : null,
                              border: Border(left: BorderSide(color: theme.dividerColor, width: 0.5)),
                            ),
                            child: score == null
                                ? Icon(Icons.add, size: 16, color: theme.disabledColor)
                                : (score == 0
                                    ? const Icon(Icons.close, size: 20, color: Colors.red)
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '$score',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: p.color,
                                            ),
                                          ),
                                          if (isServ)
                                            const Text(
                                              ' S',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.amber,
                                              ),
                                            ),
                                        ],
                                      )),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
