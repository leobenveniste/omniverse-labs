import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/game_type.dart';
import '../models/game_session.dart';
import '../models/truco_game.dart';
import '../services/storage_service.dart';
import '../services/sound_haptics_service.dart';
import '../theme/app_theme.dart';
import '../widgets/matchstick_painter.dart';
import '../widgets/winner_dialog.dart';

class TrucoScreen extends StatefulWidget {
  final GameSession? existingSession;

  const TrucoScreen({super.key, this.existingSession});

  @override
  State<TrucoScreen> createState() => _TrucoScreenState();
}

class _TrucoScreenState extends State<TrucoScreen> {
  late String _sessionId;
  late DateTime _dateStarted;
  late TrucoGame _game;
  bool _showMatchsticks = true; // Toggle between matchsticks and giant numbers

  @override
  void initState() {
    super.initState();
    if (widget.existingSession != null &&
        widget.existingSession!.gameType == GameType.truco) {
      _sessionId = widget.existingSession!.id;
      _dateStarted = widget.existingSession!.dateStarted;
      try {
        final map = jsonDecode(widget.existingSession!.stateJson) as Map<String, dynamic>;
        _game = TrucoGame.fromJson(map);
      } catch (_) {
        _game = TrucoGame();
      }
    } else {
      _sessionId = const Uuid().v4();
      _dateStarted = DateTime.now();
      _game = TrucoGame();
    }
  }

  void _saveState() {
    final session = GameSession(
      id: _sessionId,
      gameType: GameType.truco,
      title: '${_game.team1Name} vs ${_game.team2Name}',
      dateStarted: _dateStarted,
      dateFinished: _game.isFinished ? DateTime.now() : null,
      isFinished: _game.isFinished,
      winnerName: _game.winnerName,
      stateJson: jsonEncode(_game.toJson()),
    );

    if (_game.isFinished) {
      StorageService.saveToHistory(session);
      StorageService.clearActiveSession();
    } else {
      StorageService.saveActiveSession(session);
    }
  }

  void _addPoints(int teamIndex, int pts, String label) {
    if (_game.isFinished) return;
    SoundHapticsService.pointAdded();
    setState(() {
      _game.addPoints(teamIndex, pts, label: label);
    });
    _saveState();

    if (_game.isFinished) {
      _showWinnerModal();
    }
  }

  void _subtractPoint(int teamIndex) {
    SoundHapticsService.pointSubtracted();
    setState(() {
      _game.subtractPoint(teamIndex);
    });
    _saveState();
  }

  void _undo() {
    SoundHapticsService.click();
    setState(() {
      _game.undo();
    });
    _saveState();
  }

