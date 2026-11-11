import 'package:flutter/foundation.dart';

/// How an item repeats or gets triggered across completions.
enum LoopRepeatMode {
  fromLastDone,
  fixedDaily,
  fixedWeekly,
  fixedMonthly,
  chainTriggered,
}

/// How a multi-step flow resets after completion or on schedule.
enum FlowResetRule {
  manual,
  onAllComplete,
  scheduledDaily,
  scheduledWeekly,
}

/// Visual priority & confirmation status derived at `now`.
enum ItemUrgency {
  overdue,
  dueSoon,
  recentlyDone,
  scheduled,
}

/// A recurring action, chain step, or flow checklist item tracked locally.
@immutable
class DidItItem {
  const DidItItem({
    required this.id,
    required this.title,
    this.categoryIcon = 'check',
    this.repeatMode = LoopRepeatMode.fromLastDone,
    this.intervalMinutes = 480,
    this.fixedHour = 9,
    this.fixedMinute = 0,
    this.weekdays = const <int>[1, 2, 3, 4, 5, 6, 7],
    this.monthDay = 1,
    this.cooldownMinutes = 0,
    this.chainTargetItemId,
    this.chainDelayMinutes = 0,
    this.flowId,
    this.flowOrder = 0,
    this.flowStepChecked = false,
    this.lastDoneAt,
    this.nextDueAt,
    this.snoozedUntil,
    this.totalCompletions = 0,
    this.notificationsEnabled = true,
  });

  final String id;
  final String title;
  final String categoryIcon;
  final LoopRepeatMode repeatMode;
  final int intervalMinutes;
  final int fixedHour;
  final int fixedMinute;
  final List<int> weekdays;
  final int monthDay;
  final int cooldownMinutes;
  final String? chainTargetItemId;
  final int chainDelayMinutes;
  final String? flowId;
  final int flowOrder;
  final bool flowStepChecked;
  final DateTime? lastDoneAt;
  final DateTime? nextDueAt;
  final DateTime? snoozedUntil;
  final int totalCompletions;
  final bool notificationsEnabled;

  /// Effective time the item is expected next (snooze overrides nextDueAt if later).
  DateTime? get effectiveDueAt {
    if (snoozedUntil == null) return nextDueAt;
    if (nextDueAt == null) return snoozedUntil;
    return snoozedUntil!.isAfter(nextDueAt!) ? snoozedUntil : nextDueAt;
  }

