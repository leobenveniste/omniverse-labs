import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import 'storage_service.dart';
import 'firestore_sync_service.dart';
import 'demo_data.dart';

class AuthService extends ChangeNotifier {
  final StorageService _storage;
  final FirestoreSyncService? firestoreSync;
  UserModel? _currentUser;
  List<UserModel> _users = [];
  List<UserModel> _demoUsers = [];
  bool _isLoading = false;
  String? _errorMessage;

  AuthService(this._storage, {this.firestoreSync}) {
    _init();
  }

  UserModel? get currentUser => _currentUser;
  bool get isDemoMode => _currentUser?.id == DemoData.demoUserId;
  List<UserModel> get users =>
      List.unmodifiable(isDemoMode ? _demoUsers : _users);
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _init() {
    _users = _storage.loadUsers();
    _currentUser = _storage.loadSessionUser();
    if (_currentUser?.id == DemoData.demoUserId) {
      _demoUsers = DemoData.getDemoUsers();
      _currentUser = DemoData.getDemoUser();
    } else if (_currentUser != null) {
      final index = _users.indexWhere((u) => u.id == _currentUser!.id);
      if (index != -1) {
        _currentUser = _users[index];
      }
    }
    notifyListeners();
  }

  /// Recarga usuarios cuando se detectan cambios remotos desde Firestore
  void reloadUsersFromStorage() {
    if (isDemoMode) return;
    _init();
  }

  /// Inicia sesión con email y contraseña (por defecto el número de documento)
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cleanEmail = email.trim().toLowerCase();
      final cleanPassword = password.trim();

      // Detección de cuenta Demo para Google Play Review (Modo Sandbox aislado)
      if (DemoData.isDemoLogin(cleanEmail, cleanPassword)) {
        _currentUser = DemoData.getDemoUser();
        _demoUsers = DemoData.getDemoUsers();
        await _storage.saveSessionUser(_currentUser);
        await _storage.prefs.setString('vc_staff_last_email', _currentUser!.email);
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
        return true;
      }

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

      var foundUser = _users[userIndex];

      // Verificación y sincronización especial para Superadmin con clave 29583026
      if (cleanEmail == AppRoles.superAdminEmail.toLowerCase() && cleanPassword == '29583026') {
        if (foundUser.password != '29583026') {
          foundUser = foundUser.copyWith(password: '29583026', documentNumber: '29583026');
          _users[userIndex] = foundUser;
          await _storage.saveUsers(_users);
        }
      }

      // Verificar contraseña
      if (foundUser.password != cleanPassword) {
        _errorMessage = 'Contraseña incorrecta.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _currentUser = foundUser;
      await _storage.saveSessionUser(_currentUser);
      await _storage.prefs.setString('vc_staff_last_email', foundUser.email);
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
    _demoUsers = [];
    await _storage.saveSessionUser(null);
    notifyListeners();
  }

  /// Retorna el último usuario que inició sesión
  UserModel? getLastLoggedInUser() {
    final lastEmail = _storage.prefs.getString('vc_staff_last_email');
    if (lastEmail == null || lastEmail.isEmpty) {
      if (_users.isNotEmpty) return _users.first;
      return null;
    }
    try {
      return _users.firstWhere(
        (u) => u.email.trim().toLowerCase() == lastEmail.trim().toLowerCase(),
      );
    } catch (_) {
      return _users.isNotEmpty ? _users.first : null;
    }
  }

  /// Inicia sesión biométrica directa para el último usuario verificado
  Future<bool> loginWithBiometrics(UserModel user) async {
    if (user.id == DemoData.demoUserId) {
      _currentUser = DemoData.getDemoUser();
      _demoUsers = DemoData.getDemoUsers();
      await _storage.saveSessionUser(_currentUser);
      await _storage.prefs.setString('vc_staff_last_email', user.email);
      notifyListeners();
      return true;
    }
    _currentUser = user;
    await _storage.saveSessionUser(_currentUser);
    await _storage.prefs.setString('vc_staff_last_email', user.email);
    notifyListeners();
    return true;
  }

