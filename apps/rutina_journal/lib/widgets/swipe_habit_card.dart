import 'package:flutter/material.dart';
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
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0.0;
  bool _thresholdReached = false;
  late AnimationController _springController;
  late Animation<double> _springAnimation;
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
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details, double maxWidth) {
    final isCompleted = widget.log?.completed ?? false;

    setState(() {
      if (!isCompleted) {
        // Drag right to complete (0 to maxWidth)
        _dragOffset = (_dragOffset + details.primaryDelta!).clamp(0.0, maxWidth * 0.7);
        final progress = _dragOffset / (maxWidth * 0.7);
        if (progress >= 0.55 && !_thresholdReached) {
          _thresholdReached = true;
          HapticsHelper.medium();
        } else if (progress < 0.55 && _thresholdReached) {
          _thresholdReached = false;
        }
      } else {
        // Completed: Drag left to undo (-maxWidth to 0)
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
    final isCompleted = widget.log?.completed ?? false;
    final currentValue = widget.log?.currentValue ?? 0.0;
    final isCounter = widget.habit.type == HabitType.counter;

    final categoryColor = widget.habit.category.color;
    final completionColor = theme.colorScheme.primary;
    final undoColor = Colors.amber.shade700;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final isDraggingRight = _dragOffset > 0;
        final isDraggingLeft = _dragOffset < 0;

        return Stack(
          children: [
            // Background Action Reveal Layer
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: isDraggingLeft
                      ? undoColor.withValues(alpha: 0.25)
                      : (isCompleted
                          ? completionColor.withValues(alpha: 0.12)
                          : completionColor.withValues(alpha: 0.2 + ((_dragOffset / maxWidth).clamp(0.0, 1.0) * 0.5))),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: isCompleted
                        ? completionColor
                        : (isDraggingLeft ? undoColor : theme.colorScheme.outline),
                    width: isCompleted ? 1.5 : 1.0,
                  ),
                ),
                alignment: isDraggingLeft ? Alignment.centerRight : Alignment.centerLeft,
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: isDraggingLeft
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Deshacer',
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
                            scale: _thresholdReached || isCompleted ? 1.25 : 0.95,
                            duration: const Duration(milliseconds: 150),
                            child: Icon(
                              Icons.check_circle_rounded,
                              color: completionColor,
                              size: 26,
                            ),
                          ),
                          if (!isCompleted) ...[
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'Completar',
                              style: AppTypography.caption(completionColor, isMedium: true),
                            ),
                          ],
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
                child: Card(
                  elevation: isCompleted ? 0 : null,
                  color: isCompleted
                      ? theme.colorScheme.surface.withValues(alpha: 0.92)
                      : theme.colorScheme.surface,
                  child: GestureDetector(
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
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            // Status / Icon Indicator
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? completionColor
                                    : categoryColor.withValues(alpha: 0.14),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isCompleted
                                    ? Icons.check_rounded
                                    : widget.habit.category.icon,
                                size: 20,
                                color: isCompleted
                                    ? theme.colorScheme.onPrimary
                                    : categoryColor,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),

                            // Title and Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.habit.title,
                                    style: AppTypography.body(
                                      isCompleted
                                          ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
                                          : theme.colorScheme.onSurface,
                                      isMedium: true,
                                    ).copyWith(
                                      decoration: isCompleted
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
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
                                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                          ),
                                        )
                                      else if (!isCompleted)
                                        Text(
                                          'Desliza →',
                                          style: AppTypography.caption(
                                            theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                          ),
                                        )
                                      else
                                        Text(
                                          '← Desliza para deshacer',
                                          style: AppTypography.caption(
                                            theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Quick action: Counter increments or options
                            if (isCounter && !isCompleted && widget.onDelta != null) ...[
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline_rounded),
                                color: theme.colorScheme.primary,
                                iconSize: 24,
                                tooltip: '+1',
                                onPressed: () {
                                  HapticsHelper.light();
                                  widget.onDelta!(1.0);
                                },
                              ),
                            ] else ...[
                              IconButton(
                                icon: const Icon(Icons.more_vert_rounded),
                                iconSize: 20,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                tooltip: 'Editar',
                                onPressed: widget.onEdit,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
