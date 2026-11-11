import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../l10n/app_strings.dart';
import '../models/pulse_models.dart';
import 'haptic_driver.dart';
import 'metronome_engine.dart';
import 'pulse_storage.dart';
import 'tap_tempo_calculator.dart';

typedef WakelockHandler = Future<void> Function(bool enabled);

/// Application controller uniting Stage Console state, MetronomeEngine, Setlist Slots, and Settings.
class PulseController extends ChangeNotifier {
  PulseController({
    required this._storage,
    required this._hapticDriver,
    TapTempoCalculator? tapTempoCalculator,
    WakelockHandler? onWakelockChanged,
  })  : _tapTempo = tapTempoCalculator ?? TapTempoCalculator(),
        _onWakelockChanged = onWakelockChanged ?? _defaultWakelockHandler {
    _engine = MetronomeEngine(
      hapticDriver: _hapticDriver,
      onBeat: _handleBeat,
    );
  }

  static Future<void> _defaultWakelockHandler(bool enabled) async {
    try {
      if (enabled) {
        await WakelockPlus.enable();
      } else {
        await WakelockPlus.disable();
      }
    } on MissingPluginException {
      // Safe fallback on unsupported test/desktop environments.
    } on PlatformException {
      // Ignore platform channel unavailability.
    }
  }

  final PulseStorage _storage;
  final HapticDriver _hapticDriver;
  final TapTempoCalculator _tapTempo;
  final WakelockHandler _onWakelockChanged;
  late final MetronomeEngine _engine;
  final Uuid _uuid = const Uuid();

  late int _bpm;
  late TimeSignatureOption _signature;
  late List<SetlistSlot> _slots;
  late AppLocale _locale;
  late ThemeMode _themeMode;
  late HapticStrength _hapticStrength;
  late bool _visualFlashEnabled;
  late bool _keepScreenAwake;

  String? _activeSlotId;
  int _currentBeat = -1;
  bool _beatAccentActive = false;
  int _beatRevision = 0;
  bool _isPocketLocked = false;
  bool _disposed = false;

  int get bpm => _bpm;
  TimeSignatureOption get signature => _signature;
  List<SetlistSlot> get slots => List.unmodifiable(_slots);
  String? get activeSlotId => _activeSlotId;
  AppLocale get locale => _locale;
  AppStrings get strings => AppStrings(_locale);
  ThemeMode get themeMode => _themeMode;
  HapticStrength get hapticStrength => _hapticStrength;
  bool get visualFlashEnabled => _visualFlashEnabled;
  bool get keepScreenAwake => _keepScreenAwake;
  bool get isRunning => _engine.isRunning;
  int get currentBeat => _currentBeat;
  bool get beatAccentActive => _beatAccentActive;
  int get beatRevision => _beatRevision;
  bool get isPocketLocked => _isPocketLocked;

  Future<void> initialize() async {
    await _hapticDriver.initialize();
    _bpm = _storage.loadBpm();
    _signature = _storage.loadSignature();
    _slots = _storage.loadSlots();
    _locale = _storage.loadLocale();
    _themeMode = _storage.loadThemeMode();
    _hapticStrength = _storage.loadHapticStrength();
    _visualFlashEnabled = _storage.loadVisualFlash();
    _keepScreenAwake = _storage.loadKeepAwake();
    _activeSlotId = _matchingSlotId();
    _syncEngineConfig();
    notifyListeners();
  }

  String? _matchingSlotId() {
    for (final slot in _slots) {
      if (slot.bpm == _bpm && slot.signature == _signature) {
        return slot.id;
      }
    }
    return null;
  }

  void _syncEngineConfig() {
    _engine.configure(
      bpm: _bpm,
      beatsPerBar: _signature.beatsPerBar,
      strength: _hapticStrength,
    );
  }

  void _handleBeat(int beatIndex, bool isAccent) {
    if (_disposed) return;
    _currentBeat = beatIndex;
    _beatAccentActive = isAccent;
    _beatRevision++;
    notifyListeners();
  }

  Future<void> setBpm(int newBpm, {bool clearActiveSlot = true}) async {
    final clamped = newBpm.clamp(kMinBpm, kMaxBpm);
    if (clamped == _bpm && !clearActiveSlot) return;
    _bpm = clamped;
    if (clearActiveSlot) {
      _activeSlotId = _matchingSlotId();
    }
    _syncEngineConfig();
    notifyListeners();
    await _storage.saveBpm(_bpm);
  }

  Future<void> nudgeBpm(int delta) => setBpm(_bpm + delta);