  DidItItem copyWith({
    String? id,
    String? title,
    String? categoryIcon,
    LoopRepeatMode? repeatMode,
    int? intervalMinutes,
    int? fixedHour,
    int? fixedMinute,
    List<int>? weekdays,
    int? monthDay,
    int? cooldownMinutes,
    String? chainTargetItemId,
    bool clearChainTarget = false,
    int? chainDelayMinutes,
    String? flowId,
    bool clearFlowId = false,
    int? flowOrder,
    bool? flowStepChecked,
    DateTime? lastDoneAt,
    bool clearLastDoneAt = false,
    DateTime? nextDueAt,
    bool clearNextDueAt = false,
    DateTime? snoozedUntil,
    bool clearSnoozedUntil = false,
    int? totalCompletions,
    bool? notificationsEnabled,
  }) {
    return DidItItem(
      id: id ?? this.id,
      title: title ?? this.title,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      repeatMode: repeatMode ?? this.repeatMode,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      fixedHour: fixedHour ?? this.fixedHour,
      fixedMinute: fixedMinute ?? this.fixedMinute,
      weekdays: weekdays ?? this.weekdays,
      monthDay: monthDay ?? this.monthDay,
      cooldownMinutes: cooldownMinutes ?? this.cooldownMinutes,
      chainTargetItemId:
          clearChainTarget ? null : (chainTargetItemId ?? this.chainTargetItemId),
      chainDelayMinutes: chainDelayMinutes ?? this.chainDelayMinutes,
      flowId: clearFlowId ? null : (flowId ?? this.flowId),
      flowOrder: flowOrder ?? this.flowOrder,
      flowStepChecked: flowStepChecked ?? this.flowStepChecked,
      lastDoneAt: clearLastDoneAt ? null : (lastDoneAt ?? this.lastDoneAt),
      nextDueAt: clearNextDueAt ? null : (nextDueAt ?? this.nextDueAt),
      snoozedUntil:
          clearSnoozedUntil ? null : (snoozedUntil ?? this.snoozedUntil),
      totalCompletions: totalCompletions ?? this.totalCompletions,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'categoryIcon': categoryIcon,
        'repeatMode': repeatMode.name,
        'intervalMinutes': intervalMinutes,
        'fixedHour': fixedHour,
        'fixedMinute': fixedMinute,
        'weekdays': weekdays,
        'monthDay': monthDay,
        'cooldownMinutes': cooldownMinutes,
        'chainTargetItemId': chainTargetItemId,
        'chainDelayMinutes': chainDelayMinutes,
        'flowId': flowId,
        'flowOrder': flowOrder,
        'flowStepChecked': flowStepChecked,
        'lastDoneAt': lastDoneAt?.toIso8601String(),
        'nextDueAt': nextDueAt?.toIso8601String(),
        'snoozedUntil': snoozedUntil?.toIso8601String(),
        'totalCompletions': totalCompletions,
        'notificationsEnabled': notificationsEnabled,
      };

  factory DidItItem.fromJson(Map<String, dynamic> json) {
    final modeName = json['repeatMode'] as String?;
    final mode = LoopRepeatMode.values.firstWhere(
      (m) => m.name == modeName,
      orElse: () => LoopRepeatMode.fromLastDone,
    );
    final rawDays = json['weekdays'];
    final days = rawDays is List
        ? rawDays.map((e) => (e as num).toInt()).toList()
        : const <int>[1, 2, 3, 4, 5, 6, 7];

    return DidItItem(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Task',
      categoryIcon: json['categoryIcon'] as String? ?? 'check',
      repeatMode: mode,
      intervalMinutes: (json['intervalMinutes'] as num?)?.toInt() ?? 480,
      fixedHour: (json['fixedHour'] as num?)?.toInt() ?? 9,
      fixedMinute: (json['fixedMinute'] as num?)?.toInt() ?? 0,
      weekdays: days.isEmpty ? const <int>[1, 2, 3, 4, 5, 6, 7] : days,
      monthDay: ((json['monthDay'] as num?)?.toInt() ?? 1).clamp(1, 31),
      cooldownMinutes: (json['cooldownMinutes'] as num?)?.toInt() ?? 0,
      chainTargetItemId: json['chainTargetItemId'] as String?,
      chainDelayMinutes: (json['chainDelayMinutes'] as num?)?.toInt() ?? 0,
      flowId: json['flowId'] as String?,
      flowOrder: (json['flowOrder'] as num?)?.toInt() ?? 0,
      flowStepChecked: json['flowStepChecked'] as bool? ?? false,
      lastDoneAt: _parseDate(json['lastDoneAt']),
      nextDueAt: _parseDate(json['nextDueAt']),
      snoozedUntil: _parseDate(json['snoozedUntil']),
      totalCompletions: (json['totalCompletions'] as num?)?.toInt() ?? 0,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
    );
  }
}

/// Grouped checklist template whose steps reset automatically or on demand.
@immutable
class CheckFlow {
  const CheckFlow({
    required this.id,
    required this.title,
    this.iconKey = 'flow',
    this.resetRule = FlowResetRule.onAllComplete,
    this.resetCooldownMinutes = 15,
    this.resetHour = 6,
    this.resetMinute = 0,
    this.resetWeekday = 1,
    this.lastCompletedAt,
    this.nextResetAt,
    this.completedRuns = 0,
  });

  final String id;
  final String title;
  final String iconKey;
  final FlowResetRule resetRule;
  final int resetCooldownMinutes;
  final int resetHour;
  final int resetMinute;
  final int resetWeekday;
  final DateTime? lastCompletedAt;
  final DateTime? nextResetAt;
  final int completedRuns;

