import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../services/premium_service.dart';
import '../theme/app_theme.dart';
import '../widgets/about_dialog_widget.dart';
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
    final appState = CentralDeJuegosApp.of(context);
    final currentThemeMode = appState.themeMode;
    final currentLang = l10n.locale.languageCode;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.t('settingsTitle'),
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            color: isDark ? AppTheme.cyberGold : const Color(0xFF1A202C),
          ),
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
                  leading: const Text('🇪🇸', style: TextStyle(fontSize: 22)),
                  title: Text(l10n.t('languageEs'), style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: currentLang == 'es'
                      ? const Icon(Icons.check_circle_rounded, color: AppTheme.cyberGold)
                      : null,
                  onTap: () => appState.setLocale(const Locale('es')),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Text('🇺🇸', style: TextStyle(fontSize: 22)),
                  title: Text(l10n.t('languageEn'), style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: currentLang == 'en'
                      ? const Icon(Icons.check_circle_rounded, color: AppTheme.cyberGold)
                      : null,
                  onTap: () => appState.setLocale(const Locale('en')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // About Section
          _buildSectionHeader(context, l10n.t('aboutSection').toUpperCase()),
          Card(
            child: ListTile(
              leading: Image.asset(
                isDark ? 'assets/images/omniverse_labs_white.png' : 'assets/images/omniverse_labs_color.png',
                width: 32,
                height: 32,
                errorBuilder: (_, __, ___) => const Icon(Icons.all_inclusive_rounded),
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
            const SizedBox(height: 24),
            AnimatedBuilder(
              animation: premiumService!,
              builder: (context, _) {
                final isPro = premiumService!.isPro;
                return Center(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: isPro ? Colors.orangeAccent : Colors.tealAccent,
                    ),
                    icon: Icon(isPro ? Icons.lock_open_rounded : Icons.science_outlined, size: 16),
                    label: Text(
                      isPro ? l10n.t('testProDisable') : l10n.t('testProEnable'),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      await premiumService!.setProForTesting(!isPro);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              !isPro ? l10n.t('proActivatedToast') : l10n.t('proDeactivatedToast'),
                            ),
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
