import 'package:flutter/material.dart';
import '../models/player.dart';
import '../services/sound_haptics_service.dart';

class WinnerDialog extends StatefulWidget {
  final String winnerName;
  final String? subtitle;
  final VoidCallback onRematch;
  final VoidCallback onNewGame;
  final VoidCallback onExit;

  const WinnerDialog({
    super.key,
    required this.winnerName,
    this.subtitle,
    required this.onRematch,
    required this.onNewGame,
    required this.onExit,
  });

  static Future<void> show(
    BuildContext context, {
    required String winnerName,
    String? gameTitle,
    List<Player>? scores,
    required VoidCallback onRematch,
    required VoidCallback onNewGame,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => WinnerDialog(
        winnerName: winnerName,
        subtitle: gameTitle != null ? '¡Victoria en $gameTitle!' : null,
        onRematch: onRematch,
        onNewGame: onNewGame,
        onExit: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  State<WinnerDialog> createState() => _WinnerDialogState();
}

class _WinnerDialogState extends State<WinnerDialog> {
  @override
  void initState() {
    super.initState();
    SoundHapticsService.winnerCelebration();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events,
                size: 64,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '¡Tenemos Ganador!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.winnerName,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.primary,
              ),
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                widget.subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.replay),
                    label: const Text('Revancha'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onRematch();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Nueva'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onNewGame();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onExit();
              },
              child: const Text('Volver al Menú Principal'),
            ),
          ],
        ),
      ),
    );
  }
}
