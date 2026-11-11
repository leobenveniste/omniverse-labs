import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../l10n/app_strings.dart';
import '../models/guarded_item.dart';
import 'alert_scheduler.dart';
import 'vault_storage.dart';

/// Central offline state coordinator for CancelGuard.
class VaultController extends ChangeNotifier {
  VaultController({
    required VaultStorage storage,
    required AlertScheduler scheduler,
    DateTime Function()? clock,
  }) : this._internal(storage, scheduler, clock ?? DateTime.now);

  VaultController._internal(
    this._storage,
    this._scheduler,
    this._clock,
  );

  static const double appPurchasePrice = 1.49;
  static const Uuid _uuid = Uuid();

  final VaultStorage _storage;
  final AlertScheduler _scheduler;
  final DateTime Function() _clock;

  List<GuardedItem> _items = [];
  double _totalSaved = 0.0;
  String _currency = r'$';
  AppLocale _locale = AppLocale.en;
  ThemeMode _themeMode = ThemeMode.dark;
  bool _notificationsEnabled = true;
  String? _highlightedItemId;

  AppStrings get strings => AppStrings(_locale);
  AppLocale get locale => _locale;
  ThemeMode get themeMode => _themeMode;
  String get currency => _currency;
  double get totalSaved => _totalSaved;
  double get roiMultiplier => _totalSaved / appPurchasePrice;
  bool get notificationsEnabled => _notificationsEnabled;
  String? get highlightedItemId => _highlightedItemId;

  /// Active guarded items sorted earliest charge date first.
  List<GuardedItem> get activeItems {
    final list = _items
        .where((e) => e.status == ItemStatus.active)
        .toList(growable: false);
    list.sort((a, b) => a.chargeAt.compareTo(b.chargeAt));
    return list;
  }

  /// Active items inside the 48-hour cancel window (or already due).
  List<GuardedItem> get urgentActiveItems {
    final now = _clock();
    return activeItems.where((item) {
      final urgency = item.urgencyAt(now);
      return urgency == UrgencyLevel.expired ||
          urgency == UrgencyLevel.urgent24h ||
          urgency == UrgencyLevel.warning48h;
    }).toList(growable: false);
  }

  /// Active items still outside the 48-hour cancel window.
  List<GuardedItem> get safeActiveItems {
    final now = _clock();
    return activeItems
        .where((item) => item.urgencyAt(now) == UrgencyLevel.safe)
        .toList(growable: false);
  }

  /// Cancelled items sorted most recently cancelled first.
  List<GuardedItem> get historyItems {
    final list = _items
        .where((e) => e.status == ItemStatus.cancelled)
        .toList(growable: false);
    list.sort((a, b) {
      final bTime = b.cancelledAt ?? b.chargeAt;
      final aTime = a.cancelledAt ?? a.chargeAt;
      return bTime.compareTo(aTime);
    });
    return list;
  }

