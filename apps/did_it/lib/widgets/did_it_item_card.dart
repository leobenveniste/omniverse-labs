import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../l10n/app_strings.dart';
import '../models/did_it_models.dart';
import '../services/automation_engine.dart';
import '../theme/app_theme.dart';

/// Card representing a recurring action item with instant memory proof and prominent DID IT CTA.
class DidItItemCard extends StatelessWidget {
  const DidItItemCard({
    super.key,
    required this.item,
    required this.now,
    required this.strings,
    required this.defaultSnoozeMinutes,
    required this.onDidIt,
    required this.onSnooze,
    required this.onEdit,
    this.chainTargetTitle,
    this.highlighted = false,
  });

  final DidItItem item;
  final DateTime now;
  final AppStrings strings;
  final int defaultSnoozeMinutes;
  final String? chainTargetTitle;
  final bool highlighted;
  final VoidCallback onDidIt;
  final VoidCallback onSnooze;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final urgency = AutomationEngine.urgencyAt(item, now);
    final inCooldown = AutomationEngine.isInCooldown(item, now);
    final cooldownRem = AutomationEngine.remainingCooldown(item, now);
    final dueAt = item.effectiveDueAt;

    late final Color statusColor;
    late final Color statusTint;
    late final Color statusTextColor;
    String? badgeLabel;

    switch (urgency) {
      case ItemUrgency.overdue:
        statusColor = palette.danger;
        statusTint = palette.dangerTint;
        statusTextColor = palette.dangerText;
        badgeLabel = strings.overdueBadge;
      case ItemUrgency.dueSoon:
        statusColor = palette.warning;
        statusTint = palette.warningTint;
        statusTextColor = palette.warningText;
        badgeLabel = strings.dueSoonBadge;
      case ItemUrgency.recentlyDone:
        statusColor = palette.accentPrimary;
        statusTint = palette.accentTint;
        statusTextColor = palette.accentPrimary;
        badgeLabel = strings.confirmedBadge;
      case ItemUrgency.scheduled:
        statusColor = palette.border;
        statusTint = palette.surfaceElevated;
        statusTextColor = palette.textSecondary;
        if (item.repeatMode == LoopRepeatMode.chainTriggered && dueAt == null) {
          badgeLabel = strings.waitingChainBadge;
        }
    }

    final borderColor = highlighted
        ? palette.accentPrimary
        : (urgency == ItemUrgency.overdue
            ? palette.danger.withValues(alpha: 0.6)
            : palette.border);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: borderColor,
          width: highlighted ? 2.0 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: statusTint,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(
                      DidItIcons.resolve(item.categoryIcon),
                      color: urgency == ItemUrgency.scheduled
                          ? palette.textSecondary
                          : statusColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                item.title,
                                style: AppTypography.title.copyWith(
                                  color: palette.textPrimary,
                                ),
                              ),
                            ),
                            if (badgeLabel != null) ...<Widget>[
                              const SizedBox(width: AppSpacing.sm),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: statusTint,
                                  borderRadius:
                                      BorderRadius.circular(AppSpacing.radiusPill),
                                ),
                                child: Text(
                                  badgeLabel,
                                  style: AppTypography.label.copyWith(
                                    color: statusTextColor,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _buildMemoryLine(),
                          style: AppTypography.body.copyWith(
                            color: urgency == ItemUrgency.recentlyDone
                                ? palette.accentPrimary
                                : palette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (chainTargetTitle != null || inCooldown || dueAt != null) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: <Widget>[
                    _InfoPill(
                      icon: Icons.repeat_rounded,
                      label: _repeatRuleSummary(),
                      palette: palette,
                    ),
                    if (dueAt != null)
                      _InfoPill(
                        icon: Icons.schedule_rounded,
                        label: _dueStatusText(dueAt),
                        palette: palette,
                        highlightColor:
                            urgency == ItemUrgency.overdue ? palette.dangerText : null,
                      ),
                    if (inCooldown)
                      _InfoPill(
                        icon: Icons.lock_clock_outlined,
                        label: strings.cooldownActiveLabel(
                          AutomationEngine.formatDurationCompact(
                            cooldownRem,
                            isEs: strings.isEs,
                          ),
                        ),
                        palette: palette,
                        highlightColor: palette.warningText,
                      ),
                    if (chainTargetTitle != null)
                      _InfoPill(
                        icon: Icons.alt_route_rounded,
                        label: strings.chainPreview(
                          chainTargetTitle!,
                          strings.formatMinutesHuman(item.chainDelayMinutes),
                        ),
                        palette: palette,
                        highlightColor: palette.accentPrimary,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Row(
                children: <Widget>[
                  if (dueAt != null && !dueAt.isAfter(now.add(const Duration(hours: 2))))
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: OutlinedButton.icon(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          onSnooze();
                        },
                        icon: const Icon(Icons.snooze_rounded, size: 16),
                        label: Text(strings.snoozeMinutesLabel(defaultSnoozeMinutes)),
                      ),
                    ),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        onDidIt();
                      },
                      style: urgency == ItemUrgency.recentlyDone && inCooldown
                          ? FilledButton.styleFrom(
                              backgroundColor: palette.surfaceElevated,
                              foregroundColor: palette.textPrimary,
                            )
                          : null,
                      icon: Icon(
                        inCooldown
                            ? Icons.verified_rounded
                            : Icons.check_rounded,
                        size: 20,
                      ),
                      label: Text(strings.didItCta),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildMemoryLine() {
    final last = item.lastDoneAt;
    if (last == null) return strings.neverDoneLabel();
    final elapsed = AutomationEngine.formatDurationCompact(
      now.difference(last),
      isEs: strings.isEs,
    );
    final clock = DateFormat.Hm().format(last);
    return '${strings.doneAgoLabel(elapsed)} ($clock)';
  }

  String _dueStatusText(DateTime dueAt) {
    if (item.snoozedUntil != null && !item.snoozedUntil!.isBefore(dueAt)) {
      return strings.snoozedUntilLabel(DateFormat.Hm().format(dueAt));
    }
    if (!dueAt.isAfter(now)) {
      return strings.dueAgoLabel(
        AutomationEngine.formatDurationCompact(
          now.difference(dueAt),
          isEs: strings.isEs,
        ),
      );
    }
    return strings.nextInLabel(
      AutomationEngine.formatDurationCompact(
        dueAt.difference(now),
        isEs: strings.isEs,
      ),
    );
  }

  String _repeatRuleSummary() {
    final hhmm = '${item.fixedHour.toString().padLeft(2, '0')}:'
        '${item.fixedMinute.toString().padLeft(2, '0')}';
    switch (item.repeatMode) {
      case LoopRepeatMode.fromLastDone:
        return '${strings.repeatFromLastDone} · ${strings.formatMinutesHuman(item.intervalMinutes)}';
      case LoopRepeatMode.fixedDaily:
        return '${strings.repeatDaily} · $hhmm';
      case LoopRepeatMode.fixedWeekly:
        return '${strings.repeatWeekly} · $hhmm';
      case LoopRepeatMode.fixedMonthly:
        return '${strings.repeatMonthly} (${item.monthDay}) · $hhmm';
      case LoopRepeatMode.chainTriggered:
        return strings.repeatChainOnly;
    }
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.palette,
    this.highlightColor,
  });

  final IconData icon;
  final String label;
  final AppPalette palette;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final fg = highlightColor ?? palette.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.label.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}
