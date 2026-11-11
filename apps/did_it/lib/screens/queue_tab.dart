import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/did_it_models.dart';
import '../services/automation_engine.dart';
import '../services/did_it_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/did_it_item_card.dart';
import '../widgets/item_editor_sheet.dart';

/// Primary Queue view organized by Due Now / Recently Done Proof / Upcoming & Chains.
class QueueTab extends StatelessWidget {
  const QueueTab({
    super.key,
    required this.controller,
    required this.onDidItRequested,
    required this.onJumpToTemplates,
  });

  final DidItController controller;
  final ValueChanged<DidItItem> onDidItRequested;
  final VoidCallback onJumpToTemplates;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final s = controller.strings;
    final now = controller.now;
    final query = controller.searchQuery.trim().toLowerCase();

    final standalone = controller.items
        .where((item) => item.flowId == null)
        .where((item) => query.isEmpty || item.title.toLowerCase().contains(query))
        .toList();

    final titleById = <String, String>{
      for (final i in controller.items) i.id: i.title,
    };

    final dueNow = <DidItItem>[];
    final recentlyDone = <DidItItem>[];
    final upcoming = <DidItItem>[];

    for (final item in standalone) {
      final urgency = AutomationEngine.urgencyAt(item, now);
      if (urgency == ItemUrgency.overdue || urgency == ItemUrgency.dueSoon) {
        dueNow.add(item);
      } else if (urgency == ItemUrgency.recentlyDone) {
        recentlyDone.add(item);
      } else {
        upcoming.add(item);
      }
    }

    dueNow.sort((a, b) {
      final ad = a.effectiveDueAt ?? now;
      final bd = b.effectiveDueAt ?? now;
      return ad.compareTo(bd);
    });
    recentlyDone.sort((a, b) => (b.lastDoneAt ?? now).compareTo(a.lastDoneAt ?? now));
    upcoming.sort((a, b) {
      final ad = a.effectiveDueAt;
      final bd = b.effectiveDueAt;
      if (ad == null && bd == null) return a.title.compareTo(b.title);
      if (ad == null) return 1;
      if (bd == null) return -1;
      return ad.compareTo(bd);
    });

    final todayStart = DateTime(now.year, now.month, now.day);
    final doneTodayCount = controller.history
        .where((h) => !h.completedAt.isBefore(todayStart))
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.sm,
        AppSpacing.base,
        96,
      ),
      children: <Widget>[
        _MemorySummaryBanner(
          palette: palette,
          strings: s,
          dueCount: dueNow.length,
          doneTodayCount: doneTodayCount,
        ),
        const SizedBox(height: AppSpacing.base),
        if (standalone.isEmpty)
          _EmptyQueueCard(
            palette: palette,
            strings: s,
            onJumpToTemplates: onJumpToTemplates,
          )
        else ...<Widget>[
          if (dueNow.isNotEmpty) ...<Widget>[
            _SectionHeader(label: s.sectionDueNow, count: dueNow.length),
            const SizedBox(height: AppSpacing.sm),
            ...dueNow.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: DidItItemCard(
                  key: ValueKey<String>(item.id),
                  item: item,
                  now: now,
                  strings: s,
                  defaultSnoozeMinutes: controller.defaultSnoozeMinutes,
                  chainTargetTitle: item.chainTargetItemId != null
                      ? titleById[item.chainTargetItemId]
                      : null,
                  highlighted: controller.highlightedItemId == item.id,
                  onDidIt: () => onDidItRequested(item),
                  onSnooze: () => _snoozeWithFeedback(context, item, s),
                  onEdit: () => _openEditor(context, item, s),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (recentlyDone.isNotEmpty) ...<Widget>[
            _SectionHeader(
              label: s.sectionRecentlyDone,
              count: recentlyDone.length,
            ),
            const SizedBox(height: AppSpacing.sm),
            ...recentlyDone.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: DidItItemCard(
                  key: ValueKey<String>(item.id),
                  item: item,
                  now: now,
                  strings: s,
                  defaultSnoozeMinutes: controller.defaultSnoozeMinutes,
                  chainTargetTitle: item.chainTargetItemId != null
                      ? titleById[item.chainTargetItemId]
                      : null,
                  highlighted: controller.highlightedItemId == item.id,
                  onDidIt: () => onDidItRequested(item),
                  onSnooze: () => _snoozeWithFeedback(context, item, s),
                  onEdit: () => _openEditor(context, item, s),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (upcoming.isNotEmpty) ...<Widget>[
            _SectionHeader(label: s.sectionUpcoming, count: upcoming.length),
            const SizedBox(height: AppSpacing.sm),
            ...upcoming.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: DidItItemCard(
                  key: ValueKey<String>(item.id),
                  item: item,
                  now: now,
                  strings: s,
                  defaultSnoozeMinutes: controller.defaultSnoozeMinutes,
                  chainTargetTitle: item.chainTargetItemId != null
                      ? titleById[item.chainTargetItemId]
                      : null,
                  highlighted: controller.highlightedItemId == item.id,
                  onDidIt: () => onDidItRequested(item),
                  onSnooze: () => _snoozeWithFeedback(context, item, s),
                  onEdit: () => _openEditor(context, item, s),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Future<void> _snoozeWithFeedback(
    BuildContext context,
    DidItItem item,
    AppStrings s,
  ) async {
    final mins = controller.defaultSnoozeMinutes;
    await controller.snoozeItem(item.id, mins);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(s.snoozedToast(item.title, mins))));
    }
  }

  void _openEditor(BuildContext context, DidItItem item, AppStrings s) {
    ItemEditorSheet.show(
      context,
      strings: s,
      existingItems: controller.items,
      initialItem: item,
      onSave: controller.saveItem,
      onDelete: () => controller.deleteItem(item.id),
    );
  }
}

class _MemorySummaryBanner extends StatelessWidget {
  const _MemorySummaryBanner({
    required this.palette,
    required this.strings,
    required this.dueCount,
    required this.doneTodayCount,
  });

  final AppPalette palette;
  final AppStrings strings;
  final int dueCount;
  final int doneTodayCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: palette.accentTint,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  child: Text(
                    strings.memoryBadge,
                    style: AppTypography.label
                        .copyWith(color: palette.accentPrimary),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  strings.summaryLine(dueCount, doneTodayCount),
                  style: AppTypography.title.copyWith(color: palette.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Row(
      children: <Widget>[
        Text(
          label,
          style: AppTypography.label.copyWith(color: palette.textSecondary),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '($count)',
          style: AppTypography.label.copyWith(color: palette.textSecondary),
        ),
      ],
    );
  }
}

class _EmptyQueueCard extends StatelessWidget {
  const _EmptyQueueCard({
    required this.palette,
    required this.strings,
    required this.onJumpToTemplates,
  });

  final AppPalette palette;
  final AppStrings strings;
  final VoidCallback onJumpToTemplates;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: <Widget>[
          Icon(
            Icons.verified_rounded,
            size: 40,
            color: palette.accentPrimary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            strings.emptyQueueTitle,
            style: AppTypography.title.copyWith(color: palette.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            strings.emptyQueueSubtitle,
            style: AppTypography.body.copyWith(color: palette.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.base),
          OutlinedButton.icon(
            onPressed: onJumpToTemplates,
            icon: const Icon(Icons.auto_awesome_rounded, size: 18),
            label: Text(strings.flowsTab),
          ),
        ],
      ),
    );
  }
}
