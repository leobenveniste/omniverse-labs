import 'dart:async';
import 'package:flutter/material.dart';
import '../services/sound_haptics_service.dart';

class TurnTimerWidget extends StatefulWidget {
  const TurnTimerWidget({super.key});

  @override
  State<TurnTimerWidget> createState() => _TurnTimerWidgetState();
}

class _TurnTimerWidgetState extends State<TurnTimerWidget> {
  int _selectedDuration = 60; // seconds
  int _remainingSeconds = 60;
  bool _isRunning = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
        if (_remainingSeconds <= 3 && _remainingSeconds > 0) {
          SoundHapticsService.pointAdded();
        }
      } else {
        timer.cancel();
        setState(() {
          _isRunning = false;
        });
        SoundHapticsService.winnerCelebration();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer([int? newSeconds]) {
    _timer?.cancel();
    setState(() {
      if (newSeconds != null) _selectedDuration = newSeconds;
      _remainingSeconds = _selectedDuration;
      _isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _selectedDuration > 0 ? _remainingSeconds / _selectedDuration : 0.0;
    final isLowTime = _remainingSeconds <= 10 && _remainingSeconds > 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Presets
        Wrap(
          spacing: 8,
          children: [30, 60, 90, 120].map((sec) {
            final isSelected = _selectedDuration == sec;
            return ChoiceChip(
              label: Text('${sec}s'),
              selected: isSelected,
              onSelected: (_) => _resetTimer(sec),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),

        // Circular Timer
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 180,
              height: 180,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 12,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                color: isLowTime ? Colors.red : theme.colorScheme.primary,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_remainingSeconds',
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    color: isLowTime ? Colors.red : theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  'segundos',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: () => _resetTimer(),
              icon: const Icon(Icons.replay),
              label: const Text('Reiniciar'),
            ),
            const SizedBox(width: 16),
            FilledButton.icon(
              onPressed: _isRunning ? _pauseTimer : _startTimer,
              icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
              label: Text(_isRunning ? 'Pausar' : 'Comenzar'),
              style: FilledButton.styleFrom(
                backgroundColor: _isRunning ? Colors.orange.shade800 : null,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
