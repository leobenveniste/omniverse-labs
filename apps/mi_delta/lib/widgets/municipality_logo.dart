import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class MunicipalityLogo extends StatelessWidget {
  final double size;
  final bool monochrome;

  const MunicipalityLogo({
    super.key,
    this.size = 48,
    this.monochrome = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LogoPainter(monochrome: monochrome),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  final bool monochrome;

  _LogoPainter({required this.monochrome});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Outer Shield
    final shieldPath = Path()
      ..moveTo(w * 0.5, h * 0.05)
      ..cubicTo(w * 0.72, h * 0.05, w * 0.88, h * 0.16, w * 0.88, h * 0.34)
      ..cubicTo(w * 0.88, h * 0.64, w * 0.5, h * 0.94, w * 0.5, h * 0.94)
      ..cubicTo(w * 0.5, h * 0.94, w * 0.12, h * 0.64, w * 0.12, h * 0.34)
      ..cubicTo(w * 0.12, h * 0.16, w * 0.28, h * 0.05, w * 0.5, h * 0.05)
      ..close();

    final shieldPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: monochrome
            ? [Colors.white, Colors.white70]
            : [AppColors.primaryLight, AppColors.primaryDark],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(shieldPath, shieldPaint);

    final borderPaint = Paint()
      ..color = monochrome ? Colors.white : AppColors.secondaryLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.035;
    canvas.drawPath(shieldPath, borderPaint);

    // Sun disk
    final sunPaint = Paint()
      ..color = const Color(0xFFFBBF24)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.5, h * 0.32), w * 0.13, sunPaint);

    // Waves (Delta Rivers)
    final wave1 = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w * 0.04;

    final p1 = Path()
      ..moveTo(w * 0.26, h * 0.50)
      ..cubicTo(w * 0.34, h * 0.44, w * 0.42, h * 0.54, w * 0.50, h * 0.48)
      ..cubicTo(w * 0.58, h * 0.42, w * 0.66, h * 0.52, w * 0.74, h * 0.46);
    canvas.drawPath(p1, wave1);

    final wave2 = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.secondary, AppColors.accentLight],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w * 0.045;

    final p2 = Path()
      ..moveTo(w * 0.22, h * 0.62)
      ..cubicTo(w * 0.32, h * 0.54, w * 0.40, h * 0.66, w * 0.50, h * 0.58)
      ..cubicTo(w * 0.60, h * 0.50, w * 0.68, h * 0.62, w * 0.78, h * 0.54);
    canvas.drawPath(p2, wave2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
