import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/sound_haptics_service.dart';
import '../theme/app_theme.dart';

class DiceRollerWidget extends StatefulWidget {
  const DiceRollerWidget({super.key});

  @override
  State<DiceRollerWidget> createState() => _DiceRollerWidgetState();
}

class _DiceRollerWidgetState extends State<DiceRollerWidget> with TickerProviderStateMixin {
  int _diceCount = 2;
  int _diceSides = 6;
  List<int> _results = [3, 5];
  bool _isRolling = false;

  late List<AnimationController> _controllers;
  late List<double> _rotationsX;
  late List<double> _rotationsY;
  late List<double> _rotationsZ;
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
        duration: Duration(milliseconds: 650 + i * 70),
      ),
    );
    _rotationsX = List.generate(6, (_) => 0.0);
    _rotationsY = List.generate(6, (_) => 0.0);
    _rotationsZ = List.generate(6, (_) => 0.0);
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
      _rotationsX = List.generate(6, (_) => (_random.nextDouble() + 1.0) * 4 * pi);
      _rotationsY = List.generate(6, (_) => (_random.nextDouble() + 1.0) * 4 * pi);
      _rotationsZ = List.generate(6, (_) => (_random.nextDouble() - 0.5) * 2 * pi);
    });

    for (int i = 0; i < _diceCount; i++) {
      _controllers[i].forward(from: 0.0);
    }

    int ticks = 0;
    _diceJitterTimer = Timer.periodic(const Duration(milliseconds: 60), (t) {
      ticks++;
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _results = List.generate(_diceCount, (_) => _random.nextInt(_diceSides) + 1);
      });
      if (ticks >= 10) {
        t.cancel();
      }
    });

    Future.delayed(const Duration(milliseconds: 800), () {
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Top Config Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderDark),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'CANTIDAD DE DADOS:',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0.8,
                      color: Colors.white70,
                    ),
                  ),
                  Row(
                    children: [1, 2, 3, 4, 5, 6].map((count) {
                      final isSel = _diceCount == count;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _diceCount = count;
                            _results = List.generate(_diceCount, (_) => _random.nextInt(_diceSides) + 1);
                          });
                          SoundHapticsService.click();
                        },
                        child: Container(
                          width: 34,
                          height: 34,
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                            color: isSel ? AppTheme.cyberGold : AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSel ? AppTheme.cyberGold : AppTheme.borderDark,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                color: isSel ? Colors.black : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TIPO DE DADO:',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0.8,
                      color: Colors.white70,
                    ),
                  ),
                  Row(
                    children: [6, 10, 20].map((sides) {
                      final isSel = _diceSides == sides;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _diceSides = sides;
                            _results = List.generate(_diceCount, (_) => _random.nextInt(_diceSides) + 1);
                          });
                          SoundHapticsService.click();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          margin: const EdgeInsets.only(left: 6),
                          decoration: BoxDecoration(
                            color: isSel ? AppTheme.cyberGold : AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSel ? AppTheme.cyberGold : AppTheme.borderDark,
                            ),
                          ),
                          child: Text(
                            'd$sides',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              color: isSel ? Colors.black : Colors.white,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Center 3D Animated Large Dice Area
        Center(
          child: Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: List.generate(_diceCount, (index) {
              final value = index < _results.length ? _results[index] : 1;
              final controller = _controllers[index];

              return AnimatedBuilder(
                animation: controller,
                builder: (context, child) {
                  final progress = controller.value;
                  final angleX = _isRolling ? (1.0 - progress) * _rotationsX[index] : 0.0;
                  final angleY = _isRolling ? (1.0 - progress) * _rotationsY[index] : 0.0;
                  final angleZ = _isRolling ? (1.0 - progress) * _rotationsZ[index] : 0.0;
                  final scale = _isRolling ? (1.0 + sin(progress * pi) * 0.3) : 1.0;

                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0018)
                      ..rotateX(angleX)
                      ..rotateY(angleY)
                      ..rotateZ(angleZ)
                      ..scale(scale),
                    child: _build3DDiceFace(value),
                  );
                },
              );
            }),
          ),
        ),

        const SizedBox(height: 32),

        // Bottom Total & Action Section
        Column(
          children: [
            // Total Sum Display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.cyberGold, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'TOTAL:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$_totalSum',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.cyberGold,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Roll Dice Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _isRolling ? null : _rollDice,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.cyberGold,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.casino, color: Colors.black, size: 26),
                    const SizedBox(width: 10),
                    Text(
                      _isRolling ? 'LANZANDO...' : 'LANZAR DADOS',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _build3DDiceFace(int value) {
    if (_diceSides == 6) {
      return _build3DD6(value);
    }

    // Polyhedral d10 / d20
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: const Color(0xFF1E222B),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.cyberGold, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppTheme.cyberGold.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$value',
          style: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: AppTheme.cyberGold,
          ),
        ),
      ),
    );
  }

  Widget _build3DD6(int value) {
    return Container(
      width: 88,
      height: 88,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD0D5DD), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.55),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          const BoxShadow(
            color: Color(0xFFE4E7EC),
            blurRadius: 2,
            offset: const Offset(-2, -2),
          ),
        ],
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
      ..color = const Color(0xFF121316)
      ..style = PaintingStyle.fill;

    final dotRadius = size.width * 0.115;
    final center = Offset(size.width / 2, size.height / 2);
    final topLeft = Offset(size.width * 0.25, size.height * 0.25);
    final topRight = Offset(size.width * 0.75, size.height * 0.25);
    final bottomLeft = Offset(size.width * 0.25, size.height * 0.75);
    final bottomRight = Offset(size.width * 0.75, size.height * 0.75);
    final midLeft = Offset(size.width * 0.25, size.height * 0.5);
    final midRight = Offset(size.width * 0.75, size.height * 0.5);

    switch (value) {
      case 1:
        canvas.drawCircle(center, dotRadius * 1.35, dotPaint);
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
