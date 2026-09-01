import 'package:flutter/material.dart';

class MatchstickBox extends StatelessWidget {
  final int count; // 0 to 5
  final Color stickColor;
  final double size;

  const MatchstickBox({
    super.key,
    required this.count,
    this.stickColor = const Color(0xFFD32F2F),
    this.size = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MatchstickPainter(
          count: count.clamp(0, 5),
          color: stickColor,
        ),
      ),
    );
  }
}

class _MatchstickPainter extends CustomPainter {
  final int count;
  final Color color;

  _MatchstickPainter({required this.count, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final stickPaint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final headPaint = Paint()
      ..color = const Color(0xFFC62828)
      ..style = PaintingStyle.fill;

    const pad = 6.0;
    final left = pad;
    final right = size.width - pad;
    final top = pad;
    final bottom = size.height - pad;

    // 1. Top stick
    if (count >= 1) {
      canvas.drawLine(Offset(left, top), Offset(right, top), stickPaint);
      canvas.drawCircle(Offset(left + 2, top), 2.5, headPaint);
    }
    // 2. Right stick
    if (count >= 2) {
      canvas.drawLine(Offset(right, top), Offset(right, bottom), stickPaint);
      canvas.drawCircle(Offset(right, top + 2), 2.5, headPaint);
    }
    // 3. Bottom stick
    if (count >= 3) {
      canvas.drawLine(Offset(right, bottom), Offset(left, bottom), stickPaint);
      canvas.drawCircle(Offset(right - 2, bottom), 2.5, headPaint);
    }
    // 4. Left stick
    if (count >= 4) {
      canvas.drawLine(Offset(left, bottom), Offset(left, top), stickPaint);
      canvas.drawCircle(Offset(left, bottom - 2), 2.5, headPaint);
    }
    // 5. Diagonal stick
    if (count >= 5) {
      canvas.drawLine(Offset(left, top), Offset(right, bottom), stickPaint);
      canvas.drawCircle(Offset(left + 3, top + 3), 2.5, headPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MatchstickPainter oldDelegate) {
    return oldDelegate.count != count || oldDelegate.color != color;
  }
}

class MatchstickDisplayGrid extends StatelessWidget {
  final int score;
  final int maxScore;
  final Color color;
  final double boxSize;

  const MatchstickDisplayGrid({
    super.key,
    required this.score,
    this.maxScore = 30,
    this.color = const Color(0xFFE53935),
    this.boxSize = 46.0,
  });

  @override
  Widget build(BuildContext context) {
    // Determine how many boxes of 5 are needed for maxScore (e.g. 15 -> 3 boxes, 30 -> 6 boxes)
    final totalBoxes = (maxScore / 5).ceil();
    final boxes = <Widget>[];

    int remaining = score;
    for (int i = 0; i < totalBoxes; i++) {
      int inThisBox = remaining >= 5 ? 5 : (remaining > 0 ? remaining : 0);
      remaining = (remaining - 5).clamp(0, 999);
      boxes.add(
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: MatchstickBox(
            count: inThisBox,
            stickColor: color,
            size: boxSize,
          ),
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: boxes,
    );
  }
}
