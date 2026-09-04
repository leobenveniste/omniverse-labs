import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/haptics_helper.dart';

class SwipeHabitCard extends StatefulWidget {
  final Habit habit;
  final HabitLog? log;
  final ({int current, int best}) streak;
  final VoidCallback onToggle;
  final ValueChanged<double>? onDelta;
  final VoidCallback onEdit;

  const SwipeHabitCard({
    super.key,
    required this.habit,
    required this.log,
    required this.streak,
    required this.onToggle,
    this.onDelta,
    required this.onEdit,
  });

  @override
  State<SwipeHabitCard> createState() => _SwipeHabitCardState();
}

class _SwipeHabitCardState extends State<SwipeHabitCard>
    with TickerProviderStateMixin {
  double _dragOffset = 0.0;
  bool _thresholdReached = false;
  late AnimationController _springController;
  late Animation<double> _springAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseScale;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _springAnimation = Tween<double>(begin: 0, end: 0).animate(_springController)
      ..addListener(() {
        setState(() => _dragOffset = _springAnimation.value);
      });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _pulseScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.35).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: 1.35, end: 0.90).chain(CurveTween(curve: Curves.easeInOut)), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 0.90, end: 1.0).chain(CurveTween(curve: Curves.easeOutBack)), weight: 30),
    ]).animate(_pulseController);
  }

  @override
  void didUpdateWidget(covariant SwipeHabitCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasCompleted = oldWidget.log?.completed ?? false;
    final isCompleted = widget.log?.completed ?? false;
    if (!wasCompleted && isCompleted) {
      _pulseController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _springController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details, double maxWidth) {
    final isCompleted = widget.log?.completed ?? false;

    setState(() {
      if (!isCompleted) {
        // Drag right to complete (0 to maxWidth * 0.7)
        _dragOffset = (_dragOffset + details.primaryDelta!).clamp(0.0, maxWidth * 0.7);
        final progress = _dragOffset / (maxWidth * 0.7);
        if (progress >= 0.55 && !_thresholdReached) {
          _thresholdReached = true;
          HapticsHelper.medium();
        } else if (progress < 0.55 && _thresholdReached) {
          _thresholdReached = false;
        }
      } else {
        // Completed: Drag left to undo (-maxWidth * 0.7 to 0)
        _dragOffset = (_dragOffset + details.primaryDelta!).clamp(-maxWidth * 0.7, 0.0);
        final progress = (-_dragOffset) / (maxWidth * 0.7);
        if (progress >= 0.55 && !_thresholdReached) {
          _thresholdReached = true;
          HapticsHelper.medium();
        } else if (progress < 0.55 && _thresholdReached) {
          _thresholdReached = false;
        }
      }
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details, double maxWidth) {
    if (_thresholdReached) {
      HapticsHelper.heavy();
      widget.onToggle();
      setState(() {
        _dragOffset = 0.0;
        _thresholdReached = false;
      });
    } else {
      // Spring back to 0
      _springAnimation = Tween<double>(begin: _dragOffset, end: 0.0).animate(
        CurvedAnimation(parent: _springController, curve: Curves.easeOutBack),
      );
      _springController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isCompleted = widget.log?.completed ?? false;
    final currentValue = widget.log?.currentValue ?? 0.0;
    final isCounter = widget.habit.type == HabitType.counter;

    final categoryColor = widget.habit.category.color;
    final undoColor = Colors.amber.shade700;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final isDraggingLeft = _dragOffset < 0;

        return ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Stack(
            children: [
              // Background Action Reveal Layer
              if (_dragOffset != 0.0)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDraggingLeft
                          ? undoColor.withValues(alpha: 0.3)
                          : categoryColor.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    alignment: isDraggingLeft ? Alignment.centerRight : Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: isDraggingLeft
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                l10n.t('actionUndo'),
                                style: AppTypography.caption(undoColor, isMedium: true),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              AnimatedScale(
                                scale: _thresholdReached ? 1.25 : 0.95,
                                duration: const Duration(milliseconds: 150),
                                child: Icon(
                                  Icons.undo_rounded,
                                  color: undoColor,
                                  size: 26,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedScale(
                                scale: _thresholdReached ? 1.25 : 0.95,
                                duration: const Duration(milliseconds: 150),
                                child: Icon(
                                  Icons.check_circle_rounded,
                                  color: categoryColor,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                l10n.t('actionComplete'),
                                style: AppTypography.caption(categoryColor, isMedium: true),
                              ),
                            ],
                          ),
                  ),
                ),

              // Foreground Habit Card
              Transform.translate(
                offset: Offset(_dragOffset, 0),
                child: AnimatedScale(
                  scale: _isPressed ? 0.98 : 1.0,
                  duration: const Duration(milliseconds: 100),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOutCubic,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? (isDark
                              ? categoryColor.withValues(alpha: 0.32)
                              : categoryColor.withValues(alpha: 0.22))
                          : (isDark ? theme.colorScheme.surface : theme.colorScheme.surface),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: isCompleted
                            ? categoryColor.withValues(alpha: isDark ? 0.65 : 0.5)
                            : (isDark
                                ? theme.colorScheme.outline.withValues(alpha: 0.8)
                                : theme.colorScheme.outline),
                        width: isCompleted ? 1.5 : 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isCompleted
                              ? categoryColor.withValues(alpha: isDark ? 0.25 : 0.12)
                              : Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
                          blurRadius: isCompleted ? 10 : (isDark ? 8 : 4),
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        // Left Accent Strip perfectly clipped to the card's rounded corner
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: 4.5,
                          child: Container(color: categoryColor),
                        ),
                        GestureDetector(
                          onHorizontalDragUpdate: (d) => _onHorizontalDragUpdate(d, maxWidth),
                          onHorizontalDragEnd: (d) => _onHorizontalDragEnd(d, maxWidth),
                          child: InkWell(
                            onTapDown: (_) => setState(() => _isPressed = true),
                            onTapUp: (_) => setState(() => _isPressed = false),
                            onTapCancel: () => setState(() => _isPressed = false),
                            onTap: () {
                              HapticsHelper.selection();
                              widget.onToggle();
                            },
                            onLongPress: widget.onEdit,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              child: Row(
                                children: [
                                  // Category Icon with satisfying pulse on completion
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4, right: 8),
                                    child: ScaleTransition(
                                      scale: _pulseScale,
                                      child: Icon(
                                        widget.habit.category.icon,
                                        size: 30,
                                        color: categoryColor,
                                      ),
                                    ),
                                  ),
                                  // Title and Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.habit.title,
                                          style: AppTypography.body(
                                            isCompleted
                                                ? (isDark ? Colors.white : theme.colorScheme.onSurface)
                                                : theme.colorScheme.onSurface,
                                            isMedium: true,
                                          ).copyWith(
                                            decoration: isCompleted
                                                ? TextDecoration.lineThrough
                                                : TextDecoration.none,
                                            fontWeight: isCompleted ? FontWeight.w600 : FontWeight.w600,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: AppSpacing.xxs),
                                        Row(
                                          children: [
                                            // Streak badge
                                            if (widget.streak.current > 0) ...[
                                              const Icon(
                                                Icons.local_fire_department_rounded,
                                                size: 14,
                                                color: Colors.deepOrange,
                                              ),
                                              const SizedBox(width: 2),
                                              Text(
                                                '${widget.streak.current}d',
                                                style: AppTypography.caption(
                                                  Colors.deepOrange,
                                                  isMedium: true,
                                                ),
                                              ),
                                              const SizedBox(width: AppSpacing.xs),
                                            ],
                                            // Counter progress or swipe hint
                                            if (isCounter)
                                              Text(
                                                '${currentValue.toInt()} / ${widget.habit.targetValue.toInt()} ${widget.habit.unit}',
                                                style: AppTypography.caption(
                                                  theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                                  isMedium: true,
                                                ),
                                              )
                                            else if (!isCompleted)
                                              Text(
                                                l10n.t('swipeToCompleteHint'),
                                                style: AppTypography.caption(
                                                  categoryColor.withValues(alpha: 0.8),
                                                  isMedium: true,
                                                ),
                                              )
                                            else
                                              Text(
                                                l10n.t('swipeToUndoHint'),
                                                style: AppTypography.caption(
                                                  theme.colorScheme.onSurface.withValues(alpha: 0.55),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Quick action: Counter increments
                                  if (isCounter && !isCompleted && widget.onDelta != null) ...[
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline_rounded),
                                      color: categoryColor,
                                      iconSize: 24,
                                      tooltip: '+1',
                                      onPressed: () {
                                        HapticsHelper.light();
                                        widget.onDelta!(1.0);
                                      },
                                    ),
                                  ],
                                  // Dedicated Edit Icon Button
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    iconSize: 18,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                    tooltip: l10n.t('actionEdit'),
                                    onPressed: () {
                                      HapticsHelper.light();
                                      widget.onEdit();
                                    },
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
              ),
        ],
        ),
      );
      },
    );
  }
}
