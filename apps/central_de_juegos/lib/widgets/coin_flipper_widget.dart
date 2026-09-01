import 'dart:math';
import 'package:flutter/material.dart';
import '../services/sound_haptics_service.dart';

class CoinFlipperWidget extends StatefulWidget {
  const CoinFlipperWidget({super.key});

  @override
  State<CoinFlipperWidget> createState() => _CoinFlipperWidgetState();
}

class _CoinFlipperWidgetState extends State<CoinFlipperWidget> with SingleTickerProviderStateMixin {
  bool _isHeads = true; // true = Cara, false = Cruz
  bool _isFlipping = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flipCoin() {
    if (_isFlipping) return;
    SoundHapticsService.diceRolled();

    setState(() {
      _isFlipping = true;
    });

    final targetHeads = _random.nextBool();

    _controller.forward(from: 0.0).then((_) {
      if (!mounted) return;
      setState(() {
        _isHeads = targetHeads;
        _isFlipping = false;
      });
      SoundHapticsService.diceRolled();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _flipCoin,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                final rotations = _animation.value * 6 * pi;
                final isFront = (rotations % (2 * pi)) < (pi / 2) || (rotations % (2 * pi)) > (3 * pi / 2);
                final showFace = _isFlipping ? isFront : _isHeads;

                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.002) // Perspective
                    ..rotateX(rotations),
                  alignment: Alignment.center,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: showFace
                            ? [const Color(0xFFFFD54F), const Color(0xFFFFA000), const Color(0xFFFF8F00)]
                            : [const Color(0xFFE0E0E0), const Color(0xFF9E9E9E), const Color(0xFF757575)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (showFace ? Colors.amber : Colors.grey).withOpacity(0.5),
                          blurRadius: 24,
                          spreadRadius: 6,
                          offset: const Offset(0, 10),
                        )
                      ],
                      border: Border.all(
                        color: Colors.white.withOpacity(0.85),
                        width: 5,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            showFace ? Icons.face : Icons.close,
                            size: 56,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            showFace ? 'CARA' : 'CRUZ',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 2.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 36),
            Text(
              _isFlipping ? '¡Girando en el aire...!' : (_isHeads ? '¡Salió CARA!' : '¡Salió CRUZ!'),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: _isHeads ? Colors.amber.shade800 : theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app, size: 18, color: Colors.grey),
                  SizedBox(width: 6),
                  Text(
                    'Toca en cualquier parte de la pantalla para lanzar',
                    style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
