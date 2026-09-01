import 'package:flutter/material.dart';
import '../services/timer_service.dart';

class GlobalTimerBanner extends StatelessWidget {
  const GlobalTimerBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: TimerService(),
      builder: (context, _) {
        final timer = TimerService();

        if (!timer.hasActiveTimer && !timer.isFinished) {
          return const SizedBox.shrink();
        }

        final isFinished = timer.isFinished;
        final theme = Theme.of(context);

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isFinished ? Colors.red.shade700 : theme.colorScheme.primaryContainer,
            border: Border(
              bottom: BorderSide(
                color: isFinished ? Colors.red.shade900 : theme.colorScheme.primary.withOpacity(0.3),
                width: 1.5,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                isFinished ? Icons.alarm_on : Icons.timer,
                color: isFinished ? Colors.white : theme.colorScheme.onPrimaryContainer,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: isFinished
                    ? const Text(
                        '¡TIEMPO TERMINADO!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 1,
                        ),
                      )
                    : Row(
                        children: [
                          Text(
                            'Turno: ${timer.formattedRemaining}',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: timer.progress,
                                minHeight: 6,
                                backgroundColor: theme.colorScheme.onPrimaryContainer.withOpacity(0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  timer.remainingSeconds <= 10 ? Colors.red : theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(width: 8),
              if (!isFinished)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    timer.isRunning ? Icons.pause_circle : Icons.play_circle,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 22,
                  ),
                  tooltip: timer.isRunning ? 'Pausar' : 'Reanudar',
                  onPressed: () {
                    if (timer.isRunning) {
                      timer.pause();
                    } else {
                      timer.resume();
                    }
                  },
                ),
              const SizedBox(width: 6),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.close,
                  color: isFinished ? Colors.white : theme.colorScheme.onPrimaryContainer,
                  size: 20,
                ),
                tooltip: 'Cerrar Temporizador',
                onPressed: () => timer.stop(),
              ),
            ],
          ),
        );
      },
    );
  }
}
