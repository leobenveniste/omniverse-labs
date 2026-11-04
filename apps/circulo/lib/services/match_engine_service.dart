import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/circle_group_model.dart';
import '../models/swipe_interaction_model.dart';
import '../models/user_model.dart';
import 'online_firestore_service.dart';

class SwipeResult {
  final bool isMatch;
  final CircleGroupModel? formedGroup;
  final String? message;

  const SwipeResult({
    this.isMatch = false,
    this.formedGroup,
    this.message,
  });
}

class MatchEngineService extends ChangeNotifier {
  final OnlineFirestoreService _firestore;

  MatchEngineService(this._firestore);

  // --- CÁLCULO DE AFINIDAD Y QUÍMICA DE ROLES ---
  int calculateCompatibilityScore({
    required UserModel currentUser,
    UserModel? candidateUser,
    CircleGroupModel? candidateGroup,
    List<UserModel> groupMembers = const [],
  }) {
    if (candidateUser != null) {
      // 1. Intereses en común (45%)
      final sharedInterests = currentUser.interests
          .where((i) => candidateUser.interests.contains(i))
          .length;
      final totalPossibleInterests =
          math.max(1, currentUser.interests.length);
      final interestScore =
          (sharedInterests / totalPossibleInterests).clamp(0.0, 1.0) * 45;

      // 2. Planes favoritos (25%)
      final sharedPlans = currentUser.favoritePlans
          .where((p) => candidateUser.favoritePlans.contains(p))
          .length;
      final planScore = (sharedPlans / 3.0).clamp(0.0, 1.0) * 25;

      // 3. Disponibilidad horaria (15%)
      final sharedSlots = currentUser.availabilitySlots
          .where((s) => candidateUser.availabilitySlots.contains(s))
          .length;
      final slotScore = (sharedSlots / 2.0).clamp(0.0, 1.0) * 15;

      // 4. Química de Roles (15%): bonifica variedad de rol
      double roleScore = 8;
      if (currentUser.groupRole != candidateUser.groupRole) {
        roleScore = 15;
      }

      final total =
          (interestScore + planScore + slotScore + roleScore).round();
      return total.clamp(40, 99);
    } else if (candidateGroup != null && groupMembers.isNotEmpty) {
      // Compatibilidad con un Círculo (3/4 o grupo en expansión)
      int sharedInterestsCount = 0;
      for (final interest in currentUser.interests) {
        if (candidateGroup.sharedInterests.contains(interest)) {
          sharedInterestsCount++;
        }
      }
      final interestScore =
          (sharedInterestsCount / math.max(1, candidateGroup.sharedInterests.length))
                  .clamp(0.0, 1.0) *
              50;

      // ¿El grupo ya tiene organizador?
      final hasOrganizer =
          groupMembers.any((m) => m.groupRole == GroupRoles.organizer);
      double roleBonus = 15;
      if (!hasOrganizer && currentUser.groupRole == GroupRoles.organizer) {
        roleBonus = 35; // Alta necesidad de organizador
      }

      final total = (interestScore + roleBonus + 15).round();
      return total.clamp(50, 98);
    }
    return 75;
  }

