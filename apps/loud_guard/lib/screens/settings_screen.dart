import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/loud_models.dart';
import '../services/loud_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/contact_us_modal.dart';

/// Settings screen matching CancelGuard and PulsePocket layout with LoudGuard calibration/alerts, Contact Us, and Omniverse Labs info.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.controller,
  });

  final LoudController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final strings = controller.strings;
        final palette = AppPalette.of(context);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final offset = controller.calibrationOffsetDb;
        final offsetLabel =
            '${offset >= 0 ? '+' : ''}${offset.toStringAsFixed(1)} dB';

        return Scaffold(
          appBar: AppBar(
            title: Text(
              strings.settingsTitle,
              style: AppTypography.title.copyWith(color: palette.textPrimary),
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.base),
              children: [
                Text(
                  strings.appearanceSection,
                  style: AppTypography.label
                      .copyWith(color: palette.textSecondary),
                ),
                const SizedBox(height: AppSpacing.sm),
                _SettingsCard(
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _OptionChip(
                        label: strings.themeSystem,
                        icon: Icons.brightness_auto_rounded,
                        selected: controller.themeMode == ThemeMode.system,
                        onTap: () => controller.setThemeMode(ThemeMode.system),
                      ),
                      _OptionChip(
                        label: strings.themeLight,
                        icon: Icons.light_mode_outlined,
                        selected: controller.themeMode == ThemeMode.light,
                        onTap: () => controller.setThemeMode(ThemeMode.light),
                      ),
                      _OptionChip(
                        label: strings.themeDark,
                        icon: Icons.dark_mode_outlined,
                        selected: controller.themeMode == ThemeMode.dark,
                        onTap: () => controller.setThemeMode(ThemeMode.dark),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  strings.preferencesSection,
                  style: AppTypography.label
                      .copyWith(color: palette.textSecondary),
                ),
                const SizedBox(height: AppSpacing.sm),
                _SettingsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.languageLabel,
                        style: AppTypography.body
                            .copyWith(color: palette.textPrimary),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final loc in AppLocale.values)
                            _OptionChip(
                              label: loc.label,
                              selected: controller.locale == loc,
                              onTap: () => controller.setLocale(loc),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.base),
                      Divider(height: 1, color: palette.border),
                      const SizedBox(height: AppSpacing.base),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              strings.calibrationLabel,
                              style: AppTypography.body
                                  .copyWith(color: palette.textPrimary),
                            ),
                          ),
                          Text(
                            offsetLabel,
                            style: AppTypography.title.copyWith(
                              color: palette.accentPrimary,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        strings.calibrationDesc,
                        style: AppTypography.label.copyWith(
                          fontWeight: FontWeight.w400,
                          color: palette.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          _StepButton(
                            label: '-1.0',
                            onTap: offset > kMinCalibrationOffset
                                ? () => controller.adjustCalibrationOffset(-1.0)
                                : null,
                          ),
                          _StepButton(
                            label: '-0.5',
                            onTap: offset > kMinCalibrationOffset
                                ? () => controller.adjustCalibrationOffset(-0.5)
                                : null,
                          ),
                          _StepButton(
                            label: strings.resetOffsetCta,
                            onTap: offset != 0.0
                                ? () => controller.setCalibrationOffset(0.0)
                                : null,
                          ),
                          _StepButton(
                            label: '+0.5',
                            onTap: offset < kMaxCalibrationOffset
                                ? () => controller.adjustCalibrationOffset(0.5)
                                : null,
                          ),
                          _StepButton(
                            label: '+1.0',
                            onTap: offset < kMaxCalibrationOffset
                                ? () => controller.adjustCalibrationOffset(1.0)
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.base),
                      Divider(height: 1, color: palette.border),
                      const SizedBox(height: AppSpacing.base),
                      Text(
                        strings.hapticThresholdLabel,
                        style: AppTypography.body
                            .copyWith(color: palette.textPrimary),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        strings.hapticThresholdDesc,
                        style: AppTypography.label.copyWith(
                          fontWeight: FontWeight.w400,
                          color: palette.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final threshold in HapticThreshold.values)
                            _OptionChip(
                              label: strings.hapticThresholdChip(threshold),
                              selected: controller.hapticThreshold == threshold,
                              onTap: () =>
                                  controller.setHapticThreshold(threshold),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.base),
                      Divider(height: 1, color: palette.border),
                      const SizedBox(height: AppSpacing.sm),
                      _ToggleRow(
                        title: strings.keepAwakeLabel,
                        subtitle: strings.keepAwakeDesc,
                        value: controller.keepScreenAwake,
                        onChanged: controller.setKeepScreenAwake,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  strings.contactSection,
                  style: AppTypography.label
                      .copyWith(color: palette.textSecondary),
                ),
                const SizedBox(height: AppSpacing.sm),
                _SettingsCard(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ContactUsModal.show(context, strings);
                    },
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      child: Row(
                        children: [
                          Icon(
                            Icons.mail_outline_rounded,
                            color: palette.accentPrimary,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  strings.contactTitle,
                                  style: AppTypography.body
                                      .copyWith(color: palette.textPrimary),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  ContactUsModal.contactEmail,
                                  style: AppTypography.label.copyWith(
                                    fontWeight: FontWeight.w400,
                                    color: palette.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: palette.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _SettingsCard(
                  child: Column(
                    children: [
                      Image.asset(
                        isDark
                            ? 'assets/images/omniverse_labs_white.png'
                            : 'assets/images/omniverse_labs_color.png',
                        width: 72,
                        height: 72,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Icon(
                          Icons.all_inclusive_rounded,
                          size: 56,
                          color: palette.accentPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        strings.aboutCompany,
                        style: AppTypography.title.copyWith(
                          color: palette.textPrimary,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        strings.aboutMission,
                        textAlign: TextAlign.center,
                        style: AppTypography.body
                            .copyWith(color: palette.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.base),
                      Divider(height: 1, color: palette.border),
                      const SizedBox(height: AppSpacing.md),
                      _InfoRow(
                        label: strings.appDetailsLabel,
                        value: strings.appTitle,
                        highlight: true,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _InfoRow(
                        label: strings.packageIdLabel,
                        value: 'com.omniverselabs.loud_guard',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _InfoRow(
                        label: strings.versionLabel,
                        value: '1.0.0',
                      ),
                      const SizedBox(height: AppSpacing.base),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: palette.surfaceElevated,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(color: palette.border),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 18,
                              color: palette.accentPrimary,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                strings.privacyGuarantee,
                                style: AppTypography.label.copyWith(
                                  fontWeight: FontWeight.w400,
                                  color: palette.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: palette.border),
      ),
      child: child,
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        minimumSize: const Size(AppSpacing.minTouchTarget, AppSpacing.minTouchTarget),
      ),
      child: Text(
        label,
        style: AppTypography.label,
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return ChoiceChip(
      avatar: icon == null
          ? null
          : Icon(
              icon,
              size: 16,
              color: selected ? palette.onAccentPrimary : palette.textSecondary,
            ),
      label: Text(
        label,
        style: AppTypography.label.copyWith(
          color: selected ? palette.onAccentPrimary : palette.textPrimary,
        ),
      ),
      selected: selected,
      onSelected: (_) {
        HapticFeedback.selectionClick();
        onTap();
      },
      selectedColor: palette.accentPrimary,
      backgroundColor: palette.surfaceElevated,
      side: BorderSide(
        color: selected ? palette.accentPrimary : palette.border,
      ),
      showCheckmark: false,
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.body.copyWith(color: palette.textPrimary),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                style: AppTypography.label.copyWith(
                  fontWeight: FontWeight.w400,
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Switch.adaptive(
          value: value,
          activeTrackColor: palette.accentPrimary,
          onChanged: (next) {
            HapticFeedback.selectionClick();
            onChanged(next);
          },
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.label.copyWith(color: palette.textSecondary),
        ),
        const SizedBox(width: AppSpacing.md),
        Flexible(
          child: Text(
            value,
            style: AppTypography.label.copyWith(
              color: highlight ? palette.accentPrimary : palette.textPrimary,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
