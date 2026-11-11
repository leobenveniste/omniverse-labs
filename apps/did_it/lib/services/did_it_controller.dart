// ignore_for_file: prefer_initializing_formals
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../l10n/app_strings.dart';
import '../models/did_it_models.dart';
import '../models/starter_templates.dart';
import 'automation_engine.dart';
import 'did_it_scheduler.dart';
import 'did_it_storage.dart';

/// Main application controller orchestrating Queue, Flows, Chains, Proof Logbook, and Preferences.
class DidItController extends ChangeNotifier {
  DidItController({
    required DidItStorage storage,
    required DidItScheduler scheduler,
    DateTime Function()? clock,
  })  : _storage = storage,
        _scheduler = scheduler,
        _clock = clock ?? DateTime.now;

  static const Uuid _uuid = Uuid();
  final DidItStorage _storage;
  final DidItScheduler _scheduler;
  final DateTime Function() _clock;

  List<DidItItem> _items = <DidItItem>[];
  List<CheckFlow> _flows = <CheckFlow>[];
  List<CompletionEvent> _history = <CompletionEvent>[];
  final List<UndoRecord> _undoStack = <UndoRecord>[];

  ThemeMode _themeMode = ThemeMode.dark;
  String _localeCode = 'en';
  int _defaultSnoozeMinutes = 30;
  bool _notificationsEnabled = true;
  String _searchQuery = '';
  Timer? _minuteTicker;
  String? _highlightedItemId;

  List<DidItItem> get items => List<DidItItem>.unmodifiable(_items);
  List<CheckFlow> get flows => List<CheckFlow>.unmodifiable(_flows);
  List<CompletionEvent> get history => List<CompletionEvent>.unmodifiable(_history);
  ThemeMode get themeMode => _themeMode;
  String get localeCode => _localeCode;
  int get defaultSnoozeMinutes => _defaultSnoozeMinutes;
  bool get notificationsEnabled => _notificationsEnabled;
  String get searchQuery => _searchQuery;
  String? get highlightedItemId => _highlightedItemId;
  AppStrings get strings => AppStrings.of(_localeCode);
  DateTime get now => _clock();

  Future<void> initialize() async {
    final snapshot = _storage.loadSnapshot();
    _items = snapshot.items;
    _flows = snapshot.flows;
    _history = snapshot.history;
    _themeMode = snapshot.themeMode;
    _localeCode = snapshot.localeCode;
    _defaultSnoozeMinutes = snapshot.defaultSnoozeMinutes;

    // Seed initial helpful example items on very first run so Queue is immediately actionable
    if (!snapshot.seededDemo && _items.isEmpty && _flows.isEmpty) {
      await _seedStarterState();
      await _storage.markSeeded();
    }

    await _scheduler.init(onAction: _handleNotificationAction);
    _notificationsEnabled = await _scheduler.areNotificationsEnabled();

    final sweep = AutomationEngine.applyDueFlowResets(
      items: _items,
      flows: _flows,
      now: now,
    );
    if (sweep.changed) {
      _items = sweep.items;
      _flows = sweep.flows;
      await _persist();
    }

    final launch = await _scheduler.getLaunchAction();
    if (launch != null) {
      await _handleNotificationAction(launch.itemId, launch.actionId);
    }

    await _rescheduleAll();

    _minuteTicker?.cancel();
    _minuteTicker = Timer.periodic(const Duration(minutes: 1), (_) {
      unawaited(refreshClockAndResets());
    });
    notifyListeners();
  }

  Future<void> _seedStarterState() async {
    final current = now;
    final dose = StarterTemplates.instantiate('dose_guard', isEs: false, now: current);
    final leaving = StarterTemplates.instantiate('leaving_home', isEs: false, now: current);
    _items = <DidItItem>[...dose.items, ...leaving.items];
    if (leaving.flow != null) {
      _flows = <CheckFlow>[leaving.flow!];
    }
    await _persist();
  }

