import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/case_model.dart';
import '../models/user_model.dart';
import '../models/event_model.dart';
import 'storage_service.dart';

class CaseService extends ChangeNotifier {
  final StorageService _storage;
  List<CaseModel> _cases = [];

  CaseService(this._storage) {
    _cases = _storage.loadCases();
  }

  List<CaseModel> get allCases => List.unmodifiable(_cases);

  List<CaseModel> getCasesForEvent(String eventId) {
    return _cases.where((c) => c.eventId == eventId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  int getPendingSyncCount(String eventId) {
    return _cases.where((c) => c.eventId == eventId && !c.isSyncedToDrive).length;
  }

  /// Registra una nueva ficha de caso 100% offline
  Future<CaseModel> createCase({
    required EventModel event,
    required UserModel currentUser,
    required String personName,
    required String personAge,
    required String personGender,
    required String interventionType,
    required List<String> substances,
    required String symptoms,
    required String actionsTaken,
    required String observations,
  }) async {
    final newCase = CaseModel(
      id: const Uuid().v4(),
      eventId: event.id,
      eventName: event.name,
      registeredByUserId: currentUser.id,
      registeredByUserName: currentUser.fullName,
      timestamp: DateTime.now(),
      personName: personName.trim().isEmpty ? 'Anónimo / No especifica' : personName.trim(),
      personAge: personAge.trim(),
      personGender: personGender,
      interventionType: interventionType,
      substances: substances,
      symptoms: symptoms.trim(),
      actionsTaken: actionsTaken.trim(),
      observations: observations.trim(),
      isSyncedToDrive: false,
    );

    _cases.insert(0, newCase);
    await _storage.saveCases(_cases);
    notifyListeners();
    return newCase;
  }

  /// Marca casos como sincronizados con Google Drive
  Future<void> markCasesAsSynced(String eventId) async {
    final now = DateTime.now();
    bool changed = false;

    for (int i = 0; i < _cases.length; i++) {
      if (_cases[i].eventId == eventId && !_cases[i].isSyncedToDrive) {
        _cases[i] = _cases[i].copyWith(
          isSyncedToDrive: true,
          syncedAt: now,
        );
        changed = true;
      }
    }

    if (changed) {
      await _storage.saveCases(_cases);
      notifyListeners();
    }
  }
}
