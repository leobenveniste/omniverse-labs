import 'dart:async';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/routine.dart';
import '../services/app_services.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/haptics_helper.dart';

class FocusZoneScreen extends StatefulWidget {
  final Routine? routine;

  const FocusZoneScreen({
    super.key,
    this.routine,
  });

  static Future<void> show(BuildContext context, {Routine? routine}) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => FocusZoneScreen(routine: routine),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            child: child,
          );
        },
      ),
    );
  }

  @override
  State<FocusZoneScreen> createState() => _FocusZoneScreenState();
}

class _FocusZoneScreenState extends State<FocusZoneScreen>
    with SingleTickerProviderStateMixin {
  // Preset breathing durations in minutes
  static const List<int> _presetMinutes = [3, 5, 10, 15, 20];

  late int _remainingSeconds;
  late int _initialSeconds;
  bool _isRunning = true;
  Timer? _timer;

  // Box Breathing cycle: 4s Inhale, 4s Hold, 4s Exhale, 4s Hold (16s cycle)
  int _boxBreathingTick = 0;
  late AnimationController _breathingAnimController;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = 5 * 60; // 5 minutes default breathing session
    _initialSeconds = _remainingSeconds;

    // Smooth continuous controller for the 16-second box breathing loop
    _breathingAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();

    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathingAnimController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
          _boxBreathingTick++;
          // Light haptic feedback on phase transitions (every 4 seconds)
          if (_boxBreathingTick % 4 == 0) {
            HapticsHelper.light();
          }
        });
      } else {
        _timer?.cancel();
        setState(() => _isRunning = false);
        _breathingAnimController.stop();
        HapticsHelper.heavy();
        try {
          AppServices.of(context).premiumService.recordFocusSession();
        } catch (_) {}
      }
    });
  }

  void _togglePlayPause() {
    HapticsHelper.selection();
    setState(() {
      _isRunning = !_isRunning;
      if (_isRunning) {
        _breathingAnimController.repeat();
        _startTimer();
      } else {
        _breathingAnimController.stop();
        _timer?.cancel();
      }
    });
  }

  void _setDuration(int minutes) {
    HapticsHelper.light();
    setState(() {
      _remainingSeconds = minutes * 60;
      _initialSeconds = _remainingSeconds;
      _boxBreathingTick = 0;
      if (!_isRunning) {
        _isRunning = true;
        _breathingAnimController.repeat();
        _startTimer();
      }
    });
  }

  void _adjustTime(int deltaSeconds) {
    HapticsHelper.light();
    setState(() {
      _remainingSeconds = (_remainingSeconds + deltaSeconds).clamp(60, 7200);
      if (_remainingSeconds > _initialSeconds) {
        _initialSeconds = _remainingSeconds;
      }
    });
  }

  String _formatTime(int totalSecs) {
    final m = totalSecs ~/ 60;
    final s = totalSecs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget _buildArrowIndicator({
    required IconData icon,
    required bool isActive,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isActive ? activeColor.withValues(alpha: 0.2) : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 16,
        color: isActive ? activeColor : inactiveColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Deep Dark Zen Focus Palette (enforced in all theme modes for minimum distraction)
    const bgDark = Color(0xFF0E1310);
    const cardBg = Color(0xFF171F1A);
    const cardBorder = Color(0xFF28342B);
    const textWhite = Color(0xFFF4F7F4);
    const textMuted = Color(0xFFA3B0A5);
    const accentTerracotta = Color(0xFFFF8A65);
    const accentSage = Color(0xFF72D572);

    // Box Breathing Phase Calculation: 0..3 (Inhale), 4..7 (Hold), 8..11 (Exhale), 12..15 (Hold)
    final currentCycleSecond = _boxBreathingTick % 16;
    final int phaseIndex = currentCycleSecond ~/ 4; // 0, 1, 2, 3
    final int phaseCountdown = 4 - (currentCycleSecond % 4);

    String phaseLabel;
    switch (phaseIndex) {
      case 0:
        phaseLabel = l10n.t('boxBreatheInhale');
        break;
      case 1:
        phaseLabel = l10n.t('boxBreatheHold');
        break;
      case 2:
        phaseLabel = l10n.t('boxBreatheExhale');
        break;
      default:
        phaseLabel = l10n.t('boxBreatheHold2');
        break;
    }

    final currentMinutes = (_remainingSeconds / 60).round();

    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - AppSpacing.md * 2,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // Top Bar with Zen Mode Pill, Relaxing Sound Toggle & Close
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xxs + 2),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                              border: Border.all(color: cardBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.spa_rounded, color: accentSage, size: 15),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  l10n.t('focusModeTag'),
                                  style: AppTypography.caption(textMuted, isMedium: true),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  AppServices.of(context).audioService.isSoundEnabled
                                      ? Icons.volume_up_rounded
                                      : Icons.volume_off_rounded,
                                  color: AppServices.of(context).audioService.isSoundEnabled
                                      ? accentSage
                                      : textMuted,
                                ),
                                tooltip: 'Música relajante',
                                onPressed: () {
                                  HapticsHelper.light();
                                  final audio = AppServices.of(context).audioService;
                                  setState(() {
                                    audio.toggleSound(!audio.isSoundEnabled);
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, color: textWhite),
                                tooltip: l10n.t('actionClose'),
                                onPressed: () {
                                  AppServices.of(context).audioService.stopAmbient();
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Title & Subtitle
                      Text(
                        l10n.t('focusZoneTitle'),
                        textAlign: TextAlign.center,
                        style: AppTypography.display(textWhite).copyWith(
                          letterSpacing: 0.5,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        l10n.t('breathingInhaleExhale'),
                        textAlign: TextAlign.center,
                        style: AppTypography.caption(textMuted, isMedium: true),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Duration Preset Chips (Time Selector)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: _presetMinutes.map((minutes) {
                            final isSelected = currentMinutes == minutes && _remainingSeconds % 60 == 0;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                              child: ChoiceChip(
                                label: Text(
                                  '${minutes}m',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? textWhite : textMuted,
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: accentSage.withValues(alpha: 0.3),
                                backgroundColor: cardBg,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                                  side: BorderSide(
                                    color: isSelected ? accentSage : cardBorder,
                                    width: 1.2,
                                  ),
                                ),
                                onSelected: (_) => _setDuration(minutes),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Box Breathing Square Visual (Hero Component)
                      Center(
                        child: AnimatedBuilder(
                          animation: _breathingAnimController,
                          builder: (context, child) {
                            // Scale expands during inhale (0..0.25), stays at peak in hold 1 (0.25..0.5),
                            // contracts during exhale (0.5..0.75), stays compact in hold 2 (0.75..1.0).
                            double scale = 1.0;
                            final val = _breathingAnimController.value;
                            if (val < 0.25) {
                              scale = 0.90 + (val / 0.25) * 0.20; // 0.90 -> 1.10
                            } else if (val < 0.50) {
                              scale = 1.10; // Peak Hold
                            } else if (val < 0.75) {
                              scale = 1.10 - ((val - 0.50) / 0.25) * 0.20; // 1.10 -> 0.90
                            } else {
                              scale = 0.90; // Base Hold
                            }

                            return Transform.scale(
                              scale: _isRunning ? scale : 1.0,
                              child: child,
                            );
                          },
                          child: Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              color: cardBg.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                              border: Border.all(
                                color: accentTerracotta.withValues(alpha: _isRunning ? 0.75 : 0.35),
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: accentTerracotta.withValues(alpha: _isRunning ? 0.22 : 0.06),
                                  blurRadius: 36,
                                  spreadRadius: 6,
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Standardized geometric guide arrows (all 4 with identical clean style)
                                Positioned(
                                  top: 10,
                                  child: _buildArrowIndicator(
                                    icon: Icons.arrow_upward_rounded,
                                    isActive: phaseIndex == 0,
                                    activeColor: accentTerracotta,
                                    inactiveColor: textMuted.withValues(alpha: 0.35),
                                  ),
                                ),
                                Positioned(
                                  right: 10,
                                  child: _buildArrowIndicator(
                                    icon: Icons.arrow_forward_rounded,
                                    isActive: phaseIndex == 1,
                                    activeColor: accentTerracotta,
                                    inactiveColor: textMuted.withValues(alpha: 0.35),
                                  ),
                                ),
                                Positioned(
                                  bottom: 10,
                                  child: _buildArrowIndicator(
                                    icon: Icons.arrow_downward_rounded,
                                    isActive: phaseIndex == 2,
                                    activeColor: accentTerracotta,
                                    inactiveColor: textMuted.withValues(alpha: 0.35),
                                  ),
                                ),
                                Positioned(
                                  left: 10,
                                  child: _buildArrowIndicator(
                                    icon: Icons.arrow_back_rounded,
                                    isActive: phaseIndex == 3,
                                    activeColor: accentTerracotta,
                                    inactiveColor: textMuted.withValues(alpha: 0.35),
                                  ),
                                ),

                                // Center Phase Label & Countdown
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _isRunning ? phaseLabel : l10n.t('focusPaused'),
                                      textAlign: TextAlign.center,
                                      style: AppTypography.title(textWhite).copyWith(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    if (_isRunning)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: accentTerracotta.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                        ),
                                        child: Text(
                                          '${phaseCountdown}s',
                                          style: AppTypography.display(accentTerracotta).copyWith(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
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
                      const SizedBox(height: AppSpacing.md),

                      // General Timer Pill Badge (Compact for session tracking)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                          border: Border.all(color: cardBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer_outlined, color: textMuted, size: 16),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              _formatTime(_remainingSeconds),
                              style: AppTypography.body(textWhite, isMedium: true).copyWith(
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Time Adjust & Play / Pause Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Minus 1 min
                          Material(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              onTap: () => _adjustTime(-60),
                              child: const Padding(
                                padding: EdgeInsets.all(AppSpacing.sm + 4),
                                child: Icon(Icons.remove_rounded, color: textWhite, size: 20),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),

                          // Play / Pause
                          Material(
                            color: accentTerracotta,
                            shape: const CircleBorder(),
                            elevation: 4,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _togglePlayPause,
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Icon(
                                  _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),

                          // Plus 1 min
                          Material(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              onTap: () => _adjustTime(60),
                              child: const Padding(
                                padding: EdgeInsets.all(AppSpacing.sm + 4),
                                child: Icon(Icons.add_rounded, color: textWhite, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Do Not Disturb & Neuro Insight Card (Safe wrapped, never overflows)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.sm + 4),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(color: cardBorder),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.xs),
                              decoration: BoxDecoration(
                                color: accentSage.withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.do_not_disturb_on_rounded, color: accentSage, size: 18),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.t('focusDndTitle'),
                                    style: AppTypography.body(textWhite, isMedium: true),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    l10n.t('focusDndDesc'),
                                    style: AppTypography.caption(textMuted),
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
              ),
            );
          },
        ),
      ),
    );
  }
}