  /// Total amount exposed across active items charging within 30 days.
  double get atRiskNext30Days {
    final now = _clock();
    return activeItems
        .where((e) => e.chargesWithin30Days(now))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  /// Loads persisted vault state, rolls recurring dates forward, and binds alerts.
  Future<void> initialize() async {
    final snapshot = _storage.load();
    _totalSaved = snapshot.totalSaved;
    _currency = snapshot.currency;
    _locale = snapshot.locale;
    _themeMode = snapshot.themeMode;

    final now = _clock();
    var rolledAny = false;
    _items = snapshot.items.map((item) {
      final updated = item.advanceRecurringIfDue(now);
      if (updated.chargeAt != item.chargeAt) rolledAny = true;
      return updated;
    }).toList();

    if (rolledAny) {
      await _storage.saveItems(_items);
    }

    await _scheduler.init(onTapItem: highlightItem);
    _notificationsEnabled = await _scheduler.areNotificationsEnabled();

    final launchId = await _scheduler.getLaunchItemId();
    if (launchId != null) {
      _highlightedItemId = launchId;
    }

    for (final item in activeItems) {
      await _scheduler.scheduleForItem(
        item,
        currency: _currency,
        strings: strings,
      );
    }
    notifyListeners();
  }

  void highlightItem(String itemId) {
    _highlightedItemId = itemId;
    notifyListeners();
  }

  void clearHighlight() {
    if (_highlightedItemId == null) return;
    _highlightedItemId = null;
    notifyListeners();
  }

  Future<bool> requestNotificationPermission() async {
    final granted = await _scheduler.requestPermissions();
    _notificationsEnabled =
        granted || await _scheduler.areNotificationsEnabled();
    if (_notificationsEnabled) {
      for (final item in activeItems) {
        await _scheduler.scheduleForItem(
          item,
          currency: _currency,
          strings: strings,
        );
      }
    }
    notifyListeners();
    return _notificationsEnabled;
  }

  Future<GuardedItem> addItem({
    required String name,
    required double amount,
    required ItemKind kind,
    required BillingCycle billingCycle,
    required DateTime chargeAt,
    required AlertPreset alertPreset,
    String cancelUrl = '',
    String notes = '',
  }) async {
    final item = GuardedItem(
      id: _uuid.v4(),
      name: name.trim(),
      amount: amount,
      kind: kind,
      billingCycle: billingCycle,
      chargeAt: chargeAt,
      alertPreset: alertPreset,
      status: ItemStatus.active,
      createdAt: _clock(),
      cancelUrl: cancelUrl.trim(),
      notes: notes.trim(),
    );

    _items.add(item);
    await _storage.saveItems(_items);
    await _scheduler.scheduleForItem(
      item,
      currency: _currency,
      strings: strings,
    );
    notifyListeners();
    return item;
  }

  Future<void> updateItem(GuardedItem updated) async {
    final index = _items.indexWhere((e) => e.id == updated.id);
    if (index == -1) return;
    _items[index] = updated;
    await _storage.saveItems(_items);
    await _scheduler.scheduleForItem(
      updated,
      currency: _currency,
      strings: strings,
    );
    notifyListeners();
  }

  /// Marks an active item cancelled and banks its avoided charge into [totalSaved].
  Future<void> markCancelled(String id) async {
    final index = _items.indexWhere((e) => e.id == id);
    if (index == -1) return;
    final current = _items[index];
    if (current.status == ItemStatus.cancelled) return;

    final cancelled = current.copyWith(
      status: ItemStatus.cancelled,
      cancelledAt: _clock(),
    );
    _items[index] = cancelled;
    _totalSaved += cancelled.amount;

    await _storage.saveItems(_items);
    await _storage.saveTotalSaved(_totalSaved);
    await _scheduler.cancelForItem(cancelled);
    notifyListeners();
  }

  /// Restores a cancelled item back into active protection and reverses its banked ROI.
  Future<void> restoreItem(String id) async {
    final index = _items.indexWhere((e) => e.id == id);
    if (index == -1) return;
    final current = _items[index];
    if (current.status == ItemStatus.active) return;

    final restored = current.copyWith(
      status: ItemStatus.active,
      clearCancelledAt: true,
    );
    _items[index] = restored;
    _totalSaved = (_totalSaved - restored.amount).clamp(0.0, double.infinity);

    await _storage.saveItems(_items);
    await _storage.saveTotalSaved(_totalSaved);
    await _scheduler.scheduleForItem(
      restored,
      currency: _currency,
      strings: strings,
    );
    notifyListeners();
  }

  Future<void> deleteItem(String id) async {
    final index = _items.indexWhere((e) => e.id == id);
    if (index == -1) return;
    final removed = _items.removeAt(index);
    await _storage.saveItems(_items);
    await _scheduler.cancelForItem(removed);
    notifyListeners();
  }

  Future<void> setCurrency(String next) async {
    if (_currency == next) return;
    _currency = next;
    await _storage.saveCurrency(next);
    notifyListeners();
  }

  Future<void> setLocale(AppLocale next) async {
    if (_locale == next) return;
    _locale = next;
    await _storage.saveLocale(next);
    for (final item in activeItems) {
      await _scheduler.scheduleForItem(
        item,
        currency: _currency,
        strings: strings,
      );
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode next) async {
    if (_themeMode == next) return;
    _themeMode = next;
    await _storage.saveThemeMode(next);
    notifyListeners();
  }
}
