import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../services/habit_service.dart';
import '../services/preferences_service.dart';
import '../services/storage_service.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme_preset.dart';
import '../theme/app_typography.dart';
import '../utils/haptics_helper.dart';
import '../widgets/about_dialog_widget.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.t('settingsTitle'),
          style: AppTypography.display(theme.colorScheme.onSurface),
        ),
      ),
      body: AnimatedBuilder(
        animation: prefs,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
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
                subtitle: 'Tonos orgánicos y lino cálido para máxima serenidad.',
                icon: Icons.spa_rounded,
                preset: AppThemePreset.calmSage,
                bgLight: const Color(0xFF234E35),
                textColor: Colors.white,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildPresetBentoCard(
                context,
                title: 'Neo-Kinetic',
                subtitle: 'Contrastes energéticos con acentos terracotta vivos.',
                icon: Icons.bolt_rounded,
                preset: AppThemePreset.neoKinetic,
                bgLight: const Color(0xFFFAF0EB),
                textColor: const Color(0xFF2E1500),
                accentColor: const Color(0xFFE07A5F),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildPresetBentoCard(
                context,
                title: 'Midnight Bento',
                subtitle: 'Profundidad nocturna para sesiones de reflexión tardías.',
                icon: Icons.dark_mode_rounded,
                preset: AppThemePreset.midnightBento,
                bgLight: const Color(0xFF232523),
                textColor: Colors.white,
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

              // Language Selector (5 Languages!)
              _buildSectionHeader(context, l10n.t('languageTitle')),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    children: AppLocalizations.supportedLocales.map((loc) {
                      final code = loc.languageCode;
                      final isSelected = prefs.languageCode == code;
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
                    }).toList(),
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
                      onTap: () => _handleExport(context, l10n),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.upload_rounded),
                      title: Text(l10n.t('importData'), style: AppTypography.body(theme.colorScheme.onSurface)),
                      onTap: () => _handleImport(context, l10n),
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

  Widget _buildPresetBentoCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required AppThemePreset preset,
    required Color bgLight,
    required Color textColor,
    Color? accentColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = prefs.themePreset == preset;

    final cardBg = isDark
        ? (isSelected ? const Color(0xFF242C26) : const Color(0xFF191D1A))
        : bgLight;

    return GestureDetector(
      onTap: () {
        HapticsHelper.selection();
        prefs.setThemePreset(preset);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected
                ? (isDark ? theme.colorScheme.primary : const Color(0xFF2E7D32))
                : theme.colorScheme.outline.withValues(alpha: isDark ? 0.3 : 0.15),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
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
                color: (accentColor ?? theme.colorScheme.primary).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(
                icon,
                color: accentColor ?? (isDark ? theme.colorScheme.primary : textColor),
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.title(textColor).copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: AppTypography.caption(
                      textColor.withValues(alpha: 0.8),
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
                  color: accentColor ?? theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
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