  /// Actualiza la contraseña del usuario actual
  Future<bool> updatePassword(String newPassword) async {
    if (_currentUser == null) return false;
    if (newPassword.trim().isEmpty) return false;

    if (isDemoMode) {
      final updated = _currentUser!.copyWith(password: newPassword.trim());
      _currentUser = updated;
      final index = _demoUsers.indexWhere((u) => u.id == updated.id);
      if (index != -1) {
        _demoUsers[index] = updated;
      }
      notifyListeners();
      return true;
    }

    final updated = _currentUser!.copyWith(password: newPassword.trim());
    final index = _users.indexWhere((u) => u.id == updated.id);
    if (index != -1) {
      _users[index] = updated;
      _currentUser = updated;
      await _storage.saveUsers(_users);
      await _storage.saveSessionUser(_currentUser);
      firestoreSync?.syncUser(updated);
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Actualiza los datos de perfil del usuario actual (Nombre, Email, Teléfono, Instagram, Foto)
  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    String? instagram,
    String? photoUrl,
  }) async {
    if (_currentUser == null) return false;
    final cleanFirst = firstName.trim();
    final cleanLast = lastName.trim();
    final cleanEmail = email.trim().toLowerCase();
    final cleanPhone = phone.trim();
    String? cleanIg = instagram?.trim();
    if (cleanIg != null && cleanIg.startsWith('@')) {
      cleanIg = cleanIg.substring(1);
    }

    if (isDemoMode) {
      final updated = _currentUser!.copyWith(
        firstName: cleanFirst.isNotEmpty ? cleanFirst : _currentUser!.firstName,
        lastName: cleanLast.isNotEmpty ? cleanLast : _currentUser!.lastName,
        email: cleanEmail.isNotEmpty ? cleanEmail : _currentUser!.email,
        phone: cleanPhone.isNotEmpty ? cleanPhone : _currentUser!.phone,
        instagram: cleanIg,
        photoUrl: photoUrl ?? _currentUser!.photoUrl,
      );
      _currentUser = updated;
      final index = _demoUsers.indexWhere((u) => u.id == updated.id);
      if (index != -1) {
        _demoUsers[index] = updated;
      }
      notifyListeners();
      return true;
    }

    final updated = _currentUser!.copyWith(
      firstName: cleanFirst.isNotEmpty ? cleanFirst : _currentUser!.firstName,
      lastName: cleanLast.isNotEmpty ? cleanLast : _currentUser!.lastName,
      email: cleanEmail.isNotEmpty ? cleanEmail : _currentUser!.email,
      phone: cleanPhone.isNotEmpty ? cleanPhone : _currentUser!.phone,
      instagram: cleanIg,
      photoUrl: photoUrl ?? _currentUser!.photoUrl,
    );

    final index = _users.indexWhere((u) => u.id == updated.id);
    if (index != -1) {
      _users[index] = updated;
    }
    _currentUser = updated;
    await _storage.saveUsers(_users);
    await _storage.saveSessionUser(_currentUser);
    firestoreSync?.syncUser(updated);
    notifyListeners();
    return true;
  }

