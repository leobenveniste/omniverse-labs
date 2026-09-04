import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class AboutDialogWidget extends StatelessWidget {
  const AboutDialogWidget({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const AboutDialogWidget(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Omniverse Labs Logo
            Image.asset(
              isDark
                  ? 'assets/images/omniverse_labs_white.png'
                  : 'assets/images/omniverse_labs_color.png',
              width: 90,
              height: 90,
            ),
            const SizedBox(height: 16),
            const Text(
              'OMNIVERSE LABS',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.t('aboutDesc'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            // App Name & Version Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'App:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  l10n.locale.languageCode == 'en' ? 'Game Night Hub' : 'Central de Juegos',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${l10n.t('versionLabel')}:', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const Text('1.0.4 (Build 18)', style: TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.t('close')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
