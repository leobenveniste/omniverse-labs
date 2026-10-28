import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Header title widget featuring the official Vuelo Controlado logo and stylized title
/// aligned to the 8px layout grid and M3 Expressive typography.
class AppHeaderTitle extends StatelessWidget {
  final String? title;
  final String? subtitle;

  const AppHeaderTitle({super.key, this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Hero(
          tag: 'header_logo_${title ?? "root"}',
          child: Image.asset(
            isDark
                ? 'assets/images/logo_white.png'
                : 'assets/images/logo_color.png',
            height: 28,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Icon(
              Icons.flight_takeoff_rounded,
              color: isDark ? AppTheme.neonGreen : AppTheme.emeraldDark,
              size: 24,
            ),
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
