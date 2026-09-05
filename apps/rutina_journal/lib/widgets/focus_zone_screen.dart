import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/routine.dart';
import '../services/app_services.dart';
import '../services/dnd_service.dart';
import '../theme/app_colors.dart';
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
        pageBuilder: (context, anim1, anim2) => FocusZoneScreen(routine: routine),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // Preset breathing durations in minutes
  static const List<int> _presetMinutes = [3, 5, 10, 15, 20];

  int _selectedDurationMinutes = 5;
  int _sectionDurationSeconds = 4; // 4s default per phase (Inhale, Hold, Exhale, Hold)
  late int _remainingSeconds;
  bool _isRunning = true;
  Timer? _timer;

  // Box Breathing cycle tracking
  int _boxBreathingTick = 0;
  late AnimationController _breathingAnimController;
  late AnimationController _bgAnimController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _remainingSeconds = _selectedDurationMinutes * 60;

    // Continuous controller for box breathing loop (cycle = 4 * section duration)
    _breathingAnimController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _sectionDurationSeconds * 4),
    )..repeat();

    // Very slow, smooth 24-second ambient loop for background orbs
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();

    _startTimer();

    // Start ambient meditation music & enable Do Not Disturb
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final audio = AppServices.of(context).audioService;
        if (audio.isSoundEnabled) {
          audio.playBreathingAmbient();
        }
        DndService.enableDnd();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      // User left the app or switched tasks: immediately stop sound & pause timer
      if (_isRunning) {
        setState(() {
          _isRunning = false;
          _breathingAnimController.stop();
          _timer?.cancel();
        });
      }
      try {
        AppServices.of(context).audioService.stopAmbient();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _breathingAnimController.dispose();
    _bgAnimController.dispose();
    try {
      AppServices.of(context).audioService.stopAmbient();
    } catch (_) {}
    try {
      DndService.disableDnd();
    } catch (_) {}
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
          _boxBreathingTick++;
          // Haptic feedback on phase transitions
          if (_boxBreathingTick % _sectionDurationSeconds == 0) {
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
          AppServices.of(context).audioService.stopAmbient();
        } catch (_) {}
      }
    });
  }

  void _togglePlayPause() {
    HapticsHelper.selection();
    final audio = AppServices.of(context).audioService;
    setState(() {
      _isRunning = !_isRunning;
      if (_isRunning) {
        _breathingAnimController.repeat();
        _startTimer();
        if (audio.isSoundEnabled) {
          audio.playBreathingAmbient();
        }
      } else {
        _breathingAnimController.stop();
        _timer?.cancel();
        audio.stopAmbient();
      }
    });
  }

  void _setDuration(int minutes) {
    HapticsHelper.light();
    setState(() {
      _selectedDurationMinutes = minutes;
      _remainingSeconds = minutes * 60;
      _boxBreathingTick = 0;
      if (!_isRunning) {
        _isRunning = true;
        _breathingAnimController.repeat();
        _startTimer();
        final audio = AppServices.of(context).audioService;
        if (audio.isSoundEnabled) {
          audio.playBreathingAmbient();
        }
      }
    });
  }

  void _adjustSectionPace(int delta) {
    HapticsHelper.light();
    final newPace = (_sectionDurationSeconds + delta).clamp(2, 10);
    if (newPace == _sectionDurationSeconds) return;

    setState(() {
      _sectionDurationSeconds = newPace;
      _boxBreathingTick = 0;
      _breathingAnimController.duration = Duration(seconds: _sectionDurationSeconds * 4);
      if (_isRunning) {
        _breathingAnimController.reset();
        _breathingAnimController.repeat();
      }
    });
  }

  void _resetSession() {
    HapticsHelper.medium();
    setState(() {
      _remainingSeconds = _selectedDurationMinutes * 60;
      _boxBreathingTick = 0;
      _breathingAnimController.reset();
      if (_isRunning) {
        _breathingAnimController.repeat();
        _startTimer();
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
        color: isActive ? activeColor.withValues(alpha: 0.22) : Colors.transparent,
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
    final prefs = AppServices.of(context).preferencesService;
    final audio = AppServices.of(context).audioService;

    // Strict Dark Zen Mode adhering dynamically to the active Theme Preset
    final colors = AppColors.of(prefs.themePreset, true);
    final bgDark = colors.background;
    final cardBg = colors.surface;
    final cardBorder = colors.outline.withValues(alpha: 0.35);
    final textWhite = colors.textPrimary;
    final textMuted = colors.textSecondary;
    final accentPrimary = colors.primary;
    final accentSecondary = colors.secondary;

    // Box Breathing Phase Calculation based on dynamic section duration
    final cycleTotal = _sectionDurationSeconds * 4;
    final currentCycleSecond = _boxBreathingTick % cycleTotal;
    final int phaseIndex = currentCycleSecond ~/ _sectionDurationSeconds; // 0, 1, 2, 3
    final int phaseCountdown = _sectionDurationSeconds - (currentCycleSecond % _sectionDurationSeconds);

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

    return Scaffold(
      backgroundColor: bgDark,
      body: Stack(
        children: [
          // 1. Subtle, Calm Animated Abstract Mesh / Orbs Background
          Positioned.fill(
            child: _AbstractBreathingBackground(
              animation: _bgAnimController,
              primary: accentPrimary,
              secondary: accentSecondary,
            ),
          ),

          // 2. Interactive Foreground Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - AppSpacing.md * 2,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          // Top Bar: Zen Mode Badge, Audio Toggle & Close
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm + 2,
                                  vertical: AppSpacing.xxs + 2,
                                ),
                                decoration: BoxDecoration(
                                  color: cardBg.withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                  border: Border.all(color: cardBorder),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.spa_rounded, color: accentPrimary, size: 15),
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
                                      audio.isSoundEnabled
                                          ? Icons.volume_up_rounded
                                          : Icons.volume_off_rounded,
                                      color: audio.isSoundEnabled ? accentPrimary : textMuted,
                                    ),
                                    tooltip: 'Música relajante',
                                    onPressed: () {
                                      HapticsHelper.light();
                                      setState(() {
                                        audio.toggleSound(!audio.isSoundEnabled);
                                        if (audio.isSoundEnabled && _isRunning) {
                                          audio.playBreathingAmbient();
                                        } else {
                                          audio.stopAmbient();
                                        }
                                      });
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.close_rounded, color: textWhite),
                                    tooltip: l10n.t('actionClose'),
                                    onPressed: () {
                                      audio.stopAmbient();
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

                          // Duration Preset Chips (Persistent Selection)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: _presetMinutes.map((minutes) {
                                final isSelected = _selectedDurationMinutes == minutes;
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
                                    selectedColor: accentPrimary.withValues(alpha: 0.35),
                                    backgroundColor: cardBg.withValues(alpha: 0.85),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                                      side: BorderSide(
                                        color: isSelected ? accentPrimary : cardBorder,
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
                                double scale = 1.0;
                                final val = _breathingAnimController.value;
                                if (val < 0.25) {
                                  scale = 0.90 + (val / 0.25) * 0.20; // Inhale expansion
                                } else if (val < 0.50) {
                                  scale = 1.10; // Peak Hold
                                } else if (val < 0.75) {
                                  scale = 1.10 - ((val - 0.50) / 0.25) * 0.20; // Exhale contraction
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
                                  color: cardBg.withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                                  border: Border.all(
                                    color: accentPrimary.withValues(alpha: _isRunning ? 0.80 : 0.40),
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accentPrimary.withValues(alpha: _isRunning ? 0.22 : 0.06),
                                      blurRadius: 36,
                                      spreadRadius: 6,
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // 4 Clean, Uniform Directional Arrows
                                    Positioned(
                                      top: 10,
                                      child: _buildArrowIndicator(
                                        icon: Icons.arrow_upward_rounded,
                                        isActive: phaseIndex == 0,
                                        activeColor: accentPrimary,
                                        inactiveColor: textMuted.withValues(alpha: 0.35),
                                      ),
                                    ),
                                    Positioned(
                                      right: 10,
                                      child: _buildArrowIndicator(
                                        icon: Icons.arrow_forward_rounded,
                                        isActive: phaseIndex == 1,
                                        activeColor: accentPrimary,
                                        inactiveColor: textMuted.withValues(alpha: 0.35),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 10,
                                      child: _buildArrowIndicator(
                                        icon: Icons.arrow_downward_rounded,
                                        isActive: phaseIndex == 2,
                                        activeColor: accentPrimary,
                                        inactiveColor: textMuted.withValues(alpha: 0.35),
                                      ),
                                    ),
                                    Positioned(
                                      left: 10,
                                      child: _buildArrowIndicator(
                                        icon: Icons.arrow_back_rounded,
                                        isActive: phaseIndex == 3,
                                        activeColor: accentPrimary,
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
                                              color: accentPrimary.withValues(alpha: 0.20),
                                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                            ),
                                            child: Text(
                                              '${phaseCountdown}s',
                                              style: AppTypography.display(accentPrimary).copyWith(
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

                          // Session Remaining Time Pill Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                            decoration: BoxDecoration(
                              color: cardBg.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                              border: Border.all(color: cardBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.timer_outlined, color: textMuted, size: 16),
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

                          // Section Pace Adjuster (- and + per section, min 2s)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: _sectionDurationSeconds > 2 ? () => _adjustSectionPace(-1) : null,
                                icon: Icon(
                                  Icons.remove_circle_outline_rounded,
                                  color: _sectionDurationSeconds > 2 ? accentPrimary : textMuted.withValues(alpha: 0.3),
                                  size: 26,
                                ),
                                tooltip: '-1s paso',
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: cardBg.withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                  border: Border.all(color: cardBorder),
                                ),
                                child: Text(
                                  l10n.t('paceSecondsPerSection', args: {'seconds': '$_sectionDurationSeconds'}),
                                  style: AppTypography.caption(textWhite, isMedium: true).copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              IconButton(
                                onPressed: _sectionDurationSeconds < 10 ? () => _adjustSectionPace(1) : null,
                                icon: Icon(
                                  Icons.add_circle_outline_rounded,
                                  color: _sectionDurationSeconds < 10 ? accentPrimary : textMuted.withValues(alpha: 0.3),
                                  size: 26,
                                ),
                                tooltip: '+1s paso',
                              ),
                            ],
                          ),

                          const SizedBox(height: AppSpacing.md),

                          // Center Controls: Reset Timer + Play/Pause
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Reset Timer Button (Starts over session)
                              Material(
                                color: cardBg.withValues(alpha: 0.90),
                                shape: const CircleBorder(),
                                elevation: 2,
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: _resetSession,
                                  child: Tooltip(
                                    message: l10n.t('focusResetSession'),
                                    child: Padding(
                                      padding: const EdgeInsets.all(AppSpacing.sm + 4),
                                      child: Icon(
                                        Icons.replay_rounded,
                                        color: textWhite,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.lg),

                              // Play / Pause Button
                              Material(
                                color: accentPrimary,
                                shape: const CircleBorder(),
                                elevation: 4,
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: _togglePlayPause,
                                  child: Padding(
                                    padding: const EdgeInsets.all(AppSpacing.md),
                                    child: Icon(
                                      _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                      color: colors.onPrimary,
                                      size: 30,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Do Not Disturb Status Card (Non-overflow, actionable)
                          GestureDetector(
                            onTap: () async {
                              final hasPerm = await DndService.hasPermission();
                              if (!hasPerm) {
                                await DndService.openSettings();
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppSpacing.sm + 4),
                              decoration: BoxDecoration(
                                color: cardBg.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                border: Border.all(color: cardBorder),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(AppSpacing.xs),
                                    decoration: BoxDecoration(
                                      color: accentPrimary.withValues(alpha: 0.18),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.do_not_disturb_on_rounded,
                                      color: accentPrimary,
                                      size: 18,
                                    ),
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
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Subtle, Organic Animated Background with floating blurred theme gradient orbs
class _AbstractBreathingBackground extends StatelessWidget {
  final Animation<double> animation;
  final Color primary;
  final Color secondary;

  const _AbstractBreathingBackground({
    required this.animation,
    required this.primary,
    required this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value * 2 * math.pi;
        return CustomPaint(
          size: Size.infinite,
          painter: _OrbsPainter(
            t: t,
            primary: primary,
            secondary: secondary,
          ),
        );
      },
    );
  }
}

class _OrbsPainter extends CustomPainter {
  final double t;
  final Color primary;
  final Color secondary;

  _OrbsPainter({
    required this.t,
    required this.primary,
    required this.secondary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // Orb 1: Upper right floating subtle ambient glow
    final dx1 = size.width * 0.75 + math.sin(t) * 35;
    final dy1 = size.height * 0.22 + math.cos(t * 0.8) * 40;
    final r1 = size.width * 0.50 + math.sin(t * 1.2) * 20;

    final paint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          primary.withValues(alpha: 0.12),
          primary.withValues(alpha: 0.04),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(dx1, dy1), radius: r1));
    canvas.drawCircle(Offset(dx1, dy1), r1, paint1);

    // Orb 2: Lower left floating gently
    final dx2 = size.width * 0.22 - math.cos(t * 0.9) * 40;
    final dy2 = size.height * 0.72 + math.sin(t * 0.7) * 35;
    final r2 = size.width * 0.52 + math.cos(t * 1.1) * 25;

    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          secondary.withValues(alpha: 0.10),
          secondary.withValues(alpha: 0.03),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(dx2, dy2), radius: r2));
    canvas.drawCircle(Offset(dx2, dy2), r2, paint2);

    // Orb 3: Center gentle breathing aura
    final dx3 = size.width * 0.50 + math.sin(t * 0.5) * 20;
    final dy3 = size.height * 0.44 + math.cos(t * 0.6) * 25;
    final r3 = size.width * 0.38 + math.sin(t) * 15;

    final paint3 = Paint()
      ..shader = RadialGradient(
        colors: [
          primary.withValues(alpha: 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(dx3, dy3), radius: r3));
    canvas.drawCircle(Offset(dx3, dy3), r3, paint3);
  }

  @override
  bool shouldRepaint(covariant _OrbsPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.primary != primary || oldDelegate.secondary != secondary;
}
