import 'dart:async';
import 'package:flutter/services.dart';

abstract class AudioMeterDriver {
  Stream<double> get dbfsStream;

  Future<bool> hasPermission();
  Future<bool> requestPermission();
  Future<bool> start();
  Future<void> stop();
  void dispose();
}

/// Native Android AudioRecord RAM-only sampler backed by MethodChannel + EventChannel.
class NativeAudioMeterDriver implements AudioMeterDriver {
  static const MethodChannel _methodChannel =
      MethodChannel('com.omniverselabs.loud_guard/audio_meter');
  static const EventChannel _eventChannel =
      EventChannel('com.omniverselabs.loud_guard/audio_meter_stream');

  Stream<double>? _cachedStream;

  @override
  Stream<double> get dbfsStream {
    return _cachedStream ??= _eventChannel
        .receiveBroadcastStream()
        .where((event) => event is num)
        .map((event) => (event as num).toDouble());
  }

  @override
  Future<bool> hasPermission() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('hasPermission');
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      final result =
          await _methodChannel.invokeMethod<bool>('requestPermission');
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<bool> start() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('start');
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _methodChannel.invokeMethod<bool>('stop');
    } on PlatformException {
      // Ignore stop failures on teardown.
    } on MissingPluginException {
      // Ignore in non-Android test environments.
    }
  }

  @override
  void dispose() {}
}

/// Deterministic test driver for unit and widget tests.
class FakeAudioMeterDriver implements AudioMeterDriver {
  FakeAudioMeterDriver({
    this.permissionGranted = true,
    this.startSucceeds = true,
  });

  bool permissionGranted;
  bool startSucceeds;
  bool isRunning = false;

  final StreamController<double> _controller =
      StreamController<double>.broadcast();

  @override
  Stream<double> get dbfsStream => _controller.stream;

  void emitDbfs(double dbfs) {
    if (!_controller.isClosed) {
      _controller.add(dbfs);
    }
  }

  void emitSplForBaseline(double targetSplDb) {
    emitDbfs(targetSplDb - 96.0);
  }

  @override
  Future<bool> hasPermission() async => permissionGranted;

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  Future<bool> start() async {
    if (!permissionGranted || !startSucceeds) return false;
    isRunning = true;
    return true;
  }

  @override
  Future<void> stop() async {
    isRunning = false;
  }

  @override
  void dispose() {
    _controller.close();
  }
}
