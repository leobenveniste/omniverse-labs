import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/haptics_helper.dart';

class MoodOrbsSelector extends StatelessWidget {
  final int selectedMood; // 1 to 5
  final int energyLevel; // 1 to 5
  final ValueChanged<int> onMoodChanged;
  final ValueChanged<int> onEnergyChanged;

  const MoodOrbsSelector({
    super.key,
    required this.selectedMood,
    required this.energyLevel,
    required this.onMoodChanged,
    required this.onEnergyChanged,
  });

  List<Color> _getGradient(int mood) {
    switch (mood) {
      case 5:
        return AppColors.moodRadiant;
      case 4:
        return AppColors.moodGood;
      case 3:
        return AppColors.moodNeutral;
      case 2:
        return AppColors.moodLow;
      case 1:
      default:
        return AppColors.moodDifficult;
    }
  }

  String _getMoodLabelKey(int mood) {
    switch (mood) {
      case 5:
        return 'moodRadiant';
      case 4:
        return 'moodGood';
      case 3:
        return 'moodNeutral';
      case 2:
        return 'moodLow';
      case 1:
      default:
        return 'moodDifficult';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.t('howAreYouFeeling'),
          style: AppTypography.section(theme.colorScheme.onSurface),
        ),
        const SizedBox(height: AppSpacing.md),

        // 5 Atmospheric Glowing Orbs
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (index) {
            final moodValue = index + 1; // 1 to 5
            final isSelected = selectedMood == moodValue;
            final gradient = _getGradient(moodValue);
            final auraRadius = isSelected ? (12.0 + (energyLevel * 3.0)) : 0.0;

            return GestureDetector(
              onTap: () {
                HapticsHelper.selection();
                onMoodChanged(moodValue);
              },
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutBack,
                    width: isSelected ? 52 : 40,
                    height: isSelected ? 52 : 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: gradient.first.withValues(alpha: 0.55),
                                blurRadius: auraRadius,
                                spreadRadius: 2.0,
                              ),
                            ]
                          : null,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 2.0)
                          : Border.all(
                              color: theme.colorScheme.outline.withValues(alpha: 0.5),
                              width: 1.0,
                            ),
                    ),
                    child: Center(
                      child: isSelected
                          ? const Icon(
                              Icons.check_rounded,
                              size: 20,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.t(_getMoodLabelKey(moodValue)),
                    style: AppTypography.caption(
                      isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      isMedium: isSelected,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Energy Level Slider
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.t('energyLevel'),
              style: AppTypography.body(theme.colorScheme.onSurface, isMedium: true),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
              ),
              child: Text(
                '$energyLevel / 5',
                style: AppTypography.caption(theme.colorScheme.primary, isMedium: true),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: theme.colorScheme.primary,
            thumbColor: theme.colorScheme.primary,
            overlayColor: theme.colorScheme.primary.withValues(alpha: 0.15),
            trackHeight: 4.0,
          ),
          child: Slider(
            value: energyLevel.toDouble(),
            min: 1.0,
            max: 5.0,
            divisions: 4,
            onChanged: (val) {
              HapticsHelper.light();
              onEnergyChanged(val.toInt());
            },
          ),
        ),
      ],
    );
  }
}
