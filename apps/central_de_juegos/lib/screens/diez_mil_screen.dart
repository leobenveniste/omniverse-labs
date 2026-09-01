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

  const DiezMilScreen({super.key, this.existingSession});

  @override
  State<DiezMilScreen> createState() => _DiezMilScreenState();
}

class _DiezMilScreenState extends State<DiezMilScreen> {
  late String _sessionId;
  late DateTime _dateStarted;
  late DiezMilGame _game;

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
      } catch (_) {
        _game = _defaultGame();
      }
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
      entryScore: 750,
    );
  }

  void _saveState() {
    final winner = _game.winnerId != null
        ? _game.players.firstWhere((p) => p.id == _game.winnerId).name
        : null;

    final session = GameSession(
      id: _sessionId,
      gameType: GameType.diezMil,
      title: 'Diez Mil - ${_game.players.map((p) => p.name).join(' vs ')}',
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

  void _addPlayer() {
    if (_game.players.length >= 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Máximo 8 jugadores permitidos')),
      );
      return;
    }
    final nextIdx = _game.players.length;
    setState(() {
      _game.players.add(
        Player(
          id: const Uuid().v4(),
          name: 'Jugador ${nextIdx + 1}',
          colorValue: AppTheme.playerColors[nextIdx % AppTheme.playerColors.length].value,
        ),
      );
    });
    SoundHapticsService.click();
    _saveState();
  }

  void _openAddRoundDialog() {
    final controllers = <String, TextEditingController>{};
    for (var p in _game.players) {
      controllers[p.id] = TextEditingController(text: '0');
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Anotar Ronda #${_game.rounds.length + 1}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                ..._game.players.map((p) {
                  final entered = _game.hasPlayerEntered(p.id);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: p.color.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: p.color.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(backgroundColor: p.color, radius: 12),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                p.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: p.color,
                                ),
                              ),
                            ),
                            if (!entered)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Requiere ${_game.entryScore} para entrar',
                                  style: const TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: controllers[p.id],
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                decoration: const InputDecoration(
                                  labelText: 'Puntos del Tiro',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () {
                                setModalState(() {
                                  controllers[p.id]!.text = '0';
                                });
                              },
                              child: const Text('0 (Perdió)'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Quick dice math chips
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _buildScoreChip('+50', 50, controllers[p.id]!, setModalState),
                            _buildScoreChip('+100', 100, controllers[p.id]!, setModalState),
                            _buildScoreChip('+200', 200, controllers[p.id]!, setModalState),
                            _buildScoreChip('+300', 300, controllers[p.id]!, setModalState),
                            _buildScoreChip('+400', 400, controllers[p.id]!, setModalState),
                            _buildScoreChip('+500', 500, controllers[p.id]!, setModalState),
                            _buildScoreChip('+600', 600, controllers[p.id]!, setModalState),
                            _buildScoreChip('+1000', 1000, controllers[p.id]!, setModalState),
                            _buildScoreChip('+1500 (Escalera)', 1500, controllers[p.id]!, setModalState),
                          ],
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      final roundScores = <String, int>{};
                      for (var p in _game.players) {
                        int pts = int.tryParse(controllers[p.id]?.text.trim() ?? '0') ?? 0;
                        final entered = _game.hasPlayerEntered(p.id);
                        if (!entered && pts < _game.entryScore) {
                          pts = 0; // Did not reach minimum entry
                        }
                        roundScores[p.id] = pts;
                      }

                      Navigator.of(ctx).pop();

                      setState(() {
                        _game.addRound(roundScores);
                      });

                      SoundHapticsService.pointAdded();
                      _saveState();

                      if (_game.isFinished) {
                        SoundHapticsService.victory();
                        final winner = _game.players.firstWhere((p) => p.id == _game.winnerId);
                        WinnerDialog.show(
                          context,
                          winnerName: winner.name,
                          gameTitle: 'Diez Mil',
                          scores: _game.players,
                          onRematch: () {
                            setState(() {
                              _game = _defaultGame();
                              _sessionId = const Uuid().v4();
                              _dateStarted = DateTime.now();
                            });
                            _saveState();
                          },
                          onNewGame: () => Navigator.of(context).pop(),
                        );
                      }
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Guardar Ronda', style: TextStyle(fontSize: 16)),
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreChip(
    String label,
    int val,
    TextEditingController ctrl,
    StateSetter setModalState,
  ) {
    return ActionChip(
      visualDensity: VisualDensity.compact,
      label: Text(label, style: const TextStyle(fontSize: 11)),
      onPressed: () {
        setModalState(() {
          final cur = int.tryParse(ctrl.text) ?? 0;
          ctrl.text = '${cur + val}';
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Diez Mil a ${_game.targetScore}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Agregar Jugador',
            onPressed: _game.rounds.isEmpty ? _addPlayer : null,
          ),
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Deshacer Última Ronda',
            onPressed: _game.rounds.isEmpty
                ? null
                : () {
                    setState(() {
                      _game.undoLastRound();
                    });
                    SoundHapticsService.undo();
                    _saveState();
                  },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reiniciar Partida',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Reiniciar Partida'),
                  content: const Text('¿Deseas reiniciar la planilla de Diez Mil a 0?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
                    FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Reiniciar')),
                  ],
                ),
              );
              if (confirm == true) {
                setState(() {
                  _game = _defaultGame();
                  _sessionId = const Uuid().v4();
                  _dateStarted = DateTime.now();
                });
                _saveState();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Top Player Scorecards Carousel
          Container(
            height: 120,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              border: Border(bottom: BorderSide(color: theme.dividerColor)),
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _game.players.length,
              itemBuilder: (ctx, idx) {
                final p = _game.players[idx];
                final entered = _game.hasPlayerEntered(p.id);

                return Container(
                  width: 155,
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: p.color.withOpacity(0.4), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final newName = await PlayerNameDialog.show(
                            context,
                            currentName: p.name,
                            title: 'Editar Jugador',
                          );
                          if (newName != null && newName.isNotEmpty) {
                            setState(() => p.name = newName);
                            _saveState();
                          }
                        },
                        child: Row(
                          children: [
                            CircleAvatar(backgroundColor: p.color, radius: 6),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                p.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: p.color,
                                ),
                              ),
                            ),
                            Icon(Icons.edit, size: 11, color: p.color),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${p.score}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: p.color,
                            ),
                          ),
                          Text(
                            entered ? 'Entró' : 'Sin entrar',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: entered ? Colors.green : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: (p.score / _game.targetScore).clamp(0.0, 1.0),
                          minHeight: 5,
                          backgroundColor: p.color.withOpacity(0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(p.color),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Rounds Table
          Expanded(
            child: _game.rounds.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.casino, size: 56, color: theme.disabledColor),
                        const SizedBox(height: 12),
                        const Text(
                          'No hay rondas anotadas',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Toca "+ Anotar Ronda" para registrar tiros',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _game.rounds.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, idx) {
                      final round = _game.rounds[idx];

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'R${round.roundNumber}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Wrap(
                                spacing: 12,
                                runSpacing: 6,
                                children: _game.players.map((p) {
                                  final pts = round.turnScores[p.id] ?? 0;
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircleAvatar(backgroundColor: p.color, radius: 5),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${p.name}: ',
                                        style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                                      ),
                                      Text(
                                        pts > 0 ? '+$pts' : '0',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: pts > 0 ? p.color : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Action Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _openAddRoundDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Anotar Ronda', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
