import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_strings.dart';
import '../models/loud_models.dart';
import '../services/loud_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/decibel_sparkline.dart';
import '../widgets/saved_checks_sheet.dart';
import 'settings_screen.dart';

/// Primary 1-screen offline decibel meter & WHO safe-exposure console.
class SoundConsoleScreen extends StatefulWidget {
  const SoundConsoleScreen({
    super.key,
    required this.controller,
  });

  final LoudController controller;

  @override
  State<SoundConsoleScreen> createState() => _SoundConsoleScreenState();
}

class _SoundConsoleScreenState extends State<SoundConsoleScreen> {
  Future<void> _handleToggleMeter() async {
    HapticFeedback.mediumImpact();
    final wasRunning = widget.controller.isRunning;
    final ok = await widget.controller.toggleMeter();
    if (!mounted) return;
    if (!wasRunning && !ok && widget.controller.hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.controller.strings.micUnavailableMessage)),
      );
    }
  }

  Future<void> _handleLogCheck() async {
    HapticFeedback.selectionClick();
    if (!widget.controller.hasSamples) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.controller.strings.needSampleFirst)),
      );
      return;
    }
    await SavedChecksSheet.show(
      context,
      controller: widget.controller,
      startInSaveMode: true,
    );
  }

  Future<void> _handleReset() async {
    HapticFeedback.selectionClick();
    await widget.controller.resetSession();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.controller.strings.sessionResetSnackbar)),
    );
  }

  void _openHistory() {
    HapticFeedback.selectionClick();
    SavedChecksSheet.show(
      context,
      controller: widget.controller,
      startInSaveMode: false,
    );
  }

  void _openSettings() {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(controller: widget.controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final palette = AppPalette.of(context);
        final strings = controller.strings;
        final zone = controller.currentZone;
        final zoneColor = _zoneAccentColor(zone, palette);
        final zoneTint = _zoneTintColor(zone, palette);
        final zoneText = _zoneTextColor(zone, palette);

        final safeExposure = controller.safeExposureNow;
        final safeExposureText = safeExposure == null
            ? strings.unlimitedSafe
            : ExposureMath.formatDurationCompact(safeExposure);
        final sessionTimeText = ExposureMath.formatDurationCompact(
          Duration(seconds: controller.sessionSeconds),
        );
        final dosePct = controller.dosePercent;
        final doseProgress = (dosePct / 100.0).clamp(0.0, 1.0);
        final dbRatio = ((controller.currentDb - 20.0) / 100.0).clamp(0.0, 1.0);

        return Scaffold(
          appBar: AppBar(
            titleSpacing: AppSpacing.base,
            title: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    width: 28,
                    height: 28,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.graphic_eq_rounded,
                      size: 24,
                      color: palette.accentPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  strings.appTitle,
                  style:
                      AppTypography.title.copyWith(color: palette.textPrimary),
                ),
              ],
            ),
            actions: [
              Semantics(
                label: strings.savedChecksTooltip,
                button: true,
                child: IconButton(
                  tooltip: strings.savedChecksTooltip,
                  onPressed: _openHistory,
                  icon: Badge(
                    isLabelVisible: controller.savedChecks.isNotEmpty,
                    backgroundColor: palette.accentPrimary,
                    textColor: palette.onAccentPrimary,
                    label: Text('${controller.savedChecks.length}'),
                    child: const Icon(Icons.history_rounded),
                  ),
                ),
              ),
              Semantics(
                label: strings.settingsTooltip,
                button: true,
                child: IconButton(
                  tooltip: strings.settingsTooltip,
                  onPressed: _openSettings,
                  icon: const Icon(Icons.settings_outlined),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.base,
                AppSpacing.sm,
                AppSpacing.base,
                AppSpacing.base,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (controller.permissionDenied) ...[
                    _PermissionBanner(
                      strings: strings,
                      onAllowTap: _handleToggleMeter,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _MeterCard(
                            controller: controller,
                            strings: strings,
                            palette: palette,
                            zoneColor: zoneColor,
                            zoneTint: zoneTint,
                            zoneText: zoneText,
                            dbRatio: dbRatio,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _ExposureCard(
                            strings: strings,
                            palette: palette,
                            safeExposureText: safeExposureText,
                            sessionTimeText: sessionTimeText,
                            dosePct: dosePct,
                            doseProgress: doseProgress,
                            contextLabel: controller.hasSamples
                                ? strings.contextReference(controller.currentDb)
                                : strings.contextReference(35.0),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _handleToggleMeter,
                          style: controller.isRunning
                              ? ElevatedButton.styleFrom(
                                  backgroundColor: palette.warning,
                                  foregroundColor: palette.onAccentPrimary,
                                )
                              : null,
                          icon: Icon(
                            controller.isRunning
                                ? Icons.pause_rounded
                                : Icons.mic_none_rounded,
                            size: 20,
                          ),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              controller.isRunning
                                  ? strings.pauseMeterCta
                                  : strings.startMeterCta,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _handleLogCheck,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              strings.logCheckCta,
                              style: AppTypography.label.copyWith(
                                color: palette.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Semantics(
                        label: strings.resetCta,
                        button: true,
                        child: Tooltip(
                          message: strings.resetCta,
                          child: OutlinedButton(
                            onPressed: _handleReset,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                              ),
                            ),
                            child: const Icon(Icons.refresh_rounded, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _zoneAccentColor(SafetyZone zone, AppPalette palette) {
    return switch (zone) {
      SafetyZone.safe => palette.accentPrimary,
      SafetyZone.moderate => palette.textSecondary,
      SafetyZone.caution => palette.warning,
      SafetyZone.damageRisk => palette.danger,
    };
  }

  Color _zoneTintColor(SafetyZone zone, AppPalette palette) {
    return switch (zone) {
      SafetyZone.safe => palette.accentTint,
      SafetyZone.moderate => palette.surfaceElevated,
      SafetyZone.caution => palette.warningTint,
      SafetyZone.damageRisk => palette.dangerTint,
    };
  }

  Color _zoneTextColor(SafetyZone zone, AppPalette palette) {
    return switch (zone) {
      SafetyZone.safe => palette.accentPrimary,
      SafetyZone.moderate => palette.textPrimary,
      SafetyZone.caution => palette.warningText,
      SafetyZone.damageRisk => palette.dangerText,
    };
  }
}

class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner({
    required this.strings,
    required this.onAllowTap,
  });

  final AppStrings strings;
  final VoidCallback onAllowTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.warningTint,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: palette.warning),
      ),
      child: Row(
        children: [
          Icon(Icons.mic_off_outlined, color: palette.warning),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              strings.micPermissionNeeded,
              style: AppTypography.label.copyWith(
                fontWeight: FontWeight.w400,
                color: palette.warningText,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          TextButton(
            onPressed: onAllowTap,
            child: Text(
              strings.grantMicCta,
              style: AppTypography.label.copyWith(color: palette.warningText),
            ),
          ),
        ],
      ),
    );
  }
}

class _MeterCard extends StatelessWidget {
  const _MeterCard({
    required this.controller,
    required this.strings,
    required this.palette,
    required this.zoneColor,
    required this.zoneTint,
    required this.zoneText,
    required this.dbRatio,
  });

  final LoudController controller;
  final AppStrings strings;
  final AppPalette palette;
  final Color zoneColor;
  final Color zoneTint;
  final Color zoneText;
  final double dbRatio;

  @override
  Widget build(BuildContext context) {
    final statusLabel = controller.isRunning
        ? strings.statusListening
        : (controller.hasSamples ? strings.statusPaused : strings.statusReady);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: zoneTint,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  border: Border.all(color: zoneColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  strings.zoneBadgeLabel(controller.currentZone),
                  style: AppTypography.label.copyWith(color: zoneText),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: controller.isRunning
                          ? palette.accentPrimary
                          : palette.textSecondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    statusLabel,
                    style: AppTypography.label.copyWith(
                      color: controller.isRunning
                          ? palette.accentPrimary
                          : palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.base),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                controller.hasSamples
                    ? controller.currentDb.toStringAsFixed(1)
                    : '--.-',
                style: AppTypography.display.copyWith(
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                strings.dbUnit,
                style: AppTypography.label.copyWith(
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.xs),
            child: LinearProgressIndicator(
              value: controller.hasSamples ? dbRatio : 0.0,
              minHeight: AppSpacing.sm,
              backgroundColor: palette.surfaceElevated,
              valueColor: AlwaysStoppedAnimation<Color>(zoneColor),
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          DecibelSparkline(samples: controller.history),
          const SizedBox(height: AppSpacing.base),
          Divider(height: 1, color: palette.border),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _StatCell(
                label: strings.minLabel,
                value: controller.hasSamples
                    ? controller.minDb.toStringAsFixed(1)
                    : '--.-',
              ),
              _StatCell(
                label: strings.avgLabel,
                value: controller.hasSamples
                    ? controller.avgDb.toStringAsFixed(1)
                    : '--.-',
                highlight: true,
              ),
              _StatCell(
                label: strings.peakLabel,
                value: controller.hasSamples
                    ? controller.peakDb.toStringAsFixed(1)
                    : '--.-',
                accent: controller.peakDb >= 95.0
                    ? palette.danger
                    : (controller.peakDb >= 85.0 ? palette.warning : null),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    this.highlight = false,
    this.accent,
  });

  final String label;
  final String value;
  final bool highlight;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final valueColor = accent ??
        (highlight ? palette.accentPrimary : palette.textPrimary);

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.label.copyWith(color: palette.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$value dB',
            style: AppTypography.title.copyWith(
              color: valueColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExposureCard extends StatelessWidget {
  const _ExposureCard({
    required this.strings,
    required this.palette,
    required this.safeExposureText,
    required this.sessionTimeText,
    required this.dosePct,
    required this.doseProgress,
    required this.contextLabel,
  });

  final AppStrings strings;
  final AppPalette palette;
  final String safeExposureText;
  final String sessionTimeText;
  final double dosePct;
  final double doseProgress;
  final String contextLabel;

  @override
  Widget build(BuildContext context) {
    final isOverDose = dosePct >= 100.0;
    final doseColor = isOverDose
        ? palette.danger
        : (dosePct >= 50.0 ? palette.warning : palette.accentPrimary);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            strings.exposureSectionTitle,
            style: AppTypography.label.copyWith(color: palette.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.safeLimitLabel,
                      style: AppTypography.label.copyWith(
                        fontWeight: FontWeight.w400,
                        color: palette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      safeExposureText,
                      style: AppTypography.title.copyWith(
                        color: palette.textPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.sessionTimeLabel,
                      style: AppTypography.label.copyWith(
                        fontWeight: FontWeight.w400,
                        color: palette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      sessionTimeText,
                      style: AppTypography.title.copyWith(
                        color: palette.textPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      strings.dailyDoseLabel,
                      style: AppTypography.label.copyWith(
                        fontWeight: FontWeight.w400,
                        color: palette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${dosePct.toStringAsFixed(1)}%',
                      style: AppTypography.title.copyWith(
                        color: doseColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.xs),
            child: LinearProgressIndicator(
              value: doseProgress,
              minHeight: AppSpacing.xs,
              backgroundColor: palette.surfaceElevated,
              valueColor: AlwaysStoppedAnimation<Color>(doseColor),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isOverDose ? palette.dangerTint : palette.surfaceElevated,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: isOverDose ? palette.danger : palette.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isOverDose
                      ? Icons.warning_amber_rounded
                      : Icons.hearing_rounded,
                  size: 16,
                  color: isOverDose ? palette.danger : palette.accentPrimary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    isOverDose ? strings.doseWarningText : contextLabel,
                    style: AppTypography.label.copyWith(
                      fontWeight: FontWeight.w400,
                      color: isOverDose
                          ? palette.dangerText
                          : palette.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
