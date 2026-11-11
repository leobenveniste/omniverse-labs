import 'dart:convert';

/// Whether a guarded entry is a one-time free trial or an ongoing subscription.
enum ItemKind {
  trial,
  recurring;

  static ItemKind fromName(String? value) => ItemKind.values.firstWhere(
        (e) => e.name == value,
        orElse: () => ItemKind.trial,
      );
}

/// Billing interval used for recurring renewals and display formatting.
enum BillingCycle {
  trialOnce,
  monthly,
  annual;

  static BillingCycle fromName(String? value) => BillingCycle.values.firstWhere(
        (e) => e.name == value,
        orElse: () => BillingCycle.monthly,
      );
}

/// Dual-stage or single-stage "Cancel By" buffer presets before charge date.
enum AlertPreset {
  buffer48And24([48, 24]),
  buffer24Only([24]),
  buffer72And24([72, 24]),
  buffer7dAnd48h([168, 48]);

  const AlertPreset(this.hoursBefore);

  /// Ordered list of lead-time hours before [GuardedItem.chargeAt] to alert.
  final List<int> hoursBefore;

  static AlertPreset fromName(String? value) => AlertPreset.values.firstWhere(
        (e) => e.name == value,
        orElse: () => AlertPreset.buffer48And24,
      );
}

/// Lifecycle state of a guarded trial or subscription.
enum ItemStatus {
  active,
  cancelled;

  static ItemStatus fromName(String? value) => ItemStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => ItemStatus.active,
      );
}

/// Visual urgency tier derived from remaining time before charge.
enum UrgencyLevel {
  expired,
  urgent24h,
  warning48h,
  safe,
}

/// Immutable record representing a tracked free trial or recurring renewal.
class GuardedItem {
  const GuardedItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.kind,
    required this.billingCycle,
    required this.chargeAt,
    required this.alertPreset,
    required this.status,
    required this.createdAt,
    this.cancelUrl = '',
    this.notes = '',
    this.cancelledAt,
  });

  final String id;
  final String name;
  final double amount;
  final ItemKind kind;
  final BillingCycle billingCycle;
  final DateTime chargeAt;
  final AlertPreset alertPreset;
  final ItemStatus status;
  final DateTime createdAt;
  final String cancelUrl;
  final String notes;
  final DateTime? cancelledAt;

  /// Computes urgency relative to [referenceTime] (defaults to `DateTime.now()`).
  UrgencyLevel urgencyAt([DateTime? referenceTime]) {
    final now = referenceTime ?? DateTime.now();
    final remaining = chargeAt.difference(now);
    if (remaining.isNegative) return UrgencyLevel.expired;
    if (remaining.inHours < 24) return UrgencyLevel.urgent24h;
    if (remaining.inHours <= 48) return UrgencyLevel.warning48h;
    return UrgencyLevel.safe;
  }

  /// Returns whether this item charges within the next 30 days.
  bool chargesWithin30Days([DateTime? referenceTime]) {
    if (status != ItemStatus.active) return false;
    final now = referenceTime ?? DateTime.now();
    final diff = chargeAt.difference(now);
    return !diff.isNegative && diff <= const Duration(days: 30);
  }

  /// Returns the earliest alert lead-time in hours for this item.
  int get primaryLeadHours => alertPreset.hoursBefore.first;

  /// Computes the target DateTime for each configured buffer alert.
  List<DateTime> scheduledAlertTimes() {
    return alertPreset.hoursBefore
        .map((hours) => chargeAt.subtract(Duration(hours: hours)))
        .toList(growable: false);
  }

  /// Advances a past-due recurring item forward to its next future billing date.
  GuardedItem advanceRecurringIfDue([DateTime? referenceTime]) {
    if (status != ItemStatus.active || kind != ItemKind.recurring) {
      return this;
    }
    final now = referenceTime ?? DateTime.now();
    var next = chargeAt;
    while (next.isBefore(now)) {
      next = billingCycle == BillingCycle.annual
          ? DateTime(next.year + 1, next.month, next.day, next.hour, next.minute)
          : _addOneMonth(next);
    }
    if (next == chargeAt) return this;
    return copyWith(chargeAt: next);
  }

  static DateTime _addOneMonth(DateTime date) {
    final targetMonth = date.month == 12 ? 1 : date.month + 1;
    final targetYear = date.month == 12 ? date.year + 1 : date.year;
    final maxDay = DateTime(targetYear, targetMonth + 1, 0).day;
    final safeDay = date.day > maxDay ? maxDay : date.day;
    return DateTime(targetYear, targetMonth, safeDay, date.hour, date.minute);
  }

  GuardedItem copyWith({
    String? id,
    String? name,
    double? amount,
    ItemKind? kind,
    BillingCycle? billingCycle,
    DateTime? chargeAt,
    AlertPreset? alertPreset,
    ItemStatus? status,
    DateTime? createdAt,
    String? cancelUrl,
    String? notes,
    DateTime? cancelledAt,
    bool clearCancelledAt = false,
  }) {
    return GuardedItem(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      kind: kind ?? this.kind,
      billingCycle: billingCycle ?? this.billingCycle,
      chargeAt: chargeAt ?? this.chargeAt,
      alertPreset: alertPreset ?? this.alertPreset,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      cancelUrl: cancelUrl ?? this.cancelUrl,
      notes: notes ?? this.notes,
      cancelledAt: clearCancelledAt ? null : (cancelledAt ?? this.cancelledAt),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'kind': kind.name,
      'billingCycle': billingCycle.name,
      'chargeAt': chargeAt.toIso8601String(),
      'alertPreset': alertPreset.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'cancelUrl': cancelUrl,
      'notes': notes,
      'cancelledAt': cancelledAt?.toIso8601String(),
    };
  }

  factory GuardedItem.fromMap(Map<String, dynamic> map) {
    return GuardedItem(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      kind: ItemKind.fromName(map['kind'] as String?),
      billingCycle: BillingCycle.fromName(map['billingCycle'] as String?),
      chargeAt: DateTime.tryParse(map['chargeAt'] as String? ?? '') ??
          DateTime.now().add(const Duration(days: 7)),
      alertPreset: AlertPreset.fromName(map['alertPreset'] as String?),
      status: ItemStatus.fromName(map['status'] as String?),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      cancelUrl: (map['cancelUrl'] as String?)?.trim() ?? '',
      notes: map['notes'] as String? ?? '',
      cancelledAt: map['cancelledAt'] != null
          ? DateTime.tryParse(map['cancelledAt'] as String)
          : null,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory GuardedItem.fromJson(String source) =>
      GuardedItem.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
