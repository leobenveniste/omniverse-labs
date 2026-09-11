import 'package:flutter/material.dart';
import '../core/security/security_service.dart';

class SecurityProvider extends ChangeNotifier {
  final SecurityService _securityService;

  SecurityProvider(this._securityService);

  bool get isLocked => _securityService.isLocked;
  bool get hasPinCode => _securityService.hasPinCode;
  bool get isBiometricsEnabled => _securityService.isBiometricsEnabled;
  int get autoLockTimeoutSeconds => _securityService.autoLockTimeoutSeconds;

  bool verifyPin(String pin) {
    final success = _securityService.verifyPin(pin);
    if (success) {
      notifyListeners();
    }
    return success;
  }

  Future<bool> authenticateBiometrics() async {
    final success = await _securityService.authenticateWithBiometrics();
    if (success) {
      notifyListeners();
    }
    return success;
  }

  Future<void> setupPin(String pin) async {
    await _securityService.setPinCode(pin);
    notifyListeners();
  }

  Future<void> removePin() async {
    await _securityService.removePinCode();
    notifyListeners();
  }

  Future<void> toggleBiometrics(bool enabled) async {
    await _securityService.setBiometricsEnabled(enabled);
    notifyListeners();
  }

  Future<void> setAutoLockTimeout(int seconds) async {
    await _securityService.setAutoLockTimeout(seconds);
    notifyListeners();
  }

  void lock() {
    _securityService.lock();
    notifyListeners();
  }

  void unlock() {
    _securityService.unlock();
    notifyListeners();
  }

  void onAppPaused() {
    _securityService.onAppPaused();
  }

  void onAppResumed() {
    final wasLocked = _securityService.isLocked;
    final isLockedNow = _securityService.onAppResumed();
    if (wasLocked != isLockedNow) {
      notifyListeners();
    }
  }
}
