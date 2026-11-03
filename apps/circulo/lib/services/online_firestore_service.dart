import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/circle_group_model.dart';
import '../models/swipe_interaction_model.dart';
import '../models/purchase_model.dart';

class AtomicJoinCircleResult {
  final bool success;
  final bool isCompletedK4;
  final CircleGroupModel? updatedGroup;
  final String? failureReason;

  const AtomicJoinCircleResult({
    required this.success,
    this.isCompletedK4 = false,
    this.updatedGroup,
    this.failureReason,
  });
}

class OnlineFirestoreService {
  final FirebaseFirestore? _firestoreInstance;
  bool _isOnlineActive = false;

  // Espejo en memoria reactivo para sincronización online instantánea y resiliencia
  final Map<String, UserModel> _cachedUsers = {};
  final Map<String, CircleGroupModel> _cachedGroups = {};
  final Map<String, List<GroupMessageModel>> _cachedMessages = {};
  final Map<String, List<GroupPlanModel>> _cachedPlans = {};
  final List<SwipeInteractionModel> _cachedSwipes = [];
  final List<ReportModel> _cachedReports = [];
  final List<PurchaseRecordModel> _cachedPurchases = [];

  final _usersStreamController = StreamController<List<UserModel>>.broadcast();
  final _groupsStreamController =
      StreamController<List<CircleGroupModel>>.broadcast();

  OnlineFirestoreService({FirebaseFirestore? firestore})
      : _firestoreInstance = firestore;

  FirebaseFirestore? get _firestore {
    if (_firestoreInstance != null) return _firestoreInstance;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  Stream<List<UserModel>> get usersStream => _usersStreamController.stream;
  Stream<List<CircleGroupModel>> get groupsStream =>
      _groupsStreamController.stream;

  List<UserModel> get currentUsers => _cachedUsers.values.toList();
  List<CircleGroupModel> get currentGroups => _cachedGroups.values.toList();

  Future<void> init() async {
    try {
      final fs = _firestore;
      if (fs != null) {
        fs.settings = const Settings(
          persistenceEnabled: false, // 100% Online por seguridad
        );
        _isOnlineActive = true;
        _listenToUsersOnline();
        _listenToGroupsOnline();
      }
    } catch (e) {
      debugPrint('Firestore settings notice: $e');
    }
    await ensureCloudSeedData();
  }

  void _listenToUsersOnline() {
    try {
      _firestore?.collection('circulo_users').snapshots().listen(
        (snapshot) {
          for (final doc in snapshot.docs) {
            try {
              final data = Map<String, dynamic>.from(doc.data());
              data['id'] = doc.id;
              _cachedUsers[doc.id] = UserModel.fromJson(data);
            } catch (_) {}
          }
          for (final change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.removed) {
              _cachedUsers.remove(change.doc.id);
            }
          }
          _usersStreamController.add(_cachedUsers.values.toList());
        },
        onError: (err) {
          debugPrint('Online users listener notice: $err');
        },
      );
    } catch (_) {}
  }

