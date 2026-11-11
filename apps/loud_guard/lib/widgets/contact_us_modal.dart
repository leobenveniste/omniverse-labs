import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

/// Shared Omniverse Labs contact & feedback sheet (`leo.benveniste@gmail.com`).
class ContactUsModal extends StatelessWidget {
  const ContactUsModal({
    super.key,
    required this.strings,
  });

  static const String contactEmail = 'leo.benveniste@gmail.com';

  final AppStrings strings;

  static Future<void> show(BuildContext context, AppStrings strings) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ContactUsModal(strings: strings),
    );
  }

  Future<void> _launchEmail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: contactEmail,
      queryParameters: {
        'subject': '${strings.appTitle} — Feedback',
      },
    );
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      await Clipboard.setData(const ClipboardData(text: contactEmail));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.emailCopiedSnackbar)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
        border: Border(top: BorderSide(color: palette.border)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: AppSpacing.xs,
                decoration: BoxDecoration(
                  color: palette.border,
                  borderRadius: BorderRadius.circular(AppSpacing.xs),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            Row(
              children: [
                Container(
                  width: AppSpacing.minTouchTarget,
                  height: AppSpacing.minTouchTarget,
                  decoration: BoxDecoration(
                    color: palette.accentTint,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mail_outline_rounded,
                    color: palette.accentPrimary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    strings.contactTitle,
                    style: AppTypography.title.copyWith(
                      color: palette.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              strings.contactDescription,
              style: AppTypography.body.copyWith(color: palette.textSecondary),
            ),
            const SizedBox(height: AppSpacing.base),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: palette.surfaceElevated,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: palette.border),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.alternate_email_rounded,
                    size: 18,
                    color: palette.accentPrimary,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: SelectableText(
                      contactEmail,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: strings.copyEmailTooltip,
                    icon: Icon(
                      Icons.copy_rounded,
                      size: 20,
                      color: palette.textSecondary,
                    ),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      Clipboard.setData(
                        const ClipboardData(text: contactEmail),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(strings.emailCopiedSnackbar)),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        strings.gotItCta,
                        style: AppTypography.body
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        strings.sendEmailCta,
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: palette.onAccentPrimary,
                        ),
                      ),
                    ),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      _launchEmail(context);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
