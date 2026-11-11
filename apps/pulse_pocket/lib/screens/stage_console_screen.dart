import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_strings.dart';
import '../models/pulse_models.dart';
import '../services/pulse_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/beat_indicator_bar.dart';
import '../widgets/pocket_lock_overlay.dart';
import '../widgets/slot_editor_sheet.dart';
import 'settings_screen.dart';

/// Primary 1-screen silent haptic metronome console + 1-Tap Setlist Slots + Pocket Lock overlay.
class StageConsoleScreen extends StatefulWidget {
  const StageConsoleScreen({
    super.key,
    required this.controller,
  });

  final PulseController controller;

  @override
  State<StageConsoleScreen> createState() => _StageConsoleScreenState();
}

class _StageConsoleScreenState extends State<StageConsoleScreen> {
  bool _tapFlash = false;

  Future<void> _openSlotEditor({SetlistSlot? existing}) async {
    final controller = widget.controller;
    final strings = controller.strings;

    if (existing == null && controller.slots.length >= kMaxSetlistSlots) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.maxSlotsReached)),
      );
      return;
    }

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SlotEditorSheet(
        existingSlot: existing,
        currentBpm: controller.bpm,
        currentSignature: controller.signature,
        strings: strings,
        onSave: (name, bpm, signature) async {
          await controller.saveSlot(
            existingId: existing?.id,
            name: name,
            bpm: bpm,
            signature: signature,
          );
        },
        onDelete: existing == null
            ? null
            : () => controller.deleteSlot(existing.id),
      ),
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

  void _handleTapTempo() {
    HapticFeedback.mediumImpact();
    setState(() => _tapFlash = true);
    Future.delayed(const Duration(milliseconds: 110), () {
      if (mounted) {
        setState(() => _tapFlash = false);
      }
    });
    widget.controller.registerTap();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final palette = AppPalette.of(context);
        final strings = controller.strings;

        return Stack(
          children: [
            Scaffold(
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
                          Icons.vibration_rounded,
                          size: 24,
                          color: palette.accentPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      strings.appTitle,
                      style: AppTypography.title.copyWith(
                        color: palette.textPrimary,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    tooltip: strings.settingsTooltip,
                    onPressed: _openSettings,
                    icon: const Icon(Icons.settings_outlined),
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
                      _SetlistStrip(
                        slots: controller.slots,
                        activeSlotId: controller.activeSlotId,
                        strings: strings,
                        onSelect: (slot) {
                          HapticFeedback.selectionClick();
                          controller.selectSlot(slot);
                        },
                        onEdit: (slot) => _openSlotEditor(existing: slot),
                        onAdd: () => _openSlotEditor(),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.base),
                                decoration: BoxDecoration(
                                  color: palette.surface,
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusLg,
                                  ),
                                  border: Border.all(color: palette.border),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.sm,
                                            vertical: AppSpacing.xs,
                                          ),
                                          decoration: BoxDecoration(
                                            color: palette.accentTint,
                                            borderRadius: BorderRadius.circular(
                                              AppSpacing.radiusPill,
                                            ),
                                          ),
                                          child: Text(
                                            strings.silentModeBadge,
                                            style: AppTypography.label.copyWith(
                                              color: palette.accentPrimary,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          controller.signature.label,
                                          style: AppTypography.label.copyWith(
                                            color: palette.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.base),
                                    BeatIndicatorBar(
                                      beatsPerBar:
                                          controller.signature.beatsPerBar,
                                      currentBeat: controller.currentBeat,
                                      isRunning: controller.isRunning,
                                      visualFlashEnabled:
                                          controller.visualFlashEnabled,
                                      strings: strings,
                                    ),
                                    const SizedBox(height: AppSpacing.base),
                                    Divider(height: 1, color: palette.border),
                                    const SizedBox(height: AppSpacing.base),
                                    Wrap(
                                      spacing: AppSpacing.sm,
                                      runSpacing: AppSpacing.sm,
                                      alignment: WrapAlignment.center,
                                      children: [
                                        for (final sig
                                            in TimeSignatureOption.values)
                                          ChoiceChip(
                                            label: Text(
                                              sig.label,
                                              style: AppTypography.label.copyWith(
                                                color:
                                                    controller.signature == sig
                                                        ? palette.onAccentPrimary
                                                        : palette.textPrimary,
                                              ),
                                            ),
                                            selected:
                                                controller.signature == sig,
                                            selectedColor: palette.accentPrimary,
                                            backgroundColor:
                                                palette.surfaceElevated,
                                            side: BorderSide(
                                              color: controller.signature == sig
                                                  ? palette.accentPrimary
                                                  : palette.border,
                                            ),
                                            showCheckmark: false,
                                            onSelected: (_) {
                                              HapticFeedback.selectionClick();
                                              controller.setSignature(sig);
                                            },
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.base),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        _BpmStepButton(
                                          label: '-5',
                                          tooltip: '-5 BPM',
                                          onPressed: controller.bpm > kMinBpm
                                              ? () => controller.nudgeBpm(-5)
                                              : null,
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        _BpmStepButton(
                                          label: '-1',
                                          tooltip: '-1 BPM',
                                          onPressed: controller.bpm > kMinBpm
                                              ? () => controller.nudgeBpm(-1)
                                              : null,
                                        ),
                                        const SizedBox(width: AppSpacing.base),
                                        Column(
                                          children: [
                                            Text(
                                              '${controller.bpm}',
                                              key: const ValueKey('bpm-display'),
                                              style:
                                                  AppTypography.display.copyWith(
                                                color: palette.textPrimary,
                                              ),
                                            ),
                                            Text(
                                              strings.bpmUnit,
                                              style: AppTypography.label.copyWith(
                                                color: palette.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: AppSpacing.base),
                                        _BpmStepButton(
                                          label: '+1',
                                          tooltip: '+1 BPM',
                                          onPressed: controller.bpm < kMaxBpm
                                              ? () => controller.nudgeBpm(1)
                                              : null,
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        _BpmStepButton(
                                          label: '+5',
                                          tooltip: '+5 BPM',
                                          onPressed: controller.bpm < kMaxBpm
                                              ? () => controller.nudgeBpm(5)
                                              : null,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        activeTrackColor: palette.accentPrimary,
                                        inactiveTrackColor:
                                            palette.surfaceElevated,
                                        thumbColor: palette.accentPrimary,
                                        overlayColor: palette.accentPrimary
                                            .withValues(alpha: 0.16),
                                      ),
                                      child: Slider(
                                        min: kMinBpm.toDouble(),
                                        max: kMaxBpm.toDouble(),
                                        value: controller.bpm.toDouble(),
                                        onChanged: (value) =>
                                            controller.setBpm(value.round()),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Semantics(
                                button: true,
                                label: strings.tapTempoLabel,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusLg,
                                  ),
                                  onTap: _handleTapTempo,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 90),
                                    constraints: const BoxConstraints(
                                      minHeight: 84,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.base,
                                      vertical: AppSpacing.md,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _tapFlash
                                          ? palette.accentTint
                                          : palette.surface,
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusLg,
                                      ),
                                      border: Border.all(
                                        color: _tapFlash
                                            ? palette.accentPrimary
                                            : palette.border,
                                        width: _tapFlash ? 1.5 : 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.touch_app_rounded,
                                          color: palette.accentPrimary,
                                        ),
                                        const SizedBox(width: AppSpacing.md),
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              strings.tapTempoLabel,
                                              style:
                                                  AppTypography.title.copyWith(
                                                color: palette.textPrimary,
                                              ),
                                            ),
                                            Text(
                                              strings.tapTempoHint,
                                              style:
                                                  AppTypography.label.copyWith(
                                                fontWeight: FontWeight.w400,
                                                color: palette.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                controller.toggleRunning();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: controller.isRunning
                                    ? palette.danger
                                    : palette.accentPrimary,
                                foregroundColor: controller.isRunning
                                    ? Colors.white
                                    : palette.onAccentPrimary,
                              ),
                              icon: Icon(
                                controller.isRunning
                                    ? Icons.stop_rounded
                                    : Icons.play_arrow_rounded,
                              ),
                              label: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  controller.isRunning
                                      ? strings.stopCta
                                      : strings.startCta,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            flex: 2,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                controller.engagePocketLock();
                              },
                              icon: const Icon(
                                Icons.lock_outline_rounded,
                                size: 18,
                              ),
                              label: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  strings.pocketLockCta,
                                  style: AppTypography.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: palette.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (controller.isPocketLocked)
              Positioned.fill(
                child: PocketLockOverlay(
                  bpm: controller.bpm,
                  signature: controller.signature,
                  currentBeat: controller.currentBeat,
                  visualFlashEnabled: controller.visualFlashEnabled,
                  strings: strings,
                  onUnlock: controller.unlockPocketLock,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SetlistStrip extends StatelessWidget {
  const _SetlistStrip({
    required this.slots,
    required this.activeSlotId,
    required this.strings,
    required this.onSelect,
    required this.onEdit,
    required this.onAdd,
  });

  final List<SetlistSlot> slots;
  final String? activeSlotId;
  final AppStrings strings;
  final ValueChanged<SetlistSlot> onSelect;
  final ValueChanged<SetlistSlot> onEdit;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              strings.setlistSection,
              style: AppTypography.label.copyWith(color: palette.textSecondary),
            ),
            TextButton.icon(
              style: TextButton.styleFrom(
                minimumSize: const Size(
                  AppSpacing.minTouchTarget,
                  AppSpacing.minTouchTarget,
                ),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              ),
              onPressed: onAdd,
              icon: Icon(
                Icons.add_rounded,
                size: 18,
                color: palette.accentPrimary,
              ),
              label: Text(
                strings.saveSlotCta,
                style: AppTypography.label.copyWith(
                  color: palette.accentPrimary,
                ),
              ),
            ),
          ],
        ),
        SizedBox(
          height: AppSpacing.minTouchTarget,
          child: slots.isEmpty
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    strings.emptySlotsHint,
                    style: AppTypography.label.copyWith(
                      fontWeight: FontWeight.w400,
                      color: palette.textSecondary,
                    ),
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: slots.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final slot = slots[index];
                    final selected = slot.id == activeSlotId;
                    return Material(
                      color: selected
                          ? palette.accentPrimary
                          : palette.surface,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusPill,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusPill,
                        ),
                        onTap: () => onSelect(slot),
                        onLongPress: () => onEdit(slot),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.base,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusPill,
                            ),
                            border: Border.all(
                              color: selected
                                  ? palette.accentPrimary
                                  : palette.border,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${slot.name} · ${slot.bpm}',
                            style: AppTypography.label.copyWith(
                              color: selected
                                  ? palette.onAccentPrimary
                                  : palette.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _BpmStepButton extends StatelessWidget {
  const _BpmStepButton({
    required this.label,
    required this.tooltip,
    required this.onPressed,
  });

  final String label;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Tooltip(
      message: tooltip,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(
            AppSpacing.minTouchTarget,
            AppSpacing.minTouchTarget,
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          backgroundColor: palette.surfaceElevated,
        ),
        onPressed: onPressed == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onPressed!();
              },
        child: Text(
          label,
          style: AppTypography.label.copyWith(
            color: onPressed == null
                ? palette.textSecondary
                : palette.textPrimary,
          ),
        ),
      ),
    );
  }
}