  void _listenToGroupsOnline() {
    try {
      _firestore?.collection('circulo_groups').snapshots().listen(
        (snapshot) {
          for (final doc in snapshot.docs) {
            try {
              final data = Map<String, dynamic>.from(doc.data());
              data['id'] = doc.id;
              _cachedGroups[doc.id] = CircleGroupModel.fromJson(data);
            } catch (_) {}
          }
          for (final change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.removed) {
              _cachedGroups.remove(change.doc.id);
            }
          }
          _groupsStreamController.add(_cachedGroups.values.toList());
        },
        onError: (err) {
          debugPrint('Online groups listener notice: $err');
        },
      );
    } catch (_) {}
  }

  // --- CRUD USUARIOS ONLINE ---

  Future<UserModel?> getUserById(String userId) async {
    if (_cachedUsers.containsKey(userId)) {
      return _cachedUsers[userId];
    }
    try {
      final doc =
          await _firestore?.collection('circulo_users').doc(userId).get();
      if (doc != null && doc.exists && doc.data() != null) {
        final data = Map<String, dynamic>.from(doc.data()!);
        data['id'] = doc.id;
        final u = UserModel.fromJson(data);
        _cachedUsers[u.id] = u;
        return u;
      }
    } catch (_) {}
    return null;
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    for (final u in _cachedUsers.values) {
      if (u.email.trim().toLowerCase() == cleanEmail) return u;
    }
    try {
      final query = await _firestore
          ?.collection('circulo_users')
          .where('email', isEqualTo: cleanEmail)
          .limit(1)
          .get();
      if (query != null && query.docs.isNotEmpty) {
        final data = Map<String, dynamic>.from(query.docs.first.data());
        data['id'] = query.docs.first.id;
        final u = UserModel.fromJson(data);
        _cachedUsers[u.id] = u;
        return u;
      }
    } catch (_) {}
    return null;
  }

  Future<bool> upsertUser(UserModel user) async {
    _cachedUsers[user.id] = user;
    _usersStreamController.add(_cachedUsers.values.toList());

    if (_isOnlineActive && _firestore != null) {
      try {
        await _firestore!
            .collection('circulo_users')
            .doc(user.id)
            .set(user.toJson(), SetOptions(merge: true));
        return true;
      } catch (e) {
        debugPrint('Error upsertUser online: $e');
      }
    }
    return true;
  }

  Future<bool> deleteUser(String userId) async {
    _cachedUsers.remove(userId);
    _usersStreamController.add(_cachedUsers.values.toList());

    if (_isOnlineActive && _firestore != null) {
      try {
        await _firestore!.collection('circulo_users').doc(userId).delete();
        return true;
      } catch (e) {
        debugPrint('Error deleteUser online: $e');
      }
    }
    return true;
  }

  // --- SWIPES / INTERACCIONES ONLINE ---

  Future<void> recordSwipe(SwipeInteractionModel swipe) async {
    _cachedSwipes.add(swipe);
    if (_isOnlineActive && _firestore != null) {
      try {
        await _firestore!
            .collection('circulo_swipes')
            .doc(swipe.id)
            .set(swipe.toJson());
      } catch (_) {}
    }
  }

  List<SwipeInteractionModel> getSwipesFromUser(String userId) {
    return _cachedSwipes.where((s) => s.fromUserId == userId).toList();
  }

  Future<bool> removeLastSwipe(String userId) async {
    final idx = _cachedSwipes.lastIndexWhere((s) => s.fromUserId == userId);
    if (idx != -1) {
      final removed = _cachedSwipes.removeAt(idx);
      if (_isOnlineActive && _firestore != null) {
        try {
          await _firestore!.collection('circulo_swipes').doc(removed.id).delete();
        } catch (_) {}
      }
      return true;
    }
    return false;
  }

  // --- GRUPOS ONLINE ---

  Future<bool> upsertGroup(CircleGroupModel group) async {
    _cachedGroups[group.id] = group;
    _groupsStreamController.add(_cachedGroups.values.toList());

    if (_isOnlineActive && _firestore != null) {
      try {
        await _firestore!
            .collection('circulo_groups')
            .doc(group.id)
            .set(group.toJson(), SetOptions(merge: true));
        return true;
      } catch (e) {
        debugPrint('Error upsertGroup online: $e');
      }
    }
    return true;
  }

  Future<CircleGroupModel?> getGroupById(String groupId) async {
    if (_cachedGroups.containsKey(groupId)) {
      return _cachedGroups[groupId];
    }
    try {
      final doc =
          await _firestore?.collection('circulo_groups').doc(groupId).get();
      if (doc != null && doc.exists && doc.data() != null) {
        final data = Map<String, dynamic>.from(doc.data()!);
        data['id'] = doc.id;
        final g = CircleGroupModel.fromJson(data);
        _cachedGroups[g.id] = g;
        return g;
      }
    } catch (_) {}
    return null;
  }

  // --- TRANSACCIÓN ATÓMICA DE ASIGNACIÓN K4 (ACID CONCURRENCY) ---
  Future<AtomicJoinCircleResult> joinFormingCircleAtomic({
    required String groupId,
    required UserModel joiningUser,
  }) async {
    if (_isOnlineActive && _firestore != null) {
      try {
        final groupRef = _firestore!.collection('circulo_groups').doc(groupId);
        final result = await _firestore!
            .runTransaction<AtomicJoinCircleResult>((transaction) async {
          final snapshot = await transaction.get(groupRef);
          if (!snapshot.exists || snapshot.data() == null) {
            return const AtomicJoinCircleResult(
              success: false,
              failureReason: 'El Círculo no existe o fue disuelto.',
            );
          }

          final data = Map<String, dynamic>.from(snapshot.data()!);
          data['id'] = snapshot.id;
          final currentGroup = CircleGroupModel.fromJson(data);

          final memberIds = List<String>.from(currentGroup.memberIds);
          if (memberIds.contains(joiningUser.id)) {
            return AtomicJoinCircleResult(
              success: true,
              isCompletedK4: memberIds.length >= 4,
              updatedGroup: currentGroup,
            );
          }

          final maxAllowed = currentGroup.maxMembers;
          final membersToAdd = <String>[joiningUser.id];
          if (joiningUser.hasDuoPartner &&
              !memberIds.contains(joiningUser.duoPartnerId!)) {
            if (memberIds.length + 2 <= maxAllowed) {
              membersToAdd.add(joiningUser.duoPartnerId!);
            }
          }

          if (memberIds.length + membersToAdd.length > maxAllowed) {
            return const AtomicJoinCircleResult(
              success: false,
              failureReason: 'El Círculo acaba de completarse con otro amigo.',
            );
          }

          memberIds.addAll(membersToAdd);
          final isNowCompletedK4 = memberIds.length >= 4;

          final updatedGroup = currentGroup.copyWith(
            memberIds: memberIds,
            activeConfirmedMemberIds: memberIds,
            status: isNowCompletedK4 ? 'active' : 'forming_3',
            lastActivityAt: DateTime.now(),
            lastMessagePreview: isNowCompletedK4
                ? '¡Círculo completado! El chat grupal ya está activo.'
                : 'Nuevo integrante sumado al Círculo.',
          );

          transaction.set(
              groupRef, updatedGroup.toJson(), SetOptions(merge: true));

          return AtomicJoinCircleResult(
            success: true,
            isCompletedK4: isNowCompletedK4,
            updatedGroup: updatedGroup,
          );
        });

        if (result.success && result.updatedGroup != null) {
          _cachedGroups[groupId] = result.updatedGroup!;
          _groupsStreamController.add(_cachedGroups.values.toList());
        }
        return result;
      } catch (e) {
        debugPrint('Transaction joinFormingCircleAtomic error: $e');
      }
    }

    // Fallback memoria local / entorno testing
    final currentGroup = _cachedGroups[groupId];
    if (currentGroup == null) {
      return const AtomicJoinCircleResult(
        success: false,
        failureReason: 'Círculo no encontrado.',
      );
    }

    final memberIds = List<String>.from(currentGroup.memberIds);
    if (!memberIds.contains(joiningUser.id)) {
      final membersToAdd = <String>[joiningUser.id];
      if (joiningUser.hasDuoPartner &&
          !memberIds.contains(joiningUser.duoPartnerId!)) {
        if (memberIds.length + 2 <= currentGroup.maxMembers) {
          membersToAdd.add(joiningUser.duoPartnerId!);
        }
      }

      if (memberIds.length + membersToAdd.length > currentGroup.maxMembers) {
        return const AtomicJoinCircleResult(
          success: false,
          failureReason: 'El Círculo ya alcanzó su capacidad máxima.',
        );
      }

      memberIds.addAll(membersToAdd);
      final isNowCompletedK4 = memberIds.length >= 4;
      final updated = currentGroup.copyWith(
        memberIds: memberIds,
        activeConfirmedMemberIds: memberIds,
        status: isNowCompletedK4 ? 'active' : 'forming_3',
        lastActivityAt: DateTime.now(),
        lastMessagePreview: isNowCompletedK4
            ? '¡Círculo completado! El chat grupal ya está activo.'
            : 'Nuevo integrante sumado al Círculo.',
      );
      _cachedGroups[groupId] = updated;
      _groupsStreamController.add(_cachedGroups.values.toList());

      return AtomicJoinCircleResult(
        success: true,
        isCompletedK4: isNowCompletedK4,
        updatedGroup: updated,
      );
    }

    return AtomicJoinCircleResult(
      success: true,
      isCompletedK4: memberIds.length >= 4,
      updatedGroup: currentGroup,
    );
  }

  // --- MENSAJES DE CHAT ONLINE ---

  Stream<List<GroupMessageModel>> getMessagesStream(String groupId) {
    if (_isOnlineActive && _firestore != null) {
      try {
        return _firestore!
            .collection('circulo_messages')
            .where('groupId', isEqualTo: groupId)
            .snapshots()
            .map((snap) {
          final list = snap.docs.map((d) {
            final data = Map<String, dynamic>.from(d.data());
            data['id'] = d.id;
            return GroupMessageModel.fromJson(data);
          }).toList();
          list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          _cachedMessages[groupId] = list;
          return list;
        });
      } catch (_) {}
    }
    final streamCtrl =
        StreamController<List<GroupMessageModel>>.broadcast();
    final list = _cachedMessages[groupId] ?? [];
    streamCtrl.add(list);
    return streamCtrl.stream;
  }

  Future<void> sendMessage(GroupMessageModel message) async {
    _cachedMessages.putIfAbsent(message.groupId, () => []).add(message);
    if (_isOnlineActive && _firestore != null) {
      try {
        await _firestore!
            .collection('circulo_messages')
            .doc(message.id)
            .set(message.toJson());
      } catch (_) {}
    }
  }

  // --- PLANES Y SALIDAS ONLINE ---

  Future<void> upsertPlan(GroupPlanModel plan) async {
    final list = _cachedPlans.putIfAbsent(plan.groupId, () => []);
    final idx = list.indexWhere((p) => p.id == plan.id);
    if (idx != -1) {
      list[idx] = plan;
    } else {
      list.add(plan);
    }

    if (_isOnlineActive && _firestore != null) {
      try {
        await _firestore!
            .collection('circulo_plans')
            .doc(plan.id)
            .set(plan.toJson(), SetOptions(merge: true));
      } catch (_) {}
    }
  }

  List<GroupPlanModel> getPlansForGroup(String groupId) {
    return _cachedPlans[groupId] ?? [];
  }

  // --- REPORTES ONLINE ---

  Future<void> createReport(ReportModel report) async {
    _cachedReports.add(report);
    if (_isOnlineActive && _firestore != null) {
      try {
        await _firestore!
            .collection('circulo_reports')
            .doc(report.id)
            .set(report.toJson());
      } catch (_) {}
    }
  }

  List<ReportModel> getReports() => List.unmodifiable(_cachedReports);

  // --- TRANSACCIONES Y MONETIZACIÓN ONLINE ---

  Future<void> recordPurchase(PurchaseRecordModel purchase) async {
    _cachedPurchases.add(purchase);
    if (_isOnlineActive && _firestore != null) {
      try {
        await _firestore!
            .collection('circulo_purchases')
            .doc(purchase.id)
            .set(purchase.toJson());
      } catch (_) {}
    }
  }

  Future<List<PurchaseRecordModel>> getUserPurchases(String userId) async {
    if (_isOnlineActive && _firestore != null) {
      try {
        final query = await _firestore!
            .collection('circulo_purchases')
            .where('userId', isEqualTo: userId)
            .get();
        final list = query.docs
            .map((doc) => PurchaseRecordModel.fromJson(doc.data()))
            .toList();
        return list;
      } catch (_) {}
    }
    return _cachedPurchases.where((p) => p.userId == userId).toList();
  }

  // --- SEED INICIAL EN LA NUBE ---
  Future<void> ensureCloudSeedData() async {
    if (_cachedUsers.isNotEmpty) return;

    String hashPass(String p) =>
        sha256.convert(utf8.encode(p)).toString();

    // 1. Superadmin
    final superAdmin = UserModel(
      id: 'admin_leo',
      email: AppRoles.superAdminEmail,
      passwordHash: hashPass('29583026'),
      firstName: 'Leo',
      lastName: 'Benveniste',
      birthDate: DateTime(1982, 5, 20),
      phone: '+5491100001111',
      instagram: 'leobenveniste',
      bio: 'Fundador de proyectos, organizador de planes y entusiasta de juntadas reales.',
      region: AppRegions.buenosAires,
      neighborhood: 'Palermo',
      groupRole: GroupRoles.organizer,
      interests: [
        AppInterests.specialtyCoffee,
        AppInterests.boardGames,
        AppInterests.craftBeer,
        AppInterests.techAi,
      ],
      favoritePlans: [AppPlans.coffee, AppPlans.boardgames, AppPlans.beer],
      socialVibe: AppVibes.active,
      availabilitySlots: [
        AvailabilitySlots.weekdayNight,
        AvailabilitySlots.weekendDay,
        AvailabilitySlots.weekendNight,
      ],
      duoInviteCode: 'CIR-LEO1',
      completedMeetupsCount: 6,
      onboardingCompleted: true,
      roles: [AppRoles.superAdminEmail, AppRoles.miembro],
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    );

    // 2. Usuarios diversos
    final seedUsers = [
      superAdmin,
      UserModel(
        id: 'user_valen',
        email: 'valen@circulo.app',
        passwordHash: hashPass('123456'),
        firstName: 'Valentina',
        lastName: 'Rios',
        birthDate: DateTime(1998, 8, 14),
        bio: 'Amante del café de especialidad y fotógrafa aficionada.',
        region: AppRegions.buenosAires,
        neighborhood: 'Colegiales',
        groupRole: GroupRoles.connector,
        interests: [
          AppInterests.specialtyCoffee,
          AppInterests.photography,
          AppInterests.cinemaSeries,
        ],
        favoritePlans: [AppPlans.coffee, AppPlans.cinemaMusic],
        duoInviteCode: 'CIR-VAL1',
        completedMeetupsCount: 3,
        onboardingCompleted: true,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
      UserModel(
        id: 'user_mateo',
        email: 'mateo@circulo.app',
        passwordHash: hashPass('123456'),
        firstName: 'Mateo',
        lastName: 'Sanz',
        birthDate: DateTime(1996, 3, 22),
        bio: 'Fan de los juegos de mesa modernos (Catan, Terraforming Mars) y la birra.',
        region: AppRegions.buenosAires,
        neighborhood: 'Villa Crespo',
        groupRole: GroupRoles.explorer,
        interests: [
          AppInterests.boardGames,
          AppInterests.craftBeer,
          AppInterests.videoGames,
        ],
        favoritePlans: [AppPlans.boardgames, AppPlans.beer],
        duoInviteCode: 'CIR-MAT1',
        completedMeetupsCount: 4,
        onboardingCompleted: true,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
      UserModel(
        id: 'user_camila',
        email: 'camila@circulo.app',
        passwordHash: hashPass('123456'),
        firstName: 'Camila',
        lastName: 'Duarte',
        birthDate: DateTime(1999, 11, 5),
        bio: 'Tranqui, me sumo a cualquier plan con buena onda y buena música.',
        region: AppRegions.buenosAires,
        neighborhood: 'Belgrano',
        groupRole: GroupRoles.chill,
        interests: [
          AppInterests.musicLive,
          AppInterests.outdoorMate,
          AppInterests.specialtyCoffee,
        ],
        favoritePlans: [AppPlans.parkMate, AppPlans.coffee],
        duoInviteCode: 'CIR-CAM1',
        completedMeetupsCount: 2,
        onboardingCompleted: true,
        createdAt: DateTime.now().subtract(const Duration(days: 12)),
      ),
      UserModel(
        id: 'user_lucas',
        email: 'lucas@circulo.app',
        passwordHash: hashPass('123456'),
        firstName: 'Lucas',
        lastName: 'Ferrari',
        birthDate: DateTime(1995, 7, 19),
        bio: 'Running por los bosques de Palermo y salidas gastronómicas.',
        region: AppRegions.buenosAires,
        neighborhood: 'Palermo',
        groupRole: GroupRoles.organizer,
        interests: [
          AppInterests.runningFitness,
          AppInterests.cookingFoodie,
          AppInterests.craftBeer,
        ],
        favoritePlans: [AppPlans.sport, AppPlans.dinner],
        duoInviteCode: 'CIR-LUC1',
        completedMeetupsCount: 5,
        onboardingCompleted: true,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
    ];

    for (final u in seedUsers) {
      await upsertUser(u);
    }

    // 3. Círculo en formación (3/4) listo para match con el usuario actual
    final circle3of4 = CircleGroupModel(
      id: 'circle_boardgames_3of4',
      name: 'Mesa de Juegos & Café BA',
      description: 'Nos encanta jugar juegos de mesa modernos y probar cafeterías.',
      status: 'forming_3',
      memberIds: ['user_valen', 'user_mateo', 'user_camila'],
      activeConfirmedMemberIds: ['user_valen', 'user_mateo', 'user_camila'],
      maxMembers: 4,
      isOpenForExpansion: false,
      sharedInterests: [
        AppInterests.boardGames,
        AppInterests.specialtyCoffee,
      ],
      sharedPlans: [AppPlans.boardgames, AppPlans.coffee],
      region: AppRegions.buenosAires,
      lastMessagePreview: '¡Falta 1 persona para desbloquear el chat!',
      lastActivityAt: DateTime.now(),
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
    );

    // 4. Círculo en formación (2/4)
    final circle2of4 = CircleGroupModel(
      id: 'circle_running_2of4',
      name: 'Running & Birra Post-Entreno',
      description: 'Salidas de running liviano y charla después.',
      status: 'forming_2',
      memberIds: ['user_lucas', 'user_mateo'],
      activeConfirmedMemberIds: ['user_lucas', 'user_mateo'],
      maxMembers: 4,
      isOpenForExpansion: false,
      sharedInterests: [
        AppInterests.runningFitness,
        AppInterests.craftBeer,
      ],
      region: AppRegions.buenosAires,
      lastMessagePreview: 'Buscando 2 amigos más para completar el grupo.',
      lastActivityAt: DateTime.now().subtract(const Duration(hours: 4)),
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    );

    // 5. Grupo Activo de 4 miembros con capacidad abierta hasta 8
    final activeExpandedGroup = CircleGroupModel(
      id: 'circle_coffee_active_4of8',
      name: 'Club del Café & Charlas',
      description: 'Nos juntamos a merendar los sábados y charlar de todo.',
      status: 'active',
      memberIds: ['admin_leo', 'user_valen', 'user_camila', 'user_lucas'],
      activeConfirmedMemberIds: [
        'admin_leo',
        'user_valen',
        'user_camila',
        'user_lucas'
      ],
      maxMembers: 8,
      isOpenForExpansion: true,
      sharedInterests: [
        AppInterests.specialtyCoffee,
        AppInterests.musicLive,
      ],
      sharedPlans: [AppPlans.coffee, AppPlans.parkMate],
      region: AppRegions.buenosAires,
      lastMessagePreview: 'Valen: ¿Nos vemos este sábado en Colegiales?',
      lastActivityAt: DateTime.now().subtract(const Duration(minutes: 45)),
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    );

    await upsertGroup(circle3of4);
    await upsertGroup(circle2of4);
    await upsertGroup(activeExpandedGroup);

    // Mensaje de rompehielos inicial en el grupo activo
    await sendMessage(GroupMessageModel(
      id: 'msg_welcome_seed',
      groupId: activeExpandedGroup.id,
      senderId: 'system',
      senderName: 'Círculo Bot',
      type: 'icebreaker',
      text:
          '¡Bienvenidos al Círculo! 🚀 A todos les gusta el café de especialidad y la música en vivo. ¿Cuál es su cafetería o recital favorito?',
      timestamp: DateTime.now().subtract(const Duration(days: 4)),
    ));

    // Plan propuesto en el grupo activo
    await upsertPlan(GroupPlanModel(
      id: 'plan_seed_coffee',
      groupId: activeExpandedGroup.id,
      creatorId: 'user_valen',
      creatorName: 'Valentina',
      title: 'Café & Merienda en Colegiales',
      category: 'coffee',
      scheduledAt: DateTime.now().add(const Duration(days: 2, hours: 4)),
      locationName: 'Cuervo Café (Colegiales)',
      rsvpStatus: {
        'admin_leo': 'going',
        'user_valen': 'going',
        'user_camila': 'going',
        'user_lucas': 'maybe',
      },
      checkedInUserIds: [],
      isCompleted: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
    ));
  }
}
