import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/game_type.dart';
import '../models/game_session.dart';
import '../models/player.dart';
import '../services/storage_service.dart';
import '../services/sound_haptics_service.dart';
import '../theme/app_theme.dart';
import '../widgets/quick_score_dialog.dart';
import '../widgets/winner_dialog.dart';

class CustomCounterScreen extends StatefulWidget {
  final GameSession? existingSession;

  const CustomCounterScreen({super.key, this.existingSession});

  @override
  State<CustomCounterScreen> createState() => _CustomCounterScreenState();
}

class _CustomCounterScreenState extends State<CustomCounterScreen> {
  late String _sessionId;
  late DateTime _dateStarted;
  late List<Player> _players;
  int? _targetScore;
  bool _isFinished = false;
  String? _winnerName;

  @override
  void initState() {
    super.initState();
    if (widget.existingSession != null &&
        widget.existingSession!.gameType == GameType.custom) {
      _sessionId = widget.existingSession!.id;
      _dateStarted = widget.existingSession!.dateStarted;
      try {
        final map = jsonDecode(widget.existingSession!.stateJson) as Map<String, dynamic>;
        final pList = (map['players'] as List<dynamic>)
            .map((e) => Player.fromJson(e as Map<String, dynamic>))
            .toList();
        _players = pList;
        _targetScore = map['targetScore'] as int?;
        _isFinished = map['isFinished'] as bool? ?? false;
        _winnerName = map['winnerName'] as String?;
      } catch (_) {
        _initDefault();
      }
    } else {
      _initDefault();
    }
  }

  void _initDefault() {
    _sessionId = const Uuid().v4();
    _dateStarted = DateTime.now();
    _players = [
      Player(id: 'p1', name: 'Jugador 1', colorValue: AppTheme.playerColors[0].value),
      Player(id: 'p2', name: 'Jugador 2', colorValue: AppTheme.playerColors[1].value),
    ];
    _targetScore = null;
    _isFinished = false;
    _winnerName = null;
  }

  void _saveState() {
    final stateMap = {
      'players': _players.map((p) => p.toJson()).toList(),
      'targetScore': _targetScore,
      'isFinished': _isFinished,
      'winnerName': _winnerName,
    };

    final session = GameSession(
      id: _sessionId,
      gameType: GameType.custom,
      title: 'Contador (${_players.map((p) => p.name).join(' vs ')})',
      dateStarted: _dateStarted,
      dateFinished: _isFinished ? DateTime.now() : null,
      isFinished: _isFinished,
      winnerName: _winnerName,
      stateJson: jsonEncode(stateMap),
    );

    if (_isFinished) {
      StorageService.saveToHistory(session);
      StorageService.clearActiveSession();
    } else {
      StorageService.saveActiveSession(session);
    }
  }

