import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class InterestTagChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isShared;
  final bool isSelected;
  final VoidCallback? onTap;

  const InterestTagChip({
    super.key,
    required this.label,
    this.icon,
    this.isShared = false,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primaryColor(context);
    final borderColor = AppTheme.borderColor(context);
    final textPrimary = AppTheme.textPrimaryColor(context);

    final bool highlight = isShared || isSelected;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: highlight
              ? primary.withValues(alpha: 0.16)
              : AppTheme.surfaceContainer(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: highlight ? primary : borderColor,
            width: highlight ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isShared) ...[
              Icon(Icons.auto_awesome_rounded,
                  size: 14, color: AppTheme.secondaryColor(context)),
              const SizedBox(width: 6),
            ] else if (icon != null) ...[
              Icon(icon, size: 14, color: highlight ? primary : textPrimary),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                color: highlight ? primary : textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
