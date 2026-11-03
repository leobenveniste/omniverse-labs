import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CirculoLogoIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const CirculoLogoIcon({super.key, this.size = 28, this.color});

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppTheme.primaryColor(context);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CirculoLogoPainter(color: effectiveColor),
      ),
    );
  }
}

class _CirculoLogoPainter extends CustomPainter {
  final Color color;

  _CirculoLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.36;

    final ringPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.10;

    canvas.drawCircle(center, radius, ringPaint);

    // 4 nodos representando las 4 personas del match
    final nodePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final nodeRadius = size.width * 0.12;
    final offsets = [
      Offset(center.dx, center.dy - radius),
      Offset(center.dx + radius, center.dy),
      Offset(center.dx, center.dy + radius),
      Offset(center.dx - radius, center.dy),
    ];

    for (final off in offsets) {
      canvas.drawCircle(off, nodeRadius, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CirculoLogoPainter oldDelegate) =>
      oldDelegate.color != color;
}

class AppHeaderTitle extends StatelessWidget {
  final String? title;
  final String? subtitle;

  const AppHeaderTitle({super.key, this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Hero(
          tag: 'app_logo_hero',
          child: CirculoLogoIcon(
            size: 26,
            color: AppTheme.primaryColor(context),
          ),
        ),
        if (title != null && title!.isNotEmpty) ...[
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title!,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: -0.3,
                    color: textPrimary,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Text(
                    subtitle!,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
