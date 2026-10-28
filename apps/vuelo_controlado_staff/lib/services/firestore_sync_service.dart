import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/event_model.dart';
import '../models/case_model.dart';
import 'storage_service.dart';

class FirestoreSyncService {
  final StorageService _storage;
  final FirebaseFirestore _firestore;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _usersSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _eventsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _casesSub;

  VoidCallback? onUsersUpdated;
  VoidCallback? onEventsUpdated;
  VoidCallback? onCasesUpdated;

  bool _initialized = false;

  FirestoreSyncService(
    this._storage, {
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      _listenToUsers();
      _listenToEvents();
      _listenToCases();

      await _seedCloudIfEmpty();
    } catch (e) {
      debugPrint('FirestoreSyncService init notice: $e');
    }
  }

  void dispose() {
    _usersSub?.cancel();
    _eventsSub?.cancel();
    _casesSub?.cancel();
  }

  // --- ESCUCHA EN TIEMPO REAL: USUARIOS ---
  void _listenToUsers() {
    _usersSub = _firestore.collection('users').snapshots().listen(
      (snapshot) async {
        if (snapshot.docs.isEmpty) return;

        final cloudUsers = <UserModel>[];
        for (final doc in snapshot.docs) {
          try {
            final data = Map<String, dynamic>.from(doc.data());
            data['id'] = doc.id;
            cloudUsers.add(UserModel.fromJson(data));
          } catch (e) {
            debugPrint('Error parseando usuario de Firestore (${doc.id}): $e');
          }
        }

        if (cloudUsers.isNotEmpty) {
          final localUsers = _storage.loadUsers();
          final userMap = {for (var u in localUsers) u.id: u};

          bool changed = false;
          for (final cu in cloudUsers) {
            final existing = userMap[cu.id];
            if (existing == null ||
                jsonEncode(existing.toJson()) != jsonEncode(cu.toJson())) {
              userMap[cu.id] = cu;
              changed = true;
            }
          }

          if (changed || localUsers.length != userMap.length) {
            final merged = userMap.values.toList();
            await _storage.saveUsers(merged);

            final sessionUser = _storage.loadSessionUser();
            if (sessionUser != null && userMap.containsKey(sessionUser.id)) {
              await _storage.saveSessionUser(userMap[sessionUser.id]);
            }

            onUsersUpdated?.call();
          }
        }
      },
      onError: (err) {
        debugPrint('Firestore users listen error: $err');
      },
    );
  }

  // --- ESCUCHA EN TIEMPO REAL: EVENTOS ---
  void _listenToEvents() {
    _eventsSub = _firestore.collection('events').snapshots().listen(
      (snapshot) async {
        if (snapshot.docs.isEmpty) return;

        final cloudEvents = <EventModel>[];
        for (final doc in snapshot.docs) {
          try {
            final data = Map<String, dynamic>.from(doc.data());
            data['id'] = doc.id;
            cloudEvents.add(EventModel.fromJson(data));
          } catch (e) {
            debugPrint('Error parseando evento de Firestore (${doc.id}): $e');
          }
        }

        if (cloudEvents.isNotEmpty) {
          final localEvents = _storage.loadEvents();
          final eventMap = {for (var e in localEvents) e.id: e};

          bool changed = false;
          for (final ce in cloudEvents) {
            final existing = eventMap[ce.id];
            if (existing == null ||
                jsonEncode(existing.toJson()) != jsonEncode(ce.toJson())) {
              eventMap[ce.id] = ce;
              changed = true;
            }
          }

          if (changed || localEvents.length != eventMap.length) {
            final merged = eventMap.values.toList()
              ..sort((a, b) => b.date.compareTo(a.date));
            await _storage.saveEvents(merged);
            onEventsUpdated?.call();
          }
        }
      },
      onError: (err) {
        debugPrint('Firestore events listen error: $err');
      },
    );
  }

  // --- ESCUCHA EN TIEMPO REAL: CASOS ---
  void _listenToCases() {
    _casesSub = _firestore.collection('cases').snapshots().listen(
      (snapshot) async {
        if (snapshot.docs.isEmpty) return;

        final cloudCases = <CaseModel>[];
        for (final doc in snapshot.docs) {
          try {
            final data = Map<String, dynamic>.from(doc.data());
            data['id'] = doc.id;
            cloudCases.add(CaseModel.fromJson(data));
          } catch (e) {
            debugPrint('Error parseando caso de Firestore (${doc.id}): $e');
          }
        }

        if (cloudCases.isNotEmpty) {
          final localCases = _storage.loadCases();
          final caseMap = {for (var c in localCases) c.id: c};

          bool changed = false;
          for (final cc in cloudCases) {
            final existing = caseMap[cc.id];
            if (existing == null ||
                jsonEncode(existing.toJson()) != jsonEncode(cc.toJson())) {
              caseMap[cc.id] = cc;
              changed = true;
            }
          }

          if (changed || localCases.length != caseMap.length) {
            final merged = caseMap.values.toList()
              ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
            await _storage.saveCases(merged);
            onCasesUpdated?.call();
          }
        }
      },
      onError: (err) {
        debugPrint('Firestore cases listen error: $err');
      },
    );
  }

