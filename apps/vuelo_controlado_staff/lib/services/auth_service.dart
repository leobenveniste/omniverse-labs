import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import 'storage_service.dart';

class AuthService extends ChangeNotifier {
  final StorageService _storage;
  UserModel? _currentUser;
  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _errorMessage;

  AuthService(this._storage) {
    _init();
  }

  UserModel? get currentUser => _currentUser;
  List<UserModel> get users => List.unmodifiable(_users);
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _init() {
    _users = _storage.loadUsers();
    _currentUser = _storage.loadSessionUser();
    // Si la sesión guardada es de un usuario actualizado, refrescar datos
    if (_currentUser != null) {
      final index = _users.indexWhere((u) => u.id == _currentUser!.id);
      if (index != -1) {
        _currentUser = _users[index];
      }
    }
    notifyListeners();
  }

  /// Inicia sesión con email y contraseña (por defecto el número de documento)
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cleanEmail = email.trim().toLowerCase();
      final cleanPassword = password.trim();

      // Buscar usuario en base de datos local
      final userIndex = _users.indexWhere(
        (u) => u.email.trim().toLowerCase() == cleanEmail,
      );

      if (userIndex == -1) {
        _errorMessage = 'No se encontró un usuario con ese correo electrónico.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final foundUser = _users[userIndex];

      // Verificar contraseña
      if (foundUser.password != cleanPassword) {
        _errorMessage = 'Contraseña incorrecta. Recuerde que su contraseña inicial es su número de documento.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _currentUser = foundUser;
      await _storage.saveSessionUser(_currentUser);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al iniciar sesión: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Cierra la sesión activa
  Future<void> logout() async {
    _currentUser = null;
    await _storage.saveSessionUser(null);
    notifyListeners();
  }

  /// Actualiza la contraseña del usuario actual
  Future<bool> updatePassword(String newPassword) async {
    if (_currentUser == null) return false;
    if (newPassword.trim().isEmpty) return false;

    final updated = _currentUser!.copyWith(password: newPassword.trim());
    final index = _users.indexWhere((u) => u.id == updated.id);
    if (index != -1) {
      _users[index] = updated;
      _currentUser = updated;
      await _storage.saveUsers(_users);
      await _storage.saveSessionUser(_currentUser);
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Creación de nuevo usuario (Rol RRHH o Superadmin)
  /// La contraseña inicial se asigna automáticamente igual a su número de documento.
  Future<bool> createUser({
    required String email,
    required String firstName,
    required String lastName,
    required String documentType,
    required String documentNumber,
    required DateTime birthDate,
    required String phone,
    String? photoUrl,
    required List<String> initialRoles,
  }) async {
    _errorMessage = null;
    final cleanEmail = email.trim().toLowerCase();
    final cleanDoc = documentNumber.trim();

    if (_users.any((u) => u.email.trim().toLowerCase() == cleanEmail)) {
      _errorMessage = 'Ya existe un usuario registrado con el email $cleanEmail.';
      notifyListeners();
      return false;
    }

    if (_users.any((u) => u.documentNumber.trim() == cleanDoc)) {
      _errorMessage = 'Ya existe un usuario con el número de documento $cleanDoc.';
      notifyListeners();
      return false;
    }

    // Asegurar que siempre tenga el rol Miembro
    final rolesList = initialRoles.contains(AppRoles.miembro)
        ? initialRoles
        : [AppRoles.miembro, ...initialRoles];

    final newUser = UserModel(
      id: const Uuid().v4(),
      email: cleanEmail,
      password: cleanDoc, // CLAVE INICIAL = NÚMERO DE DOCUMENTO
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      documentType: documentType.trim(),
      documentNumber: cleanDoc,
      birthDate: birthDate,
      phone: phone.trim(),
      photoUrl: photoUrl,
      roles: rolesList,
      createdAt: DateTime.now(),
    );

    _users.add(newUser);
    await _storage.saveUsers(_users);
    notifyListeners();
    return true;
  }

  /// Modificación de roles de usuario (Solo Superadmin)
  Future<bool> updateUserRoles(String userId, List<String> newRoles) async {
    if (_currentUser == null || !_currentUser!.isSuperAdmin) {
      _errorMessage = 'Solo el superadmin puede modificar roles.';
      notifyListeners();
      return false;
    }

    final index = _users.indexWhere((u) => u.id == userId);
    if (index == -1) return false;

    // Asegurar que nunca se quite el rol Miembro
    final cleanRoles = newRoles.contains(AppRoles.miembro)
        ? newRoles
        : [AppRoles.miembro, ...newRoles];

    final updated = _users[index].copyWith(roles: cleanRoles);
    _users[index] = updated;

    // Si es el usuario actual en sesión, actualizar
    if (_currentUser!.id == userId) {
      _currentUser = updated;
      await _storage.saveSessionUser(_currentUser);
    }

    await _storage.saveUsers(_users);
    notifyListeners();
    return true;
  }

  /// Actualizar datos de perfil
  Future<bool> updateUserProfile(UserModel updatedUser) async {
    final index = _users.indexWhere((u) => u.id == updatedUser.id);
    if (index == -1) return false;

    _users[index] = updatedUser;
    if (_currentUser?.id == updatedUser.id) {
      _currentUser = updatedUser;
      await _storage.saveSessionUser(_currentUser);
    }

    await _storage.saveUsers(_users);
    notifyListeners();
    return true;
  }
}
