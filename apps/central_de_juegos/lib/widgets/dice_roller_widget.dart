import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/sound_haptics_service.dart';

class DiceRollerWidget extends StatefulWidget {
  const DiceRollerWidget({super.key});

  @override
  State<DiceRollerWidget> createState() => _DiceRollerWidgetState();
}

class _DiceRollerWidgetState extends State<DiceRollerWidget> with TickerProviderStateMixin {
  int _diceCount = 2;
  int _diceSides = 6; // 6, 10, 20
  List<int> _results = [3, 5];
  bool _isRolling = false;
  
  late List<AnimationController> _controllers;
  late List<double> _randomRotations;
  final Random _random = Random();
  Timer? _diceJitterTimer;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _controllers = List.generate(
      6,
      (i) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 500 + i * 80),
      ),
    );
    _randomRotations = List.generate(6, (_) => (_random.nextDouble() - 0.5) * 4 * pi);
  }

  @override
  void dispose() {
    _diceJitterTimer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _rollDice() {
    if (_isRolling) return;
    SoundHapticsService.diceRolled();

    setState(() {
      _isRolling = true;
      _randomRotations = List.generate(6, (_) => (_random.nextDouble() - 0.5) * 4 * pi);
    });

    for (int i = 0; i < _diceCount; i++) {
      _controllers[i].forward(from: 0.0);
    }

    // Jitter random numbers while rolling
    int ticks = 0;
    _diceJitterTimer = Timer.periodic(const Duration(milliseconds: 70), (t) {
      ticks++;
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _results = List.generate(_diceCount, (_) => _random.nextInt(_diceSides) + 1);
      });
      if (ticks >= 8) {
        t.cancel();
      }
    });

    Future.delayed(const Duration(milliseconds: 750), () {
      if (!mounted) return;
      _diceJitterTimer?.cancel();
      setState(() {
        _results = List.generate(_diceCount, (_) => _random.nextInt(_diceSides) + 1);
        _isRolling = false;
      });
      SoundHapticsService.diceRolled();
    });
  }

  int get _totalSum => _results.fold(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Selector controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Dados: ', style: TextStyle(fontWeight: FontWeight.bold)),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('1')),
                ButtonSegment(value: 2, label: Text('2')),
                ButtonSegment(value: 3, label: Text('3')),
                ButtonSegment(value: 5, label: Text('5')),
                ButtonSegment(value: 6, label: Text('6')),
              ],
              selected: {_diceCount},
              onSelectionChanged: (val) {
                setState(() {
                  _diceCount = val.first;
                  _results = List.generate(_diceCount, (_) => _random.nextInt(_diceSides) + 1);
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Tipo: ', style: TextStyle(fontWeight: FontWeight.bold)),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 6, label: Text('d6')),
                ButtonSegment(value: 10, label: Text('d10')),
                ButtonSegment(value: 20, label: Text('d20')),
              ],
              selected: {_diceSides},
              onSelectionChanged: (val) {
                setState(() {
                  _diceSides = val.first;
                  _results = List.generate(_diceCount, (_) => _random.nextInt(_diceSides) + 1);
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Individual Animated Dice Display
        Wrap(
          spacing: 18,
          runSpacing: 18,
          alignment: WrapAlignment.center,
          children: List.generate(_diceCount, (index) {
            final value = index < _results.length ? _results[index] : 1;
            final controller = _controllers[index];
            final rotMax = _randomRotations[index];

            return AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                final progress = controller.value;
                final angle = _isRolling ? (1.0 - progress) * rotMax : 0.0;
                final scale = _isRolling ? (1.0 + sin(progress * pi) * 0.25) : 1.0;

                return Transform.scale(
                  scale: scale,
                  child: Transform.rotate(
                    angle: angle,
                    child: _buildDiceFace(value),
                  ),
                );
              },
            );
          }),
        ),

        const SizedBox(height: 32),

        // Total Sum Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
          ),
          child: Text(
            'Total: $_totalSum',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),

        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: _isRolling ? null : _rollDice,
          icon: const Icon(Icons.casino, size: 22),
          label: const Text('¡Tirar Dados!'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildDiceFace(int value) {
    if (_diceSides == 6) {
      return _buildD6(value);
    }
    // Polygon / badge for d10 or d20
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Center(
        child: Text(
          '$value',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildD6(int value) {
    return Container(
      width: 68,
      height: 68,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
      ),
      child: CustomPaint(
        painter: _D6DotPainter(value: value),
      ),
    );
  }
}

class _D6DotPainter extends CustomPainter {
  final int value;
  _D6DotPainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = const Color(0xFF1E2125)
      ..style = PaintingStyle.fill;

    final dotRadius = size.width * 0.11;
    final center = Offset(size.width / 2, size.height / 2);
    final topLeft = Offset(size.width * 0.25, size.height * 0.25);
    final topRight = Offset(size.width * 0.75, size.height * 0.25);
    final bottomLeft = Offset(size.width * 0.25, size.height * 0.75);
    final bottomRight = Offset(size.width * 0.75, size.height * 0.75);
    final midLeft = Offset(size.width * 0.25, size.height * 0.5);
    final midRight = Offset(size.width * 0.75, size.height * 0.5);

    switch (value) {
      case 1:
        canvas.drawCircle(center, dotRadius * 1.35, dotPaint..color = const Color(0xFFE53935));
        break;
      case 2:
        canvas.drawCircle(topLeft, dotRadius, dotPaint);
        canvas.drawCircle(bottomRight, dotRadius, dotPaint);
        break;
      case 3:
        canvas.drawCircle(topLeft, dotRadius, dotPaint);
        canvas.drawCircle(center, dotRadius, dotPaint);
        canvas.drawCircle(bottomRight, dotRadius, dotPaint);
        break;
      case 4:
        canvas.drawCircle(topLeft, dotRadius, dotPaint);
        canvas.drawCircle(topRight, dotRadius, dotPaint);
        canvas.drawCircle(bottomLeft, dotRadius, dotPaint);
        canvas.drawCircle(bottomRight, dotRadius, dotPaint);
        break;
      case 5:
        canvas.drawCircle(topLeft, dotRadius, dotPaint);
        canvas.drawCircle(topRight, dotRadius, dotPaint);
        canvas.drawCircle(center, dotRadius, dotPaint);
        canvas.drawCircle(bottomLeft, dotRadius, dotPaint);
        canvas.drawCircle(bottomRight, dotRadius, dotPaint);
        break;
      case 6:
        canvas.drawCircle(topLeft, dotRadius, dotPaint);
        canvas.drawCircle(topRight, dotRadius, dotPaint);
        canvas.drawCircle(midLeft, dotRadius, dotPaint);
        canvas.drawCircle(midRight, dotRadius, dotPaint);
        canvas.drawCircle(bottomLeft, dotRadius, dotPaint);
        canvas.drawCircle(bottomRight, dotRadius, dotPaint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _D6DotPainter oldDelegate) => oldDelegate.value != value;
}
