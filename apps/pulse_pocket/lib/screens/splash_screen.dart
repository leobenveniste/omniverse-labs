import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Instant startup loading screen displayed strictly while local preferences and haptic engine initialize.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/app_logo.png',
                width: 96,
                height: 96,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Icon(
                  Icons.vibration_rounded,
                  size: 72,
                  color: palette.accentPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'PulsePocket',
                style: AppTypography.display.copyWith(color: palette.textPrimary),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: palette.accentPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
