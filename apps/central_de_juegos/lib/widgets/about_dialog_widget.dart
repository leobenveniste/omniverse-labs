import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/premium_service.dart';
import '../services/sound_haptics_service.dart';

class AboutDialogWidget extends StatelessWidget {
  final PremiumService? premiumService;

  const AboutDialogWidget({super.key, this.premiumService});

  static void show(BuildContext context, {PremiumService? premiumService}) {
    showDialog(
      context: context,
      builder: (ctx) => AboutDialogWidget(premiumService: premiumService),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    int tapCount = 0;
    DateTime? lastTap;

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
            StatefulBuilder(
              builder: (context, setInnerState) {
                return InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () async {
                    final now = DateTime.now();
                    if (lastTap == null || now.difference(lastTap!) > const Duration(seconds: 2)) {
                      tapCount = 1;
                    } else {
                      tapCount++;
                    }
                    lastTap = now;

                    if (tapCount >= 7) {
                      tapCount = 0;
                      SoundHapticsService.victory();
                      final service = premiumService ?? await PremiumService.getInstance();
                      await service.toggleDevMode();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: service.isDevMode ? const Color(0xFF2D7A4F) : const Color(0xFF475569),
                            content: Text(
                              service.isDevMode ? l10n.t('devModeUnlockedToast') : l10n.t('devModeLockedToast'),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      }
                    } else if (tapCount >= 4) {
                      SoundHapticsService.click();
                      final remaining = 7 - tapCount;
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          duration: const Duration(milliseconds: 600),
                          content: Text(
                            l10n.locale.languageCode == 'en'
                                ? 'You are $remaining steps away from developer options'
                                : 'Estás a $remaining pasos de desbloquear el modo desarrollador',
                          ),
                        ),
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${l10n.t('versionLabel')}:', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const Text('1.0.8 (Build 22)', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              },
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

