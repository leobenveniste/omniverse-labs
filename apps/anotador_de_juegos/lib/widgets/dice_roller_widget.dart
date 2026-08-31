import 'dart:math';
import 'package:flutter/material.dart';
import '../services/sound_haptics_service.dart';

class DiceRollerWidget extends StatefulWidget {
  const DiceRollerWidget({super.key});

  @override
  State<DiceRollerWidget> createState() => _DiceRollerWidgetState();
}

class _DiceRollerWidgetState extends State<DiceRollerWidget> with SingleTickerProviderStateMixin {
  int _diceCount = 2;
  int _diceSides = 6; // 6, 10, 20
  List<int> _results = [3, 5];
  bool _isRolling = false;
  late AnimationController _animController;

  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _rollDice() {
    if (_isRolling) return;
    SoundHapticsService.diceRolled();

    setState(() {
      _isRolling = true;
    });

    _animController.forward(from: 0.0);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
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
        const SizedBox(height: 24),

        // Dice Display
        AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            final angle = _animController.value * 2 * pi;
            return Transform.rotate(
              angle: _isRolling ? angle : 0.0,
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: _results.map((value) => _buildDiceFace(value)).toList(),
              ),
            );
          },
        ),

        const SizedBox(height: 24),

        // Total Sum
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Total: $_totalSum',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),

        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _isRolling ? null : _rollDice,
          icon: const Icon(Icons.casino),
          label: const Text('¡Tirar Dados!'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
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
      width: 64,
      height: 64,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
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
        canvas.drawCircle(center, dotRadius * 1.3, dotPaint..color = Colors.red.shade700);
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