  // --- MAZO DE EXPLORACIÓN DE DESCUBRIR ---
  List<DeckCandidateItem> getDiscoveryDeck({
    required UserModel currentUser,
    String? regionFilter,
    int? minAge,
    int? maxAge,
    bool circlesOnly = false,
    bool peopleOnly = false,
  }) {
    final swipes = _firestore.getSwipesFromUser(currentUser.id);
    final swipedTargetIds = swipes.map((s) => s.targetId).toSet();

    final deck = <DeckCandidateItem>[];

    // 1. Círculos en formación (3/4) y Grupos abiertos en expansión
    if (!peopleOnly) {
      for (final group in _firestore.currentGroups) {
        if (group.memberIds.contains(currentUser.id)) continue;
        if (swipedTargetIds.contains(group.id)) continue;
        if (regionFilter != null &&
            regionFilter.isNotEmpty &&
            regionFilter != AppRegions.allRegions &&
            group.region != regionFilter) {
          continue;
        }

        final members = <UserModel>[];
        for (final mId in group.memberIds) {
          final m = _firestore.currentUsers.firstWhere(
            (u) => u.id == mId,
            orElse: () => UserModel(
              id: mId,
              email: '',
              passwordHash: '',
              firstName: 'Amigo',
              lastName: '',
              birthDate: DateTime(1998, 1, 1),
              duoInviteCode: '',
              createdAt: DateTime.now(),
            ),
          );
          members.add(m);
        }

        final score = calculateCompatibilityScore(
          currentUser: currentUser,
          candidateGroup: group,
          groupMembers: members,
        );

        final isAlmostFull = group.memberIds.length == 3 && group.maxMembers == 4;

        deck.add(DeckCandidateItem(
          type: isAlmostFull
              ? DeckCandidateType.formingCircle
              : DeckCandidateType.expandedGroup,
          group: group,
          groupMembers: members,
          affinityScore: score,
          sharedInterests: group.sharedInterests,
          sharedPlans: group.sharedPlans,
        ));
      }
    }

    if (circlesOnly) {
      deck.sort((a, b) => b.affinityScore.compareTo(a.affinityScore));
      return deck;
    }

    // 2. Perfiles individuales
    for (final candidate in _firestore.currentUsers) {
      if (candidate.id == currentUser.id) continue;
      if (currentUser.hasDuoPartner && candidate.id == currentUser.duoPartnerId) {
        continue;
      }
      if (swipedTargetIds.contains(candidate.id)) continue;
      if (currentUser.blockedUserIds.contains(candidate.id)) continue;
      if (candidate.isDiscoveryPaused) continue;

      if (regionFilter != null &&
          regionFilter.isNotEmpty &&
          regionFilter != AppRegions.allRegions &&
          candidate.region != regionFilter) {
        continue;
      }

      if (minAge != null && candidate.age < minAge) continue;
      if (maxAge != null && candidate.age > maxAge) continue;

      final sharedInts = currentUser.interests
          .where((i) => candidate.interests.contains(i))
          .toList();
      final sharedPlans = currentUser.favoritePlans
          .where((p) => candidate.favoritePlans.contains(p))
          .toList();

      int score = calculateCompatibilityScore(
        currentUser: currentUser,
        candidateUser: candidate,
      );

      // Si el candidato tiene un Perfil Destacado (Boost) activo, potenciar visibilidad
      if (candidate.hasActiveBoost) {
        score = (score + 20).clamp(40, 100);
      }

      deck.add(DeckCandidateItem(
        type: DeckCandidateType.individual,
        user: candidate,
        affinityScore: score,
        sharedInterests: sharedInts,
        sharedPlans: sharedPlans,
      ));
    }

    // Ordenar: candidatos con Boost prioritarios, luego círculos 3/4 y afinidad alta
    deck.sort((a, b) {
      final aBoost = a.user?.hasActiveBoost ?? false;
      final bBoost = b.user?.hasActiveBoost ?? false;
      if (aBoost && !bBoost) return -1;
      if (!aBoost && bBoost) return 1;

      if (a.isCircle && !b.isCircle) return -1;
      if (!a.isCircle && b.isCircle) return 1;
      return b.affinityScore.compareTo(a.affinityScore);
    });

    return deck;
  }

