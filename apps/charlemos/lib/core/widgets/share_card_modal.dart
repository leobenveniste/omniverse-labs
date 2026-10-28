import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../l10n/app_localizations.dart';
import '../../models/card_item.dart';
import '../theme/app_category_theme.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/haptics_helper.dart';

class ShareCardModal extends StatelessWidget {
  final CardItem card;
  final String cardText;

  const ShareCardModal({
    super.key,
    required this.card,
    required this.cardText,
  });

  static void show(BuildContext context, {required CardItem card, required String cardText}) {
    HapticsHelper.selection();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ShareCardModal(
        card: card,
        cardText: cardText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final catStyle = AppCategoryTheme.of(card.category);
    final catColor = catStyle.primary;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.share_rounded, color: catColor, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.t('shareModalTitle'),
                style: AppTypography.title(theme.colorScheme.onSurface).copyWith(fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Mini Story Card Preview Box
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  catColor.withValues(alpha: isDark ? 0.35 : 0.20),
                  isDark ? const Color(0xFF1E1A18) : const Color(0xFFFBF8F5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: catColor.withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: catColor.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(catStyle.icon, size: 13, color: catColor),
                          const SizedBox(width: 4),
                          Text(
                            AppCategoryTheme.getCategoryName(card.category, l10n).toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: catColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Text('💬 Charlemos', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFC85A3B))),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  cardText,
                  style: AppTypography.title(theme.colorScheme.onSurface).copyWith(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'play.google.com/store/apps/details?id=com.omniverselabs.charlemos',
                  style: AppTypography.caption(theme.colorScheme.onSurface.withValues(alpha: 0.5)).copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Primary Story Option
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticsHelper.selection();
                Navigator.pop(context);
                final storyText = l10n.t('shareStoryText', args: {'text': cardText});
                Clipboard.setData(ClipboardData(text: storyText));
                Share.share(storyText);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.t('shareStoryCopied')),
                    duration: const Duration(seconds: 2),
                    backgroundColor: const Color(0xFF2E7D32),
                  ),
                );
              },
              icon: const Icon(Icons.auto_awesome_rounded, size: 20),
              label: Text(
                l10n.t('shareStoryAction'),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC85A3B),
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Simple Share / Copy text option
          OutlinedButton.icon(
            onPressed: () {
              HapticsHelper.light();
              Navigator.pop(context);
              Share.share(
                l10n.t('shareText', args: {'text': cardText}),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: Text(l10n.t('shareCard')),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
