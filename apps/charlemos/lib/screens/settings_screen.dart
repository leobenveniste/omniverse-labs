import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_theme_preset.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/haptics_helper.dart';
import '../core/widgets/about_dialog_widget.dart';
import '../core/widgets/app_header_title.dart';
import '../core/widgets/contact_us_modal.dart';
import '../core/widgets/paywall_sheet.dart';
import '../l10n/app_localizations.dart';
import '../services/app_services.dart';
import '../services/card_service.dart';
import '../services/preferences_service.dart';
import '../services/premium_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  String _getFlag(String code) {
    switch (code) {
      case 'es':
        return '🇪🇸';
      case 'en':
        return '🇺🇸';
      case 'pt':
        return '🇧🇷';
      case 'fr':
        return '🇫🇷';
      case 'it':
        return '🇮🇹';
      default:
        return '🌐';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final services = AppServices.of(context);
    final prefs = services.preferencesService;
    final premiumService = services.premiumService;
    final cardService = services.cardService;

    return AnimatedBuilder(
      animation: Listenable.merge([prefs, premiumService]),
      builder: (context, _) {
        final isPro = premiumService.isPro;

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: AppHeaderTitle(
              title: l10n.t('settingsTitle'),
              isPro: isPro,
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // Pro Banner
              _buildProCard(context, l10n, premiumService),

              // Aesthetic Presets Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionHeader(context, l10n.t('aestheticPresetTitle').toUpperCase()),
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Text(
                      l10n.t('presetCountText'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFC85A3B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxs),

              _buildPresetBentoCard(
                context,
                title: l10n.t('presetCoralMistTitle'),
                subtitle: l10n.t('presetCoralMistSub'),
                icon: Icons.wb_twilight_rounded,
                preset: AppThemePreset.coralMist,
                isLocked: false,
                prefs: prefs,
                isPro: isPro,
              ),
              const SizedBox(height: AppSpacing.sm),

              _buildPresetBentoCard(
                context,
                title: l10n.t('presetPlumOrchidTitle'),
                subtitle: l10n.t('presetPlumOrchidSub'),
                icon: Icons.auto_awesome_rounded,
                preset: AppThemePreset.plumOrchid,
                isLocked: !isPro,
                prefs: prefs,
                isPro: isPro,
              ),
              const SizedBox(height: AppSpacing.sm),

              _buildPresetBentoCard(
                context,
                title: l10n.t('presetSunsetSlateTitle'),
                subtitle: l10n.t('presetSunsetSlateSub'),
                icon: Icons.spa_rounded,
                preset: AppThemePreset.sunsetSlate,
                isLocked: !isPro,
                prefs: prefs,
                isPro: isPro,
              ),
              const SizedBox(height: AppSpacing.md),

              // Theme Mode
              _buildSectionHeader(context, l10n.t('themeModeTitle')),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Row(
                    children: [
                      _buildThemeChip(context, prefs, ThemeMode.system, l10n.t('themeSystem'), Icons.brightness_auto_rounded),
                      const SizedBox(width: AppSpacing.xs),
                      _buildThemeChip(context, prefs, ThemeMode.light, l10n.t('themeLight'), Icons.light_mode_rounded),
                      const SizedBox(width: AppSpacing.xs),
                      _buildThemeChip(context, prefs, ThemeMode.dark, l10n.t('themeDark'), Icons.dark_mode_rounded),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Language Selector (5 Languages + Auto System Default)
              _buildSectionHeader(context, l10n.t('languageTitle')),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    children: [
                      // System Automatic Option
                      ListTile(
                        leading: const Text(
                          '🌐',
                          style: TextStyle(fontSize: 20),
                        ),
                        title: Text(
                          l10n.t('languageSystem'),
                          style: AppTypography.body(theme.colorScheme.onSurface, isMedium: prefs.isAutoLanguage),
                        ),
                        subtitle: Text(
                          l10n.t('languageAuto'),
                          style: AppTypography.caption(theme.colorScheme.onSurfaceVariant),
                        ),
                        trailing: prefs.isAutoLanguage
                            ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
                            : null,
                        onTap: () {
                          HapticsHelper.selection();
                          prefs.setLanguage(null);
                        },
                      ),
                      const Divider(height: 1),
                      ...AppLocalizations.supportedLocales.map((loc) {
                        final code = loc.languageCode;
                        final isSelected = !prefs.isAutoLanguage && prefs.languageCode == code;
                        final name = AppLocalizations.getLanguageName(code);

                        return ListTile(
                          leading: Text(
                            _getFlag(code),
                            style: const TextStyle(fontSize: 20),
                          ),
                          title: Text(name, style: AppTypography.body(theme.colorScheme.onSurface, isMedium: isSelected)),
                          trailing: isSelected
                              ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
                              : null,
                          onTap: () {
                            HapticsHelper.selection();
                            prefs.setLanguage(code);
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Deck Management / Reset History & Data
              _buildSectionHeader(context, l10n.t('deckManagement')),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.refresh_rounded, color: theme.colorScheme.primary),
                      ),
                      title: Text(
                        l10n.t('resetHistoryTitle'),
                        style: AppTypography.body(theme.colorScheme.onSurface, isMedium: true),
                      ),
                      subtitle: Text(
                        l10n.t('resetHistorySubtitle'),
                        style: AppTypography.caption(theme.colorScheme.onSurfaceVariant),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () async {
                        HapticsHelper.selection();
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(l10n.t('resetDeck')),
                            content: Text(l10n.t('resetDeckConfirm')),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text(l10n.t('cancel')),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text(l10n.t('resetDeck')),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true && context.mounted) {
                          cardService.resetHistory();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.t('resetDeckDone'))),
                          );
                        }
                      },
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.delete_forever_rounded, color: theme.colorScheme.error),
                      ),
                      title: Text(
                        l10n.t('clearAllDataTitle'),
                        style: AppTypography.body(theme.colorScheme.error, isMedium: true),
                      ),
                      subtitle: Text(
                        l10n.t('clearAllDataSubtitle'),
                        style: AppTypography.caption(theme.colorScheme.onSurfaceVariant),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _handleClearAllData(context, l10n, cardService),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Contact and Feedback
              _buildSectionHeader(context, l10n.t('contactSection')),
              Card(
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.mail_outline_rounded, color: theme.colorScheme.primary),
                  ),
                  title: Text(
                    l10n.t('contactSection'),
                    style: AppTypography.body(theme.colorScheme.onSurface, isMedium: true),
                  ),
                  subtitle: Text(
                    l10n.t('contactSubtitle'),
                    style: AppTypography.caption(theme.colorScheme.onSurfaceVariant),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    HapticsHelper.selection();
                    ContactUsModal.show(context);
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Privacy Policy
              _buildSectionHeader(context, l10n.t('privacyPolicyTitle')),
              Card(
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.privacy_tip_outlined, color: theme.colorScheme.primary),
                  ),
                  title: Text(
                    l10n.t('privacyPolicyTitle'),
                    style: AppTypography.body(theme.colorScheme.onSurface, isMedium: true),
                  ),
                  subtitle: Text(
                    l10n.t('privacyPolicySubtitle'),
                    style: AppTypography.caption(theme.colorScheme.onSurfaceVariant),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showPrivacyPolicyDialog(context, l10n),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // About Omniverse Labs
              _buildSectionHeader(context, l10n.t('aboutSection')),
              Card(
                child: ListTile(
                  leading: Image.asset(
                    theme.brightness == Brightness.dark
                        ? 'assets/images/omniverse_labs_white.png'
                        : 'assets/images/omniverse_labs_color.png',
                    width: 28,
                    height: 28,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.all_inclusive_rounded),
                  ),
                  title: Text(l10n.t('aboutTitle'), style: AppTypography.body(theme.colorScheme.onSurface, isMedium: true)),
                  subtitle: Text(l10n.t('appVersion'), style: AppTypography.caption(theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    HapticsHelper.selection();
                    AboutDialogWidget.show(context);
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Developer Testing Toggle (hidden in production unless developer mode is unlocked)
              if (kDebugMode || prefs.isDevMode) ...[
                _buildSectionHeader(context, l10n.t('testingSection')),
                Card(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isPro
                          ? Colors.amber.shade600.withValues(alpha: 0.5)
                          : theme.colorScheme.outline.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: SwitchListTile.adaptive(
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isPro
                            ? Colors.amber.withValues(alpha: 0.2)
                            : theme.colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.science_rounded,
                        color: isPro ? Colors.amber.shade800 : theme.colorScheme.primary,
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
                            color: isPro ? Colors.amber.shade700 : theme.colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isPro ? 'PRO' : 'FREE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: isPro ? Colors.white : theme.colorScheme.onSurfaceVariant,
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
                    activeTrackColor: Colors.amber.shade600,
                    activeThumbColor: Colors.amber.shade900,
                    onChanged: (bool value) async {
                      HapticsHelper.medium();
                      await premiumService.setProUser(value);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              value ? l10n.t('testProActivated') : l10n.t('testProDeactivated'),
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.xs),
      child: Text(
        title,
        style: AppTypography.caption(theme.colorScheme.primary, isMedium: true),
      ),
    );
  }

  Widget _buildProCard(BuildContext context, AppLocalizations l10n, PremiumService premium) {
    final isPro = premium.isPro;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isPro) {
      return Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E281F) : const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isDark ? const Color(0xFF4CAF50).withValues(alpha: 0.5) : const Color(0xFF2E7D32),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.stars_rounded,
                color: Color(0xFF2E7D32),
                size: 26,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.t('proActiveBannerTitle'),
                    style: AppTypography.body(
                      isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32),
                      isMedium: true,
                    ),
                  ),
                  Text(
                    l10n.t('proActiveBannerDesc'),
                    style: AppTypography.caption(
                      isDark ? const Color(0xFFA5D6A7) : const Color(0xFF388E3C),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: const BorderSide(color: Color(0xFFC85A3B), width: 1.5),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFC85A3B).withValues(alpha: 0.12),
              const Color(0xFFE5BA5A).withValues(alpha: 0.15),
            ],
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: const BoxDecoration(
                    color: Color(0xFFC85A3B),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.t('proTitle'),
                        style: AppTypography.body(theme.colorScheme.onSurface, isMedium: true)
                            .copyWith(fontSize: 17),
                      ),
                      Text(
                        l10n.t('proTagline'),
                        style: AppTypography.caption(theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () {
                  HapticsHelper.medium();
                  PaywallSheet.show(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC85A3B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                child: Text(
                  l10n.t('unlockProBtn', args: {'price': premium.proProduct?.price ?? '\$3.49'}),
                  style: AppTypography.body(Colors.white, isMedium: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeChip(BuildContext context, PreferencesService prefs, ThemeMode mode, String label, IconData icon) {
    final theme = Theme.of(context);
    final isSelected = prefs.themeMode == mode;

    return Expanded(
      child: ChoiceChip(
        avatar: Icon(
          icon,
          size: 16,
          color: isSelected ? Colors.white : theme.colorScheme.onSurface,
        ),
        label: Text(label),
        selected: isSelected,
        selectedColor: theme.colorScheme.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : theme.colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 12,
        ),
        showCheckmark: false,
        onSelected: (val) {
          if (val) {
            HapticsHelper.selection();
            prefs.setThemeMode(mode);
          }
        },
      ),
    );
  }

  Widget _buildPresetBentoCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required AppThemePreset preset,
    required bool isLocked,
    required PreferencesService prefs,
    required bool isPro,
  }) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isSelected = prefs.themePreset == preset;

    return Card(
      elevation: isSelected ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : (isLocked ? const Color(0xFFE5BA5A).withValues(alpha: 0.3) : theme.colorScheme.outline.withValues(alpha: 0.2)),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.15)
                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        title: Row(
          children: [
            Text(
              title,
              style: AppTypography.body(theme.colorScheme.onSurface, isMedium: true),
            ),
            if (isLocked) ...[
              const SizedBox(width: 6),
              const Icon(Icons.lock_rounded, size: 14, color: Color(0xFFE5BA5A)),
            ],
          ],
        ),
        subtitle: Text(
          subtitle,
          style: AppTypography.caption(theme.colorScheme.onSurfaceVariant),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
            : null,
        onTap: () {
          HapticsHelper.selection();
          if (isLocked) {
            PaywallSheet.show(
              context,
              customReason: l10n.t('proThemesLockReason'),
            );
            return;
          }
          prefs.setThemePreset(preset);
        },
      ),
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context, AppLocalizations l10n) {
    HapticsHelper.selection();
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.privacy_tip_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: AppSpacing.sm),
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
            style: AppTypography.body(theme.colorScheme.onSurface),
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

  Future<void> _handleClearAllData(
    BuildContext context,
    AppLocalizations l10n,
    CardService cardService,
  ) async {
    HapticsHelper.warning();
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
            const SizedBox(width: AppSpacing.sm),
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
          style: AppTypography.body(theme.colorScheme.onSurface),
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
      await cardService.clearAllData();
      HapticsHelper.success();
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

