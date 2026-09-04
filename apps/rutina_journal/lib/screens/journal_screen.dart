import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../models/journal_entry.dart';
import '../services/journal_service.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/date_utils.dart';
import '../utils/haptics_helper.dart';
import '../widgets/mood_orbs_selector.dart';
import '../widgets/state_button.dart';

class JournalScreen extends StatefulWidget {
  final JournalService journalService;

  const JournalScreen({
    super.key,
    required this.journalService,
  });

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final DateTime _currentDate = DateTime.now();
  late String _dateKey;

  int _selectedMood = 4;
  int _energyLevel = 3;
  List<String> _selectedTags = [];

  final TextEditingController _gratitude1Controller = TextEditingController();
  final TextEditingController _gratitude2Controller = TextEditingController();
  final TextEditingController _gratitude3Controller = TextEditingController();
  final TextEditingController _dailyWinController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  ButtonState _saveButtonState = ButtonState.idle;

  final List<String> _availableTags = [
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
    _dateKey = AppDateUtils.toDateKey(_currentDate);
    _loadEntryForToday();
  }

  void _loadEntryForToday() {
    final entry = widget.journalService.getEntryForDate(_currentDate);
    _selectedMood = entry.moodLevel;
    _energyLevel = entry.energyLevel;
    _selectedTags = List.from(entry.tags);
    _gratitude1Controller.text = entry.gratitude1;
    _gratitude2Controller.text = entry.gratitude2;
    _gratitude3Controller.text = entry.gratitude3;
    _dailyWinController.text = entry.dailyWin;
    _notesController.text = entry.notes;
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

  Future<void> _saveEntry() async {
    setState(() => _saveButtonState = ButtonState.loading);
    try {
      await widget.journalService.saveEntry(
        dateKey: _dateKey,
        moodLevel: _selectedMood,
        energyLevel: _energyLevel,
        tags: _selectedTags,
        gratitude1: _gratitude1Controller.text,
        gratitude2: _gratitude2Controller.text,
        gratitude3: _gratitude3Controller.text,
        dailyWin: _dailyWinController.text,
        notes: _notesController.text,
      );

      HapticsHelper.light();
      if (mounted) {
        setState(() => _saveButtonState = ButtonState.idle);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).t('journalSaved')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saveButtonState = ButtonState.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.t('journalTitle'),
              style: AppTypography.display(theme.colorScheme.onSurface),
            ),
            Text(
              DateFormat('d MMMM yyyy', l10n.locale.languageCode).format(_currentDate),
              style: AppTypography.caption(
                theme.colorScheme.onSurface.withValues(alpha: 0.6),
                isMedium: true,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Atmospheric Glowing Mood Orbs Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: MoodOrbsSelector(
                selectedMood: _selectedMood,
                energyLevel: _energyLevel,
                onMoodChanged: (mood) => setState(() => _selectedMood = mood),
                onEnergyChanged: (energy) => setState(() => _energyLevel = energy),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Emotion Tags Selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Etiquetas de estado',
                    style: AppTypography.body(theme.colorScheme.onSurface, isMedium: true),
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
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Gratitude Prompts Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.t('gratitudePrompt'),
                    style: AppTypography.section(theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: AppSpacing.md),
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
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Daily Win Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.t('dailyWinPrompt'),
                    style: AppTypography.section(theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _dailyWinController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: l10n.t('dailyWinHint'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Freeform Notes Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pensamientos & Notas libres',
                    style: AppTypography.section(theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _notesController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Escribe libremente cualquier reflexión de tu día...',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Save Button
          StateButton(
            label: l10n.t('saveJournal'),
            state: _saveButtonState,
            icon: Icons.check_circle_outline_rounded,
            onPressed: _saveEntry,
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}