  // --- PROCESAR SWIPE (MATCH DE 4 O EXPANSIÓN) ---
  Future<SwipeResult> processSwipe({
    required UserModel currentUser,
    required DeckCandidateItem item,
    required String action, // 'like' | 'superlike' | 'pass'
  }) async {
    // Registrar swipe online
    final swipe = SwipeInteractionModel(
      id: const Uuid().v4(),
      fromUserId: currentUser.id,
      targetId: item.id,
      targetType: item.isCircle ? 'circle' : 'user',
      action: action,
      timestamp: DateTime.now(),
    );
    await _firestore.recordSwipe(swipe);

    // Si fue like o superlike a un usuario individual, registrar en whoLikedMeUserIds
    if (!item.isCircle && item.user != null && (action == 'like' || action == 'superlike')) {
      final targetUser = item.user!;
      if (!targetUser.whoLikedMeUserIds.contains(currentUser.id)) {
        final updatedLikes = List<String>.from(targetUser.whoLikedMeUserIds)
          ..add(currentUser.id);
        final updatedTarget = targetUser.copyWith(
          whoLikedMeUserIds: updatedLikes,
        );
        await _firestore.upsertUser(updatedTarget);
      }
    }

    if (action == 'pass') {
      return const SwipeResult(isMatch: false);
    }

    // CASO 1: Swipe a Círculo en Formación (Concurrencia Atómica ACID)
    if (item.type == DeckCandidateType.formingCircle && item.group != null) {
      final joinResult = await _firestore.joinFormingCircleAtomic(
        groupId: item.group!.id,
        joiningUser: currentUser,
      );

      if (!joinResult.success) {
        return SwipeResult(
          isMatch: false,
          message:
              joinResult.failureReason ?? 'No fue posible unirse al Círculo.',
        );
      }

      final updatedGroup = joinResult.updatedGroup!;
      if (joinResult.isCompletedK4) {
        // Enviar rompehielos automático en el chat
        await _firestore.sendMessage(GroupMessageModel(
          id: const Uuid().v4(),
          groupId: updatedGroup.id,
          senderId: 'system',
          senderName: 'Círculo Bot',
          type: 'icebreaker',
          text:
              '¡Se armó el grupo de 4! 🚀 Para romper el hielo: ¿Cuál fue la mejor salida o anécdota que tuvieron este año?',
          timestamp: DateTime.now(),
        ));

        notifyListeners();
        return SwipeResult(
          isMatch: true,
          formedGroup: updatedGroup,
          message: '¡Círculo de 4 personas formado con éxito!',
        );
      } else {
        notifyListeners();
        return const SwipeResult(
          isMatch: false,
          message:
              '¡Te sumaste al Círculo en formación! Esperando completar 4 miembros.',
        );
      }
    }

    // CASO 2: Swipe a Grupo Abierto en Expansión (4 a 9 personas)
    if (item.type == DeckCandidateType.expandedGroup && item.group != null) {
      final group = item.group!;
      final votes = Map<String, List<String>>.from(group.candidateVotes);
      votes[currentUser.id] = [currentUser.id]; // Autovoto de interés

      final updatedGroup = group.copyWith(
        candidateVotes: votes,
        lastActivityAt: DateTime.now(),
      );
      await _firestore.upsertGroup(updatedGroup);

      // Notificar al grupo de la nueva postulación
      await _firestore.sendMessage(GroupMessageModel(
        id: const Uuid().v4(),
        groupId: group.id,
        senderId: 'system',
        senderName: 'Círculo Bot',
        type: 'system',
        text:
            '${currentUser.firstName} quiere sumarse al Círculo. Voten en Detalles del Grupo para aceptarlo/a.',
        timestamp: DateTime.now(),
      ));

      notifyListeners();
      return SwipeResult(
        isMatch: false,
        message: '¡Te postulaste para sumarte al Círculo!',
      );
    }

    // CASO 3: Swipe a Perfil Individual
    if (item.user != null) {
      final targetUser = item.user!;
      // Verificar si el otro usuario ya le dio like al actual
      final otherSwipes = _firestore.getSwipesFromUser(targetUser.id);
      final mutual = otherSwipes.any(
        (s) => s.targetId == currentUser.id && s.action != 'pass',
      );

      if (mutual) {
        // Buscar si podemos incorporarlos a un pre-grupo 2/4 existente o crear uno nuevo
        final newCircleId = 'circle_${const Uuid().v4().substring(0, 8)}';
        final newGroup = CircleGroupModel(
          id: newCircleId,
          name: 'Círculo ${currentUser.firstName} & ${targetUser.firstName}',
          status: 'forming_2',
          memberIds: [currentUser.id, targetUser.id],
          activeConfirmedMemberIds: [currentUser.id, targetUser.id],
          maxMembers: 4,
          sharedInterests: item.sharedInterests,
          sharedPlans: item.sharedPlans,
          region: currentUser.region,
          lastMessagePreview: 'Círculo en formación (2/4). Faltan 2 personas.',
          lastActivityAt: DateTime.now(),
          createdAt: DateTime.now(),
        );

        await _firestore.upsertGroup(newGroup);
        notifyListeners();
        return const SwipeResult(
          isMatch: false,
          message: '¡Conexión mutua! Se creó un Círculo en formación (2/4).',
        );
      }
    }

    return const SwipeResult(isMatch: false);
  }

  // --- CHECK-IN DE SALIDA REAL ---
  Future<bool> confirmMeetupCheckIn({
    required String groupId,
    required String planId,
    required UserModel currentUser,
  }) async {
    final plans = _firestore.getPlansForGroup(groupId);
    final planIdx = plans.indexWhere((p) => p.id == planId);
    if (planIdx == -1) return false;

    final plan = plans[planIdx];
    final checkedIn = List<String>.from(plan.checkedInUserIds);
    if (!checkedIn.contains(currentUser.id)) {
      checkedIn.add(currentUser.id);

      final updatedPlan = plan.copyWith(
        checkedInUserIds: checkedIn,
        isCompleted: true,
      );
      await _firestore.upsertPlan(updatedPlan);

      // Acreditar +1 salida real al usuario en Firestore
      final updatedUser = currentUser.copyWith(
        completedMeetupsCount: currentUser.completedMeetupsCount + 1,
      );
      await _firestore.upsertUser(updatedUser);

      // Mensaje de sistema en el chat
      await _firestore.sendMessage(GroupMessageModel(
        id: const Uuid().v4(),
        groupId: groupId,
        senderId: 'system',
        senderName: 'Círculo Bot',
        type: 'system',
        text:
            '🎉 ¡${currentUser.firstName} confirmó Check-in de Salida Real! Suma +1 salida a su perfil de confianza.',
        timestamp: DateTime.now(),
      ));

      notifyListeners();
      return true;
    }
    return false;
  }

