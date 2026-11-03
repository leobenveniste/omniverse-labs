import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class LoadingPrimaryButton extends StatelessWidget {
  final String label;
  final String? loadingLabel;
  final Widget? icon;
  final bool isLoading;
  final VoidCallback? onPressed;
  final Color? accentColor;
  final double? width;
  final double height;

  const LoadingPrimaryButton({
    super.key,
    required this.label,
    this.loadingLabel,
    this.icon,
    this.isLoading = false,
    this.onPressed,
    this.accentColor,
    this.width,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final primary = accentColor ?? AppTheme.primaryColor(context);
    final onPrimary = AppTheme.onPrimaryColor(context);

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          elevation: 0,
        ),
        onPressed: isLoading ? null : onPressed,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isLoading
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(onPrimary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      loadingLabel ?? l10n.get('loading'),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: onPrimary,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      icon!,
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                        color: onPrimary,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class LoadingOutlinedButton extends StatelessWidget {
  final String label;
  final String? loadingLabel;
  final Widget? icon;
  final bool isLoading;
  final VoidCallback? onPressed;
  final Color? color;
  final double? width;
  final double height;

  const LoadingOutlinedButton({
    super.key,
    required this.label,
    this.loadingLabel,
    this.icon,
    this.isLoading = false,
    this.onPressed,
    this.color,
    this.width,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final effectiveColor = color ?? AppTheme.primaryColor(context);
    final borderColor = AppTheme.borderColor(context);

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: borderColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        onPressed: isLoading ? null : onPressed,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isLoading
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(effectiveColor),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      loadingLabel ?? l10n.get('loading'),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: effectiveColor,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      icon!,
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: effectiveColor,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class SavingOverlayHUD {
  static Future<T> run<T>(
    BuildContext context, {
    required String message,
    String? successMessage,
    required Future<T> Function() task,
  }) async {
    final nav = Navigator.of(context, rootNavigator: true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: AppTheme.cardColor(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: AppTheme.borderColor(context)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryColor(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Flexible(
                    child: Text(
                      message,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppTheme.textPrimaryColor(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    try {
      final result = await task();
      nav.pop(); // cierra el loader

      if (context.mounted && successMessage != null) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.emeraldMint,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    successMessage,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return result;
    } catch (e) {
      nav.pop();
      rethrow;
    }
  }
}

class SkeletonCardLoader extends StatefulWidget {
  final double height;
  final double borderRadius;

  const SkeletonCardLoader({
    super.key,
    this.height = 140,
    this.borderRadius = 20,
  });

  @override
  State<SkeletonCardLoader> createState() => _SkeletonCardLoaderState();
}

class _SkeletonCardLoaderState extends State<SkeletonCardLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = AppTheme.surfaceContainer(context);
    final borderColor = AppTheme.borderColor(context);

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final opacity = 0.4 + (_anim.value * 0.45);
        return Container(
          width: double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            color: baseColor.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(color: borderColor),
          ),
        );
      },
    );
  }
}
