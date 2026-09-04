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
              _buildSectionHeader(context, l10n.t('aestheticPresetTitle')),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    children: [
                      _buildPresetTile(
                        context,
                        title: l10n.t('presetCalmSage'),
                        subtitle: 'Lino, salvia profunda y terracota',
                        icon: Icons.spa_rounded,
                        preset: AppThemePreset.calmSage,
                      ),
                      const Divider(height: 1),
                      _buildPresetTile(
                        context,
                        title: l10n.t('presetNeoKinetic'),
                        subtitle: 'Carbono, neo-menta y ámbar solar',
                        icon: Icons.bolt_rounded,
                        preset: AppThemePreset.neoKinetic,
                      ),
                      const Divider(height: 1),
                      _buildPresetTile(
                        context,
                        title: l10n.t('presetMidnightBento'),
                        subtitle: 'Pizarra, zafiro, amatista y esmeralda',
                        icon: Icons.grid_view_rounded,
                        preset: AppThemePreset.midnightBento,
                      ),
                    ],
                  ),
                ),
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
              _buildSectionHeader(context, 'Acerca de'),
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
      padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.xs),
      child: Text(
        title,
        style: AppTypography.caption(theme.colorScheme.primary, isMedium: true),
      ),
    );
  }

  Widget _buildPresetTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required AppThemePreset preset,
  }) {
    final theme = Theme.of(context);
    final isSelected = prefs.themePreset == preset;

    return ListTile(
      leading: Icon(icon, color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.6)),
      title: Text(title, style: AppTypography.body(theme.colorScheme.onSurface, isMedium: isSelected)),
      subtitle: Text(subtitle, style: AppTypography.caption(theme.colorScheme.onSurface.withValues(alpha: 0.6))),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
          : null,
      onTap: () {
        HapticsHelper.selection();
        prefs.setThemePreset(preset);
      },
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
