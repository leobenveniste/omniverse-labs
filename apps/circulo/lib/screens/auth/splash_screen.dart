import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_header.dart';
import '../../widgets/motion_components.dart';
import '../../l10n/app_localizations.dart';

class SplashScreen extends StatelessWidget {
  final String? statusText;

  const SplashScreen({super.key, this.statusText});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final primary = AppTheme.primaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);

    return Scaffold(
      body: AppBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PulseBeacon(
                minScale: 0.92,
                maxScale: 1.08,
                period: const Duration(milliseconds: 1600),
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primary.withValues(alpha: 0.12),
                    border: Border.all(
                      color: primary.withValues(alpha: 0.35),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: CirculoLogoIcon(
                      size: 56,
                      color: primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.get('appName'),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: AppTheme.textPrimaryColor(context),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.get('appTagline'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  valueColor: AlwaysStoppedAnimation<Color>(primary),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                statusText ?? l10n.get('connectingOnline'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