  // --- ESCRITURAS HACIA LA NUBE (OFFLINE RESILIENT) ---

  Future<void> syncUser(UserModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.id)
          .set(user.toJson(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error syncUser to Firestore: $e');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
    } catch (e) {
      debugPrint('Error deleteUser in Firestore: $e');
    }
  }

  Future<void> syncEvent(EventModel event) async {
    try {
      await _firestore
          .collection('events')
          .doc(event.id)
          .set(event.toJson(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error syncEvent to Firestore: $e');
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await _firestore.collection('events').doc(eventId).delete();
    } catch (e) {
      debugPrint('Error deleteEvent in Firestore: $e');
    }
  }

  Future<void> syncCase(CaseModel caseItem) async {
    try {
      await _firestore
          .collection('cases')
          .doc(caseItem.id)
          .set(caseItem.toJson(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error syncCase to Firestore: $e');
    }
  }

  // --- SINCRONIZACIÓN FORZADA / ON DEMAND ---
  Future<bool> forceSyncAll() async {
    try {
      // 1. Enviar locales a la nube
      final localUsers = _storage.loadUsers();
      for (final u in localUsers) {
        if (u.id != 'user_demo_1') {
          await syncUser(u);
        }
      }

      final localEvents = _storage.loadEvents();
      for (final e in localEvents) {
        if (e.id != 'event_demo_1') {
          await syncEvent(e);
        }
      }

      final localCases = _storage.loadCases();
      for (final c in localCases) {
        await syncCase(c);
      }

      // 2. Traer y consolidar desde la nube
      final usersSnap = await _firestore.collection('users').get();
      if (usersSnap.docs.isNotEmpty) {
        final cloudUsers = <UserModel>[];
        for (final doc in usersSnap.docs) {
          try {
            final data = Map<String, dynamic>.from(doc.data());
            data['id'] = doc.id;
            cloudUsers.add(UserModel.fromJson(data));
          } catch (_) {}
        }
        final userMap = {for (var u in _storage.loadUsers()) u.id: u};
        for (final cu in cloudUsers) {
          userMap[cu.id] = cu;
        }
        await _storage.saveUsers(userMap.values.toList());
        onUsersUpdated?.call();
      }

      final eventsSnap = await _firestore.collection('events').get();
      if (eventsSnap.docs.isNotEmpty) {
        final cloudEvents = <EventModel>[];
        for (final doc in eventsSnap.docs) {
          try {
            final data = Map<String, dynamic>.from(doc.data());
            data['id'] = doc.id;
            cloudEvents.add(EventModel.fromJson(data));
          } catch (_) {}
        }
        final eventMap = {for (var e in _storage.loadEvents()) e.id: e};
        for (final ce in cloudEvents) {
          eventMap[ce.id] = ce;
        }
        await _storage.saveEvents(eventMap.values.toList());
        onEventsUpdated?.call();
      }

      final casesSnap = await _firestore.collection('cases').get();
      if (casesSnap.docs.isNotEmpty) {
        final cloudCases = <CaseModel>[];
        for (final doc in casesSnap.docs) {
          try {
            final data = Map<String, dynamic>.from(doc.data());
            data['id'] = doc.id;
            cloudCases.add(CaseModel.fromJson(data));
          } catch (_) {}
        }
        final caseMap = {for (var c in _storage.loadCases()) c.id: c};
        for (final cc in cloudCases) {
          caseMap[cc.id] = cc;
        }
        await _storage.saveCases(caseMap.values.toList());
        onCasesUpdated?.call();
      }

      return true;
    } catch (e) {
      debugPrint('Error en forceSyncAll: $e');
      return false;
    }
  }

  // --- SEED INICIAL EN FIRESTORE Y LIMPIEZA DE DEMOS ---
  Future<void> _seedCloudIfEmpty() async {
    try {
      // Limpiar documentos demo residuales en la nube si existiesen
      try {
        await _firestore.collection('users').doc('user_demo_1').delete();
        await _firestore.collection('events').doc('event_demo_1').delete();
      } catch (_) {}

      // 1. Usuarios: Si la nube no tiene usuarios, sube los locales
      final userSnapshot =
          await _firestore.collection('users').limit(1).get();
      if (userSnapshot.docs.isEmpty) {
        final localUsers = _storage.loadUsers();
        for (final u in localUsers) {
          if (u.id != 'user_demo_1') {
            await syncUser(u);
          }
        }
      }

      // 2. Eventos: Si la nube no tiene eventos, sube los locales
      final eventSnapshot =
          await _firestore.collection('events').limit(1).get();
      if (eventSnapshot.docs.isEmpty) {
        final localEvents = _storage.loadEvents();
        for (final e in localEvents) {
          if (e.id != 'event_demo_1') {
            await syncEvent(e);
          }
        }
      }

      // 3. Casos: Si la nube no tiene casos, sube los locales
      final caseSnapshot =
          await _firestore.collection('cases').limit(1).get();
      if (caseSnapshot.docs.isEmpty) {
        final localCases = _storage.loadCases();
        for (final c in localCases) {
          await syncCase(c);
        }
      }
    } catch (e) {
      debugPrint('Firestore seed notice: $e');
    }
  }
}