  void _showWinnerModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => WinnerDialog(
        winnerName: _game.winnerName ?? 'Ganador',
        subtitle: '${_game.team1Name} ${_game.team1Score} - ${_game.team2Score} ${_game.team2Name}',
        onRematch: () {
          setState(() {
            _game.reset();
            _sessionId = const Uuid().v4();
            _dateStarted = DateTime.now();
          });
          _saveState();
        },
        onNewGame: () {
          _editSettingsDialog();
        },
        onExit: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _editSettingsDialog() {
    final team1Controller = TextEditingController(text: _game.team1Name);
    final team2Controller = TextEditingController(text: _game.team2Name);
    int selectedTarget = _game.targetPoints;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Text('Configuración de Truco'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: team1Controller,
                  decoration: const InputDecoration(labelText: 'Nombre Equipo 1'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: team2Controller,
                  decoration: const InputDecoration(labelText: 'Nombre Equipo 2'),
                ),
                const SizedBox(height: 20),
                const Text('Puntos de la Partida:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 15, label: Text('15 pts')),
                    ButtonSegment(value: 24, label: Text('24 pts')),
                    ButtonSegment(value: 30, label: Text('30 pts')),
                  ],
                  selected: {selectedTarget},
                  onSelectionChanged: (val) {
                    setModalState(() {
                      selectedTarget = val.first;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _game.team1Name = team1Controller.text.trim().isEmpty ? 'Nosotros' : team1Controller.text.trim();
                    _game.team2Name = team2Controller.text.trim().isEmpty ? 'Ellos' : team2Controller.text.trim();
                    _game.targetPoints = selectedTarget;
                    _game.reset();
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
        title: Text('Truco a ${_game.targetPoints}'),
        actions: [
          IconButton(
            icon: Icon(_showMatchsticks ? Icons.format_list_numbered : Icons.grid_view),
            tooltip: _showMatchsticks ? 'Ver Números Gigantes' : 'Ver Fósforos',
            onPressed: () {
              setState(() {
                _showMatchsticks = !_showMatchsticks;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Deshacer',
            onPressed: _game.history.isEmpty ? null : _undo,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Opciones',
            onPressed: _editSettingsDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Score Columns
          Expanded(
            child: Row(
              children: [
                // Team 1
                Expanded(
                  child: _buildTeamColumn(
                    teamIndex: 0,
                    name: _game.team1Name,
                    score: _game.team1Score,
                    isLeading: _game.team1Score > _game.team2Score,
                    color: AppTheme.playerColors[0],
                  ),
                ),
                const VerticalDivider(width: 1, thickness: 1),
                // Team 2
                Expanded(
                  child: _buildTeamColumn(
                    teamIndex: 1,
                    name: _game.team2Name,
                    score: _game.team2Score,
                    isLeading: _game.team2Score > _game.team1Score,
                    color: AppTheme.playerColors[1],
                  ),
                ),
              ],
            ),
          ),

          // Bottom quick action bar
          _buildQuickActionButtons(theme),
        ],
      ),
    );
  }

  Widget _buildTeamColumn({
    required int teamIndex,
    required String name,
    required int score,
    required bool isLeading,
    required Color color,
  }) {
    final isBuenas = _game.isBuenas(score);
    final displayScore = _game.getDisplayScore(score);
    final scoreLabel = _game.getScoreLabel(score);

    return InkWell(
      onTap: () => _addPoints(teamIndex, 1, '+1'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          children: [
            // Name & Status
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (isBuenas ? Colors.green : Colors.red).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                scoreLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isBuenas ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Visual: Fósforos or Giant Number
            Expanded(
              child: Center(
                child: _showMatchsticks
                    ? SingleChildScrollView(
                        child: MatchstickDisplayGrid(
                          score: score,
                          maxScore: _game.targetPoints,
                          color: color,
                          boxSize: 42,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$score',
                            style: TextStyle(
                              fontSize: 84,
                              fontWeight: FontWeight.w900,
                              color: color,
                              height: 1,
                            ),
                          ),
                          Text(
                            'de ${_game.targetPoints}',
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
              ),
            ),

            // Stepper controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filledTonal(
                  icon: const Icon(Icons.remove),
                  onPressed: score > 0 ? () => _subtractPoint(teamIndex) : null,
                ),
                const SizedBox(width: 16),
                IconButton.filled(
                  icon: const Icon(Icons.add),
                  onPressed: () => _addPoints(teamIndex, 1, '+1'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButtons(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _quickTeamTantoButton(
                  label: '${_game.team1Name}',
                  teamIndex: 0,
                  color: AppTheme.playerColors[0],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _quickTeamTantoButton(
                  label: '${_game.team2Name}',
                  teamIndex: 1,
                  color: AppTheme.playerColors[1],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickTeamTantoButton({
    required String label,
    required int teamIndex,
    required Color color,
  }) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 4,
      children: [
        _tantoChip('+2', 2, teamIndex, 'Envido / Truco', color),
        _tantoChip('+3', 3, teamIndex, 'Real Envido / Retruco', color),
        _tantoChip('+4', 4, teamIndex, 'Vale 4', color),
        ActionChip(
          label: const Text('Falta', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          padding: EdgeInsets.zero,
          onPressed: () {
            final pts = _game.getFaltaEnvidoPoints(teamIndex);
            _addPoints(teamIndex, pts, 'Falta Envido (+$pts)');
          },
        ),
      ],
    );
  }

  Widget _tantoChip(String text, int points, int teamIndex, String label, Color color) {
    return ActionChip(
      label: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      padding: EdgeInsets.zero,
      onPressed: () => _addPoints(teamIndex, points, '$label (+$points)'),
    );
  }
}