  // --- SISTEMA ANTI-GRUPOS FANTASMA (LIBERAR ASIENTO) ---
  Future<bool> releaseInactiveSeat({
    required String groupId,
    required String inactiveUserId,
  }) async {
    final group = await _firestore.getGroupById(groupId);
    if (group == null) return false;

    final newMembers = List<String>.from(group.memberIds)
      ..remove(inactiveUserId);
    final newActive = List<String>.from(group.activeConfirmedMemberIds)
      ..remove(inactiveUserId);

    final updatedGroup = group.copyWith(
      memberIds: newMembers,
      activeConfirmedMemberIds: newActive,
      status: newMembers.length < 4 ? 'forming_3' : group.status,
      lastMessagePreview: 'Se liberó un lugar inactivo. ¡Buscando nuevo amigo!',
      lastActivityAt: DateTime.now(),
    );

    await _firestore.upsertGroup(updatedGroup);

    await _firestore.sendMessage(GroupMessageModel(
      id: const Uuid().v4(),
      groupId: groupId,
      senderId: 'system',
      senderName: 'Círculo Bot',
      type: 'system',
      text:
          'Se liberó un lugar inactivo. El Círculo vuelve al mazo de descubrimiento para completar el cupo con un miembro activo.',
      timestamp: DateTime.now(),
    ));

    notifyListeners();
    return true;
  }

  // --- EXPANSIÓN HASTA 10 PERSONAS (VOTACIÓN) ---
  Future<bool> updateGroupExpansionSettings(
    String groupId, {
    required bool isOpen,
    required int maxMembers,
  }) async {
    final group = await _firestore.getGroupById(groupId);
    if (group == null) return false;

    final updated = group.copyWith(
      isOpenForExpansion: isOpen,
      maxMembers: maxMembers.clamp(4, 10),
    );
    await _firestore.upsertGroup(updated);
    notifyListeners();
    return true;
  }

  Future<bool> voteForExpansionCandidate({
    required String groupId,
    required String candidateUserId,
    required String voterUserId,
    required bool approve,
  }) async {
    final group = await _firestore.getGroupById(groupId);
    if (group == null) return false;

    final votes = Map<String, List<String>>.from(group.candidateVotes);
    final candidateVoters = List<String>.from(votes[candidateUserId] ?? []);

    if (approve) {
      if (!candidateVoters.contains(voterUserId)) {
        candidateVoters.add(voterUserId);
      }
    } else {
      candidateVoters.remove(voterUserId);
    }
    votes[candidateUserId] = candidateVoters;

    // Si la mayoría de los miembros actuales votó a favor y hay vacante (< maxMembers)
    final majorityThreshold = (group.memberIds.length / 2).ceil();
    if (candidateVoters.length >= majorityThreshold &&
        group.memberIds.length < group.maxMembers) {
      final newMembers = List<String>.from(group.memberIds);
      if (!newMembers.contains(candidateUserId)) {
        newMembers.add(candidateUserId);
      }
      votes.remove(candidateUserId);

      final updatedGroup = group.copyWith(
        memberIds: newMembers,
        candidateVotes: votes,
        status: 'expanded',
        lastMessagePreview: '¡Un nuevo amigo se unió al Círculo!',
        lastActivityAt: DateTime.now(),
      );
      await _firestore.upsertGroup(updatedGroup);

      final newFriend = await _firestore.getUserById(candidateUserId);
      await _firestore.sendMessage(GroupMessageModel(
        id: const Uuid().v4(),
        groupId: groupId,
        senderId: 'system',
        senderName: 'Círculo Bot',
        type: 'system',
        text:
            '🎊 ¡${newFriend?.firstName ?? "Nuevo amigo"} fue aceptado/a en el Círculo por votación grupal! Ya somos ${newMembers.length} integrantes.',
        timestamp: DateTime.now(),
      ));

      notifyListeners();
      return true;
    } else {
      final updatedGroup = group.copyWith(candidateVotes: votes);
      await _firestore.upsertGroup(updatedGroup);
      notifyListeners();
      return false;
    }
  }

  // --- DESHACER ÚLTIMO SWIPE (REWIND / PLUS PERK) ---
  Future<bool> undoLastSwipe(String userId) async {
    final success = await _firestore.removeLastSwipe(userId);
    if (success) {
      notifyListeners();
    }
    return success;
  }
}
