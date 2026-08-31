import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/game_type.dart';
import '../models/game_session.dart';
import '../models/player.dart';
import '../models/burako_game.dart';
import '../services/storage_service.dart';
import '../services/sound_haptics_service.dart';
import '../theme/app_theme.dart';
import '../widgets/winner_dialog.dart';

class BurakoScreen extends StatefulWidget {
  final GameSession? existingSession;

  const BurakoScreen({super.key, this.existingSession});

  @override
  State<BurakoScreen> createState() => _BurakoScreenState();
}

class _BurakoScreenState extends State<BurakoScreen> {
  late String _sessionId;
  late DateTime _dateStarted;
  late BurakoGame _game;

  @override
  void initState() {
    super.initState();
    if (widget.existingSession != null &&
        widget.existingSession!.gameType == GameType.burako) {
      _sessionId = widget.existingSession!.id;
      _dateStarted = widget.existingSession!.dateStarted;
      try {
        final map = jsonDecode(widget.existingSession!.stateJson) as Map<String, dynamic>;
        _game = BurakoGame.fromJson(map);
      } catch (_) {
        _game = _defaultGame();
      }
    } else {
      _sessionId = const Uuid().v4();
      _dateStarted = DateTime.now();
      _game = _defaultGame();
    }
  }

  BurakoGame _defaultGame() {
    return BurakoGame(
      teams: [
        Player(id: 't1', name: 'Nosotros', colorValue: AppTheme.playerColors[0].value),
        Player(id: 't2', name: 'Ellos', colorValue: AppTheme.playerColors[1].value),
      ],
      targetScore: 3000,
    );
  }

  void _saveState() {
    final winner = _game.winnerId != null
        ? _game.teams.firstWhere((t) => t.id == _game.winnerId).name
        : null;

    final session = GameSession(
      id: _sessionId,
      gameType: GameType.burako,
      title: 'Burako (${_game.teams[0].name} vs ${_game.teams[1].name})',
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
    final pureControllers = {for (var t in _game.teams) t.id: TextEditingController(text: '0')};
    final impureControllers = {for (var t in _game.teams) t.id: TextEditingController(text: '0')};
    final tablePointsControllers = {for (var t in _game.teams) t.id: TextEditingController(text: '0')};
    final handPenaltyControllers = {for (var t in _game.teams) t.id: TextEditingController(text: '0')};
    final closedMap = {for (var t in _game.teams) t.id: false};
    final tookDeadMap = {for (var t in _game.teams) t.id: true};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: SingleChildScrollView(
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
                    ..._game.teams.map((team) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                team.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: team.color,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: pureControllers[team.id],
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Canastas Puras (200)',
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: impureControllers[team.id],
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Canastas Impuras (100)',
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: tablePointsControllers[team.id],
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Puntos Mesa',
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: handPenaltyControllers[team.id],
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Resta en Mano',
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: FilterChip(
                                      label: const Text('Cierre (+100)'),
                                      selected: closedMap[team.id]!,
                                      onSelected: (v) {
                                        setModalState(() {
                                          closedMap[team.id] = v;
                                        });
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: FilterChip(
                                      label: const Text('Tomó Muerto'),
                                      selected: tookDeadMap[team.id]!,
                                      onSelected: (v) {
                                        setModalState(() {
                                          tookDeadMap[team.id] = v;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () {
                        final entries = <String, BurakoRoundEntry>{};
                        for (var t in _game.teams) {
                          entries[t.id] = BurakoRoundEntry(
                            pureCanastas: int.tryParse(pureControllers[t.id]?.text ?? '0') ?? 0,
                            impureCanastas: int.tryParse(impureControllers[t.id]?.text ?? '0') ?? 0,
                            tableCardPoints: int.tryParse(tablePointsControllers[t.id]?.text ?? '0') ?? 0,
                            handCardPenalty: int.tryParse(handPenaltyControllers[t.id]?.text ?? '0') ?? 0,
                            hasClosed: closedMap[t.id]!,
                            tookDead: tookDeadMap[t.id]!,
                          );
                        }
                        Navigator.of(ctx).pop();
                        _applyRound(entries);
                      },
                      child: const Text('Guardar Ronda'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _applyRound(Map<String, BurakoRoundEntry> entries) {
    SoundHapticsService.pointAdded();
    setState(() {
      _game.addRound(entries);
    });
    _saveState();

    if (_game.isFinished) {
      final winner = _game.teams.firstWhere((t) => t.id == _game.winnerId);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => WinnerDialog(
          winnerName: winner.name,
          subtitle: '¡Alcanzó ${winner.score} puntos y ganó la partida!',
          onRematch: () {
            setState(() {
              _game = _defaultGame();
              _sessionId = const Uuid().v4();
              _dateStarted = DateTime.now();
            });
            _saveState();
          },
          onNewGame: () {},
          onExit: () => Navigator.of(context).pop(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Burako a ${_game.targetScore} pts'),
      ),
      body: Column(
        children: [
          // Teams banner
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
            child: Row(
              children: _game.teams.map((t) {
                return Expanded(
                  child: Column(
                    children: [
                      Text(
                        t.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: t.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${t.score} pts',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),

          // Rounds list
          Expanded(
            child: _game.rounds.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.grid_view, size: 64, color: theme.disabledColor),
                        const SizedBox(height: 12),
                        const Text('No hay rondas anotadas'),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _game.rounds.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, idx) {
                      final round = _game.rounds[idx];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            Text('Ronda ${round.roundNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const Spacer(),
                            ..._game.teams.map((t) {
                              final entry = round.teamEntries[t.id];
                              final total = entry?.calculateTotal() ?? 0;
                              return SizedBox(
                                width: 100,
                                child: Text(
                                  '+$total',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: total >= 0 ? Colors.green : Colors.red,
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

          // Bottom button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FilledButton.icon(
              onPressed: _game.isFinished ? null : _openAddRoundModal,
              icon: const Icon(Icons.add),
              label: const Text('Anotar Ronda'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            ),
          ),
        ],
      ),
    );
  }
}
