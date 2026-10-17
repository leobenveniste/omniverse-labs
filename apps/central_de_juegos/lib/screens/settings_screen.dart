import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../models/table_mat.dart';
import '../services/premium_service.dart';
import '../services/sound_haptics_service.dart';
import '../services/storage_service.dart';
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

          // Table Mat / Board Style Section
          _buildSectionHeader(context, l10n.t('tableMatSection').toUpperCase()),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.t('tableMatSection'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.t('tableMatSubtitle'),
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (appState.tableMat.isPro)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.cyberGold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.cyberGold, width: 1),
                          ),
                          child: const Text(
                            'PRO',
                            style: TextStyle(
                              color: AppTheme.cyberGold,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...TableMatStyle.values.map(
                    (mat) => _buildTableMatOption(
                      context,
                      mat: mat,
                      isSelected: appState.tableMat == mat,
                      isProUser: premiumService?.isPro ?? false,
                      l10n: l10n,
                      onSelect: () => appState.setTableMat(mat),
                      onLocked: () {
                        if (premiumService != null) {
                          PaywallSheet.show(
                            context,
                            premiumService: premiumService!,
                            customReason: l10n.t('proBenefitMatsSub'),
                          );
                        }
                      },
                    ),
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
          _buildSectionHeader(context, l10n.t('supportSection').toUpperCase()),
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.transparent,
                child: Icon(Icons.mail_outline_rounded, color: AppTheme.cyberGold),
              ),
              title: Text(
                l10n.t('supportContactTitle'),
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

          // Privacy Policy Section
          _buildSectionHeader(context, l10n.t('privacyPolicyTitle').toUpperCase()),
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.transparent,
                child: Icon(Icons.privacy_tip_outlined, color: AppTheme.cyberGold),
              ),
              title: Text(
                l10n.t('privacyPolicyTitle'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                l10n.t('privacyPolicySubtitle'),
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _showPrivacyPolicyDialog(context, l10n),
            ),
          ),
          const SizedBox(height: 16),

          // Data Management / Wipe
          _buildSectionHeader(context, l10n.t('clearAllDataTitle').toUpperCase()),
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.error.withValues(alpha: 0.15),
                child: Icon(Icons.delete_forever_rounded, color: theme.colorScheme.error),
              ),
              title: Text(
                l10n.t('clearAllDataTitle'),
                style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.error),
              ),
              subtitle: Text(
                l10n.t('clearAllDataSubtitle'),
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _handleClearAllData(context, l10n),
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
                'Omniverse Labs • 1.0.9 (Build 23)',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => AboutDialogWidget.show(context, premiumService: premiumService),
            ),
          ),

          // Developer Testing Toggle (Protected: visible only in debug mode or when developer mode is unlocked via Easter Egg)
          if (premiumService != null)
            AnimatedBuilder(
              animation: premiumService!,
              builder: (context, _) {
                if (!kDebugMode && !premiumService!.isDevMode) {
                  return const SizedBox.shrink();
                }
                final isPro = premiumService!.isPro;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildSectionHeader(context, l10n.t('supportTestingTitle').toUpperCase()),
                    Card(
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
                    ),
                  ],
                );
              },
            ),
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

  Widget _buildTableMatOption(
    BuildContext context, {
    required TableMatStyle mat,
    required bool isSelected,
    required bool isProUser,
    required AppLocalizations l10n,
    required VoidCallback onSelect,
    required VoidCallback onLocked,
  }) {
    final isLocked = mat.isPro && !isProUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: isLocked ? onLocked : onSelect,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: mat.backgroundGradient,
            border: Border.all(
              color: isSelected
                  ? mat.accentColor
                  : (isLocked
                      ? mat.borderColor.withValues(alpha: 0.5)
                      : mat.borderColor),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: mat.accentColor.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: mat.surfaceColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: mat.accentColor.withValues(alpha: 0.4), width: 1),
                ),
                child: Icon(
                  mat.icon,
                  color: mat.accentColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            l10n.t(mat.nameKey),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (mat.isPro) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isProUser
                                  ? AppTheme.cyberGold.withValues(alpha: 0.2)
                                  : Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isProUser ? AppTheme.cyberGold : Colors.white38,
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isLocked) ...[
                                  const Icon(Icons.lock_rounded, size: 10, color: Colors.amber),
                                  const SizedBox(width: 3),
                                ],
                                Text(
                                  'PRO',
                                  style: TextStyle(
                                    color: isProUser ? AppTheme.cyberGold : Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l10n.t(mat.descKey),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: mat.accentColor,
                  size: 22,
                )
              else if (isLocked)
                Icon(
                  Icons.lock_outline_rounded,
                  color: Colors.white.withValues(alpha: 0.4),
                  size: 20,
                )
              else
                Icon(
                  Icons.radio_button_unchecked_rounded,
                  color: Colors.white.withValues(alpha: 0.25),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context, AppLocalizations l10n) {
    SoundHapticsService.click();
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.privacy_tip_outlined, color: AppTheme.cyberGold),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.t('privacyDialogTitle'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            l10n.t('privacyDialogContent'),
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.t('close')),
          ),
        ],
      ),
    );
  }

  Future<void> _handleClearAllData(BuildContext context, AppLocalizations l10n) async {
    SoundHapticsService.pointSubtracted();
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.t('clearDataConfirmTitle'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          l10n.t('clearDataConfirmContent'),
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.t('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.t('clearDataAction')),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await StorageService.clearAllData();
      SoundHapticsService.pointAdded();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.t('clearDataSuccessToast')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

