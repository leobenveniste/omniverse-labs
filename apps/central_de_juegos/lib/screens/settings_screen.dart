import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../services/premium_service.dart';
import '../theme/app_theme.dart';
import '../widgets/about_dialog_widget.dart';
import '../widgets/app_header_title.dart';
import '../widgets/contact_us_modal.dart';
import '../widgets/paywall_sheet.dart';

class SettingsScreen extends StatelessWidget {
  final PremiumService? premiumService;

  const SettingsScreen({
    super.key,
    this.premiumService,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final isSpanish = l10n.locale.languageCode == 'es';
    final appState = CentralDeJuegosApp.of(context);
    final currentThemeMode = appState.themeMode;
    final currentLang = l10n.locale.languageCode;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: AppHeaderTitle(
          title: l10n.t('settingsTitle'),
          isPro: premiumService?.isPro ?? false,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Pro Status / Upgrade Banner
          if (premiumService != null)
            AnimatedBuilder(
              animation: premiumService!,
              builder: (context, _) {
                final isPro = premiumService!.isPro;
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isPro ? AppTheme.cyberGold : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
                      width: 1.2,
                    ),
                  ),
                  color: isPro
                      ? AppTheme.cyberGold.withValues(alpha: isDark ? 0.15 : 0.08)
                      : (isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: isPro ? AppTheme.cyberGold : Colors.grey.withValues(alpha: 0.2),
                      child: Icon(
                        isPro ? Icons.workspace_premium_rounded : Icons.star_border_rounded,
                        color: isPro ? Colors.black : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                    title: Text(
                      isPro ? l10n.t('proActiveTitle') : l10n.t('proTitle'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text(
                      isPro ? l10n.t('proActiveSubtitle') : l10n.t('proTagline'),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    trailing: isPro
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.cyberGold,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'PRO',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                              ),
                            ),
                          )
                        : FilledButton(
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              backgroundColor: AppTheme.cyberGold,
                              foregroundColor: Colors.black,
                            ),
                            onPressed: () => PaywallSheet.show(
                              context,
                              premiumService: premiumService!,
                            ),
                            child: const Text(
                              'UPGRADE',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                  ),
                );
              },
            ),

          // Theme / Appearance Section
          _buildSectionHeader(context, l10n.t('appearanceSection').toUpperCase()),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.t('themeTitle'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildThemeChip(
                        context,
                        label: l10n.t('themeDark'),
                        icon: Icons.dark_mode_rounded,
                        isSelected: currentThemeMode == ThemeMode.dark,
                        onTap: () => appState.setThemeMode(ThemeMode.dark),
                      ),
                      const SizedBox(width: 8),
                      _buildThemeChip(
                        context,
                        label: l10n.t('themeLight'),
                        icon: Icons.light_mode_rounded,
                        isSelected: currentThemeMode == ThemeMode.light,
                        onTap: () => appState.setThemeMode(ThemeMode.light),
                      ),
                      const SizedBox(width: 8),
                      _buildThemeChip(
                        context,
                        label: l10n.t('themeSystem'),
                        icon: Icons.brightness_auto_rounded,
                        isSelected: currentThemeMode == ThemeMode.system,
                        onTap: () => appState.setThemeMode(ThemeMode.system),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Language Section
          _buildSectionHeader(context, l10n.t('languageSection').toUpperCase()),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Text('🌐', style: TextStyle(fontSize: 22)),
                  title: Text(l10n.t('languageAuto'), style: TextStyle(fontWeight: appState.isAutoLanguage ? FontWeight.bold : FontWeight.w600)),
                  trailing: appState.isAutoLanguage
                      ? const Icon(Icons.check_circle_rounded, color: AppTheme.cyberGold)
                      : null,
                  onTap: () => appState.setLocale(null),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Text('🇪🇸', style: TextStyle(fontSize: 22)),
                  title: Text(l10n.t('languageEs'), style: TextStyle(fontWeight: (!appState.isAutoLanguage && currentLang == 'es') ? FontWeight.bold : FontWeight.w600)),
                  trailing: (!appState.isAutoLanguage && currentLang == 'es')
                      ? const Icon(Icons.check_circle_rounded, color: AppTheme.cyberGold)
                      : null,
                  onTap: () => appState.setLocale(const Locale('es')),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Text('🇺🇸', style: TextStyle(fontSize: 22)),
                  title: Text(l10n.t('languageEn'), style: TextStyle(fontWeight: (!appState.isAutoLanguage && currentLang == 'en') ? FontWeight.bold : FontWeight.w600)),
                  trailing: (!appState.isAutoLanguage && currentLang == 'en')
                      ? const Icon(Icons.check_circle_rounded, color: AppTheme.cyberGold)
                      : null,
                  onTap: () => appState.setLocale(const Locale('en')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Contact & Suggestions
          _buildSectionHeader(context, isSpanish ? 'SOPORTE Y CONTACTO' : 'SUPPORT & CONTACT'),
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.transparent,
                child: Icon(Icons.mail_outline_rounded, color: AppTheme.cyberGold),
              ),
              title: Text(
                isSpanish ? 'Contacto y Sugerencias' : 'Contact & Suggestions',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'leo.benveniste@gmail.com',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => ContactUsModal.show(context),
            ),
          ),
          const SizedBox(height: 16),

          // About Section
          _buildSectionHeader(context, l10n.t('aboutSection').toUpperCase()),
          Card(
            child: ListTile(
              leading: Image.asset(
                isDark ? 'assets/images/omniverse_labs_white.png' : 'assets/images/omniverse_labs_color.png',
                width: 32,
                height: 32,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.all_inclusive_rounded),
              ),
              title: Text(
                l10n.t('aboutTitle'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Omniverse Labs • 1.0.4 (Build 18)',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => AboutDialogWidget.show(context),
            ),
          ),

          // Developer Testing Toggle (Always accessible in Settings screen)
          if (premiumService != null) ...[
            const SizedBox(height: 20),
            _buildSectionHeader(context, isSpanish ? 'MODO DE PRUEBAS / TESTING' : 'TESTING & DEVELOPER'),
            AnimatedBuilder(
              animation: premiumService!,
              builder: (context, _) {
                final isPro = premiumService!.isPro;
                return Card(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isPro
                          ? AppTheme.cyberGold.withValues(alpha: 0.6)
                          : theme.colorScheme.outline.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: SwitchListTile.adaptive(
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isPro
                            ? AppTheme.cyberGold.withValues(alpha: 0.2)
                            : theme.colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.science_rounded,
                        color: isPro ? AppTheme.cyberGold : theme.colorScheme.primary,
                        size: 22,
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.t('testProToggleTitle'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isPro ? AppTheme.cyberGold : theme.colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isPro ? 'PRO' : 'FREE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: isPro ? Colors.black : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        l10n.t('testProToggleSubtitle'),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    value: isPro,
                    activeTrackColor: AppTheme.cyberGold,
                    activeThumbColor: Colors.amber.shade900,
                    onChanged: (bool value) async {
                      await premiumService!.setProForTesting(value);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              value ? l10n.t('proActivatedToast') : l10n.t('proDeactivatedToast'),
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppTheme.cyberGold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildThemeChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.cyberGold.withValues(alpha: 0.2)
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.cyberGold : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? AppTheme.cyberGold : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppTheme.cyberGold : theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
