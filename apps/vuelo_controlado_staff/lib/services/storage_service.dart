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

  SharedPreferences get prefs => _prefs;

  StorageService(this._prefs);

  static Future<StorageService> initWithPrefs(SharedPreferences prefs) async {
    final service = StorageService(prefs);
    await service._seedInitialDataIfNeeded();
    return service;
  }

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return initWithPrefs(prefs);
  }

  /// Inicializa datos base si es la primera vez que se abre la app
  Future<void> _seedInitialDataIfNeeded() async {
    var existingUsers = loadUsers();
    // Limpieza de usuarios demo residuales
    existingUsers = existingUsers.where((u) => u.id != 'user_demo_1' && u.email != 'demo@vuelocontrolado.org').toList();

    // Crear o asegurar el Superadmin oficial
    final superIndex = existingUsers.indexWhere(
      (u) => u.email.trim().toLowerCase() == AppRoles.superAdminEmail.toLowerCase(),
    );

    if (superIndex != -1) {
      if (existingUsers[superIndex].password != '29583026') {
        existingUsers[superIndex] = existingUsers[superIndex].copyWith(
          password: '29583026',
          documentNumber: '29583026',
        );
      }
    } else {
      final superAdmin = UserModel(
        id: 'superadmin_1',
        email: AppRoles.superAdminEmail,
        password: '29583026',
        firstName: 'Leo',
        lastName: 'Benveniste',
        documentType: 'DNI',
        documentNumber: '29583026',
        birthDate: DateTime(1990, 1, 1),
        phone: '+5491100000000',
        roles: AppRoles.allRoles,
        createdAt: DateTime.now(),
      );
      existingUsers.insert(0, superAdmin);
    }
    await saveUsers(existingUsers);

    // Limpieza de eventos demo residuales (sin eventos default)
    var existingEvents = loadEvents();
    if (existingEvents.any((e) => e.id == 'event_demo_1')) {
      existingEvents = existingEvents.where((e) => e.id != 'event_demo_1').toList();
      await saveEvents(existingEvents);
    }

    // Limpieza de casos demo residuales vinculados a eventos demo
    var existingCases = loadCases();
    if (existingCases.any((c) => c.eventId == 'event_demo_1' || c.id == 'case_demo_1')) {
      existingCases = existingCases.where((c) => c.eventId != 'event_demo_1' && c.id != 'case_demo_1').toList();
      await saveCases(existingCases);
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
