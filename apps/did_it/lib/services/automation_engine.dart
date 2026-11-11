import '../models/did_it_models.dart';

/// Pure deterministic engine powering intervals, calendar rollovers, chains, cooldowns, and flows.
abstract final class AutomationEngine {
  /// Returns the next due timestamp after [completedAt] for [item], or null if chain-only.
  static DateTime? computeNextDueAt(DidItItem item, DateTime completedAt) {
    switch (item.repeatMode) {
      case LoopRepeatMode.fromLastDone:
        final mins = item.intervalMinutes < 1 ? 1 : item.intervalMinutes;
        return completedAt.add(Duration(minutes: mins));

      case LoopRepeatMode.fixedDaily:
        var candidate = DateTime(
          completedAt.year,
          completedAt.month,
          completedAt.day,
          item.fixedHour,
          item.fixedMinute,
        );
        if (!candidate.isAfter(completedAt)) {
          candidate = candidate.add(const Duration(days: 1));
        }
        return candidate;

      case LoopRepeatMode.fixedWeekly:
        final activeDays = item.weekdays.isEmpty
            ? const <int>[1, 2, 3, 4, 5, 6, 7]
            : item.weekdays;
        for (var offset = 0; offset <= 7; offset++) {
          final day = completedAt.add(Duration(days: offset));
          if (!activeDays.contains(day.weekday)) continue;
          final candidate = DateTime(
            day.year,
            day.month,
            day.day,
            item.fixedHour,
            item.fixedMinute,
          );
          if (candidate.isAfter(completedAt)) {
            return candidate;
          }
        }
        return completedAt.add(const Duration(days: 7));

      case LoopRepeatMode.fixedMonthly:
        var candidate = _clampedMonthlyDate(
          completedAt.year,
          completedAt.month,
          item.monthDay,
          item.fixedHour,
          item.fixedMinute,
        );
        if (!candidate.isAfter(completedAt)) {
          final nextMonth = completedAt.month == 12 ? 1 : completedAt.month + 1;
          final nextYear =
              completedAt.month == 12 ? completedAt.year + 1 : completedAt.year;
          candidate = _clampedMonthlyDate(
            nextYear,
            nextMonth,
            item.monthDay,
            item.fixedHour,
            item.fixedMinute,
          );
        }
        return candidate;

      case LoopRepeatMode.chainTriggered:
        return null;
    }
  }

