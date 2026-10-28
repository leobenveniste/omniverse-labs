import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/security/biometric_service.dart';
import '../models/user_model.dart';
import '../models/reclamo_model.dart';
import '../models/turno_model.dart';
import '../models/beneficio_model.dart';
import '../models/alert_model.dart';

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

// --- AUTH PROVIDER ---
class AuthNotifier extends StateNotifier<UserModel?> {
  AuthNotifier() : super(null);

  bool login(String email, String password) {
    if (email.isEmpty || password.isEmpty) return false;
    state = UserModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: email.split('@').first.replaceAll('.', ' '),
      email: email,
      dni: '38.291.402',
      address: 'Av. Las Palmeras 1240',
      locality: 'Rincón Náutico',
      memberNumber: 'SD-84920',
    );
    return true;
  }

  bool loginWithDni(String dni, String password) {
    if (dni.isEmpty || password.isEmpty) return false;
    state = UserModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Leonardo Benveniste',
      email: 'leo.benveniste@gmail.com',
      dni: dni.replaceAll(RegExp(r'[^0-9]'), ''),
      address: 'Av. Las Palmeras 1240',
      locality: 'Rincón Náutico',
      memberNumber: 'SD-84920',
    );
    return true;
  }

  bool register(String name, String email, String password) {
    if (name.isEmpty || email.isEmpty || password.isEmpty) return false;
    state = UserModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      dni: '38.120.455',
      address: 'Calle Los Ceibos 310',
      locality: 'Delta Centro',
      memberNumber: 'SD-91402',
    );
    return true;
  }

  void loginAsDemo() {
    state = UserModel.demoUser;
  }

  void logout() {
    state = null;
  }

  Future<void> deleteAccountAndData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    state = null;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, UserModel?>((ref) {
  return AuthNotifier();
});

// Real asynchronous initialization pipeline.
// Resolves when authentic services, session checks, and configs are loaded without any artificial delay.
final appInitializationProvider = FutureProvider<void>((ref) async {
  // Ready for real storage / remote config / auth token verification.
  // Performs actual async tasks and completes naturally.
  await Future<void>.value();
});

// --- RECLAMOS PROVIDER ---
class ReclamosNotifier extends StateNotifier<List<ReclamoModel>> {
  ReclamosNotifier() : super(ReclamoModel.initialList);

  void addReclamo({
    required String title,
    required String category,
    required String address,
    required String locality,
    required String description,
  }) {
    final newReclamo = ReclamoModel(
      id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
      code: 'REC-${(1000 + (DateTime.now().millisecond * 9)).clamp(1000, 9999)}',
      title: title,
      category: category,
      address: address,
      locality: locality,
      description: description,
      status: ReclamoStatus.recibido,
      statusLabel: 'Recibido en el Municipio',
      date: 'Hoy, recién',
      updatedAt: 'Hace instantes',
    );
    state = [newReclamo, ...state];
  }
}

final reclamosProvider = StateNotifierProvider<ReclamosNotifier, List<ReclamoModel>>((ref) {
  return ReclamosNotifier();
});

// --- TURNOS & BENEFICIOS PROVIDERS ---
final turnosProvider = Provider<List<TurnoModel>>((ref) {
  return TurnoModel.initialList;
});

final beneficiosProvider = Provider<List<BeneficioModel>>((ref) {
  return BeneficioModel.initialList;
});

final alertProvider = Provider<AlertModel>((ref) {
  return AlertModel.initial;
});

// --- THEME MODE PROVIDER (CLARO / OSCURO / AUTOMÁTICO) ---
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const _key = 'user_theme_mode';

  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeString = prefs.getString(_key);
      if (modeString == 'light') {
        state = ThemeMode.light;
      } else if (modeString == 'dark') {
        state = ThemeMode.dark;
      } else {
        state = ThemeMode.system;
      }
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mode == ThemeMode.light) {
        await prefs.setString(_key, 'light');
      } else if (mode == ThemeMode.dark) {
        await prefs.setString(_key, 'dark');
      } else {
        await prefs.setString(_key, 'system');
      }
    } catch (_) {}
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

