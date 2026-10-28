import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/collectible_stamp.dart';
import '../theme/app_colors.dart';

class PassportStampWidget extends StatelessWidget {
  final CollectibleStamp stamp;
  final double size;

  const PassportStampWidget({
    super.key,
    required this.stamp,
    this.size = 130,
  });

  Color _resolveInkColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (stamp.inkColor) {
      case StampInkColor.crimson:
        return isDark ? AppColors.stampCrimsonDark : AppColors.stampCrimsonLight;
      case StampInkColor.cobalt:
        return isDark ? AppColors.stampCobaltDark : AppColors.stampCobaltLight;
      case StampInkColor.emerald:
        return isDark ? AppColors.stampEmeraldDark : AppColors.stampEmeraldLight;
      case StampInkColor.amber:
        return isDark ? AppColors.stampAmberDark : AppColors.stampAmberLight;
      case StampInkColor.purple:
        return isDark ? AppColors.stampPurpleDark : AppColors.stampPurpleLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final inkColor = _resolveInkColor(context);
    final dateStr = DateFormat('dd.MMM.yyyy').format(stamp.date).toUpperCase();

    return Transform.rotate(
      angle: stamp.rotationRadians,
      child: Opacity(
        opacity: 0.90, // Weathered ink appearance
        child: SizedBox(
          width: size,
          height: size * 0.85,
          child: CustomPaint(
            painter: _StampCustomPainter(
              shape: stamp.shape,
              inkColor: inkColor,
              type: stamp.type,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      stamp.type == StampType.customsCleared
                          ? '★ CUSTOMS CLEARED ★'
                          : '★ IMMIGRATION ★',
                      style: GoogleFonts.cinzel(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: inkColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stamp.cityName,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cinzel(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: inkColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        border: Border.all(color: inkColor.withValues(alpha: 0.7), width: 0.8),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        dateStr,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: inkColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${stamp.stationCode} • PASSPORT ENTRY',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w500,
                        color: inkColor.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StampCustomPainter extends CustomPainter {
  final StampShape shape;
  final Color inkColor;
  final StampType type;

  _StampCustomPainter({
    required this.shape,
    required this.inkColor,
    required this.type,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = inkColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final innerPaint = Paint()
      ..color = inkColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final rect = Rect.fromLTWH(2, 2, size.width - 4, size.height - 4);
    final innerRect = Rect.fromLTWH(6, 6, size.width - 12, size.height - 12);

    switch (shape) {
      case StampShape.circular:
      case StampShape.oval:
        canvas.drawOval(rect, paint);
        canvas.drawOval(innerRect, innerPaint);
        break;

      case StampShape.rectangular:
        final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
        final innerRRect = RRect.fromRectAndRadius(innerRect, const Radius.circular(5));
        canvas.drawRRect(rrect, paint);
        canvas.drawRRect(innerRRect, innerPaint);
        break;

      case StampShape.hexagonal:
        _drawPolygon(canvas, size, 6, paint);
        break;
    }
  }

  void _drawPolygon(Canvas canvas, Size size, int sides, Paint paint) {
    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = math.min(centerX, centerY) - 3;
    final angle = (math.pi * 2) / sides;

    for (int i = 0; i < sides; i++) {
      final x = centerX + radius * math.cos(i * angle - math.pi / 2);
      final y = centerY + radius * math.sin(i * angle - math.pi / 2);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    // Inner polygon
    final innerPath = Path();
    final innerRadius = radius - 5;
    for (int i = 0; i < sides; i++) {
      final x = centerX + innerRadius * math.cos(i * angle - math.pi / 2);
      final y = centerY + innerRadius * math.sin(i * angle - math.pi / 2);
      if (i == 0) {
        innerPath.moveTo(x, y);
      } else {
        innerPath.lineTo(x, y);
      }
    }
    innerPath.close();
    paint.strokeWidth = 0.8;
    canvas.drawPath(innerPath, paint);
  }

  @override
  bool shouldRepaint(covariant _StampCustomPainter oldDelegate) =>
      oldDelegate.shape != shape ||
      oldDelegate.inkColor != inkColor ||
      oldDelegate.type != type;
}
