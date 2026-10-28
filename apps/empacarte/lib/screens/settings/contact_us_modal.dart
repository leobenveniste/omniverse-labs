import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class ContactUsModal extends StatelessWidget {
  static const String contactEmail = 'leo.benveniste@gmail.com';

  const ContactUsModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const ContactUsModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = isDark ? AppColors.darkCard : AppColors.parchmentCard;
    final goldAccent = isDark ? AppColors.goldFoil : AppColors.burgundyBase;
    final textPrimary = isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary;
    final textSecondary = isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.parchmentBorder;

    final isSpanish = t.locale.languageCode == 'es';

    final title = isSpanish ? 'Contacto y Sugerencias' : 'Contact Us & Suggestions';
    final subtitle = isSpanish
        ? '¿Tenés ideas, encontraste un error o querés sugerir mejoras para tus viajes? ¡Escribinos directamente!'
        : 'Got ideas, spotted a bug, or have suggestions for your travel trips? Write to us directly!';
    final copyToast = isSpanish ? 'Correo copiado al portapapeles' : 'Email copied to clipboard';
    final copyBtnLabel = isSpanish ? 'Copiar Correo' : 'Copy Email Address';
    final footerMsg = isSpanish
        ? 'Respondemos cada mensaje para mejorar la experiencia de viaje.'
        : 'We answer every message to make your packing & travel experience better.';

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: goldAccent.withValues(alpha: 0.5), width: 2)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: goldAccent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mail_outline_rounded,
                  color: goldAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.subheadSerif(color: goldAccent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Subtitle
          Text(
            subtitle,
            style: AppTypography.body(color: textSecondary),
          ),
          const SizedBox(height: 20),

          // Email box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBackground : AppColors.parchmentBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Icon(Icons.alternate_email_rounded, size: 20, color: goldAccent),
                const SizedBox(width: 12),
                Expanded(
                  child: SelectableText(
                    contactEmail,
                    style: AppTypography.monoCaption(color: textPrimary).copyWith(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Copy button
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: contactEmail));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(copyToast),
                    ],
                  ),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: Text(copyBtnLabel),
            style: ElevatedButton.styleFrom(
              backgroundColor: goldAccent,
              foregroundColor: isDark ? AppColors.darkBackground : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Footer note
          Text(
            footerMsg,
            textAlign: TextAlign.center,
            style: AppTypography.caption(color: textSecondary),
          ),
        ],
      ),
    );
  }
}
