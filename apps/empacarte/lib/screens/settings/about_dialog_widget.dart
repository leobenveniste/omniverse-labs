import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

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
    final t = AppLocalizations.of(context);
    final isSpanish = t.locale.languageCode == 'es';
    final cardBg = isDark ? AppColors.darkCard : AppColors.parchmentCard;
    final goldAccent = isDark ? AppColors.goldFoil : AppColors.burgundyBase;
    final textSecondary = isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary;

    return Dialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: goldAccent.withValues(alpha: 0.4), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(26.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Omniverse Labs Logo
            Image.asset(
              isDark
                  ? 'assets/images/omniverse_labs_white.png'
                  : 'assets/images/omniverse_labs_color.png',
              width: 84,
              height: 84,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.travel_explore_rounded,
                size: 64,
                color: goldAccent,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'OMNIVERSE LABS',
              style: AppTypography.subheadSerif(color: goldAccent).copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSpanish
                  ? 'Diseño sensorial y utilidades de viaje inteligentes creadas con pasión, sellos táctiles y privacidad absoluta.'
                  : 'Sensory design and smart travel utilities crafted with tactile stamps and uncompromising privacy.',
              textAlign: TextAlign.center,
              style: AppTypography.body(color: textSecondary).copyWith(fontSize: 12.5),
            ),
            const SizedBox(height: 18),
            Divider(color: goldAccent.withValues(alpha: 0.2)),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isSpanish ? 'Aplicación:' : 'App:',
                  style: AppTypography.caption(color: textSecondary, medium: true),
                ),
                Text(
                  'EmpacArte',
                  style: AppTypography.body(color: goldAccent).copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isSpanish ? 'Versión:' : 'Version:',
                  style: AppTypography.caption(color: textSecondary, medium: true),
                ),
                Text(
                  '1.0.4 (Build 5)',
                  style: AppTypography.monoCaption(color: goldAccent, medium: true),
                ),
              ],
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: goldAccent,
                  foregroundColor: isDark ? AppColors.darkBackground : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(t.t('btn_cancel')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
