import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/journal_entry.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/haptics_helper.dart';
import 'mood_orbs_selector.dart';

class JournalEntryDialog extends StatefulWidget {
  final JournalEntry entry;
  final Function({
    required int moodLevel,
    required int energyLevel,
    required List<String> tags,
    required String gratitude1,
    required String gratitude2,
    required String gratitude3,
    required String dailyWin,
    required String notes,
  }) onSave;

  const JournalEntryDialog({
    super.key,
    required this.entry,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required JournalEntry entry,
    required Function({
      required int moodLevel,
      required int energyLevel,
      required List<String> tags,
      required String gratitude1,
      required String gratitude2,
      required String gratitude3,
      required String dailyWin,
      required String notes,
    }) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => JournalEntryDialog(entry: entry, onSave: onSave),
    );
  }

  @override
  State<JournalEntryDialog> createState() => _JournalEntryDialogState();
}

class _JournalEntryDialogState extends State<JournalEntryDialog> {
  late int _selectedMood;
  late int _energyLevel;
  late List<String> _selectedTags;

  late TextEditingController _gratitude1Controller;
  late TextEditingController _gratitude2Controller;
  late TextEditingController _gratitude3Controller;
  late TextEditingController _dailyWinController;
  late TextEditingController _notesController;

  final List<String> _availableTags = const [
    'tagCalm',
    'tagFocused',
    'tagGrateful',
    'tagEnergized',
    'tagTired',
    'tagStressed',
    'tagInspired',
    'tagPeaceful',
  ];

  @override
  void initState() {
    super.initState();
    _selectedMood = widget.entry.moodLevel;
    _energyLevel = widget.entry.energyLevel;
    _selectedTags = List.from(widget.entry.tags);

    _gratitude1Controller = TextEditingController(text: widget.entry.gratitude1);
    _gratitude2Controller = TextEditingController(text: widget.entry.gratitude2);
    _gratitude3Controller = TextEditingController(text: widget.entry.gratitude3);
    _dailyWinController = TextEditingController(text: widget.entry.dailyWin);
    _notesController = TextEditingController(text: widget.entry.notes);
  }

