import 'package:flutter/material.dart';

import '../models/loud_models.dart';
import '../theme/app_theme.dart';

/// Rolling real-time decibel level bar chart with an 85 dB WHO caution reference line.
class DecibelSparkline extends StatelessWidget {
  const DecibelSparkline({
    super.key,
    required this.samples,
    this.capacity = kSparklineCapacity,
  });

  final List<double> samples;
  final int capacity;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return SizedBox(
      height: 64,
      width: double.infinity,
      child: CustomPaint(
        painter: _SparklinePainter(
          samples: samples,
          capacity: capacity,
          palette: palette,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({
    required this.samples,
    required this.capacity,
    required this.palette,
  });

  final List<double> samples;
  final int capacity;
  final AppPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    // 85 dB reference guide line across [20..120 dB] display range.
    const double minRange = 20.0;
    const double maxRange = 120.0;
    final double refRatio = ((85.0 - minRange) / (maxRange - minRange)).clamp(0.0, 1.0);
    final double refY = size.height * (1.0 - refRatio);

    final guidePaint = Paint()
      ..color = palette.warning.withValues(alpha: 0.45)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, refY), Offset(size.width, refY), guidePaint);

    final slotWidth = size.width / capacity;
    final barWidth = (slotWidth * 0.62).clamp(2.0, 8.0);
    final offsetStart = capacity - samples.length;

    final emptyPaint = Paint()..color = palette.border.withValues(alpha: 0.45);

    for (var i = 0; i < capacity; i++) {
      final x = i * slotWidth + (slotWidth - barWidth) / 2;
      if (i < offsetStart) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height - 4, barWidth, 4),
          const Radius.circular(2),
        );
        canvas.drawRRect(rect, emptyPaint);
        continue;
      }

      final db = samples[i - offsetStart];
      final normalized = ((db - minRange) / (maxRange - minRange)).clamp(0.06, 1.0);
      final barHeight = (size.height * normalized).clamp(4.0, size.height);
      final barColor = switch (ExposureMath.classify(db)) {
        SafetyZone.safe => palette.accentPrimary,
        SafetyZone.moderate => palette.textSecondary,
        SafetyZone.caution => palette.warning,
        SafetyZone.damageRisk => palette.danger,
      };
      final paint = Paint()..color = barColor;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height - barHeight, barWidth, barHeight),
        const Radius.circular(2),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.samples != samples || oldDelegate.palette != palette;
  }
}
