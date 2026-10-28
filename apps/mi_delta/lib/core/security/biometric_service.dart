import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricAuthResult {
  final bool success;
  final bool canceled;
  final String? errorMessage;

  const BiometricAuthResult({
    required this.success,
    this.canceled = false,
    this.errorMessage,
  });
}

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();
  static const String _keyBiometricsEnabled = 'midelta_biometrics_enabled';

  /// Check if the hardware supports biometrics
  Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (e) {
      debugPrint('Error checking device support: $e');
      return false;
    }
  }

  /// Check if device can perform biometric checks and has enrolled biometrics
  Future<bool> canCheckBiometrics() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return isSupported && canCheck;
    } catch (e) {
      debugPrint('Error checking canCheckBiometrics: $e');
      return false;
    }
  }

  /// Get list of enrolled biometric types (fingerprint, face, etc.)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Check if the user enabled biometrics in the app
  Future<bool> isBiometricsEnabledInApp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyBiometricsEnabled) ?? true;
    } catch (e) {
      return true;
    }
  }

  /// Set user preference for biometrics in the app
  Future<void> setBiometricsEnabledInApp(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyBiometricsEnabled, enabled);
    } catch (e) {
      debugPrint('Error saving biometrics preference: $e');
    }
  }

  /// Perform the real biometric authentication prompt
  Future<BiometricAuthResult> authenticate({
    String reason = 'Identificate con tu huella digital o rostro para ingresar a Mi Delta',
  }) async {
    try {
      final isSupported = await isDeviceSupported();
      if (!isSupported) {
        return const BiometricAuthResult(
          success: false,
          errorMessage: 'Este dispositivo no cuenta con sensor biométrico.',
        );
      }

      final canCheck = await _auth.canCheckBiometrics;
      final available = await _auth.getAvailableBiometrics();

      if (!canCheck && available.isEmpty) {
        return const BiometricAuthResult(
          success: false,
          errorMessage: 'No tenés huella digital o rostro registrado en el celular.',
        );
      }

      final didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );

      return BiometricAuthResult(success: didAuthenticate);
    } on PlatformException catch (e) {
      debugPrint('Biometric PlatformException: ${e.code} - ${e.message}');
      if (e.code == 'UserCancel' || e.code == 'Canceled' || e.code == 'auth_in_progress') {
        return const BiometricAuthResult(
          success: false,
          canceled: true,
        );
      } else if (e.code == 'NotEnrolled') {
        return const BiometricAuthResult(
          success: false,
          errorMessage: 'No tenés datos biométricos registrados en los ajustes del dispositivo.',
        );
      } else if (e.code == 'PasscodeNotSet') {
        return const BiometricAuthResult(
          success: false,
          errorMessage: 'No tenés configurado un bloqueo de pantalla (PIN o patrón).',
        );
      } else if (e.code == 'LockedOut') {
        return const BiometricAuthResult(
          success: false,
          errorMessage: 'Sensor bloqueado temporalmente por demasiados intentos.',
        );
      } else if (e.code == 'PermanentlyLockedOut') {
        return const BiometricAuthResult(
          success: false,
          errorMessage: 'Sensor bloqueado. Desbloqueá tu dispositivo con tu clave personal.',
        );
      } else {
        return BiometricAuthResult(
          success: false,
          errorMessage: e.message ?? 'Error de autenticación biométrica.',
        );
      }
    } catch (e) {
      debugPrint('Unexpected biometric error: $e');
      return BiometricAuthResult(
        success: false,
        errorMessage: 'Ocurrió un error inesperado al validar tu identidad.',
      );
    }
  }
}
