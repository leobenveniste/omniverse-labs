import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import '../../services/app_services.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/haptics_helper.dart';

class RatingDialog extends StatelessWidget {
  const RatingDialog({super.key});

  static const MethodChannel _reviewChannel = MethodChannel('com.omniverselabs.charlemos/app_review');

  static Future<void> openStore() async {
    try {
      await _reviewChannel.invokeMethod('openPlayStore');
    } catch (_) {
      // Fallback: Copy link
      await Clipboard.setData(
        const ClipboardData(text: 'https://play.google.com/store/apps/details?id=com.omniverselabs.charlemos'),
      );
    }
  }

  static Future<void> checkAndShow(BuildContext context) async {
    final services = AppServices.of(context);
    final prefs = services.preferencesService;
    if (prefs.shouldShowRatingPrompt) {
      await show(context);
    }
  }

  static Future<void> show(BuildContext context) {
    HapticsHelper.medium();
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const RatingDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final prefs = AppServices.of(context).preferencesService;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      contentPadding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 5 Gold Stars with subtle gradient
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB800).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                5,
                (index) => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 28),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Title
          Text(
            l10n.t('ratingDialogTitle'),
            style: AppTypography.title(theme.colorScheme.onSurface).copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),

          // Description
          Text(
            l10n.t('ratingDialogDesc'),
            style: AppTypography.body(theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  HapticsHelper.selection();
                  await prefs.markRatedApp();
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                  await openStore();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC85A3B),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                child: Text(
                  l10n.t('ratingActionRate'),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            TextButton(
              onPressed: () async {
                HapticsHelper.light();
                await prefs.postponeRatingPrompt();
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: Text(
                l10n.t('ratingActionLater'),
                style: AppTypography.caption(theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
