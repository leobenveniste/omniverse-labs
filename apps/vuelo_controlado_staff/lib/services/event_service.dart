import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import 'storage_service.dart';

class EventService extends ChangeNotifier {
  final StorageService _storage;
  List<EventModel> _events = [];

  EventService(this._storage) {
    _events = _storage.loadEvents();
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
    String? location,
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
      location: location?.trim(),
      staffIds: [currentUser.id], // El creador se suma automáticamente al staff
      createdBy: currentUser.id,
      createdByName: currentUser.fullName,
      createdAt: DateTime.now(),
      isManuallyStarted: false,
      isManuallyClosed: false,
    );

    _events.insert(0, newEvent);
    await _storage.saveEvents(_events);
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
    _events[index] = event.copyWith(staffIds: updatedStaff);

    await _storage.saveEvents(_events);
    notifyListeners();
    return true;
  }

  /// Permite a un miembro bajarse de un evento si aún no comenzó
  Future<bool> leaveEvent(String eventId, String userId) async {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return false;

    final event = _events[index];
    final updatedStaff = List<String>.from(event.staffIds)..remove(userId);
    _events[index] = event.copyWith(staffIds: updatedStaff);

    await _storage.saveEvents(_events);
    notifyListeners();
    return true;
  }

  /// Alterna inicio manual del evento
  Future<void> toggleEventStarted(String eventId) async {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return;

    final current = _events[index];
    _events[index] = current.copyWith(
      isManuallyStarted: !current.isManuallyStarted,
    );

    await _storage.saveEvents(_events);
    notifyListeners();
  }

  /// Cierra el evento al finalizar
  Future<void> closeEvent(String eventId) async {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return;

    _events[index] = _events[index].copyWith(
      isManuallyClosed: true,
      isManuallyStarted: false,
    );

    await _storage.saveEvents(_events);
    notifyListeners();
  }
}
