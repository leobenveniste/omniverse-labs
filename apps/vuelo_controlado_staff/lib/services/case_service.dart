import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/case_model.dart';
import '../models/user_model.dart';
import '../models/event_model.dart';
import 'storage_service.dart';
import 'firestore_sync_service.dart';

class CaseService extends ChangeNotifier {
  final StorageService _storage;
  final FirestoreSyncService? firestoreSync;
  List<CaseModel> _cases = [];

  CaseService(this._storage, {this.firestoreSync}) {
    _cases = _storage.loadCases();
  }

  /// Recarga casos cuando Firestore detecta cambios remotos
  void reloadCasesFromStorage() {
    _cases = _storage.loadCases();
    notifyListeners();
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
  Future<bool> createCase({
    EventModel? event,
    String? eventId,
    String? eventName,
    required UserModel currentUser,
    String? personName,
    String? personAge,
    String? personGender,
    String? interventionType,
    List<String>? substances,
    String? symptoms,
    String? actionsTaken,
    String? observations,
    CaseModel? caseModelOverride,
  }) async {
    final targetEventId = event?.id ?? eventId ?? '';
    final targetEventName = event?.name ?? eventName ?? '';

    final CaseModel newCase;
    if (caseModelOverride != null) {
      newCase = CaseModel(
        id: caseModelOverride.id.isNotEmpty
            ? caseModelOverride.id
            : const Uuid().v4(),
        eventId: targetEventId,
        eventName: targetEventName,
        registeredByUserId: currentUser.id,
        registeredByUserName: currentUser.fullName,
        timestamp: DateTime.now(),
        gender: caseModelOverride.gender,
        ageRange: caseModelOverride.ageRange,
        moment: caseModelOverride.moment,
        duration: caseModelOverride.duration,
        arrivalMode: caseModelOverride.arrivalMode,
        accompaniedBy: caseModelOverride.accompaniedBy,
        consumedSubstances: caseModelOverride.consumedSubstances,
        substanceEntries: caseModelOverride.substanceEntries,
        mdmaPillName: caseModelOverride.mdmaPillName,
        otherSubstanceName: caseModelOverride.otherSubstanceName,
        isFirstTimeConsuming: caseModelOverride.isFirstTimeConsuming,
        underlyingCondition: caseModelOverride.underlyingCondition,
        physicalSymptoms: caseModelOverride.physicalSymptoms,
        otherPhysicalSymptoms: caseModelOverride.otherPhysicalSymptoms,
        psychologicalSymptoms: caseModelOverride.psychologicalSymptoms,
        healthTeamIntervened: caseModelOverride.healthTeamIntervened,
        isComplexCase: caseModelOverride.isComplexCase,
        resolution: caseModelOverride.resolution,
        otherResolution: caseModelOverride.otherResolution,
        attendingStaff: caseModelOverride.attendingStaff.isNotEmpty
            ? caseModelOverride.attendingStaff
            : currentUser.fullName,
        relevantInfo: caseModelOverride.relevantInfo,
        isSyncedToDrive: false,
      );
    } else {
      final Map<String, String> subMap = {};
      if (substances != null) {
        for (final s in substances) {
          subMap[s] = '';
        }
      }
      newCase = CaseModel(
        id: const Uuid().v4(),
        eventId: targetEventId,
        eventName: targetEventName,
        registeredByUserId: currentUser.id,
        registeredByUserName: currentUser.fullName,
        timestamp: DateTime.now(),
        gender: personGender ?? 'No especifica',
        ageRange: personAge ?? '18 – 25',
        moment: 'Main',
        duration: 'hasta 30\'',
        arrivalMode: 'Solx',
        consumedSubstances: (substances != null && substances.isNotEmpty) ? 'Si' : 'No',
        substanceEntries: subMap,
        isFirstTimeConsuming: 'No',
        underlyingCondition: 'No',
        physicalSymptoms: const [],
        psychologicalSymptoms: const [],
        resolution: interventionType ?? 'Recuperación íntegra',
        attendingStaff: currentUser.fullName,
        relevantInfo: observations ?? '',
        isSyncedToDrive: false,
      );
    }

    _cases.insert(0, newCase);
    await _storage.saveCases(_cases);
    firestoreSync?.syncCase(newCase);
    notifyListeners();
    return true;
  }

  /// Actualiza una ficha de caso existente 100% offline
  Future<bool> updateCase(CaseModel updatedCase) async {
    final index = _cases.indexWhere((c) => c.id == updatedCase.id);
    if (index != -1) {
      _cases[index] = updatedCase;
    } else {
      _cases.insert(0, updatedCase);
    }

    await _storage.saveCases(_cases);
    firestoreSync?.syncCase(updatedCase);
    notifyListeners();
    return true;
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
        firestoreSync?.syncCase(_cases[i]);
        changed = true;
      }
    }

    if (changed) {
      await _storage.saveCases(_cases);
      notifyListeners();
    }
  }
}
