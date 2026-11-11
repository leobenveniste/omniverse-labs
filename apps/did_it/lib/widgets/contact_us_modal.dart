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
      queryParameters: <String, String>{
        'subject': '${strings.appTitle} — Feedback',
      },
    );
    var launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }
    if (!launched && context.mounted) {
      await Clipboard.setData(const ClipboardData(text: contactEmail));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              strings.isEs
                  ? 'Correo copiado: $contactEmail'
                  : 'Email copied: $contactEmail',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          children: <Widget>[
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
              children: <Widget>[
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        strings.contactTitle,
                        style: AppTypography.title
                            .copyWith(color: palette.textPrimary),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        contactEmail,
                        style: AppTypography.label
                            .copyWith(color: palette.accentPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.base),
            Container(
              padding: const EdgeInsets.all(AppSpacing.base),
              decoration: BoxDecoration(
                color: palette.surfaceElevated,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: palette.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    Icons.shield_outlined,
                    size: 20,
                    color: palette.accentPrimary,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      strings.privacyOfflineBody,
                      style: AppTypography.body
                          .copyWith(color: palette.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            FilledButton.icon(
              onPressed: () => _launchEmail(context),
              icon: const Icon(Icons.send_rounded, size: 18),
              label: Text(
                strings.isEs ? 'Escribir a Soporte' : 'Email Support',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: Image.asset(
                isDark
                    ? 'assets/images/omniverse_labs_white.png'
                    : 'assets/images/omniverse_labs_color.png',
                height: 28,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Text(
                  'OMNIVERSE LABS',
                  style: AppTypography.label
                      .copyWith(color: palette.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
