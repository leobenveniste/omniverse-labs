import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class SecurityService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final SharedPreferences _prefs;

  bool _isLocked = false;
  DateTime? _lastPausedTime;

  SecurityService(this._prefs) {
    _isLocked = hasPinCode;
  }

  bool get isLocked => _isLocked;

  bool get hasPinCode {
    final pin = _prefs.getString(AppConstants.keyPinCode);
    return pin != null && pin.length == 4;
  }

  bool get isBiometricsEnabled =>
      _prefs.getBool(AppConstants.keyBiometricsEnabled) ?? false;

  int get autoLockTimeoutSeconds =>
      _prefs.getInt(AppConstants.keyAutoLockTimeout) ?? 0; // 0 = Immediate

  Future<void> setPinCode(String pin) async {
    await _prefs.setString(AppConstants.keyPinCode, pin);
    _isLocked = false;
  }

  Future<void> removePinCode() async {
    await _prefs.remove(AppConstants.keyPinCode);
    await _prefs.setBool(AppConstants.keyBiometricsEnabled, false);
    _isLocked = false;
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    await _prefs.setBool(AppConstants.keyBiometricsEnabled, enabled);
  }

  Future<void> setAutoLockTimeout(int seconds) async {
    await _prefs.setInt(AppConstants.keyAutoLockTimeout, seconds);
  }

  bool verifyPin(String enteredPin) {
    final stored = _prefs.getString(AppConstants.keyPinCode);
    if (stored == enteredPin) {
      _isLocked = false;
      return true;
    }
    return false;
  }

  Future<bool> checkBiometricsAvailable() async {
    try {
      final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      return canAuthenticate;
    } catch (e) {
      debugPrint('Biometrics check error: $e');
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    if (!isBiometricsEnabled) return false;
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Desbloquea OmniTrade para acceder a tus operaciones',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      if (authenticated) {
        _isLocked = false;
      }
      return authenticated;
    } catch (e) {
      debugPrint('Biometrics auth error: $e');
      return false;
    }
  }

  void onAppPaused() {
    _lastPausedTime = DateTime.now();
  }

  bool onAppResumed() {
    if (!hasPinCode) {
      _isLocked = false;
      return false;
    }

    if (_lastPausedTime != null) {
      final elapsed = DateTime.now().difference(_lastPausedTime!).inSeconds;
      if (elapsed >= autoLockTimeoutSeconds) {
        _isLocked = true;
      }
    } else {
      _isLocked = true;
    }

    return _isLocked;
  }

  void unlock() {
    _isLocked = false;
  }

  void lock() {
    if (hasPinCode) {
      _isLocked = true;
    }
  }
}
