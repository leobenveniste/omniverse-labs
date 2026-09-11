import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics_helper.dart';
import '../../../l10n/app_localizations.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  final bool canUseBiometrics;
  final Future<bool> Function() onBiometricRequested;
  final bool Function(String pin) onPinVerify;

  const LockScreen({
    super.key,
    required this.onUnlocked,
    required this.canUseBiometrics,
    required this.onBiometricRequested,
    required this.onPinVerify,
  });

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with SingleTickerProviderStateMixin {
  String _enteredPin = '';
  late AnimationController _shakeController;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    // Prompt biometrics on startup if enabled
    if (widget.canUseBiometrics) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerBiometrics();
      });
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _triggerBiometrics() async {
    HapticsHelper.light();
    final success = await widget.onBiometricRequested();
    if (success && mounted) {
      HapticsHelper.medium();
      widget.onUnlocked();
    }
  }

  void _onDigitPressed(String digit) {
    if (_enteredPin.length >= 4) return;

    HapticsHelper.selection();
    setState(() {
      _hasError = false;
      _enteredPin += digit;
    });

    if (_enteredPin.length == 4) {
      _verifyPin();
    }
  }

  void _onBackspace() {
    if (_enteredPin.isEmpty) return;
    HapticsHelper.light();
    setState(() {
      _hasError = false;
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
    });
  }

  void _verifyPin() {
    final valid = widget.onPinVerify(_enteredPin);
    if (valid) {
      HapticsHelper.medium();
      widget.onUnlocked();
    } else {
      HapticsHelper.error();
      setState(() {
        _hasError = true;
        _enteredPin = '';
      });
      _shakeController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.dark;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Shield Icon Header
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.surfaceElevated,
                  border: Border.all(color: colors.outline, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.15),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.shield_rounded,
                  color: colors.secondary,
                  size: 36,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              Text(
                l10n.t('secureAppTitle'),
                style: AppTypography.display(colors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _hasError ? l10n.t('pinErrorSubtitle') : l10n.t('enterPinSubtitle'),
                style: AppTypography.body(
                  _hasError ? colors.loss : colors.textSecondary,
                  isMedium: _hasError,
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // 4-Dots PIN Display with Shake animation
              AnimatedBuilder(
                animation: _shakeController,
                builder: (context, child) {
                  final offset = _hasError
                      ? (12.0 * (1.0 - _shakeController.value) *
                          (0.5 - ((_shakeController.value * 6) % 1.0)))
                      : 0.0;
                  return Transform.translate(
                    offset: Offset(offset, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        final filled = index < _enteredPin.length;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: filled
                                ? (_hasError ? colors.loss : colors.secondary)
                                : colors.surfaceElevated,
                            border: Border.all(
                              color: _hasError ? colors.loss : colors.outline,
                              width: 1.5,
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                },
              ),

              const Spacer(flex: 3),

              // Numeric Keypad
              _buildKeypad(colors),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad(AppColors colors) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildKeypadRow(['1', '2', '3'], colors),
        const SizedBox(height: AppSpacing.md),
        _buildKeypadRow(['4', '5', '6'], colors),
        const SizedBox(height: AppSpacing.md),
        _buildKeypadRow(['7', '8', '9'], colors),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Biometrics or empty
            widget.canUseBiometrics
                ? _buildKeypadButton(
                    icon: Icons.fingerprint_rounded,
                    onTap: _triggerBiometrics,
                    colors: colors,
                  )
                : const SizedBox(width: 72, height: 72),
            _buildKeypadButton(
              digit: '0',
              onTap: () => _onDigitPressed('0'),
              colors: colors,
            ),
            _buildKeypadButton(
              icon: Icons.backspace_outlined,
              onTap: _onBackspace,
              colors: colors,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeypadRow(List<String> digits, AppColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) {
        return _buildKeypadButton(
          digit: d,
          onTap: () => _onDigitPressed(d),
          colors: colors,
        );
      }).toList(),
    );
  }

  Widget _buildKeypadButton({
    String? digit,
    IconData? icon,
    required VoidCallback onTap,
    required AppColors colors,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.surface,
            border: Border.all(color: colors.outline, width: 1.0),
          ),
          child: digit != null
              ? Text(
                  digit,
                  style: AppTypography.display(colors.textPrimary),
                )
              : Icon(
                  icon,
                  color: colors.textPrimary,
                  size: 26,
                ),
        ),
      ),
    );
  }
}
