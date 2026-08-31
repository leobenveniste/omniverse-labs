import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/sound_haptics_service.dart';

class FingerRouletteWidget extends StatefulWidget {
  const FingerRouletteWidget({super.key});

  @override
  State<FingerRouletteWidget> createState() => _FingerRouletteWidgetState();
}

class _FingerTouch {
  final int id;
  Offset position;
  final Color color;

  _FingerTouch({required this.id, required this.position, required this.color});
}

class _FingerRouletteWidgetState extends State<FingerRouletteWidget> {
  final Map<int, _FingerTouch> _touches = {};
  Timer? _countdownTimer;
  int? _selectedPointerId;
  bool _isSelecting = false;
  double _progress = 0.0;

  static const List<Color> _colors = [
    Color(0xFFE53935),
    Color(0xFF1E88E5),
    Color(0xFF43A047),
    Color(0xFFFB8C00),
    Color(0xFF8E24AA),
    Color(0xFF00ACC1),
    Color(0xFFD81B60),
    Color(0xFFFDD835),
  ];

  void _onPointerDown(PointerDownEvent event) {
    if (_selectedPointerId != null) {
      _reset();
    }

    final color = _colors[_touches.length % _colors.length];
    setState(() {
      _touches[event.pointer] = _FingerTouch(
        id: event.pointer,
        position: event.localPosition,
        color: color,
      );
    });

    SoundHapticsService.pointAdded();
    _checkCountdown();
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_touches.containsKey(event.pointer)) {
      setState(() {
        _touches[event.pointer]!.position = event.localPosition;
      });
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    setState(() {
      _touches.remove(event.pointer);
    });
    _checkCountdown();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    setState(() {
      _touches.remove(event.pointer);
    });
    _checkCountdown();
  }

  void _checkCountdown() {
    _countdownTimer?.cancel();
    _progress = 0.0;

    if (_touches.length >= 2 && _selectedPointerId == null) {
      _isSelecting = true;
      const totalSteps = 25;
      int currentStep = 0;

      _countdownTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        currentStep++;
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          _progress = currentStep / totalSteps;
        });

        if (currentStep % 5 == 0) {
          SoundHapticsService.click();
        }

        if (currentStep >= totalSteps) {
          timer.cancel();
          _pickWinner();
        }
      });
    } else {
      _isSelecting = false;
    }
  }

  void _pickWinner() {
    if (_touches.isEmpty) return;
    final keys = _touches.keys.toList();
    final winnerKey = keys[Random().nextInt(keys.length)];

    setState(() {
      _selectedPointerId = winnerKey;
      _isSelecting = false;
    });

    SoundHapticsService.winnerCelebration();
  }

  void _reset() {
    _countdownTimer?.cancel();
    setState(() {
      _touches.clear();
      _selectedPointerId = null;
      _isSelecting = false;
      _progress = 0.0;
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
        ),
        child: Stack(
          children: [
            // Center instruction
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.touch_app,
                    size: 64,
                    color: theme.colorScheme.onSurface.withOpacity(0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _selectedPointerId != null
                        ? '¡Este jugador empieza!'
                        : (_touches.length < 2
                            ? 'Coloquen 2 o más dedos en la pantalla'
                            : '¡Mantengan presionando!'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),

            // Finger touch circles
            ..._touches.values.map((touch) {
              final isWinner = _selectedPointerId == touch.id;
              final isLoser = _selectedPointerId != null && !isWinner;

              if (isLoser) {
                return Positioned(
                  left: touch.position.dx - 40,
                  top: touch.position.dy - 40,
                  child: Opacity(
                    opacity: 0.2,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: touch.color.withOpacity(0.4),
                      ),
                    ),
                  ),
                );
              }

              return Positioned(
                left: touch.position.dx - (isWinner ? 60 : 45),
                top: touch.position.dy - (isWinner ? 60 : 45),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isWinner ? 120 : 90,
                  height: isWinner ? 120 : 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isWinner ? Colors.amber : touch.color.withOpacity(0.85),
                    boxShadow: [
                      BoxShadow(
                        color: isWinner ? Colors.amber.withOpacity(0.8) : touch.color.withOpacity(0.6),
                        blurRadius: isWinner ? 32 : 16,
                        spreadRadius: isWinner ? 12 : 4,
                      )
                    ],
                  ),
                  child: isWinner
                      ? const Icon(Icons.star, color: Colors.white, size: 54)
                      : (_isSelecting
                          ? CircularProgressIndicator(
                              value: _progress,
                              color: Colors.white,
                              strokeWidth: 4,
                            )
                          : null),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