  Future<void> reloadFromDisk() async {
    await _storage.reload();
    final snapshot = _storage.loadSnapshot();
    _items = snapshot.items;
    _flows = snapshot.flows;
    _history = snapshot.history;
    await refreshClockAndResets();
  }

  Future<void> refreshClockAndResets() async {
    final sweep = AutomationEngine.applyDueFlowResets(
      items: _items,
      flows: _flows,
      now: now,
    );
    if (sweep.changed) {
      _items = sweep.items;
      _flows = sweep.flows;
      await _persist();
    }
    notifyListeners();
  }

  Future<void> _handleNotificationAction(String itemId, String? actionId) async {
    await reloadFromDisk();
    if (actionId == kDidItActionDone) {
      await markDone(itemId, forceCooldown: true, source: 'notification');
    } else if (actionId == kDidItActionSnooze) {
      await snoozeItem(itemId, _defaultSnoozeMinutes);
    } else {
      _highlightedItemId = itemId;
      notifyListeners();
    }
  }

  void clearHighlight() {
    _highlightedItemId = null;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> toggleThemeMode() async {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await _storage.savePreferences(
      themeMode: _themeMode,
      localeCode: _localeCode,
      defaultSnoozeMinutes: _defaultSnoozeMinutes,
    );
    notifyListeners();
  }

  Future<void> setLocaleCode(String code) async {
    _localeCode = code;
    await _storage.savePreferences(
      themeMode: _themeMode,
      localeCode: _localeCode,
      defaultSnoozeMinutes: _defaultSnoozeMinutes,
    );
    await _rescheduleAll();
    notifyListeners();
  }

  Future<void> setDefaultSnoozeMinutes(int minutes) async {
    _defaultSnoozeMinutes = minutes.clamp(5, 180);
    await _storage.savePreferences(
      themeMode: _themeMode,
      localeCode: _localeCode,
      defaultSnoozeMinutes: _defaultSnoozeMinutes,
    );
    notifyListeners();
  }

  Future<bool> requestNotificationPermission() async {
    final granted = await _scheduler.requestPermissions();
    _notificationsEnabled =
        granted || await _scheduler.areNotificationsEnabled();
    await _rescheduleAll();
    notifyListeners();
    return _notificationsEnabled;
  }

  /// Marks [itemId] Done if outside cooldown (or [forceCooldown] == true).
  /// Returns null when blocked by cooldown, or the [CompletionTransitionResult] on success.
  Future<CompletionTransitionResult?> markDone(
    String itemId, {
    bool forceCooldown = false,
    String source = 'app',
  }) async {
    final target = _items.where((i) => i.id == itemId).firstOrNull;
    if (target == null) return null;

    final currentNow = now;
    if (!forceCooldown && AutomationEngine.isInCooldown(target, currentNow)) {
      return null;
    }

    final eventId = _uuid.v4();
    _undoStack.add(UndoRecord(
      eventId: eventId,
      previousItems: List<DidItItem>.from(_items),
      previousFlows: List<CheckFlow>.from(_flows),
    ));
    if (_undoStack.length > 10) {
      _undoStack.removeAt(0);
    }

    final res = AutomationEngine.applyCompletion(
      items: _items,
      flows: _flows,
      itemId: itemId,
      now: currentNow,
      eventId: eventId,
      source: source,
    );

    _items = res.items;
    _flows = res.flows;
    _history = <CompletionEvent>[res.event, ..._history];

    await _persist();
    for (final id in res.rescheduleItemIds) {
      final item = _items.where((i) => i.id == id).firstOrNull;
      if (item != null) {
        await _scheduler.scheduleItem(item, strings: strings);
      }
    }
    notifyListeners();
    return res;
  }

  /// Reverts the most recent UndoRecord matching [eventId] (or top of undo stack).
  Future<bool> undoCompletion([String? eventId]) async {
    if (_undoStack.isEmpty) return false;
    final index = eventId == null
        ? _undoStack.length - 1
        : _undoStack.lastIndexWhere((u) => u.eventId == eventId);
    if (index < 0) return false;

    final record = _undoStack.removeAt(index);
    _items = record.previousItems;
    _flows = record.previousFlows;
    _history = _history.where((h) => h.id != record.eventId).toList();

    await _persist();
    await _rescheduleAll();
    notifyListeners();
    return true;
  }

  Future<void> snoozeItem(String itemId, [int? minutes]) async {
    final idx = _items.indexWhere((i) => i.id == itemId);
    if (idx < 0) return;
    final snoozeMins = minutes ?? _defaultSnoozeMinutes;
    final until = now.add(Duration(minutes: snoozeMins));
    _items[idx] = _items[idx].copyWith(snoozedUntil: until);
    await _persist();
    await _scheduler.scheduleItem(_items[idx], strings: strings);
    notifyListeners();
  }

  Future<void> saveItem(DidItItem item) async {
    final idx = _items.indexWhere((i) => i.id == item.id);
    if (idx >= 0) {
      _items[idx] = item;
    } else {
      _items.add(item);
    }
    await _persist();
    await _scheduler.scheduleItem(item, strings: strings);
    notifyListeners();
  }

  Future<void> deleteItem(String itemId) async {
    _items.removeWhere((i) => i.id == itemId);
    // Clean dangling chain links pointing to deleted item
    _items = _items
        .map(
          (i) => i.chainTargetItemId == itemId
              ? i.copyWith(clearChainTarget: true)
              : i,
        )
        .toList();
    await _scheduler.cancelItem(itemId);
    await _persist();
    notifyListeners();
  }

  Future<void> saveFlowWithSteps({
    required CheckFlow flow,
    required List<DidItItem> steps,
  }) async {
    final existingIdx = _flows.indexWhere((f) => f.id == flow.id);
    if (existingIdx >= 0) {
      _flows[existingIdx] = flow;
    } else {
      _flows.add(flow);
    }

    final existingSteps =
        _items.where((i) => i.flowId == flow.id).map((i) => i.id).toSet();
    final keptIds = steps.map((s) => s.id).toSet();
    for (final removedId in existingSteps.difference(keptIds)) {
      await _scheduler.cancelItem(removedId);
    }

    _items.removeWhere((i) => i.flowId == flow.id);
    _items.addAll(steps);

    await _persist();
    for (final step in steps) {
      await _scheduler.scheduleItem(step, strings: strings);
    }
    notifyListeners();
  }

  Future<void> deleteFlow(String flowId) async {
    final removedSteps = _items.where((i) => i.flowId == flowId).toList();
    _flows.removeWhere((f) => f.id == flowId);
    _items.removeWhere((i) => i.flowId == flowId);
    for (final step in removedSteps) {
      await _scheduler.cancelItem(step.id);
    }
    await _persist();
    notifyListeners();
  }

  Future<void> resetFlowManually(String flowId) async {
    final res = AutomationEngine.resetFlowManually(
      items: _items,
      flows: _flows,
      flowId: flowId,
    );
    _items = res.items;
    _flows = res.flows;
    await _persist();
    notifyListeners();
  }

  Future<String> importStarterTemplate(String templateKey) async {
    final bundle = StarterTemplates.instantiate(
      templateKey,
      isEs: strings.isEs,
      now: now,
    );
    if (bundle.flow != null) {
      _flows.add(bundle.flow!);
    }
    _items.addAll(bundle.items);
    await _persist();
    for (final item in bundle.items) {
      await _scheduler.scheduleItem(item, strings: strings);
    }
    notifyListeners();
    return bundle.flow?.title ?? bundle.items.first.title;
  }

  Future<void> clearHistory() async {
    _history = <CompletionEvent>[];
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() => _storage.saveState(
        items: _items,
        flows: _flows,
        history: _history,
      );

  Future<void> _rescheduleAll() async {
    for (final item in _items) {
      await _scheduler.scheduleItem(item, strings: strings);
    }
  }

  @override
  void dispose() {
    _minuteTicker?.cancel();
    super.dispose();
  }
}