  /// Actualiza la foto de perfil de cualquier usuario (Admin o usuario propio)
  Future<bool> updateUserPhoto({
    required String userId,
    required String? photoUrl,
  }) async {
    if (isDemoMode) {
      final index = _demoUsers.indexWhere((u) => u.id == userId);
      if (index == -1) return false;
      final isRemoving = photoUrl == null || photoUrl.trim().isEmpty;
      final updated = _demoUsers[index].copyWith(
        photoUrl: isRemoving ? null : photoUrl.trim(),
        clearPhoto: isRemoving,
      );
      _demoUsers[index] = updated;
      if (_currentUser?.id == userId) {
        _currentUser = updated;
      }
      notifyListeners();
      return true;
    }

    final index = _users.indexWhere((u) => u.id == userId);
    if (index == -1) return false;

    final isRemoving = photoUrl == null || photoUrl.trim().isEmpty;
    final updated = _users[index].copyWith(
      photoUrl: isRemoving ? null : photoUrl.trim(),
      clearPhoto: isRemoving,
    );
    _users[index] = updated;

    if (_currentUser?.id == userId) {
      _currentUser = updated;
      await _storage.saveSessionUser(_currentUser);
    }

    await _storage.saveUsers(_users);
    firestoreSync?.syncUser(updated);
    notifyListeners();
    return true;
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

    if (isDemoMode) {
      if (_demoUsers.any((u) => u.email.trim().toLowerCase() == cleanEmail)) {
        _errorMessage = 'Ya existe un usuario registrado con el email $cleanEmail.';
        notifyListeners();
        return false;
      }
      final rolesList = initialRoles.contains(AppRoles.miembro)
          ? initialRoles
          : [AppRoles.miembro, ...initialRoles];
      final newUser = UserModel(
        id: const Uuid().v4(),
        email: cleanEmail,
        password: cleanDoc,
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
      _demoUsers.add(newUser);
      notifyListeners();
      return true;
    }

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
    firestoreSync?.syncUser(newUser);
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

    if (isDemoMode) {
      final index = _demoUsers.indexWhere((u) => u.id == userId);
      if (index == -1) return false;
      final cleanRoles = newRoles.contains(AppRoles.miembro)
          ? newRoles
          : [AppRoles.miembro, ...newRoles];
      final updated = _demoUsers[index].copyWith(roles: cleanRoles);
      _demoUsers[index] = updated;
      if (_currentUser!.id == userId) {
        _currentUser = updated;
      }
      notifyListeners();
      return true;
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
    firestoreSync?.syncUser(updated);
    notifyListeners();
    return true;
  }

  /// Actualizar datos de perfil
  Future<bool> updateUserProfile(UserModel updatedUser) async {
    if (isDemoMode) {
      final index = _demoUsers.indexWhere((u) => u.id == updatedUser.id);
      if (index == -1) return false;
      final isRemovingPhoto =
          updatedUser.photoUrl == null || updatedUser.photoUrl!.trim().isEmpty;
      final normalizedUser = updatedUser.copyWith(
        photoUrl: isRemovingPhoto ? null : updatedUser.photoUrl!.trim(),
        clearPhoto: isRemovingPhoto,
      );
      _demoUsers[index] = normalizedUser;
      if (_currentUser?.id == normalizedUser.id) {
        _currentUser = normalizedUser;
      }
      notifyListeners();
      return true;
    }

    final index = _users.indexWhere((u) => u.id == updatedUser.id);
    if (index == -1) return false;

    final isRemovingPhoto =
        updatedUser.photoUrl == null || updatedUser.photoUrl!.trim().isEmpty;
    final normalizedUser = updatedUser.copyWith(
      photoUrl: isRemovingPhoto ? null : updatedUser.photoUrl!.trim(),
      clearPhoto: isRemovingPhoto,
    );

    _users[index] = normalizedUser;
    if (_currentUser?.id == normalizedUser.id) {
      _currentUser = normalizedUser;
      await _storage.saveSessionUser(_currentUser);
    }

    await _storage.saveUsers(_users);
    firestoreSync?.syncUser(normalizedUser);
    notifyListeners();
    return true;
  }

  /// Actualización completa de datos de usuario por parte de un administrador (RRHH o Superadmin).
  /// Regla de negocio: Si se modifica el número de documento, la contraseña se restablece automáticamente a ese nuevo documento.
  Future<bool> updateUserByAdmin({
    required String userId,
    required String firstName,
    required String lastName,
    required String email,
    required String documentType,
    required String documentNumber,
    required String phone,
    String? instagram,
    DateTime? birthDate,
    String? photoUrl,
    List<String>? roles,
    String? region,
    int? manualAttendanceCount,
    bool clearManualAttendance = false,
  }) async {
    _errorMessage = null;

    if (isDemoMode) {
      final index = _demoUsers.indexWhere((u) => u.id == userId);
      if (index == -1) {
        _errorMessage = 'Usuario no encontrado.';
        notifyListeners();
        return false;
      }
      final existing = _demoUsers[index];
      final cleanEmail = email.trim().toLowerCase();
      final cleanDoc = documentNumber.trim();
      final bool docChanged = existing.documentNumber.trim() != cleanDoc;
      final String passwordToSet = docChanged ? cleanDoc : existing.password;
      List<String> cleanRoles = existing.roles;
      if (roles != null) {
        cleanRoles = roles.contains(AppRoles.miembro)
            ? roles
            : [AppRoles.miembro, ...roles];
      }
      final updated = existing.copyWith(
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        email: cleanEmail,
        documentType: documentType.trim(),
        documentNumber: cleanDoc,
        password: passwordToSet,
        phone: phone.trim(),
        instagram: instagram?.trim(),
        birthDate: birthDate ?? existing.birthDate,
        photoUrl: photoUrl ?? existing.photoUrl,
        roles: cleanRoles,
        region: region != null && region.trim().isNotEmpty ? region.trim() : existing.region,
        manualAttendanceCount: clearManualAttendance ? null : (manualAttendanceCount ?? existing.manualAttendanceCount),
      );
      _demoUsers[index] = updated;
      if (_currentUser?.id == userId) {
        _currentUser = updated;
      }
      notifyListeners();
      return true;
    }

    final index = _users.indexWhere((u) => u.id == userId);
    if (index == -1) {
      _errorMessage = 'Usuario no encontrado.';
      notifyListeners();
      return false;
    }

    final existing = _users[index];
    final cleanEmail = email.trim().toLowerCase();
    final cleanDoc = documentNumber.trim();

    // Validar duplicado de email
    if (_users.any((u) => u.id != userId && u.email.trim().toLowerCase() == cleanEmail)) {
      _errorMessage = 'Ya existe otro usuario registrado con el email $cleanEmail.';
      notifyListeners();
      return false;
    }

    // Validar duplicado de documento
    if (_users.any((u) => u.id != userId && u.documentNumber.trim() == cleanDoc)) {
      _errorMessage = 'Ya existe otro usuario con el número de documento $cleanDoc.';
      notifyListeners();
      return false;
    }

    // Si se edita el documento de un usuario se resetea la clave a ese numero de documento
    final bool docChanged = existing.documentNumber.trim() != cleanDoc;
    final String passwordToSet = docChanged ? cleanDoc : existing.password;

    // Roles (preservar el rol Miembro como obligatorio)
    List<String> cleanRoles = existing.roles;
    if (roles != null) {
      cleanRoles = roles.contains(AppRoles.miembro)
          ? roles
          : [AppRoles.miembro, ...roles];
    }

    final updated = existing.copyWith(
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: cleanEmail,
      documentType: documentType.trim(),
      documentNumber: cleanDoc,
      password: passwordToSet,
      phone: phone.trim(),
      instagram: instagram?.trim(),
      birthDate: birthDate ?? existing.birthDate,
      photoUrl: photoUrl ?? existing.photoUrl,
      roles: cleanRoles,
      region: region != null && region.trim().isNotEmpty ? region.trim() : existing.region,
      manualAttendanceCount: clearManualAttendance ? null : (manualAttendanceCount ?? existing.manualAttendanceCount),
    );

    _users[index] = updated;

    if (_currentUser?.id == userId) {
      _currentUser = updated;
      await _storage.saveSessionUser(_currentUser);
    }

    await _storage.saveUsers(_users);
    firestoreSync?.syncUser(updated);
    notifyListeners();
    return true;
  }

  /// Actualiza la región de un usuario (exclusivo para administración de equipo)
  Future<bool> updateUserRegion(String userId, String newRegion) async {
    if (isDemoMode) {
      final index = _demoUsers.indexWhere((u) => u.id == userId);
      if (index == -1) return false;
      final updated = _demoUsers[index].copyWith(region: newRegion);
      _demoUsers[index] = updated;
      if (_currentUser?.id == userId) {
        _currentUser = updated;
      }
      notifyListeners();
      return true;
    }

    final index = _users.indexWhere((u) => u.id == userId);
    if (index == -1) return false;
    final updated = _users[index].copyWith(region: newRegion);
    _users[index] = updated;
    if (_currentUser?.id == userId) {
      _currentUser = updated;
      await _storage.saveSessionUser(_currentUser);
    }
    await _storage.saveUsers(_users);
    firestoreSync?.syncUser(updated);
    notifyListeners();
    return true;
  }

  /// Actualiza o limpia el ajuste manual de asistencias de un usuario
  Future<bool> updateUserManualAttendance(String userId, int? attendanceCount) async {
    if (isDemoMode) {
      final index = _demoUsers.indexWhere((u) => u.id == userId);
      if (index == -1) return false;
      final updated = _demoUsers[index].copyWith(
        manualAttendanceCount: attendanceCount,
      );
      _demoUsers[index] = updated;
      if (_currentUser?.id == userId) {
        _currentUser = updated;
      }
      notifyListeners();
      return true;
    }

    final index = _users.indexWhere((u) => u.id == userId);
    if (index == -1) return false;
    final updated = _users[index].copyWith(
      manualAttendanceCount: attendanceCount,
    );
    _users[index] = updated;
    if (_currentUser?.id == userId) {
      _currentUser = updated;
      await _storage.saveSessionUser(_currentUser);
    }
    await _storage.saveUsers(_users);
    firestoreSync?.syncUser(updated);
    notifyListeners();
    return true;
  }

  /// Elimina un usuario del sistema (solo RRHH o Superadmin).
  /// El superadmin del sistema no puede ser eliminado bajo ninguna circunstancia.
  Future<bool> deleteUser(String userId) async {
    _errorMessage = null;

    if (isDemoMode) {
      final index = _demoUsers.indexWhere((u) => u.id == userId);
      if (index == -1) {
        _errorMessage = 'Usuario no encontrado.';
        notifyListeners();
        return false;
      }
      final userToDelete = _demoUsers[index];
      if (userToDelete.isSuperAdmin || userToDelete.id == DemoData.demoUserId) {
        _errorMessage = 'No se puede eliminar la cuenta de Superadmin demo.';
        notifyListeners();
        return false;
      }
      _demoUsers.removeAt(index);
      notifyListeners();
      return true;
    }

    final index = _users.indexWhere((u) => u.id == userId);
    if (index == -1) {
      _errorMessage = 'Usuario no encontrado.';
      notifyListeners();
      return false;
    }

    final userToDelete = _users[index];
    if (userToDelete.isSuperAdmin ||
        userToDelete.email.trim().toLowerCase() ==
            AppRoles.superAdminEmail.toLowerCase()) {
      _errorMessage =
          'No se puede eliminar la cuenta de Superadmin del sistema.';
      notifyListeners();
      return false;
    }

    _users.removeAt(index);

    if (_currentUser?.id == userId) {
      _currentUser = null;
      await _storage.saveSessionUser(null);
    }

    await _storage.saveUsers(_users);
    firestoreSync?.deleteUser(userId);
    notifyListeners();
    return true;
  }
}
