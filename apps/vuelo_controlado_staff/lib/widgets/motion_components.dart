import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Un envoltorio táctil interactivo que provee un micro-rebote elástico al presionar,
/// retroalimentación háptica y compatibilidad total con estados de accesibilidad.
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double targetScale;
  final Duration duration;
  final Curve curve;
  final BorderRadius? borderRadius;
  final bool enableHaptic;
  final Color? splashColor;
  final String? semanticLabel;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.targetScale = 0.96,
    this.duration = const Duration(milliseconds: 120),
    this.curve = Curves.easeOutBack,
    this.borderRadius,
    this.enableHaptic = true,
    this.splashColor,
    this.semanticLabel,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.targetScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
      reverseCurve: widget.curve,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onTap == null && widget.onLongPress == null) return;
    if (widget.enableHaptic) {
      HapticFeedback.selectionClick();
    }
    _controller.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    Widget core = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        if (reduceMotion) return child!;
        final scale = _scaleAnimation.value * (_isHovered ? 1.02 : 1.0);
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: widget.child,
    );

    if (widget.onTap != null || widget.onLongPress != null) {
      core = MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          child: core,
        ),
      );
    }

    if (widget.semanticLabel != null) {
      return Semantics(
        button: widget.onTap != null,
        label: widget.semanticLabel,
        child: core,
      );
    }

    return core;
  }
}

/// Revelación secuencial escalonada para elementos de listas y tarjetas.
class StaggeredEntrance extends StatelessWidget {
  final int index;
  final Widget child;
  final Duration baseDelay;
  final Duration stepDelay;
  final Duration duration;
  final Offset offset;

  const StaggeredEntrance({
    super.key,
    required this.index,
    required this.child,
    this.baseDelay = const Duration(milliseconds: 30),
    this.stepDelay = const Duration(milliseconds: 35),
    this.duration = const Duration(milliseconds: 320),
    this.offset = const Offset(0, 0.08),
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) return child;

    final cappedIndex = math.min(index, 10);
    final totalDelay = baseDelay + (stepDelay * cappedIndex);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: duration + totalDelay,
      curve: Curves.easeOutCubic,
      builder: (context, progress, widgetChild) {
        final delayedProgress =
            ((progress - (totalDelay.inMilliseconds / (duration.inMilliseconds + totalDelay.inMilliseconds))) /
                    (duration.inMilliseconds / (duration.inMilliseconds + totalDelay.inMilliseconds)))
                .clamp(0.0, 1.0);

        final curvedVal = Curves.easeOutCubic.transform(delayedProgress);
        final currentOffset = Offset(
          offset.dx * (1.0 - curvedVal),
          offset.dy * (1.0 - curvedVal),
        );

        return Opacity(
          opacity: curvedVal,
          child: Transform.translate(
            offset: currentOffset * 200,
            child: widgetChild,
          ),
        );
      },
      child: child,
    );
  }
}

/// Animación elástica de sacudida horizontal (shake) ante errores de validación o PIN incorrecto.
class ShakeAnimation extends StatefulWidget {
  final Widget child;
  final AnimationController controller;
  final double offsetRange;

  const ShakeAnimation({
    super.key,
    required this.child,
    required this.controller,
    this.offsetRange = 16.0,
  });

  @override
  State<ShakeAnimation> createState() => _ShakeAnimationState();
}

class _ShakeAnimationState extends State<ShakeAnimation> {
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: widget.controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final progress = widget.controller.value;
        // 3 ciclos de oscilación armónica amortiguada
        final sine = math.sin(progress * math.pi * 6);
        final damping = 1.0 - progress;
        final offset = sine * widget.offsetRange * damping;

        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Indicador sutil de pulso / respiración para eventos activos o estados destacados.
class PulseBeacon extends StatefulWidget {
  final Widget child;
  final bool isPulsing;
  final double minScale;
  final double maxScale;
  final Duration period;

  const PulseBeacon({
    super.key,
    required this.child,
    this.isPulsing = true,
    this.minScale = 0.95,
    this.maxScale = 1.05,
    this.period = const Duration(milliseconds: 1800),
  });

  @override
  State<PulseBeacon> createState() => _PulseBeaconState();
}

class _PulseBeaconState extends State<PulseBeacon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.period);
    _scaleAnimation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutSine,
    ));

    if (widget.isPulsing) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PulseBeacon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing != oldWidget.isPulsing) {
      if (widget.isPulsing) {
        _controller.repeat(reverse: true);
      } else {
        _controller.animateTo(0.0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion || !widget.isPulsing) return widget.child;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
