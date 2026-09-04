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
              Text(
                l10n.t('journalTitle'),
                style: AppTypography.title(theme.colorScheme.onSurface),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Scrollable fields
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Atmospheric Glowing Mood Orbs
                  MoodOrbsSelector(
                    selectedMood: _selectedMood,
                    energyLevel: _energyLevel,
                    onMoodChanged: (m) => setState(() => _selectedMood = m),
                    onEnergyChanged: (e) => setState(() => _energyLevel = e),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // State Tags
                  Text(
                    'Etiquetas de estado',
                    style: AppTypography.caption(
                      theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      isMedium: true,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: _availableTags.map((tagKey) {
                      final isSelected = _selectedTags.contains(tagKey);
                      return FilterChip(
                        label: Text(l10n.t(tagKey)),
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
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Gratitude Prompts
                  Text(
                    l10n.t('gratitudePrompt'),
                    style: AppTypography.section(theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextField(
                    controller: _gratitude1Controller,
                    decoration: InputDecoration(
                      hintText: l10n.t('gratitudeHint1'),
                      prefixIcon: const Icon(Icons.favorite_outline_rounded, size: 18),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextField(
                    controller: _gratitude2Controller,
                    decoration: InputDecoration(
                      hintText: l10n.t('gratitudeHint2'),
                      prefixIcon: const Icon(Icons.star_outline_rounded, size: 18),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextField(
                    controller: _gratitude3Controller,
                    decoration: InputDecoration(
                      hintText: l10n.t('gratitudeHint3'),
                      prefixIcon: const Icon(Icons.wb_sunny_outlined, size: 18),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Daily Win
                  Text(
                    l10n.t('dailyWinPrompt'),
                    style: AppTypography.section(theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextField(
                    controller: _dailyWinController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: l10n.t('dailyWinHint'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Freeform Notes
                  Text(
                    'Pensamientos & Notas libres',
                    style: AppTypography.section(theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Escribe libremente cualquier reflexión...',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Save Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _save,
              child: Text(l10n.t('saveJournal')),
            ),
          ),
        ],
      ),
    );
  }
}