  @override
  void dispose() {
    _gratitude1Controller.dispose();
    _gratitude2Controller.dispose();
    _gratitude3Controller.dispose();
    _dailyWinController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    HapticsHelper.medium();
    widget.onSave(
      moodLevel: _selectedMood,
      energyLevel: _energyLevel,
      tags: _selectedTags,
      gratitude1: _gratitude1Controller.text.trim(),
      gratitude2: _gratitude2Controller.text.trim(),
      gratitude3: _gratitude3Controller.text.trim(),
      dailyWin: _dailyWinController.text.trim(),
      notes: _notesController.text.trim(),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.t('journalLogTitle'),
                    style: AppTypography.title(theme.colorScheme.onSurface).copyWith(fontSize: 18),
                  ),
                  Text(
                    l10n.t('journalLogSubtitle'),
                    style: AppTypography.caption(
                      theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      isMedium: true,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                tooltip: l10n.t('actionClose'),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Scrollable fields
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Estado General (5 options with distinct semantic colors)
                  Text(
                    l10n.t('moodLevelTitle'),
                    style: AppTypography.caption(theme.colorScheme.onSurface.withValues(alpha: 0.8), isMedium: true),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      _buildLevelItem(
                        context,
                        title: l10n.t('moodDifficult'),
                        icon: Icons.sentiment_very_dissatisfied_rounded,
                        color: const Color(0xFFD96B6B),
                        isSelected: _selectedMood == 1,
                        onTap: () {
                          HapticsHelper.selection();
                          setState(() => _selectedMood = 1);
                        },
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      _buildLevelItem(
                        context,
                        title: l10n.t('moodLow'),
                        icon: Icons.sentiment_dissatisfied_rounded,
                        color: const Color(0xFFE28A53),
                        isSelected: _selectedMood == 2,
                        onTap: () {
                          HapticsHelper.selection();
                          setState(() => _selectedMood = 2);
                        },
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      _buildLevelItem(
                        context,
                        title: l10n.t('moodNeutral'),
                        icon: Icons.sentiment_neutral_rounded,
                        color: const Color(0xFFE5BA5A),
                        isSelected: _selectedMood == 3,
                        onTap: () {
                          HapticsHelper.selection();
                          setState(() => _selectedMood = 3);
                        },
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      _buildLevelItem(
                        context,
                        title: l10n.t('moodGood'),
                        icon: Icons.sentiment_satisfied_alt_rounded,
                        color: const Color(0xFF6B9E78),
                        isSelected: _selectedMood == 4,
                        onTap: () {
                          HapticsHelper.selection();
                          setState(() => _selectedMood = 4);
                        },
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      _buildLevelItem(
                        context,
                        title: l10n.t('moodRadiant'),
                        icon: Icons.sentiment_very_satisfied_rounded,
                        color: const Color(0xFF2D7A4F),
                        isSelected: _selectedMood == 5,
                        onTap: () {
                          HapticsHelper.selection();
                          setState(() => _selectedMood = 5);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 2. Nivel de Energía (5 levels: Sereno a Muy Alto)
                  Text(
                    l10n.t('energyLevelTitle'),
                    style: AppTypography.caption(theme.colorScheme.onSurface.withValues(alpha: 0.8), isMedium: true),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      _buildLevelItem(
                        context,
                        title: l10n.t('energyVeryLow'),
                        icon: Icons.battery_0_bar_rounded,
                        color: const Color(0xFF64748B),
                        isSelected: _energyLevel == 1,
                        onTap: () {
                          HapticsHelper.selection();
                          setState(() => _energyLevel = 1);
                        },
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      _buildLevelItem(
                        context,
                        title: l10n.t('energyLow'),
                        icon: Icons.battery_2_bar_rounded,
                        color: const Color(0xFF5E8B7E),
                        isSelected: _energyLevel == 2,
                        onTap: () {
                          HapticsHelper.selection();
                          setState(() => _energyLevel = 2);
                        },
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      _buildLevelItem(
                        context,
                        title: l10n.t('energyModerate'),
                        icon: Icons.battery_4_bar_rounded,
                        color: const Color(0xFF388E3C),
                        isSelected: _energyLevel == 3,
                        onTap: () {
                          HapticsHelper.selection();
                          setState(() => _energyLevel = 3);
                        },
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      _buildLevelItem(
                        context,
                        title: l10n.t('energyHigh'),
                        icon: Icons.battery_5_bar_rounded,
                        color: const Color(0xFFE07A5F),
                        isSelected: _energyLevel == 4,
                        onTap: () {
                          HapticsHelper.selection();
                          setState(() => _energyLevel = 4);
                        },
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      _buildLevelItem(
                        context,
                        title: l10n.t('energyVeryHigh'),
                        icon: Icons.bolt_rounded,
                        color: const Color(0xFFD32F2F),
                        isSelected: _energyLevel == 5,
                        onTap: () {
                          HapticsHelper.selection();
                          setState(() => _energyLevel = 5);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Tres Gratitudes Section
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.favorite_outline_rounded, color: Color(0xFFC85A3B), size: 20),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  l10n.t('threeGratitudesTitle'),
                                  style: AppTypography.title(theme.colorScheme.onSurface).copyWith(fontSize: 16),
                                ),
                              ],
                            ),
                            Text(
                              '${[_gratitude1Controller.text, _gratitude2Controller.text, _gratitude3Controller.text].where((s) => s.trim().isNotEmpty).length}/3',
                              style: AppTypography.caption(theme.colorScheme.onSurface.withValues(alpha: 0.5), isMedium: true),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.t('threeGratitudesSubtitle'),
                          style: AppTypography.caption(theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        _buildNumberedField(1, _gratitude1Controller, l10n.t('gratitudeHint1')),
                        const SizedBox(height: AppSpacing.xs),
                        _buildNumberedField(2, _gratitude2Controller, l10n.t('gratitudeHint2')),
                        const SizedBox(height: AppSpacing.xs),
                        _buildNumberedField(3, _gratitude3Controller, l10n.t('gratitudeHint3')),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Victoria del Día Section
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.military_tech_outlined, color: Color(0xFF2E7D32), size: 20),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              l10n.t('dailyWinTitle'),
                              style: AppTypography.title(theme.colorScheme.onSurface).copyWith(fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.t('dailyWinSubtitle'),
                          style: AppTypography.caption(theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          controller: _dailyWinController,
                          decoration: InputDecoration(
                            hintText: l10n.t('dailyWinPlaceholder'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Reflexión libre & Factores Influyentes
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.mode_edit_outline_rounded, size: 20),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              l10n.t('freeReflectionTitle'),
                              style: AppTypography.title(theme.colorScheme.onSurface).copyWith(fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.t('freeReflectionSubtitle'),
                          style: AppTypography.caption(theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          controller: _notesController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: l10n.t('freeReflectionPlaceholder'),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Factores influyentes hoy (10 chips en Wrap)
                        Text(
                          l10n.t('influencingFactorsTitle'),
                          style: AppTypography.caption(theme.colorScheme.onSurface.withValues(alpha: 0.7), isMedium: true),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            _buildFactorChip('factorHydration', Icons.water_drop_outlined, l10n.t('factorHydration')),
                            _buildFactorChip('factorRest', Icons.bedtime_outlined, l10n.t('factorRest')),
                            _buildFactorChip('factorWalk', Icons.directions_walk_rounded, l10n.t('factorWalk')),
                            _buildFactorChip('factorDigitalDetox', Icons.phonelink_erase_rounded, l10n.t('factorDigitalDetox')),
                            _buildFactorChip('factorNutrition', Icons.restaurant_rounded, l10n.t('factorNutrition')),
                            _buildFactorChip('factorExercise', Icons.fitness_center_rounded, l10n.t('factorExercise')),
                            _buildFactorChip('factorSocial', Icons.people_outline_rounded, l10n.t('factorSocial')),
                            _buildFactorChip('factorMindfulness', Icons.self_improvement_rounded, l10n.t('factorMindfulness')),
                            _buildFactorChip('factorDeepWork', Icons.psychology_outlined, l10n.t('factorDeepWork')),
                            _buildFactorChip('factorNature', Icons.park_outlined, l10n.t('factorNature')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Save Button Zen CTA
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2D4638),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              onPressed: _save,
              icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
              label: Text(
                l10n.t('saveDayLog'),
                style: AppTypography.body(Colors.white, isMedium: true),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: isDark ? 0.28 : 0.18)
                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: isSelected ? color : theme.colorScheme.outline.withValues(alpha: 0.20),
              width: isSelected ? 1.8 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? color : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                size: 20,
              ),
              const SizedBox(height: 2),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? color : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberedField(int number, TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            '$number.',
            style: const TextStyle(
              color: Color(0xFFC85A3B),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 0),
        hintText: hint,
      ),
    );
  }

  Widget _buildFactorChip(String tagKey, IconData icon, String label) {
    final isSelected = _selectedTags.contains(tagKey);
    return FilterChip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      onSelected: (selected) {
        HapticsHelper.selection();
        setState(() {
          if (selected) {
            _selectedTags.add(tagKey);
          } else {
            _selectedTags.remove(tagKey);
          }
        });
      },
    );
  }
}
