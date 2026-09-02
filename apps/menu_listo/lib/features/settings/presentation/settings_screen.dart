import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:menu_listo/core/localization/app_localizations.dart';
import 'package:menu_listo/core/localization/locale_provider.dart';
import 'package:menu_listo/core/theme/app_colors.dart';
import 'package:menu_listo/core/theme/app_theme_types.dart';
import 'package:menu_listo/core/theme/theme_provider.dart';
import '../../backup/services/backup_service.dart';
import 'widgets/about_dialog_widget.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final currentDesignTheme = ref.watch(designThemeProvider);
    final currentThemeMode = ref.watch(themeModeProvider);
    final currentLanguage = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.settingsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
        children: [
          // 1. Visual Theme
          Text(
            strings.visualThemeTitle,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          _buildThemeOptionCard(
            context: context,
            title: strings.themeBotanical,
            colors: [AppColors.botanicalPrimaryLight, AppColors.botanicalSecondaryLight, AppColors.botanicalAccentLight],
            isSelected: currentDesignTheme == AppDesignTheme.modernBotanical,
            onTap: () => ref.read(designThemeProvider.notifier).setDesignTheme(AppDesignTheme.modernBotanical),
          ),
          const SizedBox(height: 8),

          _buildThemeOptionCard(
            context: context,
            title: strings.themeGourmet,
            colors: [AppColors.gourmetPrimaryLight, AppColors.gourmetSecondaryLight, AppColors.gourmetAccentLight],
            isSelected: currentDesignTheme == AppDesignTheme.editorialGourmet,
            onTap: () => ref.read(designThemeProvider.notifier).setDesignTheme(AppDesignTheme.editorialGourmet),
          ),
          const SizedBox(height: 8),

          _buildThemeOptionCard(
            context: context,
            title: strings.themeBento,
            colors: [AppColors.bentoPrimaryLight, AppColors.bentoSecondaryLight, AppColors.bentoAccentLight],
            isSelected: currentDesignTheme == AppDesignTheme.materialYouBento,
            onTap: () => ref.read(designThemeProvider.notifier).setDesignTheme(AppDesignTheme.materialYouBento),
          ),
          const SizedBox(height: 24),

          // 2. Color Mode
          Text(
            strings.appearanceTitle,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                value: ThemeMode.system,
                icon: const Icon(Icons.brightness_auto),
                label: Text(strings.modeSystem),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: const Icon(Icons.light_mode),
                label: Text(strings.modeLight),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: const Icon(Icons.dark_mode),
                label: Text(strings.modeDark),
              ),
            ],
            selected: {currentThemeMode},
            onSelectionChanged: (newSelection) {
              ref.read(themeModeProvider.notifier).setThemeMode(newSelection.first);
            },
          ),
          const SizedBox(height: 24),

          // 3. Language Selector
          Text(
            strings.languageTitle,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SegmentedButton<AppLanguage>(
            segments: [
              ButtonSegment(
                value: AppLanguage.system,
                label: Text(strings.langSystem),
              ),
              const ButtonSegment(
                value: AppLanguage.es,
                label: Text('Español'),
              ),
              const ButtonSegment(
                value: AppLanguage.en,
                label: Text('English'),
              ),
            ],
            selected: {currentLanguage},
            onSelectionChanged: (newSelection) {
              ref.read(localeProvider.notifier).setLanguage(newSelection.first);
            },
          ),
          const SizedBox(height: 24),

          // 4. Backup & Privacy
          Text(
            strings.backupTitle,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_upload_outlined),
                  title: Text(strings.exportBackup),
                  onTap: () async {
                    final backup = BackupService();
                    final path = await backup.exportBackupJson();
                    if (context.mounted && path != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(strings.isSpanish ? 'Copia exportada con éxito' : 'Backup exported successfully')),
                      );
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cloud_download_outlined),
                  title: Text(strings.importBackup),
                  onTap: () async {
                    final backup = BackupService();
                    final ok = await backup.importBackupJson();
                    if (context.mounted && ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(strings.isSpanish ? 'Copia restaurada con éxito' : 'Backup restored successfully')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 5. About Screen
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: Text(strings.aboutApp),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => const AboutDialogWidget(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOptionCard({
    required BuildContext context,
    required String title,
    required List<Color> colors,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.1) : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Row(
                children: colors
                    .map((c) => Container(
                          width: 16,
                          height: 16,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 20)
              else
                Icon(Icons.radio_button_unchecked, color: theme.colorScheme.outline, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
