import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class ProgressRing extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final Widget? child;

  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 80.0,
    this.strokeWidth = 7.0,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (progress * 100).toInt().clamp(0, 100);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Track
          CircularProgressIndicator(
            value: 1.0,
            strokeWidth: strokeWidth,
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          // Animated Progress Ring
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: progress.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return CircularProgressIndicator(
                value: value,
                strokeWidth: strokeWidth,
                strokeCap: StrokeCap.round,
                valueColor: AlwaysStoppedAnimation<Color>(
                  value >= 1.0 ? Colors.green : theme.colorScheme.primary,
                ),
              );
            },
          ),
          // Center content
          child ??
              Text(
                '$percent%',
                style: AppTypography.caption(
                  theme.colorScheme.onSurface,
                  isMedium: true,
                ),
              ),
        ],
      ),
    );
  }
}
