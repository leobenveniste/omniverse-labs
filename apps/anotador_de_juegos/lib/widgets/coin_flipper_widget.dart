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
      duration: const Duration(milliseconds: 1000),
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

    return Column(
      mainAxisSize: MainAxisSize.min,
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
                width: 140,
                height: 140,
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
                      blurRadius: 20,
                      spreadRadius: 4,
                      offset: const Offset(0, 8),
                    )
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.8),
                    width: 4,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        showFace ? Icons.face : Icons.close,
                        size: 48,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        showFace ? 'CARA' : 'CRUZ',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 32),
        Text(
          _isFlipping ? 'Girando...' : (_isHeads ? '¡Salió CARA!' : '¡Salió CRUZ!'),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: _isHeads ? Colors.amber.shade800 : theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _isFlipping ? null : _flipCoin,
          icon: const Icon(Icons.refresh),
          label: const Text('Lanzar Moneda'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          ),
        ),
      ],
    );
  }
}
