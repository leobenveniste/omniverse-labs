import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:menu_listo/core/localization/app_localizations.dart';
import 'package:menu_listo/core/localization/locale_provider.dart';
import 'package:menu_listo/core/theme/app_theme_types.dart';
import 'package:menu_listo/core/theme/theme_provider.dart';
import '../../backup/services/backup_service.dart';
import '../../recipes/providers/recipe_provider.dart';
import 'widgets/about_dialog_widget.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);

    final currentThemeMode = ref.watch(themeModeProvider);
    final currentDesignTheme = ref.watch(designThemeProvider);
    final currentLanguage = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.settingsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Visual Design Style Selector
          _buildSectionHeader(theme, strings.visualTheme),
          Card(
            child: Column(
              children: [
                RadioListTile<AppDesignTheme>(
                  title: Text(strings.styleModernBotanical, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Editorial botánica, verde oliva, salvia y crema'),
                  value: AppDesignTheme.modernBotanical,
                  groupValue: currentDesignTheme,
                  onChanged: (val) {
                    if (val != null) ref.read(designThemeProvider.notifier).setDesignTheme(val);
                  },
                ),
                const Divider(height: 1),
                RadioListTile<AppDesignTheme>(
                  title: Text(strings.styleEditorialGourmet, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Revista de lujo, tipografía serif refinada y líneas puras'),
                  value: AppDesignTheme.editorialGourmet,
                  groupValue: currentDesignTheme,
                  onChanged: (val) {
                    if (val != null) ref.read(designThemeProvider.notifier).setDesignTheme(val);
                  },
                ),
                const Divider(height: 1),
                RadioListTile<AppDesignTheme>(
                  title: Text(strings.styleMaterialBento, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Material You dinámico, tarjetas Bento y acentos de mostaza'),
                  value: AppDesignTheme.materialYouBento,
                  groupValue: currentDesignTheme,
                  onChanged: (val) {
                    if (val != null) ref.read(designThemeProvider.notifier).setDesignTheme(val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Color Mode (Light / Dark / System)
          _buildSectionHeader(theme, strings.themeMode),
          Card(
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: Text(strings.themeSystem),
                  value: ThemeMode.system,
                  groupValue: currentThemeMode,
                  onChanged: (val) {
                    if (val != null) ref.read(themeModeProvider.notifier).setThemeMode(val);
                  },
                ),
                const Divider(height: 1),
                RadioListTile<ThemeMode>(
                  title: Text(strings.themeLight),
                  value: ThemeMode.light,
                  groupValue: currentThemeMode,
                  onChanged: (val) {
                    if (val != null) ref.read(themeModeProvider.notifier).setThemeMode(val);
                  },
                ),
                const Divider(height: 1),
                RadioListTile<ThemeMode>(
                  title: Text(strings.themeDark),
                  value: ThemeMode.dark,
                  groupValue: currentThemeMode,
                  onChanged: (val) {
                    if (val != null) ref.read(themeModeProvider.notifier).setThemeMode(val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Language Selector
          _buildSectionHeader(theme, strings.languageTitle),
          Card(
            child: Column(
              children: [
                ...AppLanguage.values.map((lang) {
                  return Column(
                    children: [
                      RadioListTile<AppLanguage>(
                        title: Text(lang.displayName),
                        value: lang,
                        groupValue: currentLanguage,
                        onChanged: (val) {
                          if (val != null) ref.read(localeProvider.notifier).setLanguage(val);
                        },
                      ),
                      if (lang != AppLanguage.values.last) const Divider(height: 1),
                    ],
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Backup & Data
          _buildSectionHeader(theme, strings.dataBackup),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.file_upload_outlined, color: theme.colorScheme.primary),
                  title: Text(strings.exportBackup),
                  subtitle: const Text('Guarda todas tus recetas y listas en un archivo'),
                  onTap: () async {
                    final path = await BackupService().exportBackupJson();
                    if (context.mounted && path != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(strings.backupExportSuccess)),
                      );
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.file_download_outlined, color: theme.colorScheme.primary),
                  title: Text(strings.importBackup),
                  subtitle: const Text('Restaura recetas desde una copia previa'),
                  onTap: () async {
                    final success = await BackupService().importBackupJson();
                    if (context.mounted) {
                      if (success) {
                        ref.read(recipesListProvider.notifier).loadRecipes();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(strings.backupImportSuccess)),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(strings.backupError)),
                        );
                      }
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.refresh, color: theme.colorScheme.primary),
                  title: Text(strings.restoreSampleRecipes),
                  onTap: () => _confirmReloadSamples(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // About Omniverse Labs
          Card(
            child: ListTile(
              leading: Icon(Icons.info_outline, color: theme.colorScheme.primary),
              title: Text(strings.aboutOmniverseLabs, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => AboutDialogWidget.show(context),
            ),
          ),
          const SizedBox(height: 16),

          // Privacy Statement
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              strings.privacyNotice,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _confirmReloadSamples(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.restoreSampleRecipes),
        content: Text(strings.restoreSampleRecipesConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(strings.cancel)),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(recipesListProvider.notifier).reloadSampleRecipes();
            },
            child: Text(strings.confirm),
          ),
        ],
      ),
    );
  }
}
