import 'package:flutter/material.dart';

class MatchstickBox extends StatelessWidget {
  final int count; // 0 to 5
  final double size;

  const MatchstickBox({
    super.key,
    required this.count,
    this.size = 64.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
          width: 1.2,
        ),
      ),
      child: CustomPaint(
        painter: _RealisticMatchstickPainter(
          count: count.clamp(0, 5),
        ),
      ),
    );
  }
}

class _RealisticMatchstickPainter extends CustomPainter {
  final int count;

  _RealisticMatchstickPainter({required this.count});

  @override
  void paint(Canvas canvas, Size size) {
    // Realistic wood stick paint
    final woodPaint = Paint()
      ..color = const Color(0xFFE8C59E) // Warm wood
      ..strokeWidth = 4.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final woodShadowPaint = Paint()
      ..color = const Color(0xFFBD956F) // Wood shading
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Classic red sulfur match head
    final headPaint = Paint()
      ..color = const Color(0xFFD32F2F)
      ..style = PaintingStyle.fill;

    final headDarkPaint = Paint()
      ..color = const Color(0xFF8E0000)
      ..style = PaintingStyle.fill;

    const pad = 9.0;
    final left = pad;
    final right = size.width - pad;
    final top = pad;
    final bottom = size.height - pad;

    void drawMatchstick(Offset start, Offset end, Offset headPos) {
      // Wood stick
      canvas.drawLine(start, end, woodPaint);
      canvas.drawLine(start, end, woodShadowPaint);
      // Red match head
      canvas.drawCircle(headPos, 4.2, headDarkPaint);
      canvas.drawCircle(headPos, 3.6, headPaint);
    }

    // 1. Top stick (head on left)
    if (count >= 1) {
      drawMatchstick(Offset(left + 2, top), Offset(right - 2, top), Offset(left + 2, top));
    }
    // 2. Right stick (head on top)
    if (count >= 2) {
      drawMatchstick(Offset(right, top + 2), Offset(right, bottom - 2), Offset(right, top + 2));
    }
    // 3. Bottom stick (head on right)
    if (count >= 3) {
      drawMatchstick(Offset(right - 2, bottom), Offset(left + 2, bottom), Offset(right - 2, bottom));
    }
    // 4. Left stick (head on bottom)
    if (count >= 4) {
      drawMatchstick(Offset(left, bottom - 2), Offset(left, top + 2), Offset(left, bottom - 2));
    }
    // 5. Diagonal stick (crossing from top-left to bottom-right, head on top-left)
    if (count >= 5) {
      drawMatchstick(Offset(left + 3, top + 3), Offset(right - 3, bottom - 3), Offset(left + 4, top + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _RealisticMatchstickPainter oldDelegate) {
    return oldDelegate.count != count;
  }
}

class MatchstickDisplayGrid extends StatelessWidget {
  final int score;
  final int maxScore;
  final Color? color;
  final double boxSize;

  const MatchstickDisplayGrid({
    super.key,
    required this.score,
    this.maxScore = 30,
    this.color,
    this.boxSize = 58.0,
  });

  @override
  Widget build(BuildContext context) {
    final totalBoxes = (maxScore / 5).ceil(); // 6 boxes for 30 points
    final boxes = <Widget>[];

    int remaining = score;
    for (int i = 0; i < totalBoxes; i++) {
      int inThisBox = remaining >= 5 ? 5 : (remaining > 0 ? remaining : 0);
      remaining = (remaining - 5).clamp(0, 999);
      boxes.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3.5),
          child: MatchstickBox(
            count: inThisBox,
            size: boxSize,
          ),
        ),
      );
    }

    // Single vertical column layout
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: boxes,
    );
  }
}
