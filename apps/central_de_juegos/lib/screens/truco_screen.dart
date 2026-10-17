import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../models/game_type.dart';
import '../models/game_session.dart';
import '../models/player.dart';
import '../models/truco_game.dart';
import '../services/storage_service.dart';
import '../services/sound_haptics_service.dart';
import '../theme/app_theme.dart';
import '../widgets/matchstick_painter.dart';
import '../widgets/winner_dialog.dart';
import '../widgets/player_name_dialog.dart';

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
        _game.targetPoints = 30; // Always 30 points
      } catch (_) {
        _game = TrucoGame(targetPoints: 30);
      }
    } else {
      _sessionId = const Uuid().v4();
      _dateStarted = DateTime.now();
      _game = TrucoGame(targetPoints: 30);
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
    if (pts > 0) {
      SoundHapticsService.pointAdded();
    } else {
      SoundHapticsService.pointSubtracted();
    }
    setState(() {
      _game.addPoints(teamIndex, pts, label: label);
    });
    _saveState();

    if (_game.isFinished) {
      SoundHapticsService.victory();
      WinnerDialog.show(
        context,
        winnerName: _game.winnerName ?? 'Ganador',
        gameTitle: 'Truco a 30',
        scores: [
          Player(id: '1', name: _game.team1Name, score: _game.team1Score, colorValue: AppTheme.playerColors[0].value),
          Player(id: '2', name: _game.team2Name, score: _game.team2Score, colorValue: AppTheme.playerColors[1].value),
        ],
        onRematch: () {
          setState(() {
            _game.reset();
            _sessionId = const Uuid().v4();
            _dateStarted = DateTime.now();
          });
          _saveState();
        },
        onNewGame: () {
          Navigator.of(context).pop();
        },
      );
    }
  }

  void _undo() {
    setState(() {
      _game.undo();
    });
    SoundHapticsService.undo();
    _saveState();
  }

  void _faltaEnvidoDialog() {
    final l10n = AppLocalizations.of(context);
    final ptsForT1 = _game.calculateFaltaEnvido(0);
    final ptsForT2 = _game.calculateFaltaEnvido(1);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text(l10n.t('faltaEnvidoTitle'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.t('faltaEnvidoExplanation'),
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: CircleAvatar(backgroundColor: AppTheme.playerColors[0], radius: 14),
              title: Text('${_game.team1Name} (+$ptsForT1)', style: const TextStyle(color: Colors.white)),
              trailing: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppTheme.cyberGold, foregroundColor: Colors.black),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _addPoints(0, ptsForT1, 'Falta Envido (+$ptsForT1)');
                },
                child: Text(l10n.t('save')),
              ),
            ),
            const Divider(color: AppTheme.borderDark),
            ListTile(
              leading: CircleAvatar(backgroundColor: AppTheme.playerColors[1], radius: 14),
              title: Text('${_game.team2Name} (+$ptsForT2)', style: const TextStyle(color: Colors.white)),
              trailing: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppTheme.cyberGold, foregroundColor: Colors.black),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _addPoints(1, ptsForT2, 'Falta Envido (+$ptsForT2)');
                },
                child: Text(l10n.t('save')),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.t('cancel'), style: const TextStyle(color: Colors.white70))),
        ],
      ),
    );
  }

  void _renameTeam(int teamIndex) async {
    final l10n = AppLocalizations.of(context);
    final currentName = teamIndex == 0 ? _game.team1Name : _game.team2Name;
    final newName = await PlayerNameDialog.show(
      context,
      currentName: currentName,
      title: l10n.t('editTeamName'),
    );
    if (newName != null && newName.isNotEmpty) {
      setState(() {
        if (teamIndex == 0) {
          _game.team1Name = newName;
        } else {
          _game.team2Name = newName;
        }
      });
      _saveState();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final appState = CentralDeJuegosApp.of(context);
    final tableMat = appState.tableMat;

    return Scaffold(
      backgroundColor: tableMat.surfaceColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo_dark.png',
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'TRUCO',
              style: TextStyle(
                color: AppTheme.cyberGold,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo, color: Colors.white70),
            tooltip: l10n.t('trucoRules'),
            onPressed: _game.history.isEmpty ? null : _undo,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            tooltip: l10n.t('confirmResetTitle'),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppTheme.surfaceDark,
                  title: Text(l10n.t('confirmResetTitle'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  content: Text(l10n.t('confirmResetMsg'), style: const TextStyle(color: Colors.white70)),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.t('cancel'))),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text(l10n.t('confirmResetBtn')),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                setState(() {
                  _game.reset();
                });
                _saveState();
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: tableMat.backgroundGradient),
        child: Column(
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
                Container(
                  width: 1.5,
                  color: AppTheme.borderDark,
                ),
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
    final l10n = AppLocalizations.of(context);
    final isBuenas = _game.isBuenas(score);
    final scoreLabel = isBuenas
        ? '${score - _game.halfTarget} ${l10n.t('trucoGoodPoints')}'
        : '$score ${l10n.t('trucoBadPoints')}';

    return InkWell(
      onTap: () => _addPoints(teamIndex, 1, '+1'),
      splashColor: color.withValues(alpha: 0.15),
      highlightColor: color.withValues(alpha: 0.08),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          children: [
            // Touchable Name for Renaming at Top
            GestureDetector(
              onTap: () => _renameTeam(teamIndex),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.edit, size: 13, color: color.withValues(alpha: 0.8)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Matchsticks displayed in a single vertical column
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: MatchstickDisplayGrid(
                    score: score,
                    maxScore: _game.targetPoints,
                    color: color,
                    boxSize: 56.0,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 6),

            // Large Clean Score Tag at the Bottom of the column (without redundant number)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              decoration: BoxDecoration(
                color: isBuenas ? Colors.green.shade900.withValues(alpha: 0.4) : Colors.orange.shade900.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isBuenas ? Colors.green : Colors.orange,
                  width: 1.5,
                ),
              ),
              child: Text(
                scoreLabel.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: isBuenas ? Colors.greenAccent : Colors.orangeAccent,
                ),
              ),
            ),

          const SizedBox(height: 6),

          // Quick +/- buttons under score tag
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () => _addPoints(teamIndex, -1, '-1'),
                    child: const Icon(Icons.remove, color: Colors.white70, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: color,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () => _addPoints(teamIndex, 1, '+1'),
                    child: const Icon(Icons.add, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  Widget _buildQuickActionButtons(ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: AppTheme.borderDark, width: 1.2)),
      ),
      child: SafeArea(
        top: false,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _buildTantoChip('Envido (+2)', 2),
            _buildTantoChip('Real Envido (+3)', 3),
            _buildTantoChip('Truco (+2)', 2),
            _buildTantoChip('Retruco (+3)', 3),
            _buildTantoChip('Vale 4 (+4)', 4),
            ActionChip(
              avatar: const Icon(Icons.flash_on, size: 16, color: AppTheme.cyberGold),
              label: Text(l10n.t('faltaEnvidoTitle'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              backgroundColor: AppTheme.cyberGold.withValues(alpha: 0.15),
              side: const BorderSide(color: AppTheme.cyberGold),
              onPressed: _faltaEnvidoDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTantoChip(String label, int points) {
    final l10n = AppLocalizations.of(context);
    final question = l10n.locale.languageCode == 'es'
        ? '¿Quién ganó el $label?'
        : 'Who won $label?';

    return ActionChip(
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: AppTheme.surfaceElevated,
      side: const BorderSide(color: AppTheme.borderDark),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: AppTheme.surfaceDark,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) => Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  question,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: AppTheme.playerColors[0]),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _addPoints(0, points, label);
                        },
                        child: Text(_game.team1Name),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: AppTheme.playerColors[1]),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _addPoints(1, points, label);
                        },
                        child: Text(_game.team2Name),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
