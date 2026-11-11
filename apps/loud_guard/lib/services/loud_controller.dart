import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../l10n/app_strings.dart';
import '../models/loud_models.dart';
import 'audio_meter_driver.dart';
import 'loud_storage.dart';

typedef WakelockHandler = Future<void> Function(bool enable);
typedef ThresholdHapticHandler = Future<void> Function();

class LoudController extends ChangeNotifier {
  LoudController({
    required this.storage,
    required this.driver,
    WakelockHandler? wakelockHandler,
    ThresholdHapticHandler? thresholdHapticHandler,
    DateTime Function()? nowProvider,
  })  : _wakelockHandler = wakelockHandler ?? _defaultWakelock,
        _thresholdHapticHandler =
            thresholdHapticHandler ?? _defaultThresholdHaptic,
        _now = nowProvider ?? DateTime.now;

  static Future<void> _defaultWakelock(bool enable) async {
    try {
      await WakelockPlus.toggle(enable: enable);
    } catch (_) {
      // Safe no-op in headless/test environments.
    }
  }

  static Future<void> _defaultThresholdHaptic() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  final LoudStorage storage;
  final AudioMeterDriver driver;
  final WakelockHandler _wakelockHandler;
  final ThresholdHapticHandler _thresholdHapticHandler;
  final DateTime Function() _now;
  final Uuid _uuid = const Uuid();

  StreamSubscription<double>? _subscription;
  Timer? _sessionTimer;

  ThemeMode _themeMode = ThemeMode.dark;
  AppLocale _locale = AppLocale.en;
  double _calibrationOffsetDb = 0.0;
  HapticThreshold _hapticThreshold = HapticThreshold.db90;
  bool _keepScreenAwake = true;
  List<SoundCheckLog> _savedChecks = [];

  bool _hasPermission = false;
  bool _permissionDenied = false;
  bool _isRunning = false;
  bool _hasSamples = false;

  double _currentDb = 0.0;
  double _minDb = 0.0;
  double _peakDb = 0.0;
  double _sumDb = 0.0;
  int _sampleCount = 0;
  int _sessionSeconds = 0;
  double _doseFraction = 0.0;
  DateTime? _lastThresholdHapticAt;

  final List<double> _history = <double>[];

  ThemeMode get themeMode => _themeMode;
  AppLocale get locale => _locale;
  AppStrings get strings => AppStrings.of(_locale);
  double get calibrationOffsetDb => _calibrationOffsetDb;
  HapticThreshold get hapticThreshold => _hapticThreshold;
  bool get keepScreenAwake => _keepScreenAwake;
  List<SoundCheckLog> get savedChecks => List.unmodifiable(_savedChecks);

  bool get hasPermission => _hasPermission;
  bool get permissionDenied => _permissionDenied;
  bool get isRunning => _isRunning;
  bool get hasSamples => _hasSamples;

  double get currentDb => _currentDb;
  double get minDb => _hasSamples ? _minDb : 0.0;
  double get avgDb => _sampleCount > 0 ? (_sumDb / _sampleCount) : 0.0;
  double get peakDb => _hasSamples ? _peakDb : 0.0;
  int get sessionSeconds => _sessionSeconds;
  double get dosePercent => (_doseFraction * 100.0).clamp(0.0, 999.9);
  List<double> get history => List.unmodifiable(_history);

  SafetyZone get currentZone => ExposureMath.classify(_currentDb);
  Duration? get safeExposureNow =>
      _hasSamples ? ExposureMath.safeExposureDuration(_currentDb) : null;

  Future<void> initialize() async {
    _themeMode = storage.loadThemeMode();
    _locale = storage.loadLocale();
    _calibrationOffsetDb = storage.loadCalibrationOffset();
    _hapticThreshold = storage.loadHapticThreshold();
    _keepScreenAwake = storage.loadKeepScreenAwake();
    _savedChecks = storage.loadSavedChecks();
    _hasPermission = await driver.hasPermission();

    _subscription = driver.dbfsStream.listen(_onDbfsSample);
    notifyListeners();
  }

  void _onDbfsSample(double dbfs) {
    if (!_isRunning) return;
    final spl = ExposureMath.convertDbfsToSpl(
      dbfs,
      calibrationOffsetDb: _calibrationOffsetDb,
    );

    if (!_hasSamples) {
      _hasSamples = true;
      _currentDb = spl;
      _minDb = spl;
      _peakDb = spl;
    } else {
      _currentDb = (_currentDb * 0.55) + (spl * 0.45);
      if (spl < _minDb) _minDb = spl;
      if (spl > _peakDb) _peakDb = spl;
    }

    _sumDb += spl;
    _sampleCount += 1;
    _history.add(spl);
    if (_history.length > kSparklineCapacity) {
      _history.removeAt(0);
    }

    _maybeTriggerThresholdHaptic(spl);
    notifyListeners();
  }

