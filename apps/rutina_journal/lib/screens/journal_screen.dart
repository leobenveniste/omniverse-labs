import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../models/journal_entry.dart';
import '../services/app_services.dart';
import '../services/journal_service.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../utils/date_utils.dart';
import '../utils/haptics_helper.dart';
import '../widgets/app_header_title.dart';
import '../widgets/first_use_guide_card.dart';
import '../widgets/journal_entry_dialog.dart';
import '../widgets/paywall_sheet.dart';

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
  bool _showGuide = false;

  @override
  void initState() {
    super.initState();
    _loadGuideState();
  }

  Future<void> _loadGuideState() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('has_seen_guide_journal') ?? false;
    if (!seen && mounted) {
      setState(() => _showGuide = true);
    }
  }

  Future<void> _dismissGuide() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_guide_journal', true);
    if (mounted) {
      setState(() => _showGuide = false);
    }
  }

  void _openEntryDialog(BuildContext context, DateTime today, String todayKey) {
    HapticsHelper.medium();
    final todayEntry = widget.journalService.getEntryForDate(today);
    JournalEntryDialog.show(
      context,
      entry: todayEntry,
      onSave: ({
        required moodLevel,
        required energyLevel,
        required tags,
        required gratitude1,
        required gratitude2,
        required gratitude3,
        required dailyWin,
        required notes,
      }) {
        widget.journalService.saveEntry(
          dateKey: todayKey,
          moodLevel: moodLevel,
          energyLevel: energyLevel,
          tags: tags,
          gratitude1: gratitude1,
          gratitude2: gratitude2,
          gratitude3: gratitude3,
          dailyWin: dailyWin,
          notes: notes,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final appServices = AppServices.of(context);
    final prefs = appServices.preferencesService;
    final premiumService = appServices.premiumService;
    final today = DateTime.now();
    final todayKey = AppDateUtils.toDateKey(today);

    return Scaffold(
      appBar: AppBar(
        title: AppHeaderTitle(
          title: l10n.t('navJournal'),
          isPro: premiumService.isPro,
        ),
        actions: [
          if (!premiumService.isPro)
            IconButton(
              icon: const Text('👑', style: TextStyle(fontSize: 18)),
              tooltip: 'Ritmo PRO',
              onPressed: () {
                HapticsHelper.light();
                PaywallSheet.show(context);
              },
            ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: l10n.t('newEntry'),
            onPressed: () => _openEntryDialog(context, today, todayKey),
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.getAtmosphericBackground(context, prefs.themePreset),
        child: AnimatedBuilder(
          animation: widget.journalService,
          builder: (context, _) {
            final todayEntry = widget.journalService.getEntryForDate(today);
            final entries = widget.journalService.allEntries;

            return ListView(
              padding: const EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                top: AppSpacing.sm,
                bottom: 88,
              ),
              children: [
                if (_showGuide)
                  FirstUseGuideCard(
                    icon: Icons.auto_stories_rounded,
                    title: l10n.locale.languageCode == 'es' ? 'Tu Diario y Gratitud' : 'Your Journal & Reflection',
                    description: l10n.locale.languageCode == 'es'
                        ? 'Registra tu ánimo, niveles de energía y momentos de gratitud para cuidar tu bienestar mental.'
                        : 'Log your mood, energy levels, and gratitude reflections to nurture mindful growth.',
                    bulletPoints: l10n.locale.languageCode == 'es'
                        ? [
                            'Toca "Registrar Hoy" para completar tu check-in diario en 1 minuto.',
                            'Revisa tu historial cronológico para ver patrones de ánimo y reflexiones.',
                            'Toca (+) arriba en cualquier momento para agregar notas o aprendizajes.',
                          ]
                        : [
                            'Tap "Check In" to record your mood & energy in under 1 minute.',
                            'Review your timeline feed to reflect on insights and victories.',
                            'Tap (+) on top anytime to log new thoughts and gratitude entries.',
                          ],
                    onDismiss: _dismissGuide,
                  ),
                // Today's Status / Check-in Hero Card
                _buildTodayHeroCard(context, l10n, todayEntry),
                const SizedBox(height: AppSpacing.lg),

                // Timeline Feed Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.t('pastEntries'),
                      style: AppTypography.section(theme.colorScheme.onSurface),
                    ),
                    Text(
                      l10n.t('journalEntriesCount', args: {'count': '${entries.length}'}),
                      style: AppTypography.caption(
                        theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        isMedium: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Feed List
                if (entries.isEmpty)
                  _buildEmptyState(context, l10n)
                else
                  ...entries.map((entry) => _buildEntryFeedCard(context, l10n, entry)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTodayHeroCard(BuildContext context, AppLocalizations l10n, JournalEntry todayEntry) {
    final theme = Theme.of(context);
    final hasLogged = !todayEntry.isEmpty;
    final energyColor = _getEnergyColor(todayEntry.energyLevel);

    return Container(
      decoration: BoxDecoration(
        color: hasLogged
            ? energyColor.withValues(alpha: 0.12)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: hasLogged
              ? energyColor.withValues(alpha: 0.5)
              : theme.colorScheme.outline.withValues(alpha: 0.3),
          width: hasLogged ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: hasLogged
                ? energyColor.withValues(alpha: 0.08)
                : theme.colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: hasLogged
                    ? energyColor
                    : theme.colorScheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasLogged ? _getMoodIcon(todayEntry.moodLevel) : Icons.add_reaction_outlined,
                color: hasLogged ? Colors.white : theme.colorScheme.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasLogged ? 'Check-in de hoy completado' : l10n.t('howAreYouFeeling'),
                    style: AppTypography.body(theme.colorScheme.onSurface, isMedium: true),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasLogged
                        ? 'Ánimo: ${_getMoodLabel(l10n, todayEntry.moodLevel)} • Energía: ${todayEntry.energyLevel}/5'
                        : 'Dedica 2 minutos para registrar tu estado y gratitudes.',
                    style: AppTypography.caption(
                      theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            FilledButton.tonal(
              onPressed: () {
                HapticsHelper.selection();
                JournalEntryDialog.show(
                  context,
                  entry: todayEntry,
                  onSave: ({
                    required moodLevel,
                    required energyLevel,
                    required tags,
                    required gratitude1,
                    required gratitude2,
                    required gratitude3,
                    required dailyWin,
                    required notes,
                  }) {
                    widget.journalService.saveEntry(
                      dateKey: todayEntry.dateKey,
                      moodLevel: moodLevel,
                      energyLevel: energyLevel,
                      tags: tags,
                      gratitude1: gratitude1,
                      gratitude2: gratitude2,
                      gratitude3: gratitude3,
                      dailyWin: dailyWin,
                      notes: notes,
                    );
                  },
                );
              },
              child: Text(hasLogged ? 'Editar' : 'Registrar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryFeedCard(BuildContext context, AppLocalizations l10n, JournalEntry entry) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final parsedDate = DateTime.tryParse(entry.dateKey) ?? entry.createdAt;
    final dateStr = DateFormat('EEEE, d MMMM yyyy', l10n.locale.languageCode).format(parsedDate);
    final energyColor = _getEnergyColor(entry.energyLevel);

    // Tint card based on energy level
    final cardBgColor = isDark
        ? energyColor.withValues(alpha: 0.16)
        : energyColor.withValues(alpha: 0.10);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: energyColor.withValues(alpha: 0.45),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: energyColor.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: () {
            HapticsHelper.selection();
            JournalEntryDialog.show(
              context,
              entry: entry,
              onSave: ({
                required moodLevel,
                required energyLevel,
                required tags,
                required gratitude1,
                required gratitude2,
                required gratitude3,
                required dailyWin,
                required notes,
              }) {
                widget.journalService.saveEntry(
                  dateKey: entry.dateKey,
                  moodLevel: moodLevel,
                  energyLevel: energyLevel,
                  tags: tags,
                  gratitude1: gratitude1,
                  gratitude2: gratitude2,
                  gratitude3: gratitude3,
                  dailyWin: dailyWin,
                  notes: notes,
                );
              },
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Mood Orb + Date + Energy Pill
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _getMoodColor(entry.moodLevel).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getMoodIcon(entry.moodLevel),
                        color: _getMoodColor(entry.moodLevel),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateStr,
                            style: AppTypography.body(theme.colorScheme.onSurface, isMedium: true),
                          ),
                          Row(
                            children: [
                              Text(
                                _getMoodLabel(l10n, entry.moodLevel),
                                style: AppTypography.caption(
                                  theme.colorScheme.onSurface.withValues(alpha: 0.65),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: energyColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                                ),
                                child: Text(
                                  l10n.t('energyPill', args: {'level': '${entry.energyLevel}'}),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: energyColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ],
                ),

                // Tags
                if (entry.tags.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: entry.tags.map((t) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                          border: Border.all(
                            color: energyColor.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          l10n.t(t),
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                // Daily Win
                if (entry.dailyWin.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.emoji_events_outlined, size: 16, color: Colors.amber.shade800),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          entry.dailyWin,
                          style: AppTypography.body(theme.colorScheme.onSurface).copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // Gratitudes Preview
                if (entry.gratitude1.isNotEmpty || entry.gratitude2.isNotEmpty || entry.gratitude3.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  if (entry.gratitude1.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text('• ${entry.gratitude1}',
                          style: AppTypography.caption(theme.colorScheme.onSurface.withValues(alpha: 0.85))),
                    ),
                  if (entry.gratitude2.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text('• ${entry.gratitude2}',
                          style: AppTypography.caption(theme.colorScheme.onSurface.withValues(alpha: 0.85))),
                    ),
                  if (entry.gratitude3.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text('• ${entry.gratitude3}',
                          style: AppTypography.caption(theme.colorScheme.onSurface.withValues(alpha: 0.85))),
                    ),
                ],

                // Notes Preview
                if (entry.notes.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    entry.notes,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption(
                      theme.colorScheme.onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 48,
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No hay entradas registradas aún',
              style: AppTypography.body(theme.colorScheme.onSurface, isMedium: true),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Presiona el botón inferior para comenzar tu diario reflexivo.',
              style: AppTypography.caption(theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }

  Color _getEnergyColor(int energy) {
    switch (energy) {
      case 5:
        return const Color(0xFFE65100); // Solar Orange/Gold (Maximum vitality)
      case 4:
        return const Color(0xFF2E7D32); // Deep Energetic Emerald
      case 3:
        return const Color(0xFF0288D1); // Focus Teal / Sky Blue
      case 2:
        return const Color(0xFF5C6BC0); // Twilight Indigo
      case 1:
      default:
        return const Color(0xFF607D8B); // Slate / Restful Calm
    }
  }

  IconData _getMoodIcon(int level) {
    switch (level) {
      case 5:
        return Icons.sentiment_very_satisfied_rounded;
      case 4:
        return Icons.sentiment_satisfied_rounded;
      case 3:
        return Icons.sentiment_neutral_rounded;
      case 2:
        return Icons.sentiment_dissatisfied_rounded;
      case 1:
      default:
        return Icons.sentiment_very_dissatisfied_rounded;
    }
  }

  Color _getMoodColor(int level) {
    switch (level) {
      case 5:
        return Colors.amber.shade700;
      case 4:
        return Colors.green.shade700;
      case 3:
        return Colors.teal.shade700;
      case 2:
        return Colors.orange.shade800;
      case 1:
      default:
        return Colors.blueGrey;
    }
  }

  String _getMoodLabel(AppLocalizations l10n, int level) {
    switch (level) {
      case 5:
        return l10n.t('moodRadiant');
      case 4:
        return l10n.t('moodGood');
      case 3:
        return l10n.t('moodNeutral');
      case 2:
        return l10n.t('moodLow');
      case 1:
      default:
        return l10n.t('moodDifficult');
    }
  }
}