  Future<void> setSignature(
    TimeSignatureOption sig, {
    bool clearActiveSlot = true,
  }) async {
    if (sig == _signature) return;
    _signature = sig;
    if (_currentBeat >= sig.beatsPerBar) {
      _currentBeat = 0;
    }
    if (clearActiveSlot) {
      _activeSlotId = _matchingSlotId();
    }
    _syncEngineConfig();
    notifyListeners();
    await _storage.saveSignature(sig);
  }

  Future<int?> registerTap({int? nowMs}) async {
    final ts = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    final computed = _tapTempo.registerTap(ts);
    if (computed != null) {
      await setBpm(computed);
    }
    return computed;
  }

  Future<void> toggleRunning() async {
    if (_engine.isRunning) {
      await stop();
    } else {
      await start();
    }
  }

  Future<void> start() async {
    if (_engine.isRunning) return;
    _syncEngineConfig();
    _engine.start();
    if (_keepScreenAwake || _isPocketLocked) {
      await _onWakelockChanged(true);
    }
    notifyListeners();
  }

  Future<void> stop() async {
    _engine.stop();
    _currentBeat = -1;
    _beatAccentActive = false;
    _isPocketLocked = false;
    await _onWakelockChanged(false);
    notifyListeners();
  }

  Future<void> engagePocketLock() async {
    _isPocketLocked = true;
    if (!_engine.isRunning) {
      _syncEngineConfig();
      _engine.start();
    }
    await _onWakelockChanged(true);
    notifyListeners();
  }

  Future<void> unlockPocketLock() async {
    if (!_isPocketLocked) return;
    _isPocketLocked = false;
    unawaited(_hapticDriver.pulseUnlock());
    if (!_engine.isRunning || !_keepScreenAwake) {
      await _onWakelockChanged(false);
    }
    notifyListeners();
  }

  Future<void> selectSlot(SetlistSlot slot) async {
    _bpm = slot.bpm;
    _signature = slot.signature;
    _activeSlotId = slot.id;
    _syncEngineConfig();
    notifyListeners();
    await _storage.saveBpm(_bpm);
    await _storage.saveSignature(_signature);
  }

  Future<bool> saveSlot({
    String? existingId,
    required String name,
    required int bpm,
    required TimeSignatureOption signature,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;

    if (existingId != null) {
      _slots = _slots
          .map(
            (slot) => slot.id == existingId
                ? slot.copyWith(
                    name: trimmed,
                    bpm: bpm,
                    signature: signature,
                  )
                : slot,
          )
          .toList();
      _activeSlotId = existingId;
    } else {
      if (_slots.length >= kMaxSetlistSlots) {
        return false;
      }
      final created = SetlistSlot(
        id: _uuid.v4(),
        name: trimmed,
        bpm: bpm,
        signature: signature,
      );
      _slots = [..._slots, created];
      _activeSlotId = created.id;
    }

    _bpm = bpm.clamp(kMinBpm, kMaxBpm);
    _signature = signature;
    _syncEngineConfig();
    notifyListeners();
    await Future.wait([
      _storage.saveSlots(_slots),
      _storage.saveBpm(_bpm),
      _storage.saveSignature(_signature),
    ]);
    return true;
  }

  Future<void> deleteSlot(String slotId) async {
    _slots = _slots.where((s) => s.id != slotId).toList();
    if (_activeSlotId == slotId) {
      _activeSlotId = _matchingSlotId();
    }
    notifyListeners();
    await _storage.saveSlots(_slots);
  }

  Future<void> triggerTestPulse() async {
    await _hapticDriver.pulse(isAccent: true, strength: _hapticStrength);
  }

  Future<void> setLocale(AppLocale newLocale) async {
    if (newLocale == _locale) return;
    _locale = newLocale;
    notifyListeners();
    await _storage.saveLocale(newLocale);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    await _storage.saveThemeMode(mode);
  }

  Future<void> setHapticStrength(HapticStrength strength) async {
    if (strength == _hapticStrength) return;
    _hapticStrength = strength;
    _syncEngineConfig();
    notifyListeners();
    await _storage.saveHapticStrength(strength);
    await triggerTestPulse();
  }

  Future<void> setVisualFlashEnabled(bool enabled) async {
    if (enabled == _visualFlashEnabled) return;
    _visualFlashEnabled = enabled;
    notifyListeners();
    await _storage.saveVisualFlash(enabled);
  }

  Future<void> setKeepScreenAwake(bool enabled) async {
    if (enabled == _keepScreenAwake) return;
    _keepScreenAwake = enabled;
    if (_engine.isRunning && !_isPocketLocked) {
      await _onWakelockChanged(enabled);
    }
    notifyListeners();
    await _storage.saveKeepAwake(enabled);
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _engine.dispose();
    unawaited(_onWakelockChanged(false));
    super.dispose();
  }
}