  static DateTime _clampedMonthlyDate(
    int year,
    int month,
    int desiredDay,
    int hour,
    int minute,
  ) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final safeDay = desiredDay.clamp(1, daysInMonth);
    return DateTime(year, month, safeDay, hour, minute);
  }

  /// True when [item] was marked Done inside its anti-double-tap cooldown window.
  static bool isInCooldown(DidItItem item, DateTime now) {
    if (item.cooldownMinutes <= 0 || item.lastDoneAt == null) return false;
    final unlockAt =
        item.lastDoneAt!.add(Duration(minutes: item.cooldownMinutes));
    return now.isBefore(unlockAt);
  }

  static Duration remainingCooldown(DidItItem item, DateTime now) {
    if (!isInCooldown(item, now)) return Duration.zero;
    return item.lastDoneAt!
        .add(Duration(minutes: item.cooldownMinutes))
        .difference(now);
  }

  static ItemUrgency urgencyAt(DidItItem item, DateTime now) {
    final due = item.effectiveDueAt;
    if (due != null) {
      if (!due.isAfter(now)) return ItemUrgency.overdue;
      if (due.difference(now) <= const Duration(minutes: 60)) {
        return ItemUrgency.dueSoon;
      }
    }
    if (item.lastDoneAt != null &&
        now.difference(item.lastDoneAt!) <= const Duration(hours: 12)) {
      return ItemUrgency.recentlyDone;
    }
    return ItemUrgency.scheduled;
  }

  /// Applies a completion transition cleanly, advancing intervals, chains, and flow resets.
  static CompletionTransitionResult applyCompletion({
    required List<DidItItem> items,
    required List<CheckFlow> flows,
    required String itemId,
    required DateTime now,
    required String eventId,
    String source = 'app',
  }) {
    final updatedItems = List<DidItItem>.from(items);
    final updatedFlows = List<CheckFlow>.from(flows);
    final rescheduleIds = <String>{itemId};

    final idx = updatedItems.indexWhere((i) => i.id == itemId);
    if (idx < 0) {
      throw ArgumentError('Item $itemId not found');
    }

    final current = updatedItems[idx];
    final nextDue = computeNextDueAt(current, now);
    final completed = current.copyWith(
      lastDoneAt: now,
      nextDueAt: nextDue,
      clearNextDueAt: nextDue == null,
      clearSnoozedUntil: true,
      flowStepChecked: current.flowId != null ? true : current.flowStepChecked,
      totalCompletions: current.totalCompletions + 1,
    );
    updatedItems[idx] = completed;

    String? flowTitle;
    String? triggeredChainTitle;

    // 1. Trigger downstream chained item if configured.
    final targetId = current.chainTargetItemId;
    if (targetId != null && targetId != current.id) {
      final tIdx = updatedItems.indexWhere((i) => i.id == targetId);
      if (tIdx >= 0) {
        final target = updatedItems[tIdx];
        final delay = current.chainDelayMinutes < 0 ? 0 : current.chainDelayMinutes;
        final chainDueAt = now.add(Duration(minutes: delay));
        updatedItems[tIdx] = target.copyWith(
          nextDueAt: chainDueAt,
          clearSnoozedUntil: true,
        );
        triggeredChainTitle = target.title;
        rescheduleIds.add(targetId);
      }
    }

    // 2. Progress parent CheckFlow & handle auto-reset if all steps are complete.
    if (current.flowId != null) {
      final fIdx = updatedFlows.indexWhere((f) => f.id == current.flowId);
      if (fIdx >= 0) {
        final flow = updatedFlows[fIdx];
        flowTitle = flow.title;
        final stepIndices = <int>[];
        for (var i = 0; i < updatedItems.length; i++) {
          if (updatedItems[i].flowId == flow.id) {
            stepIndices.add(i);
          }
        }
        final allChecked = stepIndices.isNotEmpty &&
            stepIndices.every((i) => updatedItems[i].flowStepChecked);

        if (allChecked) {
          if (flow.resetRule == FlowResetRule.onAllComplete &&
              flow.resetCooldownMinutes <= 0) {
            for (final si in stepIndices) {
              updatedItems[si] = updatedItems[si].copyWith(flowStepChecked: false);
            }
            updatedFlows[fIdx] = flow.copyWith(
              lastCompletedAt: now,
              clearNextResetAt: true,
              completedRuns: flow.completedRuns + 1,
            );
          } else if (flow.resetRule == FlowResetRule.onAllComplete) {
            updatedFlows[fIdx] = flow.copyWith(
              lastCompletedAt: now,
              nextResetAt: now.add(Duration(minutes: flow.resetCooldownMinutes)),
              completedRuns: flow.completedRuns + 1,
            );
          } else {
            final nextReset = _computeFlowNextReset(flow, now);
            updatedFlows[fIdx] = flow.copyWith(
              lastCompletedAt: now,
              nextResetAt: nextReset,
              clearNextResetAt: nextReset == null,
              completedRuns: flow.completedRuns + 1,
            );
          }
        }
      }
    }

    final event = CompletionEvent(
      id: eventId,
      itemId: current.id,
      itemTitle: current.title,
      flowTitle: flowTitle,
      completedAt: now,
      source: source,
    );

    return CompletionTransitionResult(
      items: updatedItems,
      flows: updatedFlows,
      event: event,
      rescheduleItemIds: rescheduleIds.toList(),
      triggeredChainTitle: triggeredChainTitle,
    );
  }

  /// Processes scheduled flow resets whose `nextResetAt` has passed at [now].
  static FlowResetSweepResult applyDueFlowResets({
    required List<DidItItem> items,
    required List<CheckFlow> flows,
    required DateTime now,
  }) {
    var changed = false;
    final updatedItems = List<DidItItem>.from(items);
    final updatedFlows = List<CheckFlow>.from(flows);

    for (var fi = 0; fi < updatedFlows.length; fi++) {
      final flow = updatedFlows[fi];
      var shouldReset = false;

      if (flow.nextResetAt != null && !flow.nextResetAt!.isAfter(now)) {
        shouldReset = true;
      } else if (flow.resetRule == FlowResetRule.scheduledDaily ||
          flow.resetRule == FlowResetRule.scheduledWeekly) {
        final anchor = flow.lastCompletedAt;
        final scheduledSlot = _mostRecentScheduledSlot(flow, now);
        final hasAnyChecked = updatedItems.any(
          (item) => item.flowId == flow.id && item.flowStepChecked,
        );
        if (hasAnyChecked &&
            scheduledSlot != null &&
            (anchor == null || anchor.isBefore(scheduledSlot))) {
          shouldReset = true;
        }
      }

      if (shouldReset) {
        changed = true;
        for (var ii = 0; ii < updatedItems.length; ii++) {
          if (updatedItems[ii].flowId == flow.id) {
            updatedItems[ii] = updatedItems[ii].copyWith(flowStepChecked: false);
          }
        }
        updatedFlows[fi] = flow.copyWith(
          nextResetAt: _computeFlowNextReset(flow, now),
          clearNextResetAt: flow.resetRule == FlowResetRule.onAllComplete ||
              flow.resetRule == FlowResetRule.manual,
        );
      }
    }

    return FlowResetSweepResult(
      items: updatedItems,
      flows: updatedFlows,
      changed: changed,
    );
  }

  /// Manually resets all step check states of [flowId].
  static FlowResetSweepResult resetFlowManually({
    required List<DidItItem> items,
    required List<CheckFlow> flows,
    required String flowId,
  }) {
    final updatedItems = items
        .map(
          (i) => i.flowId == flowId ? i.copyWith(flowStepChecked: false) : i,
        )
        .toList();
    final updatedFlows = flows
        .map((f) => f.id == flowId ? f.copyWith(clearNextResetAt: true) : f)
        .toList();
    return FlowResetSweepResult(
      items: updatedItems,
      flows: updatedFlows,
      changed: true,
    );
  }

  static DateTime? _computeFlowNextReset(CheckFlow flow, DateTime now) {
    switch (flow.resetRule) {
      case FlowResetRule.manual:
      case FlowResetRule.onAllComplete:
        return null;
      case FlowResetRule.scheduledDaily:
        var candidate =
            DateTime(now.year, now.month, now.day, flow.resetHour, flow.resetMinute);
        if (!candidate.isAfter(now)) {
          candidate = candidate.add(const Duration(days: 1));
        }
        return candidate;
      case FlowResetRule.scheduledWeekly:
        for (var offset = 0; offset <= 7; offset++) {
          final day = now.add(Duration(days: offset));
          if (day.weekday != flow.resetWeekday) continue;
          final candidate = DateTime(
            day.year,
            day.month,
            day.day,
            flow.resetHour,
            flow.resetMinute,
          );
          if (candidate.isAfter(now)) return candidate;
        }
        return now.add(const Duration(days: 7));
    }
  }

  static DateTime? _mostRecentScheduledSlot(CheckFlow flow, DateTime now) {
    if (flow.resetRule == FlowResetRule.scheduledDaily) {
      var candidate =
          DateTime(now.year, now.month, now.day, flow.resetHour, flow.resetMinute);
      if (candidate.isAfter(now)) {
        candidate = candidate.subtract(const Duration(days: 1));
      }
      return candidate;
    }
    if (flow.resetRule == FlowResetRule.scheduledWeekly) {
      for (var offset = 0; offset <= 7; offset++) {
        final day = now.subtract(Duration(days: offset));
        if (day.weekday != flow.resetWeekday) continue;
        final candidate = DateTime(
          day.year,
          day.month,
          day.day,
          flow.resetHour,
          flow.resetMinute,
        );
        if (!candidate.isAfter(now)) return candidate;
      }
    }
    return null;
  }

  static String formatDurationCompact(Duration d, {required bool isEs}) {
    final absSecs = d.inSeconds.abs();
    if (absSecs < 60) return isEs ? '0m' : '0m';
    final totalMins = absSecs ~/ 60;
    if (totalMins < 60) return '${totalMins}m';
    final hours = totalMins ~/ 60;
    if (hours < 24) {
      final remMins = totalMins % 60;
      return remMins == 0 ? '${hours}h' : '${hours}h ${remMins}m';
    }
    final days = hours ~/ 24;
    final remHours = hours % 24;
    return remHours == 0 ? '${days}d' : '${days}d ${remHours}h';
  }
}

class CompletionTransitionResult {
  const CompletionTransitionResult({
    required this.items,
    required this.flows,
    required this.event,
    required this.rescheduleItemIds,
    this.triggeredChainTitle,
  });

  final List<DidItItem> items;
  final List<CheckFlow> flows;
  final CompletionEvent event;
  final List<String> rescheduleItemIds;
  final String? triggeredChainTitle;
}

class FlowResetSweepResult {
  const FlowResetSweepResult({
    required this.items,
    required this.flows,
    required this.changed,
  });

  final List<DidItItem> items;
  final List<CheckFlow> flows;
  final bool changed;
}
