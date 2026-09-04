import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../services/app_services.dart';
import '../services/habit_service.dart';
import '../services/preferences_service.dart';
import '../services/premium_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme_preset.dart';
import '../theme/app_typography.dart';
import '../utils/haptics_helper.dart';
import '../widgets/about_dialog_widget.dart';
import '../widgets/paywall_sheet.dart';

class SettingsScreen extends StatelessWidget {
  final PreferencesService prefs;
  final StorageService storage;
  final HabitService habitService;

  const SettingsScreen({
    super.key,
    required this.prefs,
    required this.storage,
    required this.habitService,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final premiumService = AppServices.of(context).premiumService;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.t('settingsTitle'),
          style: AppTypography.display(theme.colorScheme.onSurface),
        ),
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([prefs, premiumService]),
        builder: (context, _) {
          final isPro = premiumService.isPro;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // Ritmo Pro Hero Banner
              _buildProCard(context, l10n, premiumService),

              // Aesthetic Presets Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionHeader(context, l10n.t('aestheticPresetTitle').toUpperCase()),
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Text(
                      '3 temas disponibles',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFC85A3B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxs),
              _buildPresetBentoCard(
                context,
                title: 'Calm Sage',
                subtitle: 'Forest Canopy • Lino cálido y verde bosque orgánico.',
                icon: Icons.spa_rounded,
                preset: AppThemePreset.calmSage,
                isLocked: false,
                l10n: l10n,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildPresetBentoCard(
                context,
                title: 'Desert Rose',
                subtitle: 'Sunset Boulevard • Terracotta enriquecida y brasas de arcilla.',
                icon: Icons.wb_twilight_rounded,
                preset: AppThemePreset.neoKinetic,
                isLocked: !isPro,
                l10n: l10n,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildPresetBentoCard(
                context,
                title: 'Midnight Galaxy',
                subtitle: 'Deep Cosmic • Obsidiana estelar y bígaro celestial.',
                icon: Icons.auto_awesome_rounded,
                preset: AppThemePreset.midnightBento,
                isLocked: !isPro,
                l10n: l10n,
              ),
              const SizedBox(height: AppSpacing.md),

              // Theme Mode
              _buildSectionHeader(context, l10n.t('themeModeTitle')),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Row(
                    children: [
                      _buildThemeChip(context, ThemeMode.system, l10n.t('themeSystem'), Icons.brightness_auto_rounded),
                      const SizedBox(width: AppSpacing.xs),
                      _buildThemeChip(context, ThemeMode.light, l10n.t('themeLight'), Icons.light_mode_rounded),
                      const SizedBox(width: AppSpacing.xs),
                      _buildThemeChip(context, ThemeMode.dark, l10n.t('themeDark'), Icons.dark_mode_rounded),
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

              // Notifications
              _buildSectionHeader(context, l10n.t('notificationsTitle')),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(l10n.t('notifHabitReminders'), style: AppTypography.body(theme.colorScheme.onSurface)),
                      value: prefs.notifHabits,
                      onChanged: (v) => prefs.setNotifHabits(v),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: Text(l10n.t('notifStreakWarning'), style: AppTypography.body(theme.colorScheme.onSurface)),
                      value: prefs.notifStreak,
                      onChanged: (v) => prefs.setNotifStreak(v),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: Text(l10n.t('notifEveningReflection'), style: AppTypography.body(theme.colorScheme.onSurface)),
                      value: prefs.notifEvening,
                      onChanged: (v) => prefs.setNotifEvening(v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Backup & Data
              _buildSectionHeader(context, l10n.t('backupTitle')),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.download_rounded),
                      title: Text(l10n.t('exportData'), style: AppTypography.body(theme.colorScheme.onSurface)),
                      trailing: !isPro ? _buildProBadge() : null,
                      onTap: () {
                        if (!isPro) {
                          HapticsHelper.warning();
                          PaywallSheet.show(context, customReason: l10n.t('proLimitBackupMsg'));
                          return;
                        }
                        _handleExport(context, l10n);
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.upload_rounded),
                      title: Text(l10n.t('importData'), style: AppTypography.body(theme.colorScheme.onSurface)),
                      trailing: !isPro ? _buildProBadge() : null,
                      onTap: () {
                        if (!isPro) {
                          HapticsHelper.warning();
                          PaywallSheet.show(context, customReason: l10n.t('proLimitBackupMsg'));
                          return;
                        }
                        _handleImport(context, l10n);
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.restore_rounded),
                      title: Text(l10n.t('proRestoreBtn'), style: AppTypography.body(theme.colorScheme.onSurface)),
                      onTap: () async {
                        HapticsHelper.selection();
                        final restored = await premiumService.restorePurchases();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                restored ? l10n.t('proRestoreSuccess') : l10n.t('proRestoreNone'),
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.auto_awesome_rounded),
                      title: Text(l10n.t('loadSampleData'), style: AppTypography.body(theme.colorScheme.onSurface)),
                      onTap: () async {
                        HapticsHelper.medium();
                        await habitService.loadSampleData();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.t('sampleDataLoaded')),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // About Modal Trigger
              _buildSectionHeader(context, l10n.t('aboutSection')),
              Card(
                child: ListTile(
                  leading: Image.asset(
                    theme.brightness == Brightness.dark
                        ? 'assets/images/omniverse_labs_white.png'
                        : 'assets/images/omniverse_labs_color.png',
                    width: 28,
                    height: 28,
                    errorBuilder: (_, __, ___) => const Icon(Icons.all_inclusive_rounded),
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
              const SizedBox(height: AppSpacing.xxl),
            ],
          );
        },
      ),
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
                  Row(
                    children: [
                      Text(
                        l10n.t('proActiveTitle'),
                        style: AppTypography.title(theme.colorScheme.onSurface).copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'PRO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.t('proActiveSubtitle'),
                    style: AppTypography.caption(theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: theme.brightness == Brightness.dark
            ? const LinearGradient(
                colors: [Color(0xFF2A1C16), Color(0xFF1E1715)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFFFF6F0), Color(0xFFFDECE4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: const Color(0xFFC85A3B).withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC85A3B).withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: const Color(0xFFC85A3B).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFFC85A3B),
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                l10n.t('proTitle'),
                style: AppTypography.title(theme.colorScheme.onSurface).copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFC85A3B),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'LIFETIME',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.t('proTagline'),
            style: AppTypography.body(theme.colorScheme.onSurface.withValues(alpha: 0.8)).copyWith(
              fontSize: 13,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticsHelper.selection();
                PaywallSheet.show(context);
              },
              icon: const Icon(Icons.stars_rounded, size: 18),
              label: Text(
                '${l10n.t('proBadge')} • ${premium.proProduct?.price ?? '\$2.99 USD'}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC85A3B),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFC85A3B).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFC85A3B).withValues(alpha: 0.4)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_rounded, size: 10, color: Color(0xFFC85A3B)),
          SizedBox(width: 3),
          Text(
            'PRO',
            style: TextStyle(
              color: Color(0xFFC85A3B),
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetBentoCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required AppThemePreset preset,
    bool isLocked = false,
    required AppLocalizations l10n,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = prefs.themePreset == preset;
    final presetColors = AppColors.of(preset, isDark);

    return GestureDetector(
      onTap: () {
        if (isLocked) {
          HapticsHelper.warning();
          PaywallSheet.show(context, customReason: l10n.t('proLimitThemeMsg'));
          return;
        }
        HapticsHelper.selection();
        prefs.setThemePreset(preset);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? presetColors.surface : (isSelected ? presetColors.surfaceVariant : presetColors.surface),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected
                ? presetColors.primary
                : presetColors.outline.withValues(alpha: isDark ? 0.4 : 0.6),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: presetColors.primary.withValues(alpha: isDark ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(
                icon,
                color: presetColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: AppTypography.title(theme.colorScheme.onSurface).copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (isLocked) ...[
                        const SizedBox(width: 8),
                        _buildProBadge(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: AppTypography.caption(
                      theme.colorScheme.onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: presetColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: presetColors.onPrimary,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeChip(
    BuildContext context,
    ThemeMode mode,
    String label,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final isSelected = prefs.themeMode == mode;

    return Expanded(
      child: ChoiceChip(
        avatar: Icon(icon, size: 16, color: isSelected ? theme.colorScheme.onPrimary : null),
        label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? theme.colorScheme.onPrimary : null)),
        selected: isSelected,
        selectedColor: theme.colorScheme.primary,
        onSelected: (_) => prefs.setThemeMode(mode),
      ),
    );
  }

  String _getFlag(String code) {
    switch (code) {
      case 'es':
        return '🇪🇸';
      case 'en':
        return '🇬🇧';
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

  Future<void> _handleExport(BuildContext context, AppLocalizations l10n) async {
    final jsonStr = await storage.exportFullJson();
    await Clipboard.setData(ClipboardData(text: jsonStr));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.t('exportSuccess')} (Copiado al portapapeles)'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleImport(BuildContext context, AppLocalizations l10n) async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text == null || data!.text!.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay datos JSON en el portapapeles para restaurar.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final success = await storage.importFullJson(data.text!);
    if (success) {
      await habitService.load();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.t('importSuccess')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
