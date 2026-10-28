import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/event_model.dart';
import '../models/event_pair.dart';
import '../models/event_round_log.dart';
import '../models/event_unified_report.dart';
import '../models/user_model.dart';
import 'storage_service.dart';
import 'firestore_sync_service.dart';

class EventService extends ChangeNotifier {
  final StorageService _storage;
  final FirestoreSyncService? firestoreSync;
  List<EventModel> _events = [];

  EventService(this._storage, {this.firestoreSync}) {
    _events = _storage.loadEvents();
  }

  /// Recarga eventos cuando Firestore detecta cambios remotos
  void reloadEventsFromStorage() {
    _events = _storage.loadEvents();
    notifyListeners();
  }

  List<EventModel> get events => List.unmodifiable(_events);

  EventModel? getEventById(String id) {
    try {
      return _events.firstWhere((e) => e.id == id);
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
      staffIds: const [], // Ningún miembro asociado automáticamente por defecto
      createdBy: currentUser.id,
      createdByName: currentUser.fullName,
      createdAt: DateTime.now(),
      isManuallyStarted: false,
      isManuallyClosed: false,
    );

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
    required UserModel currentUser,
  }) async {
    if (!currentUser.canCreateEvents) {
      return false;
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

    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return false;

    _events.removeAt(index);
    await _storage.saveEvents(_events);
    firestoreSync?.deleteEvent(eventId);
    notifyListeners();
    return true;
  }

  /// Permite a un miembro del staff sumarse a un evento
  Future<bool> joinEvent(String eventId, String userId) async {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return false;

    final event = _events[index];
    if (event.staffIds.contains(userId)) {
      return true; // Ya está sumado
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
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return false;

    final event = _events[index];
    final updatedStaff = List<String>.from(event.staffIds)..remove(userId);
    final updated = event.copyWith(staffIds: updatedStaff);
    _events[index] = updated;

    await _storage.saveEvents(_events);
    firestoreSync?.syncEvent(updated);
    notifyListeners();
    return true;
  }

  /// Alterna inicio manual del evento
  Future<void> toggleEventStarted(String eventId) async {
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
