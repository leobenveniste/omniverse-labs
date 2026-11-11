import 'package:flutter/material.dart';

import '../services/did_it_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/contact_us_modal.dart';

/// Settings page controlling Theme, Bilingual Locale, Notifications, Quick Snooze, and Privacy.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.controller,
  });

  final DidItController controller;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final s = controller.strings;
        final isDark = controller.themeMode == ThemeMode.dark;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              s.settingsTitle,
              style: AppTypography.title.copyWith(color: palette.textPrimary),
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.base),
              children: <Widget>[
                Text(
                  s.appearanceSection,
                  style: AppTypography.label.copyWith(color: palette.textSecondary),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.base),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(color: palette.border),
                  ),
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              s.themeLabel,
                              style: AppTypography.body
                                  .copyWith(color: palette.textPrimary),
                            ),
                          ),
                          SegmentedButton<ThemeMode>(
                            segments: <ButtonSegment<ThemeMode>>[
                              ButtonSegment<ThemeMode>(
                                value: ThemeMode.dark,
                                label: Text(s.darkLabel),
                              ),
                              ButtonSegment<ThemeMode>(
                                value: ThemeMode.light,
                                label: Text(s.lightLabel),
                              ),
                            ],
                            selected: <ThemeMode>{
                              isDark ? ThemeMode.dark : ThemeMode.light,
                            },
                            onSelectionChanged: (sel) {
                              if ((sel.first == ThemeMode.dark) != isDark) {
                                controller.toggleThemeMode();
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.base),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              s.languageLabel,
                              style: AppTypography.body
                                  .copyWith(color: palette.textPrimary),
                            ),
                          ),
                          SegmentedButton<String>(
                            segments: const <ButtonSegment<String>>[
                              ButtonSegment<String>(value: 'en', label: Text('EN')),
                              ButtonSegment<String>(value: 'es', label: Text('ES')),
                            ],
                            selected: <String>{
                              controller.localeCode.startsWith('es') ? 'es' : 'en',
                            },
                            onSelectionChanged: (sel) {
                              controller.setLocaleCode(sel.first);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  s.automationSection,
                  style: AppTypography.label.copyWith(color: palette.textSecondary),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.base),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(color: palette.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              s.notifPermissionLabel,
                              style: AppTypography.body
                                  .copyWith(color: palette.textPrimary),
                            ),
                          ),
                          if (controller.notificationsEnabled)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: palette.accentTint,
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusPill),
                              ),
                              child: Text(
                                s.grantedLabel,
                                style: AppTypography.label
                                    .copyWith(color: palette.accentPrimary),
                              ),
                            )
                          else
                            FilledButton(
                              onPressed: controller.requestNotificationPermission,
                              child: Text(s.enableBtn),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.base),
                      Text(
                        s.defaultSnoozeLabel,
                        style: AppTypography.body
                            .copyWith(color: palette.textPrimary),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        children: <int>[15, 30, 60].map((mins) {
                          return ChoiceChip(
                            selected: controller.defaultSnoozeMinutes == mins,
                            label: Text('${mins}m'),
                            onSelected: (_) =>
                                controller.setDefaultSnoozeMinutes(mins),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.base),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(color: palette.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.shield_outlined,
                            color: palette.accentPrimary,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            s.privacyOfflineTitle,
                            style: AppTypography.title
                                .copyWith(color: palette.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        s.privacyOfflineBody,
                        style: AppTypography.body
                            .copyWith(color: palette.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.base),
                      OutlinedButton.icon(
                        onPressed: () => ContactUsModal.show(context, s),
                        icon: const Icon(Icons.mail_outline_rounded, size: 18),
                        label: Text(s.contactSupportBtn),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
