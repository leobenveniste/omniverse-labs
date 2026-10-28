// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/guide/guide_controller.dart';
import '../../core/widgets/app_header_title.dart';
import '../../core/widgets/tactile_pressable.dart';
import '../../repositories/storage_repository.dart';
import '../pro/pro_paywall_modal.dart';
import 'about_dialog_widget.dart';
import 'contact_us_modal.dart';

class SettingsScreen extends StatelessWidget {
  final ThemeController themeController;
  final LocaleController localeController;
  final GuideController guideController;
  final StorageRepository? storage;

  const SettingsScreen({
    super.key,
    required this.themeController,
    required this.localeController,
    required this.guideController,
    this.storage,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: storage ?? ValueNotifier(false),
      builder: (context, _) {
        final t = AppLocalizations.of(context);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final isSpanish = t.locale.languageCode == 'es';
        final isPro = storage?.isPro ?? false;

        final cardBg = isDark ? AppColors.darkCard : AppColors.parchmentCard;
        final borderColor = isDark ? AppColors.darkBorder : AppColors.parchmentBorder;
        final textPrimary = isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary;
        final textSecondary = isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary;
        final goldAccent = isDark ? AppColors.goldFoil : AppColors.burgundyBase;

        return Scaffold(
          appBar: AppBar(
            title: AppHeaderTitle(
              title: t.t('settings_title'),
              isPro: isPro,
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
          // --- EMPACARTE PRO STATUS BANNER ---
          TactilePressable(
            onTap: () {
              if (storage != null) {
                ProPaywallModal.show(context, storage!);
              }
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isPro
                      ? [
                          AppColors.goldFoil.withValues(alpha: 0.25),
                          (isDark ? AppColors.goldFoilDark : AppColors.burgundyBase).withValues(alpha: 0.15),
                        ]
                      : [
                          (isDark ? AppColors.goldFoilDark : AppColors.burgundyBase).withValues(alpha: 0.2),
                          cardBg,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isPro ? AppColors.goldFoil : goldAccent.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? AppColors.goldFoil : AppColors.burgundyBase).withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [goldAccent, AppColors.goldFoilLight],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        isPro ? '👑' : '⭐',
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPro ? 'EMPACARTE PRO' : (isSpanish ? 'Desbloquear Modo PRO' : 'Unlock PRO Mode'),
                          style: AppTypography.subheadSerif(color: isDark ? AppColors.goldFoil : AppColors.burgundyBase),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isPro
                              ? (isSpanish ? 'Acceso de por vida activado' : 'Lifetime access unlocked')
                              : (isSpanish ? 'Viajes ilimitados, 3 bultos y balanza' : 'Unlimited trips, 3-bag split & scales'),
                          style: AppTypography.caption(color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isPro ? Icons.check_circle_rounded : Icons.arrow_forward_ios_rounded,
                    size: 18,
                    color: isPro ? AppColors.stampEmeraldLight : goldAccent,
                  ),
                ],
              ),
            ),
          ),

          // --- APPEARANCE & THEME ---
          Text(
            t.t('settings_appearance'),
            style: AppTypography.subheadSerif(color: goldAccent),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: Column(
              children: [
                _ThemeRadioTile(
                  title: t.t('settings_theme_system'),
                  icon: Icons.brightness_auto_rounded,
                  value: ThemeMode.system,
                  groupValue: themeController.themeMode,
                  onChanged: (mode) => themeController.setThemeMode(mode!),
                  isDark: isDark,
                ),
                Divider(height: 1, color: borderColor),
                _ThemeRadioTile(
                  title: t.t('settings_theme_light'),
                  icon: Icons.light_mode_rounded,
                  value: ThemeMode.light,
                  groupValue: themeController.themeMode,
                  onChanged: (mode) => themeController.setThemeMode(mode!),
                  isDark: isDark,
                ),
                Divider(height: 1, color: borderColor),
                _ThemeRadioTile(
                  title: t.t('settings_theme_dark'),
                  icon: Icons.dark_mode_rounded,
                  value: ThemeMode.dark,
                  groupValue: themeController.themeMode,
                  onChanged: (mode) => themeController.setThemeMode(mode!),
                  isDark: isDark,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // --- LANGUAGE & LOCALIZATION ---
          Text(
            t.t('settings_language'),
            style: AppTypography.subheadSerif(color: goldAccent),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: Column(
              children: [
                // Auto-detect option
                RadioListTile<bool>(
                  value: true,
                  groupValue: localeController.isAutoDetect,
                  title: Text(t.t('settings_lang_system'), style: AppTypography.body(color: textPrimary)),
                  secondary: const Icon(Icons.language_rounded),
                  activeColor: goldAccent,
                  onChanged: (_) => localeController.setAutoDetect(),
                ),
                Divider(height: 1, color: borderColor),

                // 6 Language options
                ...AppLanguage.values.map((lang) {
                  return RadioListTile<String>(
                    value: lang.code,
                    groupValue: localeController.isAutoDetect ? null : localeController.currentLocale.languageCode,
                    title: Row(
                      children: [
                        Text(lang.flag, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Text(lang.displayName, style: AppTypography.body(color: textPrimary)),
                      ],
                    ),
                    activeColor: goldAccent,
                    onChanged: (code) {
                      if (code != null) localeController.setLocale(code);
                    },
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // --- CONTACT & FEEDBACK ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.mail_outline_rounded, color: goldAccent, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      isDark || t.locale.languageCode != 'es' ? 'Contact & Feedback' : 'Contacto y Sugerencias',
                      style: AppTypography.subheadSerif(color: goldAccent),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  t.locale.languageCode == 'es'
                      ? '¿Tenés sugerencias, ideas o encontraste algún error? Hablá directo con el creador.'
                      : 'Have suggestions, ideas, or spotted a bug? Chat directly with the developer.',
                  style: AppTypography.body(color: textSecondary),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => ContactUsModal.show(context),
                        icon: const Icon(Icons.send_rounded, size: 16),
                        label: Text(t.locale.languageCode == 'es' ? 'Escribir a Leo' : 'Contact Leo'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: goldAccent,
                          side: BorderSide(color: goldAccent.withValues(alpha: 0.6)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.outlined(
                      tooltip: t.locale.languageCode == 'es' ? 'Rever guías de uso' : 'Replay usage guides',
                      icon: const Icon(Icons.help_outline_rounded, size: 18),
                      style: IconButton.styleFrom(
                        foregroundColor: goldAccent,
                        side: BorderSide(color: goldAccent.withValues(alpha: 0.6)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        await guideController.resetAllGuides();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                t.locale.languageCode == 'es'
                                    ? 'Las guías de uso se mostrarán nuevamente en cada pantalla.'
                                    : 'Usage guides will be displayed again on each screen.',
                              ),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // --- ABOUT SECTION ---
          TactilePressable(
            onTap: () => AboutDialogWidget.show(context),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1.2),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: goldAccent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.info_outline_rounded, color: goldAccent, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.t('settings_about'),
                          style: AppTypography.subheadSerif(color: goldAccent),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${t.t('settings_version')} 1.0.4 (Build 5) • Omniverse Labs',
                          style: AppTypography.caption(color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: goldAccent, size: 22),
                ],
              ),
            ),
          ),

          // --- DEVELOPER TESTING TOGGLE ---
          if (storage != null) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.science_rounded, color: goldAccent, size: 20),
                const SizedBox(width: 8),
                Text(
                  isSpanish ? 'MODO DE PRUEBAS / TESTING' : 'TESTING & DEVELOPER',
                  style: AppTypography.subheadSerif(color: goldAccent),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isPro
                      ? AppColors.goldFoil.withValues(alpha: 0.6)
                      : borderColor,
                  width: 1.2,
                ),
              ),
              child: SwitchListTile.adaptive(
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isPro
                        ? AppColors.goldFoil.withValues(alpha: 0.15)
                        : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.science_rounded,
                    color: isPro ? AppColors.goldFoil : textSecondary,
                    size: 22,
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.t('settings_test_pro_title'),
                        style: AppTypography.body(color: textPrimary).copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isPro ? AppColors.stampEmeraldLight : (isDark ? Colors.white24 : Colors.black26),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isPro ? 'PRO' : 'FREE',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    t.t('settings_test_pro_subtitle'),
                    style: AppTypography.caption(color: textSecondary),
                  ),
                ),
                value: isPro,
                activeTrackColor: AppColors.goldFoil,
                activeThumbColor: AppColors.burgundyBase,
                onChanged: (bool value) async {
                  HapticFeedback.mediumImpact();
                  await storage!.setPro(value);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value ? t.t('settings_test_pro_active') : t.t('settings_test_pro_inactive'),
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
      },
    );
  }
}

class _ThemeRadioTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final ThemeMode value;
  final ThemeMode groupValue;
  final ValueChanged<ThemeMode?> onChanged;
  final bool isDark;

  const _ThemeRadioTile({
    required this.title,
    required this.icon,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final goldAccent = isDark ? AppColors.goldFoil : AppColors.burgundyBase;
    final textPrimary = isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary;

    return RadioListTile<ThemeMode>(
      value: value,
      groupValue: groupValue,
      title: Text(title, style: AppTypography.body(color: textPrimary)),
      secondary: Icon(icon, color: goldAccent, size: 20),
      activeColor: goldAccent,
      onChanged: onChanged,
    );
  }
}
