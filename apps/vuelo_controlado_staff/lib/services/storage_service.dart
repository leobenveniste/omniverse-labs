import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/event_model.dart';
import '../models/case_model.dart';

class StorageService {
  static const String _usersKey = 'vc_staff_users';
  static const String _eventsKey = 'vc_staff_events';
  static const String _casesKey = 'vc_staff_cases';
  static const String _sessionUserKey = 'vc_staff_session_user';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    final service = StorageService(prefs);
    await service._seedInitialDataIfNeeded();
    return service;
  }

  /// Inicializa datos base si es la primera vez que se abre la app
  Future<void> _seedInitialDataIfNeeded() async {
    final existingUsers = loadUsers();
    if (existingUsers.isEmpty) {
      // Crear Superadmin inicial
      final superAdmin = UserModel(
        id: 'superadmin_1',
        email: AppRoles.superAdminEmail,
        password: 'admin', // Se puede cambiar desde el perfil
        firstName: 'Leo',
        lastName: 'Benveniste',
        documentType: 'DNI',
        documentNumber: 'admin',
        birthDate: DateTime(1990, 1, 1),
        phone: '+5491100000000',
        roles: AppRoles.allRoles,
        createdAt: DateTime.now(),
      );

      // Crear usuario de ejemplo para pruebas / demo
      final rrhhUser = UserModel(
        id: 'user_demo_1',
        email: 'demo@vuelocontrolado.org',
        password: '12345678', // Igual a su DNI
        firstName: 'Staff',
        lastName: 'Demo',
        documentType: 'DNI',
        documentNumber: '12345678',
        birthDate: DateTime(1995, 5, 12),
        phone: '+5491112345678',
        roles: [AppRoles.miembro, AppRoles.rrhh],
        createdAt: DateTime.now(),
      );

      await saveUsers([superAdmin, rrhhUser]);
    }

    final existingEvents = loadEvents();
    if (existingEvents.isEmpty) {
      final sampleEvent = EventModel(
        id: 'event_demo_1',
        name: 'Festival Under Vuelo Controlado',
        date: DateTime.now(),
        startTime: '22:00',
        doorsOpenTime: '21:00',
        endTime: '06:00',
        location: 'Costanera Norte, CABA',
        staffIds: ['superadmin_1'],
        createdBy: 'superadmin_1',
        createdByName: 'Leo Benveniste',
        createdAt: DateTime.now(),
        isManuallyStarted: true, // Iniciado para poder probar fichas de caso de inmediato
      );

      await saveEvents([sampleEvent]);
    }
  }

  // --- USUARIOS ---
  List<UserModel> loadUsers() {
    final raw = _prefs.getString(_usersKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(raw);
      return list.map((item) => UserModel.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveUsers(List<UserModel> users) async {
    final raw = jsonEncode(users.map((u) => u.toJson()).toList());
    await _prefs.setString(_usersKey, raw);
  }

  // --- SESIÓN PERSISTENTE LOCAL ---
  UserModel? loadSessionUser() {
    final raw = _prefs.getString(_sessionUserKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSessionUser(UserModel? user) async {
    if (user == null) {
      await _prefs.remove(_sessionUserKey);
    } else {
      await _prefs.setString(_sessionUserKey, jsonEncode(user.toJson()));
    }
  }

  // --- EVENTOS ---
  List<EventModel> loadEvents() {
    final raw = _prefs.getString(_eventsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(raw);
      return list.map((item) => EventModel.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveEvents(List<EventModel> events) async {
    final raw = jsonEncode(events.map((e) => e.toJson()).toList());
    await _prefs.setString(_eventsKey, raw);
  }

  // --- FICHAS DE CASO ---
  List<CaseModel> loadCases() {
    final raw = _prefs.getString(_casesKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(raw);
      return list.map((item) => CaseModel.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCases(List<CaseModel> cases) async {
    final raw = jsonEncode(cases.map((c) => c.toJson()).toList());
    await _prefs.setString(_casesKey, raw);
  }
}
