import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = AppTheme.primaryColor(context);

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        gradient: RadialGradient(
          center: const Alignment(0.6, -0.8),
          radius: 1.4,
          colors: [
            primary.withValues(alpha: isDark ? 0.12 : 0.06),
            theme.scaffoldBackgroundColor,
          ],
          stops: const [0.0, 1.0],
        ),
      ),
      child: child,
    );
  }
}
