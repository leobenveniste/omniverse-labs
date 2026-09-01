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
import '../widgets/player_name_dialog.dart';

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
      title: '${_game.teams[0].name} vs ${_game.teams[1].name}',
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

  void _openAddRoundDialog() {
    final t1 = _game.teams[0];
    final t2 = _game.teams[1];

    final t1BaseCtrl = TextEditingController(text: '0');
    final t1PtsCtrl = TextEditingController(text: '0');
    final t2BaseCtrl = TextEditingController(text: '0');
    final t2PtsCtrl = TextEditingController(text: '0');
    String selectedStarter = t1.id;

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
                      'Anotar Mano #${_game.rounds.length + 1}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Quién comenzó esta mano
                const Text('¿Quién comenzó / salió esta mano?', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: Center(child: Text(t1.name, overflow: TextOverflow.ellipsis)),
                        selected: selectedStarter == t1.id,
                        selectedColor: t1.color.withOpacity(0.2),
                        onSelected: (sel) {
                          if (sel) setModalState(() => selectedStarter = t1.id);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceChip(
                        label: Center(child: Text(t2.name, overflow: TextOverflow.ellipsis)),
                        selected: selectedStarter == t2.id,
                        selectedColor: t2.color.withOpacity(0.2),
                        onSelected: (sel) {
                          if (sel) setModalState(() => selectedStarter = t2.id);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Team 1 Inputs
                _buildTeamInputSection(
                  team: t1,
                  baseCtrl: t1BaseCtrl,
                  ptsCtrl: t1PtsCtrl,
                  setModalState: setModalState,
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // Team 2 Inputs
                _buildTeamInputSection(
                  team: t2,
                  baseCtrl: t2BaseCtrl,
                  ptsCtrl: t2PtsCtrl,
                  setModalState: setModalState,
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      final t1Base = int.tryParse(t1BaseCtrl.text.trim()) ?? 0;
                      final t1Pts = int.tryParse(t1PtsCtrl.text.trim()) ?? 0;
                      final t2Base = int.tryParse(t2BaseCtrl.text.trim()) ?? 0;
                      final t2Pts = int.tryParse(t2PtsCtrl.text.trim()) ?? 0;

                      Navigator.of(ctx).pop();

                      setState(() {
                        _game.addRound(
                          starterTeamId: selectedStarter,
                          scores: {
                            t1.id: BurakoRoundTeamScore(base: t1Base, puntos: t1Pts),
                            t2.id: BurakoRoundTeamScore(base: t2Base, puntos: t2Pts),
                          },
                        );
                      });

                      SoundHapticsService.pointAdded();
                      _saveState();

                      if (_game.isFinished) {
                        SoundHapticsService.victory();
                        final winner = _game.teams.firstWhere((t) => t.id == _game.winnerId);
                        WinnerDialog.show(
                          context,
                          winnerName: winner.name,
                          gameTitle: 'Burako',
                          scores: _game.teams,
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
                    label: const Text('Guardar Ronda'),
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

  Widget _buildTeamInputSection({
    required Player team,
    required TextEditingController baseCtrl,
    required TextEditingController ptsCtrl,
    required StateSetter setModalState,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(backgroundColor: team.color, radius: 10),
            const SizedBox(width: 8),
            Text(
              team.name,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: team.color),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: baseCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Base (Canastas/Muerto)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: ptsCtrl,
                keyboardType: const TextInputType.numberWithOptions(signed: true),
                decoration: const InputDecoration(
                  labelText: 'Puntos (Mesa - Mano)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          children: [
            _buildQuickBaseChip('+100', 100, baseCtrl, setModalState),
            _buildQuickBaseChip('+200', 200, baseCtrl, setModalState),
            _buildQuickBaseChip('+300', 300, baseCtrl, setModalState),
            _buildQuickBaseChip('-100', -100, baseCtrl, setModalState),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickBaseChip(
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
    final t1 = _game.teams[0];
    final t2 = _game.teams[1];

    return Scaffold(
      appBar: AppBar(
        title: Text('Burako a ${_game.targetScore} pts'),
        actions: [
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
                  content: const Text('¿Deseas reiniciar la planilla de Burako a 0?'),
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
          // Table Header: Team 1 | Quién Empezó | Team 2
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
              border: Border(bottom: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
                // Team 1 Name (Editable)
                Expanded(
                  flex: 5,
                  child: GestureDetector(
                    onTap: () async {
                      final newName = await PlayerNameDialog.show(
                        context,
                        currentName: t1.name,
                        title: 'Editar Equipo',
                      );
                      if (newName != null && newName.isNotEmpty) {
                        setState(() => t1.name = newName);
                        _saveState();
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            t1.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: t1.color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.edit, size: 12, color: t1.color.withOpacity(0.8)),
                      ],
                    ),
                  ),
                ),

                // Center Column: Salió
                const Expanded(
                  flex: 3,
                  child: Center(
                    child: Text(
                      'SALIDA',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                  ),
                ),

                // Team 2 Name (Editable)
                Expanded(
                  flex: 5,
                  child: GestureDetector(
                    onTap: () async {
                      final newName = await PlayerNameDialog.show(
                        context,
                        currentName: t2.name,
                        title: 'Editar Equipo',
                      );
                      if (newName != null && newName.isNotEmpty) {
                        setState(() => t2.name = newName);
                        _saveState();
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            t2.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: t2.color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.edit, size: 12, color: t2.color.withOpacity(0.8)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Rounds Table
          Expanded(
            child: _game.rounds.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.grid_view, size: 56, color: theme.disabledColor),
                        const SizedBox(height: 12),
                        const Text(
                          'No hay manos anotadas',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Toca "+ Anotar Ronda" para comenzar',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _game.rounds.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, idx) {
                      final round = _game.rounds[idx];
                      final s1 = round.teamScores[t1.id] ?? BurakoRoundTeamScore();
                      final s2 = round.teamScores[t2.id] ?? BurakoRoundTeamScore();
                      final t1Started = round.starterTeamId == t1.id;
                      final t2Started = round.starterTeamId == t2.id;

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            // Team 1 round detail
                            Expanded(
                              flex: 5,
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Base:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      Text('${s1.base}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Puntos:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      Text('${s1.puntos}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      '${s1.total >= 0 ? "+" : ""}${s1.total}',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        color: t1.color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Center: Starter Indicator
                            Expanded(
                              flex: 3,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'Mano ${round.roundNumber}',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (t1Started)
                                    const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.arrow_back, size: 14, color: Colors.green),
                                        SizedBox(width: 2),
                                        Text('Salió', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                                      ],
                                    )
                                  else if (t2Started)
                                    const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text('Salió', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                                        SizedBox(width: 2),
                                        Icon(Icons.arrow_forward, size: 14, color: Colors.green),
                                      ],
                                    ),
                                ],
                              ),
                            ),

                            // Team 2 round detail
                            Expanded(
                              flex: 5,
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Base:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      Text('${s2.base}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Puntos:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      Text('${s2.puntos}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      '${s2.total >= 0 ? "+" : ""}${s2.total}',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        color: t2.color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Sticky Total Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Team 1 Total
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '${t1.score} pts',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: t1.color,
                              ),
                            ),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (t1.score / _game.targetScore).clamp(0.0, 1.0),
                                minHeight: 6,
                                backgroundColor: t1.color.withOpacity(0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(t1.color),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'TOTAL',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1),
                        ),
                      ),

                      // Team 2 Total
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '${t2.score} pts',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: t2.color,
                              ),
                            ),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (t2.score / _game.targetScore).clamp(0.0, 1.0),
                                minHeight: 6,
                                backgroundColor: t2.color.withOpacity(0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(t2.color),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _openAddRoundDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Anotar Ronda', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
