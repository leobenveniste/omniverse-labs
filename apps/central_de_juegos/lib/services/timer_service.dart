import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'sound_haptics_service.dart';

class TimerService extends ChangeNotifier {
  static final TimerService _instance = TimerService._internal();
  factory TimerService() => _instance;
  TimerService._internal();

  Timer? _timer;
  int _totalSeconds = 60;
  int _remainingSeconds = 60;
  bool _isRunning = false;
  bool _isFinished = false;

  int get totalSeconds => _totalSeconds;
  int get remainingSeconds => _remainingSeconds;
  bool get isRunning => _isRunning;
  bool get isFinished => _isFinished;
  bool get hasActiveTimer => _isRunning || (_remainingSeconds > 0 && _remainingSeconds < _totalSeconds);

  double get progress => _totalSeconds > 0 ? (_remainingSeconds / _totalSeconds) : 0.0;

  String get formattedRemaining {
    final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void start(int seconds) {
    _timer?.cancel();
    _totalSeconds = seconds;
    _remainingSeconds = seconds;
    _isRunning = true;
    _isFinished = false;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 1) {
        _remainingSeconds--;
        if (_remainingSeconds <= 5) {
          SoundHapticsService.click();
        }
        notifyListeners();
      } else {
        _remainingSeconds = 0;
        _isRunning = false;
        _isFinished = true;
        timer.cancel();
        _onTimerFinished();
        notifyListeners();
      }
    });
  }

  void pause() {
    if (_isRunning) {
      _timer?.cancel();
      _isRunning = false;
      notifyListeners();
    }
  }

  void resume() {
    if (!_isRunning && _remainingSeconds > 0) {
      _isRunning = true;
      _isFinished = false;
      notifyListeners();

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 1) {
          _remainingSeconds--;
          if (_remainingSeconds <= 5) {
            SoundHapticsService.click();
          }
          notifyListeners();
        } else {
          _remainingSeconds = 0;
          _isRunning = false;
          _isFinished = true;
          timer.cancel();
          _onTimerFinished();
          notifyListeners();
        }
      });
    }
  }

  void stop() {
    _timer?.cancel();
    _isRunning = false;
    _remainingSeconds = _totalSeconds;
    _isFinished = false;
    notifyListeners();
  }

  void reset() {
    _timer?.cancel();
    _isRunning = false;
    _remainingSeconds = _totalSeconds;
    _isFinished = false;
    notifyListeners();
  }

  void _onTimerFinished() {
    // Play alert sound & heavy haptic feedback
    SoundHapticsService.timerAlarm();
  }
}
