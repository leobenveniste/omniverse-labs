import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/event_model.dart';
import '../models/event_pair.dart';
import '../models/event_round_log.dart';
import '../models/event_unified_report.dart';
import '../models/user_model.dart';
import 'storage_service.dart';
import 'firestore_sync_service.dart';
import 'auth_service.dart';
import 'demo_data.dart';

class EventService extends ChangeNotifier {
  final StorageService _storage;
  final FirestoreSyncService? firestoreSync;
  final AuthService? authService;
  List<EventModel> _events = [];
  List<EventModel> _demoEvents = [];

  EventService(
    this._storage, {
    this.firestoreSync,
    this.authService,
  }) {
    _events = _storage.loadEvents();
    _demoEvents = DemoData.getDemoEvents();
    authService?.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    if (isDemoMode && _demoEvents.isEmpty) {
      _demoEvents = DemoData.getDemoEvents();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    authService?.removeListener(_onAuthChanged);
    super.dispose();
  }

  bool get isDemoMode => authService?.isDemoMode ?? false;

  void resetDemoData() {
    _demoEvents = DemoData.getDemoEvents();
    notifyListeners();
  }

  /// Recarga eventos cuando Firestore detecta cambios remotos
  void reloadEventsFromStorage() {
    if (isDemoMode) return;
    _events = _storage.loadEvents();
    notifyListeners();
  }

  List<EventModel> get events =>
      List.unmodifiable(isDemoMode ? _demoEvents : _events);

  EventModel? getEventById(String id) {
    try {
      final list = isDemoMode ? _demoEvents : _events;
      return list.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Crea un nuevo evento (Organización, Producción o Superadmin)
  Future<bool> createEvent({
    required String name,
    required DateTime date,
    required String startTime,
    required String doorsOpenTime,
    required String endTime,
    required String location,
    String? address,
    String? imageUrl,
    int requiredStaffCount = 15,
    String region = AppRegions.buenosAires,
    required UserModel currentUser,
  }) async {
    if (!currentUser.canCreateEvents) {
      return false;
    }

    final newEvent = EventModel(
      id: const Uuid().v4(),
      name: name.trim(),
      date: date,
      startTime: startTime.trim(),
      doorsOpenTime: doorsOpenTime.trim(),
      endTime: endTime.trim(),
      location: location.trim(),
      address: address?.trim().isEmpty == true ? null : address?.trim(),
      imageUrl: imageUrl?.trim().isEmpty == true ? null : imageUrl?.trim(),
      requiredStaffCount: requiredStaffCount > 0 ? requiredStaffCount : 15,
      region: region.trim().isEmpty ? AppRegions.buenosAires : region.trim(),
      staffIds: const [], // Ningún miembro asociado automáticamente por defecto
      confirmedStaffIds: const [],
      absentStaffIds: const [],
      createdBy: currentUser.id,
      createdByName: currentUser.fullName,
      createdAt: DateTime.now(),
      isManuallyStarted: false,
      isManuallyClosed: false,
    );

    if (isDemoMode) {
      _demoEvents.insert(0, newEvent);
      notifyListeners();
      return true;
    }

    _events.insert(0, newEvent);
    await _storage.saveEvents(_events);
    firestoreSync?.syncEvent(newEvent);
    notifyListeners();
    return true;
  }

  /// Actualiza un evento existente (Organización, Producción o Superadmin)
  Future<bool> updateEvent({
    required String eventId,
    required String name,
    required DateTime date,
    required String startTime,
    required String doorsOpenTime,
    required String endTime,
    required String location,
    String? address,
    String? imageUrl,
    required int requiredStaffCount,
    String? region,
    required UserModel currentUser,
  }) async {
    if (!currentUser.canCreateEvents) {
      return false;
    }

    if (isDemoMode) {
      final index = _demoEvents.indexWhere((e) => e.id == eventId);
      if (index == -1) return false;
      final existing = _demoEvents[index];
      final updated = existing.copyWith(
        name: name.trim(),
        date: date,
        startTime: startTime.trim(),
        doorsOpenTime: doorsOpenTime.trim(),
        endTime: endTime.trim(),
        location: location.trim(),
        address: address?.trim().isEmpty == true ? null : address?.trim(),
        imageUrl: imageUrl?.trim().isEmpty == true ? null : imageUrl?.trim(),
        requiredStaffCount: requiredStaffCount > 0 ? requiredStaffCount : 15,
        region: region != null && region.trim().isNotEmpty ? region.trim() : existing.region,
      );
      _demoEvents[index] = updated;
      notifyListeners();
      return true;
    }

    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return false;

    final existing = _events[index];
    final updated = existing.copyWith(
      name: name.trim(),
      date: date,
      startTime: startTime.trim(),
      doorsOpenTime: doorsOpenTime.trim(),
      endTime: endTime.trim(),
      location: location.trim(),
      address: address?.trim().isEmpty == true ? null : address?.trim(),
      imageUrl: imageUrl?.trim().isEmpty == true ? null : imageUrl?.trim(),
      requiredStaffCount: requiredStaffCount > 0 ? requiredStaffCount : 15,
      region: region != null && region.trim().isNotEmpty ? region.trim() : existing.region,
    );

    _events[index] = updated;
    await _storage.saveEvents(_events);
    firestoreSync?.syncEvent(updated);
    notifyListeners();
    return true;
  }

  /// Elimina un evento existente (Organización, Producción o Superadmin)
  Future<bool> deleteEvent(String eventId, UserModel currentUser) async {
    if (!currentUser.canCreateEvents) {
      return false;
    }

    if (isDemoMode) {
      final index = _demoEvents.indexWhere((e) => e.id == eventId);
      if (index == -1) return false;
      _demoEvents.removeAt(index);
      notifyListeners();
      return true;
    }

    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return false;

    _events.removeAt(index);
    await _storage.saveEvents(_events);
    firestoreSync?.deleteEvent(eventId);
    notifyListeners();
    return true;
  }

  /// Permite a un miembro del staff anotarse a un evento (queda pendiente de confirmación)
  Future<bool> joinEvent(String eventId, String userId) async {
    if (isDemoMode) {
      final index = _demoEvents.indexWhere((e) => e.id == eventId);
      if (index == -1) return false;
      final event = _demoEvents[index];
      if (event.staffIds.contains(userId)) return true;
      final updatedStaff = List<String>.from(event.staffIds)..add(userId);
      final updated = event.copyWith(staffIds: updatedStaff);
      _demoEvents[index] = updated;
      notifyListeners();
      return true;
    }

    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return false;

    final event = _events[index];
    if (event.staffIds.contains(userId)) {
      return true; // Ya está anotado
    }

    final updatedStaff = List<String>.from(event.staffIds)..add(userId);
    final updated = event.copyWith(staffIds: updatedStaff);
    _events[index] = updated;

    await _storage.saveEvents(_events);
    firestoreSync?.syncEvent(updated);
    notifyListeners();
    return true;
  }

  /// Permite a un miembro bajarse de un evento si aún no comenzó
  Future<bool> leaveEvent(String eventId, String userId) async {
    if (isDemoMode) {
      final index = _demoEvents.indexWhere((e) => e.id == eventId);
      if (index == -1) return false;
      final event = _demoEvents[index];
      final updatedStaff = List<String>.from(event.staffIds)..remove(userId);
      final updatedConfirmed = List<String>.from(event.confirmedStaffIds)..remove(userId);
      final updatedAbsent = List<String>.from(event.absentStaffIds)..remove(userId);
      final updatedPairs = List<EventPair>.from(event.pairs)
        ..removeWhere((p) => p.containsUser(userId));
      final updated = event.copyWith(
        staffIds: updatedStaff,
        confirmedStaffIds: updatedConfirmed,
        absentStaffIds: updatedAbsent,
        pairs: updatedPairs,
      );
      _demoEvents[index] = updated;
      notifyListeners();
      return true;
    }

    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return false;

    final event = _events[index];
    final updatedStaff = List<String>.from(event.staffIds)..remove(userId);
    final updatedConfirmed = List<String>.from(event.confirmedStaffIds)..remove(userId);
    final updatedAbsent = List<String>.from(event.absentStaffIds)..remove(userId);
    final updatedPairs = List<EventPair>.from(event.pairs)
      ..removeWhere((p) => p.containsUser(userId));

    final updated = event.copyWith(
      staffIds: updatedStaff,
      confirmedStaffIds: updatedConfirmed,
      absentStaffIds: updatedAbsent,
      pairs: updatedPairs,
    );
    _events[index] = updated;

    await _storage.saveEvents(_events);
    firestoreSync?.syncEvent(updated);
    notifyListeners();
    return true;
  }

  /// Confirma a un miembro anotado para el evento
  Future<bool> confirmStaffMember({
    required String eventId,
    required String userId,
    required UserModel currentUser,
  }) async {
    final canManage = currentUser.isSuperAdmin ||
        currentUser.hasRole(AppRoles.organizacion) ||
        currentUser.hasRole(AppRoles.produccion) ||
        currentUser.hasRole(AppRoles.rrhh);
    if (!canManage) return false;

    if (isDemoMode) {
      final index = _demoEvents.indexWhere((e) => e.id == eventId);
      if (index == -1) return false;
      final event = _demoEvents[index];
      final updatedStaff = List<String>.from(event.staffIds);
      if (!updatedStaff.contains(userId)) updatedStaff.add(userId);
      final updatedConfirmed = List<String>.from(event.confirmedStaffIds);
      if (!updatedConfirmed.contains(userId)) updatedConfirmed.add(userId);
      final updated = event.copyWith(
        staffIds: updatedStaff,
        confirmedStaffIds: updatedConfirmed,
      );
      _demoEvents[index] = updated;
      notifyListeners();
      return true;
    }

    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return false;

    final event = _events[index];
    final updatedStaff = List<String>.from(event.staffIds);
    if (!updatedStaff.contains(userId)) {
      updatedStaff.add(userId);
    }
    final updatedConfirmed = List<String>.from(event.confirmedStaffIds);
    if (!updatedConfirmed.contains(userId)) {
      updatedConfirmed.add(userId);
    }

    final updated = event.copyWith(
      staffIds: updatedStaff,
      confirmedStaffIds: updatedConfirmed,
    );
    _events[index] = updated;

    await _storage.saveEvents(_events);
    firestoreSync?.syncEvent(updated);
    notifyListeners();
    return true;
  }

  /// Remueve o saca a un miembro del evento (desanota y desconfirma)
  Future<bool> removeStaffMember({
    required String eventId,
    required String userId,
    required UserModel currentUser,
  }) async {
    final canManage = currentUser.isSuperAdmin ||
        currentUser.hasRole(AppRoles.organizacion) ||
        currentUser.hasRole(AppRoles.produccion) ||
        currentUser.hasRole(AppRoles.rrhh);
    if (!canManage) return false;

    if (isDemoMode) {
      final index = _demoEvents.indexWhere((e) => e.id == eventId);
      if (index == -1) return false;
      final event = _demoEvents[index];
      final updatedStaff = List<String>.from(event.staffIds)..remove(userId);
      final updatedConfirmed = List<String>.from(event.confirmedStaffIds)..remove(userId);
      final updatedAbsent = List<String>.from(event.absentStaffIds)..remove(userId);
      final updatedPairs = List<EventPair>.from(event.pairs)
        ..removeWhere((p) => p.containsUser(userId));
      final updated = event.copyWith(
        staffIds: updatedStaff,
        confirmedStaffIds: updatedConfirmed,
        absentStaffIds: updatedAbsent,
        pairs: updatedPairs,
      );
      _demoEvents[index] = updated;
      notifyListeners();
      return true;
    }

    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return false;

    final event = _events[index];
    final updatedStaff = List<String>.from(event.staffIds)..remove(userId);
    final updatedConfirmed = List<String>.from(event.confirmedStaffIds)..remove(userId);
    final updatedAbsent = List<String>.from(event.absentStaffIds)..remove(userId);
    final updatedPairs = List<EventPair>.from(event.pairs)
      ..removeWhere((p) => p.containsUser(userId));

    final updated = event.copyWith(
      staffIds: updatedStaff,
      confirmedStaffIds: updatedConfirmed,
      absentStaffIds: updatedAbsent,
      pairs: updatedPairs,
    );
    _events[index] = updated;

    await _storage.saveEvents(_events);
    firestoreSync?.syncEvent(updated);
    notifyListeners();
    return true;
  }

  /// Establece la lista de miembros ausentes en el evento (para conteo de asistencia)
  Future<bool> setAbsentStaff({
    required String eventId,
    required List<String> absentStaffIds,
    required UserModel currentUser,
  }) async {
    final canManage = currentUser.isSuperAdmin ||
        currentUser.hasRole(AppRoles.organizacion) ||
        currentUser.hasRole(AppRoles.produccion) ||
        currentUser.hasRole(AppRoles.rrhh);
    if (!canManage) return false;

    if (isDemoMode) {
      final index = _demoEvents.indexWhere((e) => e.id == eventId);
      if (index == -1) return false;
      final updated = _demoEvents[index].copyWith(absentStaffIds: absentStaffIds);
      _demoEvents[index] = updated;
      notifyListeners();
      return true;
    }

    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return false;

    final updated = _events[index].copyWith(absentStaffIds: absentStaffIds);
    _events[index] = updated;

    await _storage.saveEvents(_events);
    firestoreSync?.syncEvent(updated);
    notifyListeners();
    return true;
  }

  /// Alterna inicio manual del evento
  Future<void> toggleEventStarted(String eventId) async {
    if (isDemoMode) {
      final index = _demoEvents.indexWhere((e) => e.id == eventId);
      if (index != -1) {
        final current = _demoEvents[index];
        _demoEvents[index] = current.copyWith(
          isManuallyStarted: !current.isManuallyStarted,
        );
        notifyListeners();
      }
      return;
    }

    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return;

    final current = _events[index];
    final updated = current.copyWith(
      isManuallyStarted: !current.isManuallyStarted,
    );
    _events[index] = updated;

    await _storage.saveEvents(_events);
    firestoreSync?.syncEvent(updated);
    notifyListeners();
  }

  /// Cierra el evento al finalizar
  Future<void> closeEvent(String eventId) async {
    if (isDemoMode) {
      final index = _demoEvents.indexWhere((e) => e.id == eventId);
      if (index != -1) {
        final updated = _demoEvents[index].copyWith(
          isManuallyClosed: true,
          isManuallyStarted: false,
        );
        _demoEvents[index] = updated;
        notifyListeners();
      }
      return;
    }

    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return;

    final updated = _events[index].copyWith(
      isManuallyClosed: true,
      isManuallyStarted: false,
    );
    _events[index] = updated;

    await _storage.saveEvents(_events);
    firestoreSync?.syncEvent(updated);
    notifyListeners();
  }

  /// Guarda o actualiza el Registro Unificado por Evento (exclusivo para Producción o Superadmin)
  Future<bool> saveEventReport({
    required String eventId,
    required EventUnifiedReport report,
    required UserModel currentUser,
  }) async {
    final canManageReport =
        currentUser.isSuperAdmin || currentUser.hasRole(AppRoles.produccion);
    if (!canManageReport) {
      return false;
    }

    if (isDemoMode) {
      final index = _demoEvents.indexWhere((e) => e.id == eventId);
      if (index == -1) return false;
      final current = _demoEvents[index];
      final updated = current.copyWith(unifiedReport: report);
      _demoEvents[index] = updated;
      notifyListeners();
      return true;
    }

    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return false;

    final current = _events[index];
    final updated = current.copyWith(unifiedReport: report);
    _events[index] = updated;

    await _storage.saveEvents(_events);
    firestoreSync?.syncEvent(updated);
    notifyListeners();
    return true;
  }

  /// Arma una pareja de guardia/ronda entre dos miembros del evento.
  /// Exclusivo para usuarios con rol de Organización o Producción (o Superadmin).
  Future<bool> addEventPair({
    required String eventId,
    required String user1Id,
    required String user1Name,
    required String user2Id,
    required String user2Name,
    required UserModel currentUser,
  }) async {
    final canManagePairs = currentUser.isSuperAdmin ||
        currentUser.hasRole(AppRoles.organizacion) ||
        currentUser.hasRole(AppRoles.produccion);
    if (!canManagePairs) return false;

    if (user1Id == user2Id) return false;

    if (isDemoMode) {
      final index = _demoEvents.indexWhere((e) => e.id == eventId);
      if (index == -1) return false;
      final event = _demoEvents[index];
      final currentPairs = List<EventPair>.from(event.pairs)
        ..removeWhere((p) => p.containsUser(user1Id) || p.containsUser(user2Id));
      final newPair = EventPair(
        id: const Uuid().v4(),
        user1Id: user1Id,
        user1Name: user1Name,
        user2Id: user2Id,
        user2Name: user2Name,
        createdAt: DateTime.now(),
      );
      currentPairs.add(newPair);
      final updated = event.copyWith(pairs: currentPairs);
      _demoEvents[index] = updated;
      notifyListeners();
      return true;
    }

    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return false;

    final event = _events[index];
    // Quitar previamente si alguno ya estaba en otra pareja para evitar duplicidad
    final currentPairs = List<EventPair>.from(event.pairs)
      ..removeWhere((p) => p.containsUser(user1Id) || p.containsUser(user2Id));

    final newPair = EventPair(
      id: const Uuid().v4(),
      user1Id: user1Id,
      user1Name: user1Name,
      user2Id: user2Id,
      user2Name: user2Name,
      createdAt: DateTime.now(),
    );

    currentPairs.add(newPair);
    final updated = event.copyWith(pairs: currentPairs);
    _events[index] = updated;

    await _storage.saveEvents(_events);
    firestoreSync?.syncEvent(updated);
    notifyListeners();
    return true;
  }

  /// Desarma una pareja de guardia/ronda (Organización, Producción o Superadmin).
  Future<bool> removeEventPair({
    required String eventId,
    required String pairId,
    required UserModel currentUser,
  }) async {
    final canManagePairs = currentUser.isSuperAdmin ||
        currentUser.hasRole(AppRoles.organizacion) ||
        currentUser.hasRole(AppRoles.produccion);
    if (!canManagePairs) return false;

    if (isDemoMode) {
      final index = _demoEvents.indexWhere((e) => e.id == eventId);
      if (index == -1) return false;
      final event = _demoEvents[index];
      final currentPairs = List<EventPair>.from(event.pairs)
        ..removeWhere((p) => p.id == pairId);
      final updated = event.copyWith(pairs: currentPairs);
      _demoEvents[index] = updated;
      notifyListeners();
      return true;
    }

    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return false;

    final event = _events[index];
    final currentPairs = List<EventPair>.from(event.pairs)
      ..removeWhere((p) => p.id == pairId);

    final updated = event.copyWith(pairs: currentPairs);
    _events[index] = updated;

    await _storage.saveEvents(_events);
    firestoreSync?.syncEvent(updated);
    notifyListeners();
    return true;
  }

  /// Agrega un registro de ronda al evento.
  /// Cualquier miembro participante del evento (o Superadmin) puede registrar una ronda.
  /// Asocia automáticamente a su pareja asignada si existe.
  Future<bool> addEventRoundLog({
    required String eventId,
    required int detectedCasesCount,
    required int callsCount,
    required String observations,
    required UserModel currentUser,
  }) async {
    if (isDemoMode) {
      final index = _demoEvents.indexWhere((e) => e.id == eventId);
      if (index == -1) return false;
      final event = _demoEvents[index];
      final assignedPair = event.getPairForUser(currentUser.id);
      final partnerId = assignedPair?.getPartnerId(currentUser.id);
      final partnerName = assignedPair?.getPartnerName(currentUser.id);
      final newLog = EventRoundLog(
        id: const Uuid().v4(),
        timestamp: DateTime.now(),
        memberId: currentUser.id,
        memberName: currentUser.fullName,
        partnerId: partnerId,
        partnerName: partnerName,
        detectedCasesCount: detectedCasesCount,
        callsCount: callsCount,
        observations: observations.trim(),
      );
      final updatedLogs = List<EventRoundLog>.from(event.roundLogs)
        ..insert(0, newLog);
      final updated = event.copyWith(roundLogs: updatedLogs);
      _demoEvents[index] = updated;
      notifyListeners();
      return true;
    }

    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return false;

    final event = _events[index];
    final isParticipant =
        event.isUserInStaff(currentUser.id) || currentUser.isSuperAdmin;
    if (!isParticipant) return false;

    final assignedPair = event.getPairForUser(currentUser.id);
    final partnerId = assignedPair?.getPartnerId(currentUser.id);
    final partnerName = assignedPair?.getPartnerName(currentUser.id);

    final newLog = EventRoundLog(
      id: const Uuid().v4(),
      timestamp: DateTime.now(),
      memberId: currentUser.id,
      memberName: currentUser.fullName,
      partnerId: partnerId,
      partnerName: partnerName,
      detectedCasesCount: detectedCasesCount,
      callsCount: callsCount,
      observations: observations.trim(),
    );

    final updatedLogs = List<EventRoundLog>.from(event.roundLogs)
      ..insert(0, newLog);
    final updated = event.copyWith(roundLogs: updatedLogs);
    _events[index] = updated;

    await _storage.saveEvents(_events);
    firestoreSync?.syncEvent(updated);
    notifyListeners();
    return true;
  }
}