  void _maybeTriggerThresholdHaptic(double spl) {
    final ceiling = _hapticThreshold.decibels;
    if (ceiling == null || spl < ceiling) return;

    final now = _now();
    if (_lastThresholdHapticAt != null &&
        now.difference(_lastThresholdHapticAt!) < const Duration(seconds: 10)) {
      return;
    }
    _lastThresholdHapticAt = now;
    _thresholdHapticHandler();
  }

  Future<bool> toggleMeter() async {
    if (_isRunning) {
      await pauseMeter();
      return true;
    }
    return startMeter();
  }

  Future<bool> startMeter() async {
    if (_isRunning) return true;

    var granted = await driver.hasPermission();
    if (!granted) {
      granted = await driver.requestPermission();
    }
    _hasPermission = granted;
    _permissionDenied = !granted;
    if (!granted) {
      notifyListeners();
      return false;
    }

    final started = await driver.start();
    if (!started) {
      notifyListeners();
      return false;
    }

    _isRunning = true;
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isRunning) return;
      _sessionSeconds += 1;
      if (_hasSamples) {
        _doseFraction += ExposureMath.doseIncrementFraction(_currentDb, 1.0);
      }
      notifyListeners();
    });

    if (_keepScreenAwake) {
      await _wakelockHandler(true);
    }
    notifyListeners();
    return true;
  }

  Future<void> pauseMeter() async {
    if (!_isRunning) return;
    _isRunning = false;
    _sessionTimer?.cancel();
    _sessionTimer = null;
    await driver.stop();
    await _wakelockHandler(false);
    notifyListeners();
  }

  Future<void> resetSession() async {
    _hasSamples = false;
    _currentDb = 0.0;
    _minDb = 0.0;
    _peakDb = 0.0;
    _sumDb = 0.0;
    _sampleCount = 0;
    _sessionSeconds = 0;
    _doseFraction = 0.0;
    _history.clear();
    _lastThresholdHapticAt = null;
    notifyListeners();
  }

  Future<SoundCheckLog?> saveCurrentCheck(String rawLabel) async {
    if (!_hasSamples) return null;
    final label = rawLabel.trim().isEmpty ? 'Sound Check' : rawLabel.trim();
    final entry = SoundCheckLog(
      id: _uuid.v4(),
      label: label,
      avgDb: double.parse(avgDb.toStringAsFixed(1)),
      peakDb: double.parse(_peakDb.toStringAsFixed(1)),
      minDb: double.parse(_minDb.toStringAsFixed(1)),
      durationSeconds: _sessionSeconds,
      dosePercent: double.parse(dosePercent.toStringAsFixed(1)),
      createdAtMs: _now().millisecondsSinceEpoch,
    );
    _savedChecks = [entry, ..._savedChecks].take(kMaxSavedChecks).toList();
    await storage.saveChecks(_savedChecks);
    notifyListeners();
    return entry;
  }

  Future<void> deleteSavedCheck(String id) async {
    _savedChecks = _savedChecks.where((item) => item.id != id).toList();
    await storage.saveChecks(_savedChecks);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    await storage.saveThemeMode(mode);
    notifyListeners();
  }

  Future<void> setLocale(AppLocale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    await storage.saveLocale(locale);
    notifyListeners();
  }

  Future<void> adjustCalibrationOffset(double delta) async {
    final next = ((_calibrationOffsetDb + delta) * 2).round() / 2.0;
    await setCalibrationOffset(next);
  }

  Future<void> setCalibrationOffset(double offsetDb) async {
    final clamped =
        offsetDb.clamp(kMinCalibrationOffset, kMaxCalibrationOffset);
    if (_calibrationOffsetDb == clamped) return;
    _calibrationOffsetDb = clamped;
    await storage.saveCalibrationOffset(clamped);
    notifyListeners();
  }

  Future<void> setHapticThreshold(HapticThreshold threshold) async {
    if (_hapticThreshold == threshold) return;
    _hapticThreshold = threshold;
    await storage.saveHapticThreshold(threshold);
    notifyListeners();
  }

  Future<void> setKeepScreenAwake(bool enabled) async {
    if (_keepScreenAwake == enabled) return;
    _keepScreenAwake = enabled;
    await storage.saveKeepScreenAwake(enabled);
    if (_isRunning) {
      await _wakelockHandler(enabled);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _subscription?.cancel();
    driver.stop();
    driver.dispose();
    _wakelockHandler(false);
    super.dispose();
  }
}