  CheckFlow copyWith({
    String? id,
    String? title,
    String? iconKey,
    FlowResetRule? resetRule,
    int? resetCooldownMinutes,
    int? resetHour,
    int? resetMinute,
    int? resetWeekday,
    DateTime? lastCompletedAt,
    bool clearLastCompletedAt = false,
    DateTime? nextResetAt,
    bool clearNextResetAt = false,
    int? completedRuns,
  }) {
    return CheckFlow(
      id: id ?? this.id,
      title: title ?? this.title,
      iconKey: iconKey ?? this.iconKey,
      resetRule: resetRule ?? this.resetRule,
      resetCooldownMinutes: resetCooldownMinutes ?? this.resetCooldownMinutes,
      resetHour: resetHour ?? this.resetHour,
      resetMinute: resetMinute ?? this.resetMinute,
      resetWeekday: resetWeekday ?? this.resetWeekday,
      lastCompletedAt:
          clearLastCompletedAt ? null : (lastCompletedAt ?? this.lastCompletedAt),
      nextResetAt: clearNextResetAt ? null : (nextResetAt ?? this.nextResetAt),
      completedRuns: completedRuns ?? this.completedRuns,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'iconKey': iconKey,
        'resetRule': resetRule.name,
        'resetCooldownMinutes': resetCooldownMinutes,
        'resetHour': resetHour,
        'resetMinute': resetMinute,
        'resetWeekday': resetWeekday,
        'lastCompletedAt': lastCompletedAt?.toIso8601String(),
        'nextResetAt': nextResetAt?.toIso8601String(),
        'completedRuns': completedRuns,
      };

  factory CheckFlow.fromJson(Map<String, dynamic> json) {
    final ruleName = json['resetRule'] as String?;
    final rule = FlowResetRule.values.firstWhere(
      (r) => r.name == ruleName,
      orElse: () => FlowResetRule.onAllComplete,
    );
    return CheckFlow(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Flow',
      iconKey: json['iconKey'] as String? ?? 'flow',
      resetRule: rule,
      resetCooldownMinutes: (json['resetCooldownMinutes'] as num?)?.toInt() ?? 15,
      resetHour: (json['resetHour'] as num?)?.toInt() ?? 6,
      resetMinute: (json['resetMinute'] as num?)?.toInt() ?? 0,
      resetWeekday: ((json['resetWeekday'] as num?)?.toInt() ?? 1).clamp(1, 7),
      lastCompletedAt: _parseDate(json['lastCompletedAt']),
      nextResetAt: _parseDate(json['nextResetAt']),
      completedRuns: (json['completedRuns'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Immutable timestamped proof log entry answering "Did I already do this?".
@immutable
class CompletionEvent {
  const CompletionEvent({
    required this.id,
    required this.itemId,
    required this.itemTitle,
    this.flowTitle,
    required this.completedAt,
    this.source = 'app',
  });

  final String id;
  final String itemId;
  final String itemTitle;
  final String? flowTitle;
  final DateTime completedAt;
  final String source;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'itemId': itemId,
        'itemTitle': itemTitle,
        'flowTitle': flowTitle,
        'completedAt': completedAt.toIso8601String(),
        'source': source,
      };

  factory CompletionEvent.fromJson(Map<String, dynamic> json) {
    return CompletionEvent(
      id: json['id'] as String,
      itemId: json['itemId'] as String,
      itemTitle: json['itemTitle'] as String? ?? 'Task',
      flowTitle: json['flowTitle'] as String?,
      completedAt: _parseDate(json['completedAt']) ?? DateTime.now(),
      source: json['source'] as String? ?? 'app',
    );
  }
}

/// Session snapshot enabling single-tap Undo for recent completions.
@immutable
class UndoRecord {
  const UndoRecord({
    required this.eventId,
    required this.previousItems,
    required this.previousFlows,
  });

  final String eventId;
  final List<DidItItem> previousItems;
  final List<CheckFlow> previousFlows;
}

DateTime? _parseDate(dynamic value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}
