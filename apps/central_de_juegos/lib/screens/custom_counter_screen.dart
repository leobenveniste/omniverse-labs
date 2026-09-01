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
import '../widgets/player_name_dialog.dart';

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
      title: _players.length == 2
          ? '${_players[0].name} vs ${_players[1].name}'
          : 'Contador Libre (${_players.length} jugadores)',
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

  void _updateScore(Player player, int delta) {
    if (_isFinished) return;
    SoundHapticsService.pointAdded();

    setState(() {
      player.score += delta;
      if (player.score < 0) player.score = 0;

      if (_targetScore != null && player.score >= _targetScore!) {
        _isFinished = true;
        _winnerName = player.name;
      }
    });

    _saveState();

    if (_isFinished) {
      SoundHapticsService.victory();
      WinnerDialog.show(
        context,
        winnerName: _winnerName ?? player.name,
        gameTitle: 'Contador Libre',
        scores: _players,
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
        onNewGame: () => Navigator.of(context).pop(),
      );
    }
  }

  void _editPlayerConfig(Player player) {
    final nameController = TextEditingController(text: player.name);
    final scoreController = TextEditingController(text: '${player.score}');
    int selectedColor = player.colorValue;

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Configurar Jugador',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Jugador',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: scoreController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Puntaje Actual',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calculate),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Color del Jugador:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: AppTheme.playerColors.map((col) {
                  final isSelected = col.value == selectedColor;
                  return GestureDetector(
                    onTap: () {
                      setModalState(() {
                        selectedColor = col.value;
                      });
                    },
                    child: CircleAvatar(
                      backgroundColor: col,
                      radius: 18,
                      child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () {
                      setModalState(() {
                        scoreController.text = '0';
                      });
                    },
                    child: const Text('Poner a 0'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () {
                      final newName = nameController.text.trim();
                      final newScore = int.tryParse(scoreController.text.trim()) ?? player.score;
                      setState(() {
                        if (newName.isNotEmpty) player.name = newName;
                        player.score = newScore;
                        player.colorValue = selectedColor;
                      });
                      _saveState();
                      Navigator.of(ctx).pop();
                    },
                    child: const Text('Guardar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addPlayer() {
    if (_players.length >= 12) return;
    setState(() {
      final nextIdx = _players.length;
      _players.add(Player(
        id: const Uuid().v4(),
        name: 'Jugador ${nextIdx + 1}',
        colorValue: AppTheme.playerColors[nextIdx % AppTheme.playerColors.length].value,
      ));
    });
    _saveState();
  }

  void _removePlayer(Player player) {
    if (_players.length <= 1) return;
    setState(() {
      _players.removeWhere((p) => p.id == player.id);
    });
    _saveState();
  }

  void _resetScores() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reiniciar Puntajes'),
        content: const Text('¿Deseas reiniciar todos los puntajes a 0?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Reiniciar')),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        for (var p in _players) {
          p.score = 0;
        }
        _isFinished = false;
        _winnerName = null;
      });
      _saveState();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    int maxScore = -999999;
    for (var p in _players) {
      if (p.score > maxScore) maxScore = p.score;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_targetScore != null ? 'Meta: $_targetScore pts' : 'Contador Libre'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Agregar Jugador',
            onPressed: _players.length < 12 ? _addPlayer : null,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reiniciar a 0',
            onPressed: _resetScores,
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _players.length <= 2 ? 1 : 2,
          childAspectRatio: _players.length <= 2 ? 1.4 : 0.82,
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
      child: InkWell(
        onTap: () => _updateScore(player, 1), // Touch card to add +1
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                player.color.withOpacity(0.1),
                theme.cardColor,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Header: Name + Config Button
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.emoji_events, color: Colors.amber, size: 14),
                          SizedBox(width: 2),
                          Text('Líder', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber)),
                        ],
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.settings, size: 20),
                    tooltip: 'Configurar Jugador',
                    onPressed: () => _editPlayerConfig(player),
                  ),
                ],
              ),

              // Giant Score Display (Tappable area for +1)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${player.score}',
                        style: TextStyle(
                          fontSize: 54,
                          fontWeight: FontWeight.w900,
                          color: player.color,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Toca para sumar +1',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Quick adjustment chips
              Wrap(
                spacing: 6,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: [
                  _buildScoreChip(player, -5, '-5', isSub: true),
                  _buildScoreChip(player, -1, '-1', isSub: true),
                  _buildScoreChip(player, 5, '+5'),
                  _buildScoreChip(player, 10, '+10'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreChip(Player player, int delta, String label, {bool isSub = false}) {
    return ActionChip(
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isSub ? Colors.red.shade400 : null,
        ),
      ),
      onPressed: () => _updateScore(player, delta),
    );
  }
}
