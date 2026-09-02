import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FeatureGuideItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  const FeatureGuideItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });
}

class FeatureGuideDialog extends StatelessWidget {
  final String prefKey;
  final IconData headerIcon;
  final Color headerColor;
  final String title;
  final String subtitle;
  final List<FeatureGuideItem> features;

  const FeatureGuideDialog({
    super.key,
    required this.prefKey,
    required this.headerIcon,
    required this.headerColor,
    required this.title,
    required this.subtitle,
    required this.features,
  });

  /// Checks if the guide was already shown. If not, displays it and marks as seen.
  static Future<void> showIfFirstTime({
    required BuildContext context,
    required String prefKey,
    required IconData headerIcon,
    required Color headerColor,
    required String title,
    required String subtitle,
    required List<FeatureGuideItem> features,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool(prefKey) ?? false;
    if (hasSeen) return;

    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FeatureGuideDialog(
        prefKey: prefKey,
        headerIcon: headerIcon,
        headerColor: headerColor,
        title: title,
        subtitle: subtitle,
        features: features,
      ),
    );

    await prefs.setBool(prefKey, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header Badge
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: headerColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(headerIcon, size: 36, color: headerColor),
          ),
          const SizedBox(height: 14),

          // Title & Subtitle
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Feature Rows
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.15)),
            ),
            child: Column(
              children: [
                for (int i = 0; i < features.length; i++) ...[
                  _buildFeatureRow(theme, features[i]),
                  if (i < features.length - 1) const Divider(height: 20),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Dismiss Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              child: const Text(
                '¡Entendido!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(ThemeData theme, FeatureGuideItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: item.iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(item.icon, size: 20, color: item.iconColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                item.description,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