  void _addPoints(Player player, int points) {
    if (_isFinished) return;
    if (points >= 0) {
      SoundHapticsService.pointAdded();
    } else {
      SoundHapticsService.pointSubtracted();
    }

    setState(() {
      player.score += points;
      if (_targetScore != null && player.score >= _targetScore!) {
        _isFinished = true;
        _winnerName = player.name;
      }
    });
    _saveState();

    if (_isFinished) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => WinnerDialog(
          winnerName: _winnerName ?? player.name,
          subtitle: '¡Alcanzó la meta de $_targetScore puntos!',
          onRematch: () {
            setState(() {
              for (var p in _players) {
                p.score = 0;
              }
              _isFinished = false;
              _winnerName = null;
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

  void _resetScores() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reiniciar Puntajes'),
        content: const Text('¿Deseas reiniciar todos los contadores a 0?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                for (var p in _players) {
                  p.score = 0;
                }
                _isFinished = false;
                _winnerName = null;
              });
              _saveState();
            },
            child: const Text('Reiniciar'),
          ),
        ],
      ),
    );
  }

  void _managePlayersDialog() {
    final controllers = _players.map((p) => TextEditingController(text: p.name)).toList();
    final targetController = TextEditingController(text: _targetScore?.toString() ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Text('Configurar Contador'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: [
                  TextField(
                    controller: targetController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Puntaje Objetivo (Opcional)',
                      hintText: 'Ej: 50, 100, etc.',
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Jugadores o Equipos:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...List.generate(controllers.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
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
                          if (controllers.length > 1)
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
                  if (controllers.length < 12)
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
                    final oldScore = i < _players.length ? _players[i].score : 0;
                    newPlayers.add(Player(
                      id: 'p${i + 1}',
                      name: name,
                      score: oldScore,
                      colorValue: AppTheme.playerColors[i % AppTheme.playerColors.length].value,
                    ));
                  }
                  final target = int.tryParse(targetController.text);
                  setState(() {
                    _players = newPlayers;
                    _targetScore = target;
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

    // Determine leader score
    int maxScore = -999999;
    for (var p in _players) {
      if (p.score > maxScore) maxScore = p.score;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_targetScore != null ? 'Meta: $_targetScore pts' : 'Contador Libre'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reiniciar a 0',
            onPressed: _resetScores,
          ),
          IconButton(
            icon: const Icon(Icons.group_add),
            tooltip: 'Configurar Jugadores',
            onPressed: _managePlayersDialog,
          ),
        ],
      ),
      body: _players.length == 1
          ? Center(child: _buildSinglePlayerCard(_players.first, maxScore, theme))
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _players.length <= 2 ? 1 : 2,
                childAspectRatio: _players.length <= 2 ? 1.5 : 0.85,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _players.length,
              itemBuilder: (ctx, idx) {
                final player = _players[idx];
                return _buildPlayerCard(player, maxScore, theme);
              },
            ),
    );
  }

  Widget _buildSinglePlayerCard(Player player, int maxScore, ThemeData theme) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      child: _buildPlayerCard(player, maxScore, theme),
    );
  }

  Widget _buildPlayerCard(Player player, int maxScore, ThemeData theme) {
    final isLeading = player.score == maxScore && player.score > 0;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isLeading ? Colors.amber : player.color.withOpacity(0.4),
          width: isLeading ? 2.5 : 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              player.color.withOpacity(0.08),
              theme.cardColor,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Header: Avatar, Name & Leader Badge
            Row(
              children: [
                CircleAvatar(backgroundColor: player.color, radius: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    player.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: player.color,
                    ),
                  ),
                ),
                if (isLeading)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.emoji_events, size: 14, color: Colors.amber),
                        SizedBox(width: 2),
                        Text('1°', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber)),
                      ],
                    ),
                  ),
              ],
            ),

            // Giant Score Display (Tap to open custom amount dialog)
            Expanded(
              child: InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => QuickScoreDialog(
                      playerName: player.name,
                      currentScore: player.score,
                      onApply: (delta) => _addPoints(player, delta),
                    ),
                  );
                },
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${player.score}',
                        style: TextStyle(
                          fontSize: _players.length <= 2 ? 64 : 44,
                          fontWeight: FontWeight.w900,
                          color: player.color,
                          height: 1,
                        ),
                      ),
                      Text(
                        'Toca para editar',
                        style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Quick increment / decrement chips
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: [
                _actionChip('-1', () => _addPoints(player, -1), isNegative: true),
                _actionChip('+1', () => _addPoints(player, 1)),
                _actionChip('+5', () => _addPoints(player, 5)),
                _actionChip('+10', () => _addPoints(player, 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionChip(String label, VoidCallback onTap, {bool isNegative = false}) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      padding: EdgeInsets.zero,
      backgroundColor: isNegative ? Colors.red.withOpacity(0.08) : Colors.green.withOpacity(0.08),
      labelStyle: TextStyle(color: isNegative ? Colors.red : Colors.green),
      onPressed: onTap,
    );
  }
}
