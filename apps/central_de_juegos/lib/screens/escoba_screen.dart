import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/game_type.dart';
import '../models/game_session.dart';
import '../models/player.dart';
import '../models/escoba_game.dart';
import '../services/storage_service.dart';
import '../services/sound_haptics_service.dart';
import '../theme/app_theme.dart';
import '../widgets/winner_dialog.dart';
import '../widgets/player_name_dialog.dart';

class EscobaScreen extends StatefulWidget {
  final GameSession? existingSession;

  const EscobaScreen({super.key, this.existingSession});

  @override
  State<EscobaScreen> createState() => _EscobaScreenState();
}

class _EscobaScreenState extends State<EscobaScreen> {
  late String _sessionId;
  late DateTime _dateStarted;
  late EscobaGame _game;

  @override
  void initState() {
    super.initState();
    if (widget.existingSession != null &&
        widget.existingSession!.gameType == GameType.escoba) {
      _sessionId = widget.existingSession!.id;
      _dateStarted = widget.existingSession!.dateStarted;
      try {
        final map = jsonDecode(widget.existingSession!.stateJson) as Map<String, dynamic>;
        _game = EscobaGame.fromJson(map);
      } catch (_) {
        _game = _defaultGame();
      }
    } else {
      _sessionId = const Uuid().v4();
      _dateStarted = DateTime.now();
      _game = _defaultGame();
    }
  }

  EscobaGame _defaultGame() {
    return EscobaGame(
      players: [
        Player(id: 'p1', name: 'Jugador 1', colorValue: AppTheme.playerColors[0].value),
        Player(id: 'p2', name: 'Jugador 2', colorValue: AppTheme.playerColors[1].value),
      ],
      targetScore: 15,
    );
  }

  void _saveState() {
    final winner = _game.winnerId != null
        ? _game.players.firstWhere((p) => p.id == _game.winnerId).name
        : null;

    final session = GameSession(
      id: _sessionId,
      gameType: GameType.escoba,
      title: 'Escoba de 15 (${_game.players.map((p) => p.name).join(' vs ')})',
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

  void _openAddHandModal() {
    final escobasControllers = {for (var p in _game.players) p.id: TextEditingController(text: '0')};
    String? mostCardsWinner;
    String? mostOrosWinner;
    String? sieteDeOroWinner;
    String? setentaWinner;

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
                      'Anotar Mano ${_game.hands.length + 1}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Escobas input
                    const Text('Escobas Limpias:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ..._game.players.map((p) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Row(
                          children: [
                            CircleAvatar(backgroundColor: p.color, radius: 10),
                            const SizedBox(width: 8),
                            Expanded(child: Text(p.name)),
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: escobasControllers[p.id],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 12),
                    // Tantos específicos (1 pt cada uno)
                    _buildSelectorRow('Mayoría de Cartas (+1)', mostCardsWinner, (val) {
                      setModalState(() => mostCardsWinner = val);
                    }),
                    _buildSelectorRow('Mayoría de Oros (+1)', mostOrosWinner, (val) {
                      setModalState(() => mostOrosWinner = val);
                    }),
                    _buildSelectorRow('7 de Oro (+1)', sieteDeOroWinner, (val) {
                      setModalState(() => sieteDeOroWinner = val);
                    }),
                    _buildSelectorRow('La Setenta (+1)', setentaWinner, (val) {
                      setModalState(() => setentaWinner = val);
                    }),

                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        final entries = <String, EscobaHandEntry>{};
                        for (var p in _game.players) {
                          entries[p.id] = EscobaHandEntry(
                            escobas: int.tryParse(escobasControllers[p.id]?.text ?? '0') ?? 0,
                            hasMostCards: mostCardsWinner == p.id,
                            hasMostOros: mostOrosWinner == p.id,
                            hasSieteDeOro: sieteDeOroWinner == p.id,
                            hasSetenta: setentaWinner == p.id,
                          );
                        }
                        Navigator.of(ctx).pop();
                        _applyHand(entries);
                      },
                      child: const Text('Confirmar Mano'),
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

  Widget _buildSelectorRow(String title, String? selectedId, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            children: [
              ChoiceChip(
                label: const Text('Ninguno / Empate'),
                selected: selectedId == null,
                onSelected: (_) => onChanged(null),
              ),
              ..._game.players.map((p) {
                return ChoiceChip(
                  label: Text(p.name),
                  selected: selectedId == p.id,
                  onSelected: (sel) => onChanged(sel ? p.id : null),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  void _applyHand(Map<String, EscobaHandEntry> entries) {
    SoundHapticsService.pointAdded();
    setState(() {
      _game.addHand(entries);
    });
    _saveState();

    if (_game.isFinished) {
      final winner = _game.players.firstWhere((p) => p.id == _game.winnerId);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => WinnerDialog(
          winnerName: winner.name,
          subtitle: '¡Llegó a ${winner.score} puntos y ganó la Escoba!',
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
        title: Text('Escoba del 15 a ${_game.targetScore} pts'),
      ),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
            child: Row(
              children: _game.players.map((p) {
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
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: p.color,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.edit, size: 14, color: p.color.withOpacity(0.8)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${p.score} pts',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),

          // Hands list
          Expanded(
            child: _game.hands.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cleaning_services, size: 64, color: theme.disabledColor),
                        const SizedBox(height: 12),
                        const Text('No hay manos anotadas'),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _game.hands.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, idx) {
                      final hand = _game.hands[idx];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            Text('Mano ${hand.handNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const Spacer(),
                            ..._game.players.map((p) {
                              final entry = hand.playerEntries[p.id];
                              final total = entry?.calculateTotal() ?? 0;
                              return SizedBox(
                                width: 80,
                                child: Text(
                                  '+$total',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
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

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FilledButton.icon(
              onPressed: _game.isFinished ? null : _openAddHandModal,
              icon: const Icon(Icons.add),
              label: const Text('Anotar Mano'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            ),
          ),
        ],
      ),
    );
  }
}
