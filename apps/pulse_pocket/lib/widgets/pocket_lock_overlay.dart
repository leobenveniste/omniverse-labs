import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_strings.dart';
import '../models/pulse_models.dart';
import '../theme/app_theme.dart';

/// Pure OLED blackout touch-guard blocking accidental pocket touches behind a 1.2s hold-to-unlock gesture.
class PocketLockOverlay extends StatefulWidget {
  const PocketLockOverlay({
    super.key,
    required this.bpm,
    required this.signature,
    required this.currentBeat,
    required this.visualFlashEnabled,
    required this.strings,
    required this.onUnlock,
  });

  final int bpm;
  final TimeSignatureOption signature;
  final int currentBeat;
  final bool visualFlashEnabled;
  final AppStrings strings;
  final VoidCallback onUnlock;

  @override
  State<PocketLockOverlay> createState() => _PocketLockOverlayState();
}

class _PocketLockOverlayState extends State<PocketLockOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _holdController;
  bool _holding = false;

  @override
  void initState() {
    super.initState();
    _holdController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onUnlock();
        }
      });
  }

  @override
  void dispose() {
    _holdController.dispose();
    super.dispose();
  }

  void _startHold() {
    if (!mounted || _holding) return;
    setState(() => _holding = true);
    HapticFeedback.selectionClick();
    _holdController.forward(from: 0.0);
  }

  void _cancelHold() {
    if (!mounted || !_holding) return;
    setState(() => _holding = false);
    _holdController.stop();
    _holdController.value = 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.dark;
    final isBeatOne = widget.currentBeat == 0;
    final dotColor = isBeatOne ? palette.warning : palette.accentPrimary;

    return PopScope(
      canPop: false,
      child: Material(
        color: Colors.black,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (_) => _startHold(),
          onPointerUp: (_) => _cancelHold(),
          onPointerCancel: (_) => _cancelHold(),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (widget.visualFlashEnabled)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 80),
                      width: isBeatOne ? 16 : 12,
                      height: isBeatOne ? 16 : 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.currentBeat >= 0
                            ? dotColor.withValues(alpha: 0.75)
                            : Colors.white12,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    widget.strings.pocketLockTitle,
                    style: AppTypography.label.copyWith(
                      color: palette.textSecondary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${widget.bpm} ${widget.strings.bpmUnit} · ${widget.signature.label}',
                    style: AppTypography.display.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: AnimatedBuilder(
                      animation: _holdController,
                      builder: (context, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 72,
                              height: 72,
                              child: CircularProgressIndicator(
                                value: _holding ? _holdController.value : 0.0,
                                strokeWidth: 4,
                                backgroundColor: const Color(0xFF1F2630),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  palette.accentPrimary,
                                ),
                              ),
                            ),
                            Icon(
                              _holding
                                  ? Icons.lock_open_rounded
                                  : Icons.lock_outline_rounded,
                              size: 28,
                              color: _holding
                                  ? palette.accentPrimary
                                  : palette.textSecondary,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.base),
                  Text(
                    widget.strings.pocketLockHint,
                    textAlign: TextAlign.center,
                    style: AppTypography.body.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
