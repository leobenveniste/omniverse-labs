import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import 'online_firestore_service.dart';

class AuthService extends ChangeNotifier {
  final OnlineFirestoreService _firestore;
  final SharedPreferences _prefs;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  static const String _sessionUserKey = 'circulo_session_user_id';
  static const String _lastEmailKey = 'circulo_last_email';

  AuthService(this._firestore, this._prefs) {
    _initSession();
  }

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password.trim())).toString();
  }

  Future<void> _initSession() async {
    final savedId = _prefs.getString(_sessionUserKey);
    if (savedId != null && savedId.isNotEmpty) {
      final user = await _firestore.getUserById(savedId);
      if (user != null) {
        _currentUser = user;
        notifyListeners();
      }
    }
  }

  UserModel? getLastLoggedInUser() {
    final lastEmail = _prefs.getString(_lastEmailKey);
    if (lastEmail == null || lastEmail.isEmpty) {
      return null;
    }
    for (final u in _firestore.currentUsers) {
      if (u.email.trim().toLowerCase() == lastEmail.trim().toLowerCase()) {
        return u;
      }
    }
    return null;
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cleanEmail = email.trim().toLowerCase();
      final cleanPass = password.trim();

      var user = await _firestore.getUserByEmail(cleanEmail);
      if (user == null) {
        _errorMessage = 'No se encontró un usuario con ese correo electrónico.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Bypass Superadmin para pruebas
      final bool isSuperAdminPass =
          cleanEmail == AppRoles.superAdminEmail.toLowerCase() &&
              cleanPass == '29583026';

      final hashedInput = _hashPassword(cleanPass);
      if (!isSuperAdminPass && user.passwordHash != hashedInput) {
        _errorMessage = 'Contraseña incorrecta.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _currentUser = user;
      await _prefs.setString(_sessionUserKey, user.id);
      await _prefs.setString(_lastEmailKey, user.email);
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

  Future<bool> loginWithBiometrics(UserModel user) async {
    _currentUser = user;
    await _prefs.setString(_sessionUserKey, user.id);
    await _prefs.setString(_lastEmailKey, user.email);
    notifyListeners();
    return true;
  }

  Future<bool> registerPublicUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required DateTime birthDate,
    required String region,
    String gender = AppGenders.preferNotToSay,
    String neighborhood = '',
    String phone = '',
    String? instagram,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cleanEmail = email.trim().toLowerCase();
      final existing = await _firestore.getUserByEmail(cleanEmail);
      if (existing != null) {
        _errorMessage = 'Ya existe una cuenta con el correo $cleanEmail.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final uid = const Uuid().v4();
      final code = 'CIR-${uid.substring(0, 4).toUpperCase()}';

      final newUser = UserModel(
        id: uid,
        email: cleanEmail,
        passwordHash: _hashPassword(password),
        authProvider: 'email',
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        birthDate: birthDate,
        gender: gender,
        phone: phone.trim(),
        instagram: instagram?.replaceAll('@', '').trim(),
        region: region.trim(),
        neighborhood: neighborhood.trim(),
        duoInviteCode: code,
        onboardingCompleted: false,
        createdAt: DateTime.now(),
      );

      await _firestore.upsertUser(newUser);
      _currentUser = newUser;
      await _prefs.setString(_sessionUserKey, newUser.id);
      await _prefs.setString(_lastEmailKey, newUser.email);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al crear la cuenta: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle({
    String? fallbackEmail,
    String? fallbackName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
      // Forzar que Google siempre muestre el diálogo de selección de cuentas
      try {
        await googleSignIn.signOut();
      } catch (_) {}

      final account = await googleSignIn.signIn();
      if (account == null) {
        // Usuario canceló la selección de cuenta
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final targetEmail = account.email.trim().toLowerCase();
      final displayName = account.displayName?.trim() ?? '';
      final firstFromGoogle = displayName.isNotEmpty
          ? displayName.split(' ').first
          : (fallbackName ?? 'Usuario Google');
      final lastFromGoogle = displayName.isNotEmpty && displayName.split(' ').length > 1
          ? displayName.split(' ').sublist(1).join(' ')
          : '';

      var user = await _firestore.getUserByEmail(targetEmail);
      if (user == null) {
        final uid = const Uuid().v4();
        final code = 'CIR-${uid.substring(0, 4).toUpperCase()}';
        user = UserModel(
          id: uid,
          email: targetEmail,
          passwordHash: _hashPassword('google_auth_oauth2'),
          authProvider: 'google',
          firstName: firstFromGoogle,
          lastName: lastFromGoogle,
          photoUrl: account.photoUrl,
          birthDate: DateTime(2000, 1, 1),
          duoInviteCode: code,
          onboardingCompleted: false,
          createdAt: DateTime.now(),
        );
        await _firestore.upsertUser(user);
      }

      _currentUser = user;
      await _prefs.setString(_sessionUserKey, user.id);
      await _prefs.setString(_lastEmailKey, user.email);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al conectar con Google: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeOnboarding({
    required String bio,
    required String? photoUrl,
    required String groupRole,
    required List<String> interests,
    required List<String> favoritePlans,
    required String socialVibe,
    required List<String> availabilitySlots,
    String? firstName,
    String? lastName,
    DateTime? birthDate,
    String? gender,
    String? region,
    String? neighborhood,
    String? phone,
    String? instagram,
  }) async {
    if (_currentUser == null) return false;

    final updated = _currentUser!.copyWith(
      firstName: firstName != null && firstName.trim().isNotEmpty
          ? firstName.trim()
          : _currentUser!.firstName,
      lastName: lastName != null && lastName.trim().isNotEmpty
          ? lastName.trim()
          : _currentUser!.lastName,
      birthDate: birthDate ?? _currentUser!.birthDate,
      gender: gender ?? _currentUser!.gender,
      region: region != null && region.trim().isNotEmpty
          ? region.trim()
          : _currentUser!.region,
      neighborhood: neighborhood != null && neighborhood.trim().isNotEmpty
          ? neighborhood.trim()
          : _currentUser!.neighborhood,
      phone: phone != null && phone.trim().isNotEmpty
          ? phone.trim()
          : _currentUser!.phone,
      instagram: instagram != null
          ? instagram.replaceAll('@', '').trim()
          : _currentUser!.instagram,
      bio: bio.trim(),
      photoUrl: photoUrl,
      groupRole: groupRole,
      interests: interests,
      favoritePlans: favoritePlans,
      socialVibe: socialVibe,
      availabilitySlots: availabilitySlots,
      onboardingCompleted: true,
    );

    await _firestore.upsertUser(updated);
    _currentUser = updated;
    notifyListeners();
    return true;
  }

  Future<bool> updateProfile(UserModel updatedUser) async {
    await _firestore.upsertUser(updatedUser);
    if (_currentUser?.id == updatedUser.id) {
      _currentUser = updatedUser;
    }
    notifyListeners();
    return true;
  }

  Future<void> refreshCurrentUser() async {
    if (_currentUser == null) return;
    final refreshed = await _firestore.getUserById(_currentUser!.id);
    if (refreshed != null) {
      _currentUser = refreshed;
      notifyListeners();
    }
  }

  Future<bool> toggleShareContactWithGroup(String groupId) async {
    if (_currentUser == null) return false;

    final currentShared = List<String>.from(_currentUser!.sharedContactGroupIds);
    if (currentShared.contains(groupId)) {
      currentShared.remove(groupId);
    } else {
      currentShared.add(groupId);
    }

    final updated =
        _currentUser!.copyWith(sharedContactGroupIds: currentShared);
    await _firestore.upsertUser(updated);
    _currentUser = updated;
    notifyListeners();
    return true;
  }

  Future<bool> linkDuoPartner(String partnerInviteCode) async {
    if (_currentUser == null) return false;
    final cleanCode = partnerInviteCode.trim().toUpperCase();

    UserModel? partner;
    for (final u in _firestore.currentUsers) {
      if (u.duoInviteCode.trim().toUpperCase() == cleanCode &&
          u.id != _currentUser!.id) {
        partner = u;
        break;
      }
    }

    if (partner == null) {
      _errorMessage = 'Código de Dupla no encontrado.';
      notifyListeners();
      return false;
    }

    final updatedMe = _currentUser!.copyWith(duoPartnerId: partner.id);
    final updatedPartner = partner.copyWith(duoPartnerId: _currentUser!.id);

    await _firestore.upsertUser(updatedMe);
    await _firestore.upsertUser(updatedPartner);

    _currentUser = updatedMe;
    notifyListeners();
    return true;
  }

  Future<bool> unlinkDuoPartner() async {
    if (_currentUser == null || _currentUser!.duoPartnerId == null) {
      return false;
    }

    final partnerId = _currentUser!.duoPartnerId!;
    final partner = await _firestore.getUserById(partnerId);

    final updatedMe = _currentUser!.copyWith(clearDuoPartner: true);
    await _firestore.upsertUser(updatedMe);

    if (partner != null) {
      final updatedPartner = partner.copyWith(clearDuoPartner: true);
      await _firestore.upsertUser(updatedPartner);
    }

    _currentUser = updatedMe;
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _currentUser = null;
    await _prefs.remove(_sessionUserKey);
    await _prefs.remove(_lastEmailKey);
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    notifyListeners();
  }

  // --- MÉTODOS DE ADMINISTRACIÓN (SUPERADMIN) ---

  Future<bool> updateUserManualMeetups(String userId, int? count) async {
    final user = await _firestore.getUserById(userId);
    if (user == null) return false;

    final updated = user.copyWith(
      manualMeetupCount: count,
      clearManualMeetups: count == null,
    );
    await _firestore.upsertUser(updated);
    if (_currentUser?.id == userId) {
      _currentUser = updated;
    }
    notifyListeners();
    return true;
  }

  Future<bool> deleteUserByAdmin(String userId) async {
    if (_currentUser == null || !_currentUser!.isSuperAdmin) return false;
    final target = await _firestore.getUserById(userId);
    if (target != null && target.isSuperAdmin) {
      _errorMessage = 'No se puede eliminar la cuenta de Superadmin.';
      notifyListeners();
      return false;
    }
    await _firestore.deleteUser(userId);
    notifyListeners();
    return true;
  }

  /// Eliminación definitiva de cuenta iniciada por el propio usuario (Google Play compliance)
  Future<bool> deleteMyAccount() async {
    if (_currentUser == null) return false;
    final uid = _currentUser!.id;
    try {
      await _firestore.deleteUser(uid);
      await logout();
      return true;
    } catch (e) {
      _errorMessage = 'Error al eliminar cuenta: $e';
      notifyListeners();
      return false;
    }
  }
}
