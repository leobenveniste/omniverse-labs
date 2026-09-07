import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/haptics_helper.dart';

enum ButtonState {
  idle,
  loading,
  disabled,
  error,
}

class StateButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final ButtonState state;
  final bool isSecondary;
  final Color? customColor;
  final double? height;

  const StateButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.state = ButtonState.idle,
    this.isSecondary = false,
    this.customColor,
    this.height,
  });

  @override
  State<StateButton> createState() => _StateButtonState();
}

class _StateButtonState extends State<StateButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = widget.state == ButtonState.idle && widget.onPressed != null;
    final isLoading = widget.state == ButtonState.loading;
    final isError = widget.state == ButtonState.error;

    final baseColor = widget.customColor ??
        (widget.isSecondary
            ? theme.colorScheme.secondary
            : theme.colorScheme.primary);

    Color bg;
    Color fg;

    if (isError) {
      bg = theme.colorScheme.error;
      fg = theme.colorScheme.onError;
    } else if (widget.isSecondary) {
      bg = theme.colorScheme.surfaceContainerHighest;
      fg = baseColor;
    } else {
      bg = baseColor;
      fg = theme.colorScheme.onPrimary;
    }

    return AnimatedScale(
      scale: _isPressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: isEnabled || isLoading ? 1.0 : 0.38,
        duration: const Duration(milliseconds: 200),
        child: SizedBox(
          width: double.infinity,
          height: widget.height ?? AppSpacing.xxl,
          child: Material(
            color: bg,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: InkWell(
              onTap: isEnabled
                  ? () {
                      HapticsHelper.selection();
                      widget.onPressed?.call();
                    }
                  : null,
              onHighlightChanged: (pressed) {
                if (isEnabled) {
                  setState(() => _isPressed = pressed);
                }
              },
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          valueColor: AlwaysStoppedAnimation<Color>(fg),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(widget.icon, size: 18, color: fg),
                            const SizedBox(width: AppSpacing.xs),
                          ],
                          Text(
                            widget.label,
                            style: AppTypography.body(fg, isMedium: true),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
