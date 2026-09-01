import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/player.dart';
import '../theme/app_theme.dart';
import '../services/sound_haptics_service.dart';
import '../widgets/player_name_dialog.dart';

class GameSetupScreen extends StatefulWidget {
  final String gameTitle;
  final int minPlayers;
  final int maxPlayers;
  final List<Player>? initialPlayers;
  final void Function(List<Player> players, Map<String, dynamic> config) onStartGame;

  const GameSetupScreen({
    super.key,
    required this.gameTitle,
    this.minPlayers = 2,
    this.maxPlayers = 8,
    this.initialPlayers,
    required this.onStartGame,
  });

  @override
  State<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends State<GameSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late List<Player> _players;

  // Diez Mil config
  int _entryScore = 750;
  int _minRoundScore = 350;

  @override
  void initState() {
    super.initState();
    if (widget.initialPlayers != null && widget.initialPlayers!.isNotEmpty) {
      _players = widget.initialPlayers!
          .map((p) => Player(id: p.id, name: p.name, colorValue: p.colorValue))
          .toList();
    } else {
      _players = [
        Player(
          id: const Uuid().v4(),
          name: 'Jugador 1',
          colorValue: AppTheme.playerColors[0].value,
        ),
        Player(
          id: const Uuid().v4(),
          name: 'Jugador 2',
          colorValue: AppTheme.playerColors[1].value,
        ),
      ];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addPlayer() {
    final name = _nameController.text.trim();
    final effectiveName = name.isEmpty ? 'Jugador ${_players.length + 1}' : name;

    if (_players.length >= widget.maxPlayers) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Máximo ${widget.maxPlayers} jugadores permitidos')),
      );
      return;
    }

    final colorIdx = _players.length % AppTheme.playerColors.length;
    setState(() {
      _players.add(
        Player(
          id: const Uuid().v4(),
          name: effectiveName,
          colorValue: AppTheme.playerColors[colorIdx].value,
        ),
      );
      _nameController.clear();
    });

    SoundHapticsService.click();
    _focusNode.requestFocus();
  }

  void _removePlayer(int index) {
    if (_players.length <= widget.minPlayers) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mínimo ${widget.minPlayers} jugadores requeridos')),
      );
      return;
    }
    setState(() {
      _players.removeAt(index);
    });
    SoundHapticsService.click();
  }

  void _editPlayerName(Player player) async {
    final newName = await PlayerNameDialog.show(
      context,
      currentName: player.name,
      title: 'Editar Nombre',
    );
    if (newName != null && newName.isNotEmpty) {
      setState(() {
        player.name = newName;
      });
      SoundHapticsService.click();
    }
  }

  void _pickColor(Player player) async {
    final selected = await showDialog<Color>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Elegir Color', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: AppTheme.playerColors.map((c) {
            return GestureDetector(
              onTap: () => Navigator.of(ctx).pop(c),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: player.colorValue == c.value ? Colors.white : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );

    if (selected != null) {
      setState(() {
        player.colorValue = selected.value;
      });
      SoundHapticsService.click();
    }
  }

  void _submit() {
    if (_players.length < widget.minPlayers) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Agrega al menos ${widget.minPlayers} jugadores para comenzar')),
      );
      return;
    }

    SoundHapticsService.click();
    widget.onStartGame(_players, {
      'entryScore': _entryScore,
      'minRoundScore': _minRoundScore,
    });
  }

  @override
  Widget build(BuildContext context) {
    final headerCode = widget.gameTitle.toUpperCase().replaceAll(' ', '_');
    final isDiezMil = widget.gameTitle.toLowerCase().contains('diez');

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
            Text(
              headerCode,
              style: const TextStyle(
                color: AppTheme.cyberGold,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title & Subtitle in Spanish
              const Text(
                'Nuevo Juego',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Agrega jugadores y define el orden de turno.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 18),

              // Player input row with white background box + golden square '+' button
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _nameController,
                        focusNode: _focusNode,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Nombre del jugador...',
                          hintStyle: TextStyle(color: Colors.black38, fontSize: 15),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                        ),
                        onSubmitted: (_) => _addPlayer(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _addPlayer,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppTheme.cyberGold,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(Icons.add, color: Colors.black, size: 28),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Reorderable list of players
              Expanded(
                child: ReorderableListView.builder(
                  itemCount: _players.length,
                  onReorder: (oldIdx, newIdx) {
                    setState(() {
                      if (oldIdx < newIdx) {
                        newIdx -= 1;
                      }
                      final p = _players.removeAt(oldIdx);
                      _players.insert(newIdx, p);
                    });
                    SoundHapticsService.click();
                  },
                  itemBuilder: (ctx, idx) {
                    final player = _players[idx];

                    return Container(
                      key: ValueKey(player.id),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderDark, width: 1),
                      ),
                      child: Row(
                        children: [
                          // Drag handle / Turn order
                          ReorderableDragStartListener(
                            index: idx,
                            child: const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: Icon(Icons.drag_indicator, color: Colors.white38, size: 20),
                            ),
                          ),

                          // Player Name (editable on tap)
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _editPlayerName(player),
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      player.name,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.edit, size: 14, color: Colors.white38),
                                ],
                              ),
                            ),
                          ),

                          // Color selector circle pill
                          GestureDetector(
                            onTap: () => _pickColor(player),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: player.color,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white24, width: 1.5),
                              ),
                            ),
                          ),

                          const SizedBox(width: 14),

                          // Remove X button
                          GestureDetector(
                            onTap: () => _removePlayer(idx),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white54,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Diez Mil Specific Config (Mínimo para entrar & Mínimo por ronda)
              if (isDiezMil) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderDark),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Mínimo para Entrar (Apertura):',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
                          ),
                          DropdownButton<int>(
                            value: _entryScore,
                            dropdownColor: AppTheme.surfaceDark,
                            style: const TextStyle(color: AppTheme.cyberGold, fontWeight: FontWeight.w900, fontSize: 14),
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(value: 0, child: Text('Sin mínimo')),
                              DropdownMenuItem(value: 500, child: Text('500 pts')),
                              DropdownMenuItem(value: 750, child: Text('750 pts (Def)')),
                              DropdownMenuItem(value: 1000, child: Text('1.000 pts')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _entryScore = val);
                            },
                          ),
                        ],
                      ),
                      const Divider(color: AppTheme.borderDark, height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Mínimo por Ronda (Plantarse):',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
                          ),
                          DropdownButton<int>(
                            value: _minRoundScore,
                            dropdownColor: AppTheme.surfaceDark,
                            style: const TextStyle(color: AppTheme.cyberGold, fontWeight: FontWeight.w900, fontSize: 14),
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(value: 0, child: Text('Sin mínimo')),
                              DropdownMenuItem(value: 200, child: Text('200 pts')),
                              DropdownMenuItem(value: 300, child: Text('300 pts')),
                              DropdownMenuItem(value: 350, child: Text('350 pts (Def)')),
                              DropdownMenuItem(value: 400, child: Text('400 pts')),
                              DropdownMenuItem(value: 500, child: Text('500 pts')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _minRoundScore = val);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Big full-width Golden "COMENZAR JUEGO ▶" button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.cyberGold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'COMENZAR JUEGO',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_right, color: Colors.black, size: 26),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
