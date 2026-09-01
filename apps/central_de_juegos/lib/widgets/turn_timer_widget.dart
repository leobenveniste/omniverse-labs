import 'package:flutter/material.dart';
import '../services/timer_service.dart';

class TurnTimerWidget extends StatefulWidget {
  const TurnTimerWidget({super.key});

  @override
  State<TurnTimerWidget> createState() => _TurnTimerWidgetState();
}

class _TurnTimerWidgetState extends State<TurnTimerWidget> {
  int _selectedDuration = 60; // seconds

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timerService = TimerService();

    return AnimatedBuilder(
      animation: timerService,
      builder: (context, _) {
        final remaining = timerService.remainingSeconds;
        final isRunning = timerService.isRunning;
        final progress = timerService.progress;
        final isLowTime = remaining <= 10 && remaining > 0;
        final isFinished = timerService.isFinished;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Presets
            Wrap(
              spacing: 8,
              children: [30, 60, 90, 120].map((sec) {
                final isSelected = _selectedDuration == sec && !isRunning;
                return ChoiceChip(
                  label: Text('${sec}s'),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedDuration = sec;
                    });
                    timerService.start(sec);
                    timerService.pause();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Circular Timer
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 190,
                  height: 190,
                  child: CircularProgressIndicator(
                    value: isFinished ? 0.0 : progress,
                    strokeWidth: 14,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    color: isFinished
                        ? Colors.red
                        : (isLowTime ? Colors.red : theme.colorScheme.primary),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isFinished ? '0' : '$remaining',
                      style: TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.w900,
                        color: isFinished || isLowTime
                            ? Colors.red
                            : theme.colorScheme.onSurface,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isFinished ? '¡TIEMPO!' : 'segundos',
                      style: TextStyle(
                        color: isFinished
                            ? Colors.red
                            : theme.colorScheme.onSurfaceVariant,
                        fontSize: 15,
                        fontWeight: isFinished ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 36),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    timerService.start(_selectedDuration);
                    timerService.pause();
                  },
                  icon: const Icon(Icons.replay),
                  label: const Text('Reiniciar'),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: () {
                    if (isRunning) {
                      timerService.pause();
                    } else {
                      if (timerService.remainingSeconds == 0 || isFinished) {
                        timerService.start(_selectedDuration);
                      } else {
                        timerService.resume();
                      }
                    }
                  },
                  icon: Icon(isRunning ? Icons.pause : Icons.play_arrow),
                  label: Text(isRunning ? 'Pausar' : 'Comenzar'),
                  style: FilledButton.styleFrom(
                    backgroundColor: isRunning ? Colors.orange.shade800 : null,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
