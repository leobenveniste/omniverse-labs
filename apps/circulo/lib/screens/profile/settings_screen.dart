// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_service.dart';
import '../../services/settings_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../l10n/app_localizations.dart';
import '../auth/login_screen.dart';
import '../auth/welcome_guide_screen.dart';
import '../admin/admin_dashboard_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthService>();
    final settings = context.watch<SettingsService>();
    final biometric = context.read<BiometricService>();
    final user = auth.currentUser;

    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);
    final primary = AppTheme.primaryColor(context);

    return AppScaffold(
      showHelpButton: false,
      title: l10n.get('settingsTitle'),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // SECCIÓN TEMA
          _buildSectionHeader(l10n.get('themeSectionTitle'), textPrimary),
          Card(
            child: Column(
              children: [
                RadioListTile<String>(
                  title: Text(l10n.get('themeAuto')),
                  subtitle: Text(l10n.get('themeAutoSubtitle')),
                  value: 'system',
                  groupValue: settings.themeModeName,
                  activeColor: primary,
                  onChanged: (val) {
                    if (val != null) settings.setThemeModePreference(val);
                  },
                ),
                RadioListTile<String>(
                  title: Text(l10n.get('themeLight')),
                  value: 'light',
                  groupValue: settings.themeModeName,
                  activeColor: primary,
                  onChanged: (val) {
                    if (val != null) settings.setThemeModePreference(val);
                  },
                ),
                RadioListTile<String>(
                  title: Text(l10n.get('themeDark')),
                  value: 'dark',
                  groupValue: settings.themeModeName,
                  activeColor: primary,
                  onChanged: (val) {
                    if (val != null) settings.setThemeModePreference(val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // SECCIÓN IDIOMA (i18n)
          _buildSectionHeader(l10n.get('languageSectionTitle'), textPrimary),
          Card(
            child: Column(
              children: [
                _buildLanguageTile(
                    context, settings, 'auto', l10n.get('langAuto'), '🌐'),
                _buildLanguageTile(
                    context, settings, 'es', 'Español', '🇪🇸'),
                _buildLanguageTile(
                    context, settings, 'en', 'English', '🇺🇸'),
                _buildLanguageTile(
                    context, settings, 'pt', 'Português', '🇧🇷'),
                _buildLanguageTile(
                    context, settings, 'fr', 'Français', '🇫🇷'),
                _buildLanguageTile(
                    context, settings, 'it', 'Italiano', '🇮🇹'),
                _buildLanguageTile(
                    context, settings, 'de', 'Deutsch', '🇩🇪'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // SECCIÓN SEGURIDAD Y PRIVACIDAD
          _buildSectionHeader(l10n.get('securityTitle'), textPrimary),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.fingerprint_rounded),
                  title: Text(l10n.get('biometricAuthToggle')),
                  value: settings.biometricEnabled,
                  activeThumbColor: primary,
                  onChanged: (val) async {
                    if (val) {
                      final ok = await biometric.authenticate(
                        localizedReason: 'Validar huella para activar acceso rápido',
                      );
                      if (ok) settings.setBiometricEnabled(true);
                    } else {
                      settings.setBiometricEnabled(false);
                    }
                  },
                ),
                const Divider(height: 1),
                if (user != null)
                  SwitchListTile(
                    secondary: const Icon(Icons.pause_circle_outline_rounded),
                    title: Text(l10n.get('discoveryPauseToggle')),
                    subtitle: Text(
                      l10n.get('discoveryPauseHint'),
                      style: TextStyle(fontSize: 11, color: textSecondary),
                    ),
                    value: user.isDiscoveryPaused,
                    activeThumbColor: primary,
                    onChanged: (val) {
                      auth.updateProfile(user.copyWith(isDiscoveryPaused: val));
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // GUÍA Y PANEL ADMIN
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.help_outline_rounded),
                  title: Text(l10n.get('howItWorksBtn')),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (_) => const WelcomeGuideScreen(isModal: true),
                      ),
                    );
                  },
                ),
                if (user?.isSuperAdmin == true) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings_outlined,
                        color: AppTheme.vibrantCoral),
                    title: Text(
                      l10n.get('adminPanelBtn'),
                      style: const TextStyle(
                        color: AppTheme.vibrantCoral,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AdminDashboardScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // SECCIÓN LEGAL Y PRIVACIDAD (Google Play Compliance)
          _buildSectionHeader(l10n.get('legalPrivacySectionTitle'), textPrimary),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined, color: AppTheme.electricViolet),
                  title: Text(l10n.get('privacyPolicyTitle')),
                  subtitle: Text(
                    l10n.get('privacyPolicySubtitle'),
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                  onTap: () => _openUrl('https://leobenveniste.github.io/omniverse-labs/circulo-privacy.html'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_sweep_outlined, color: AppTheme.vibrantCoral),
                  title: Text(l10n.get('deleteAccountWebTitle')),
                  subtitle: Text(
                    l10n.get('deleteAccountWebSubtitle'),
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                  onTap: () => _openUrl('https://leobenveniste.github.io/omniverse-labs/circulo-delete-account.html'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // CERRAR SESIÓN
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: textPrimary,
              side: BorderSide(color: textSecondary.withOpacity(0.3)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: Text(l10n.get('logoutBtn')),
            onPressed: () async {
              HapticFeedback.mediumImpact();
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(height: 16),

          // ELIMINAR CUENTA (In-App Deletion - Google Play Requirement)
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorRed,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.delete_forever_rounded, size: 20),
            label: Text(
              l10n.get('deleteAccountInAppBtn'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            onPressed: () => _showDeleteAccountDialog(context, auth, l10n),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showDeleteAccountDialog(
    BuildContext context,
    AuthService auth,
    AppLocalizations l10n,
  ) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(
          l10n.get('deleteAccountDialogTitle'),
          style: const TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.w800),
        ),
        content: Text(l10n.get('deleteAccountDialogMsg')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(l10n.get('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              HapticFeedback.heavyImpact();
              final ok = await auth.deleteMyAccount();
              if (ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppTheme.darkSurface,
                    content: Text(l10n.get('deleteAccountSuccessNotice')),
                  ),
                );
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: Text(l10n.get('deleteAccountConfirmBtn')),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textPrimary) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),
    );
  }

  Widget _buildLanguageTile(
    BuildContext context,
    SettingsService settings,
    String code,
    String name,
    String flag,
  ) {
    final primary = AppTheme.primaryColor(context);

    return RadioListTile<String>(
      title: Row(
        children: [
          Text(flag, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Text(name),
        ],
      ),
      value: code,
      groupValue: settings.localeCode,
      activeColor: primary,
      onChanged: (val) {
        if (val != null) settings.setLocaleCode(val);
      },
    );
  }
}
