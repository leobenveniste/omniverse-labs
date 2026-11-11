import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

/// Visual beat indicator dots with Beat 1 highlighted in warning amber and sub-beats in emerald.
class BeatIndicatorBar extends StatelessWidget {
  const BeatIndicatorBar({
    super.key,
    required this.beatsPerBar,
    required this.currentBeat,
    required this.isRunning,
    required this.visualFlashEnabled,
    required this.strings,
  });

  final int beatsPerBar;
  final int currentBeat;
  final bool isRunning;
  final bool visualFlashEnabled;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.center,
          children: List.generate(beatsPerBar, (index) {
            final isBeatOne = index == 0;
            final isActive =
                visualFlashEnabled && isRunning && currentBeat == index;
            final activeColor =
                isBeatOne ? palette.warning : palette.accentPrimary;

            return Semantics(
              label: 'Beat ${index + 1}',
              selected: isActive,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 90),
                curve: Curves.easeOut,
                width: isBeatOne ? 24 : 18,
                height: isBeatOne ? 24 : 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? activeColor
                      : (isBeatOne ? palette.warningTint : palette.surfaceElevated),
                  border: Border.all(
                    color: isActive
                        ? activeColor
                        : (isBeatOne ? palette.warning : palette.border),
                    width: isBeatOne ? 2.0 : 1.5,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: activeColor.withValues(alpha: 0.45),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          strings.beatOneAccent,
          style: AppTypography.label.copyWith(color: palette.textSecondary),
        ),
      ],
    );
  }
}
