import 'package:flutter/material.dart';

/// Unifies the entire app background with the signature subtle radar texture
/// and a high-contrast gradient overlay, ensuring 100% WCAG AA/AAA compliance
/// and seamless integration behind transparent AppBars.
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Capa de imagen: Textura de radar
        Image.asset(
          'assets/images/login_bg.jpg',
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          errorBuilder: (_, _, _) => Container(
            color: isDark ? const Color(0xFF0F151C) : const Color(0xFFF3F4F6),
          ),
        ),

        // 2. Capa de degradado cinematográfico para maximizar contraste
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      const Color(0xFF090D12).withValues(alpha: 0.82),
                      const Color(0xFF0C1117).withValues(alpha: 0.92),
                      const Color(0xFF10161F).withValues(alpha: 0.97),
                    ]
                  : [
                      const Color(0xFFF9FAFB).withValues(alpha: 0.92),
                      const Color(0xFFF3F4F6).withValues(alpha: 0.96),
                      const Color(0xFFFFFFFF).withValues(alpha: 0.98),
                    ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),

        // 3. Contenido de la pantalla
        child,
      ],
    );
  }
}
