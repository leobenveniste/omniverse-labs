import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vuelo_controlado_staff/models/user_model.dart';
import 'package:vuelo_controlado_staff/models/event_model.dart';
import 'package:vuelo_controlado_staff/models/event_pair.dart';
import 'package:vuelo_controlado_staff/models/event_round_log.dart';
import 'package:vuelo_controlado_staff/models/event_unified_report.dart';
import 'package:vuelo_controlado_staff/models/case_model.dart';
import 'package:vuelo_controlado_staff/services/storage_service.dart';
import 'package:vuelo_controlado_staff/services/auth_service.dart';
import 'package:vuelo_controlado_staff/services/event_service.dart';

void main() {
  group('UserModel Tests', () {
    test('Superadmin leobenveniste@vuelocontrolado.org has all permissions', () {
      final superadmin = UserModel(
        id: 'u1',
        email: 'leobenveniste@vuelocontrolado.org',
        password: 'admin',
        firstName: 'Leo',
        lastName: 'Benveniste',
        documentType: 'DNI',
        documentNumber: '12345678',
        birthDate: DateTime(1990, 1, 1),
        phone: '1234',
        roles: [AppRoles.miembro],
        createdAt: DateTime.now(),
      );

      expect(superadmin.isSuperAdmin, isTrue);
      expect(superadmin.canManageUsers, isTrue);
      expect(superadmin.canCreateEvents, isTrue);
      expect(superadmin.canCreateUsers, isTrue);
      expect(superadmin.canViewCommercial, isTrue);
      expect(superadmin.hasRole(AppRoles.produccion), isTrue);
      expect(superadmin.hasRole(AppRoles.rrhh), isTrue);
    });

    test('Regular member has only base permissions and Miembro role cannot be removed', () {
      final member = UserModel(
        id: 'u2',
        email: 'voluntario@vuelocontrolado.org',
        password: 'password123',
        firstName: 'Juan',
        lastName: 'Pérez',
        documentType: 'DNI',
        documentNumber: '35111222',
        birthDate: DateTime(1998, 5, 20),
        phone: '1199887766',
        roles: [AppRoles.miembro],
        createdAt: DateTime.now(),
      );

      expect(member.isSuperAdmin, isFalse);
      expect(member.canManageUsers, isFalse);
      expect(member.canCreateEvents, isFalse);
      expect(member.canCreateUsers, isFalse);
      expect(member.hasRole(AppRoles.miembro), isTrue);

      // Intento de copyWith sin rol miembro lo reincorpora
      final updated = member.copyWith(roles: [AppRoles.organizacion]);
      expect(updated.roles.contains(AppRoles.miembro), isTrue);
      expect(updated.roles.contains(AppRoles.organizacion), isTrue);
      expect(updated.canCreateEvents, isTrue);
    });

    test('RRHH user can create users', () {
      final rrhh = UserModel(
        id: 'u3',
        email: 'rrhh_staff@vuelocontrolado.org',
        password: 'password123',
        firstName: 'Ana',
        lastName: 'Gómez',
        documentType: 'DNI',
        documentNumber: '38111222',
        birthDate: DateTime(1995, 2, 10),
        phone: '1122334455',
        roles: [AppRoles.miembro, AppRoles.rrhh],
        createdAt: DateTime.now(),
      );

      expect(rrhh.canCreateUsers, isTrue);
      expect(rrhh.canManageUsers, isFalse); // Solo superadmin
    });
  });

  group('EventModel Tests', () {
    test('Event staff membership and lifecycle', () {
      final event = EventModel(
        id: 'e1',
        name: 'Festival Test',
        date: DateTime.now(),
        startTime: '22:00',
        doorsOpenTime: '21:00',
        endTime: '06:00',
        location: 'Costanera Norte, CABA',
        staffIds: ['u1', 'u2'],
        createdBy: 'u1',
        createdByName: 'Leo',
        createdAt: DateTime.now(),
        isManuallyStarted: false,
      );

      expect(event.isUserInStaff('u1'), isTrue);
      expect(event.isUserInStaff('u2'), isTrue);
      expect(event.isUserInStaff('u99'), isFalse);

      final pastEvent = event.copyWith(
        date: DateTime.now().subtract(const Duration(days: 2)),
      );
      expect(pastEvent.isPast, isTrue);
      expect(pastEvent.hasStarted, isTrue);
      expect(pastEvent.statusText, 'Finalizado');

      final now = DateTime.now();
      final ongoingEvent = event.copyWith(
        date: now,
        doorsOpenTime: '${(now.hour - 1).clamp(0, 23).toString().padLeft(2, '0')}:00',
        endTime: '${((now.hour + 2) % 24).toString().padLeft(2, '0')}:00',
      );
      expect(ongoingEvent.isOngoing, isTrue);
      expect(ongoingEvent.hasStarted, isTrue);
      expect(ongoingEvent.statusText, 'En Curso');
    });

    test('EventUnifiedReport serialization and production role guard', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = StorageService(prefs);
      final eventService = EventService(storage);

      final prodUser = UserModel(
        id: 'u_prod',
        email: 'prod@vuelocontrolado.org',
        password: 'pass',
        firstName: 'Prod',
        lastName: 'Lead',
        documentType: 'DNI',
        documentNumber: '111',
        birthDate: DateTime(1990, 1, 1),
        phone: '111',
        roles: [AppRoles.miembro, AppRoles.produccion],
        createdAt: DateTime.now(),
      );

      final regularUser = UserModel(
        id: 'u_reg',
        email: 'reg@vuelocontrolado.org',
        password: 'pass',
        firstName: 'Reg',
        lastName: 'Member',
        documentType: 'DNI',
        documentNumber: '222',
        birthDate: DateTime(1990, 1, 1),
        phone: '222',
        roles: [AppRoles.miembro],
        createdAt: DateTime.now(),
      );

      // Create an event
      await eventService.createEvent(
        name: 'Event with Report',
        date: DateTime.now(),
        startTime: '22:00',
        doorsOpenTime: '21:00',
        endTime: '06:00',
        location: 'Club Hípico',
        currentUser: prodUser,
      );

      final event = eventService.events.first;
      final report = EventUnifiedReport(
        durationTotal: '8 horas',
        producer: 'BAN Talent',
        vueloPresent: true,
        eventType: 'Festival',
        timeSlot: 'Nocturno',
        spaceType: 'Outdoor',
        dayNumber: 'Única',
        hasFreeWater: true,
        perceivedDensity: 'Alta',
        weatherTypes: ['Calor', 'Húmedo'],
        medicalAttendedCount: 12,
        medicalTransferredCount: 1,
        vcAttendedCount: 45,
        medicalComposition: {
          'traumatologico': 2,
          'intoxicacion': 8,
          'crisisPsicologica': 1,
          'malestarFisico': 1,
        },
        vueloVolunteersCount: '16',
        vueloFruitQuantity: '20 kg',
        otherRelevantInfo: 'Operativo fluido',
        completedByUserId: prodUser.id,
        completedByUserName: prodUser.fullName,
        completedAt: DateTime.now(),
      );

      // Regular member cannot save production report
      final denied = await eventService.saveEventReport(
        eventId: event.id,
        report: report,
        currentUser: regularUser,
      );
      expect(denied, isFalse);

      // Production member can save production report
      final allowed = await eventService.saveEventReport(
        eventId: event.id,
        report: report,
        currentUser: prodUser,
      );
      expect(allowed, isTrue);

      final savedEvent = eventService.getEventById(event.id);
      expect(savedEvent?.unifiedReport, isNotNull);
      expect(savedEvent?.unifiedReport?.producer, 'BAN Talent');
      expect(savedEvent?.unifiedReport?.medicalAttendedCount, 12);
      expect(savedEvent?.unifiedReport?.medicalComposition['intoxicacion'], 8);
    });

    test('EventPair and EventRoundLog serialization and helpers', () {
      final pair = EventPair(
        id: 'p1',
        user1Id: 'u1',
        user1Name: 'Leo',
        user2Id: 'u2',
        user2Name: 'Clara',
        createdAt: DateTime(2026, 10, 28, 22, 0),
      );

      expect(pair.containsUser('u1'), isTrue);
      expect(pair.containsUser('u2'), isTrue);
      expect(pair.containsUser('u3'), isFalse);
      expect(pair.getPartnerId('u1'), 'u2');
      expect(pair.getPartnerName('u1'), 'Clara');
      expect(pair.getPartnerId('u2'), 'u1');
      expect(pair.getPartnerName('u2'), 'Leo');
      expect(pair.getPartnerId('u3'), isNull);

      final pairJson = pair.toJson();
      final fromJsonPair = EventPair.fromJson(pairJson);
      expect(fromJsonPair.user1Name, 'Leo');
      expect(fromJsonPair.user2Name, 'Clara');

      final round = EventRoundLog(
        id: 'r1',
        timestamp: DateTime(2026, 10, 28, 23, 15),
        memberId: 'u1',
        memberName: 'Leo',
        partnerId: 'u2',
        partnerName: 'Clara',
        detectedCasesCount: 3,
        callsCount: 1,
        observations: 'Sector barras tranquilo',
      );

      final roundJson = round.toJson();
      final fromJsonRound = EventRoundLog.fromJson(roundJson);
      expect(fromJsonRound.detectedCasesCount, 3);
      expect(fromJsonRound.callsCount, 1);
      expect(fromJsonRound.partnerName, 'Clara');
      expect(fromJsonRound.observations, 'Sector barras tranquilo');
    });

    test('EventService pair management and round logs workflow', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = StorageService(prefs);
      final eventService = EventService(storage);

      final orgUser = UserModel(
        id: 'u_org',
        email: 'org@vuelocontrolado.org',
        password: 'pass',
        firstName: 'Org',
        lastName: 'Lead',
        documentType: 'DNI',
        documentNumber: '111',
        birthDate: DateTime(1990, 1, 1),
        phone: '111',
        roles: [AppRoles.miembro, AppRoles.organizacion],
        createdAt: DateTime.now(),
      );

      final member1 = UserModel(
        id: 'm1',
        email: 'm1@vuelocontrolado.org',
        password: 'pass',
        firstName: 'Miembro',
        lastName: 'Uno',
        documentType: 'DNI',
        documentNumber: '222',
        birthDate: DateTime(1995, 1, 1),
        phone: '222',
        roles: [AppRoles.miembro],
        createdAt: DateTime.now(),
      );

      final member2 = UserModel(
        id: 'm2',
        email: 'm2@vuelocontrolado.org',
        password: 'pass',
        firstName: 'Miembro',
        lastName: 'Dos',
        documentType: 'DNI',
        documentNumber: '333',
        birthDate: DateTime(1996, 1, 1),
        phone: '333',
        roles: [AppRoles.miembro],
        createdAt: DateTime.now(),
      );

      // Crear evento y sumarlos
      await eventService.createEvent(
        name: 'Evento Rondas Test',
        date: DateTime.now(),
        startTime: '22:00',
        doorsOpenTime: '21:00',
        endTime: '06:00',
        location: 'Espacio Test',
        currentUser: orgUser,
      );
      final eventId = eventService.events.first.id;
      await eventService.joinEvent(eventId, member1.id);
      await eventService.joinEvent(eventId, member2.id);

      // Miembro común no puede armar parejas
      final denied = await eventService.addEventPair(
        eventId: eventId,
        user1Id: member1.id,
        user1Name: member1.fullName,
        user2Id: member2.id,
        user2Name: member2.fullName,
        currentUser: member1,
      );
      expect(denied, isFalse);

      // Rol Organización sí puede armar parejas
      final allowed = await eventService.addEventPair(
        eventId: eventId,
        user1Id: member1.id,
        user1Name: member1.fullName,
        user2Id: member2.id,
        user2Name: member2.fullName,
        currentUser: orgUser,
      );
      expect(allowed, isTrue);

      final eventWithPairs = eventService.getEventById(eventId)!;
      expect(eventWithPairs.pairs.length, 1);
      expect(eventWithPairs.getPairForUser(member1.id)?.user2Name, 'Miembro Dos');

      // Member1 registra una ronda (debe detectar automáticamente que su pareja es member2)
      final roundOk = await eventService.addEventRoundLog(
        eventId: eventId,
        detectedCasesCount: 2,
        callsCount: 1,
        observations: 'Ronda por escenario principal sin novedades',
        currentUser: member1,
      );
      expect(roundOk, isTrue);

      final eventWithRound = eventService.getEventById(eventId)!;
      expect(eventWithRound.roundLogs.length, 1);
      final savedLog = eventWithRound.roundLogs.first;
      expect(savedLog.memberId, member1.id);
      expect(savedLog.partnerId, member2.id);
      expect(savedLog.partnerName, member2.fullName);
      expect(savedLog.detectedCasesCount, 2);
      expect(savedLog.callsCount, 1);
      expect(savedLog.observations, 'Ronda por escenario principal sin novedades');

      // Desarmar pareja
      final removeOk = await eventService.removeEventPair(
        eventId: eventId,
        pairId: eventWithPairs.pairs.first.id,
        currentUser: orgUser,
      );
      expect(removeOk, isTrue);
      expect(eventService.getEventById(eventId)!.pairs.isEmpty, isTrue);
    });
  });

  group('CaseModel Tests', () {
    test('Case serialization and spreadsheet generation', () {
      final caseItem = CaseModel(
        id: 'c1',
        eventId: 'e1',
        eventName: 'Festival Test',
        registeredByUserId: 'u1',
        registeredByUserName: 'Leo Benveniste',
        timestamp: DateTime(2026, 10, 23, 23, 30),
        gender: 'F',
        ageRange: '18 – 25',
        moment: 'Main',
        duration: 'hasta 30\'',
        arrivalMode: 'Solx',
        consumedSubstances: 'Si',
        substanceEntries: {'Alcohol': '2 vasos', 'Cannabis': '1 porro'},
        isFirstTimeConsuming: 'No',
        underlyingCondition: 'No',
        physicalSymptoms: ['Sensación de calor', 'Palpitaciones'],
        psychologicalSymptoms: ['Ansiedad / Angustia / Miedo'],
        healthTeamIntervened: false,
        isComplexCase: false,
        resolution: 'Recuperación íntegra',
        attendingStaff: 'Leo Benveniste',
        relevantInfo: 'Se retiró en buen estado',
        isSyncedToDrive: false,
      );

      final row = caseItem.toSpreadsheetRow();
      expect(row.length, equals(CaseModel.spreadsheetHeaders.length));
      expect(row[0], 'c1');
      expect(row[2], 'Festival Test');
      expect(row[3], 'F');
      expect(row[4], '18 – 25');
      expect(row[5], 'Main');
      expect(row[6], 'hasta 30\'');
      expect(row[7], 'Solx');
      expect(row[8], 'Si');
      expect(row[9], contains('Alcohol (2 vasos)'));
      expect(row[16], 'Recuperación íntegra');
      expect(row[17], 'Leo Benveniste');
      expect(row[19], 'Pendiente');

      final synced = caseItem.copyWith(isSyncedToDrive: true);
      expect(synced.isSyncedToDrive, isTrue);
      expect(synced.toSpreadsheetRow()[19], 'Sincronizado');
    });
  });

  group('AuthService User Management Tests', () {
    test('updateUserByAdmin resets password when document number changes', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = StorageService(prefs);
      final auth = AuthService(storage);

      // Create a user
      final created = await auth.createUser(
        email: 'staff1@vuelocontrolado.org',
        firstName: 'Staff',
        lastName: 'Uno',
        documentType: 'DNI',
        documentNumber: '11223344',
        birthDate: DateTime(1995, 1, 1),
        phone: '12345678',
        initialRoles: [AppRoles.miembro],
      );
      expect(created, isTrue);

      final user = auth.users.firstWhere((u) => u.email == 'staff1@vuelocontrolado.org');
      expect(user.password, '11223344');

      // Edit without changing document number -> password stays the same
      await auth.updateUserByAdmin(
        userId: user.id,
        firstName: 'Staff Modificado',
        lastName: 'Uno',
        email: 'staff1@vuelocontrolado.org',
        documentType: 'DNI',
        documentNumber: '11223344',
        phone: '99999999',
      );
      final userAfterNameChange = auth.users.firstWhere((u) => u.id == user.id);
      expect(userAfterNameChange.firstName, 'Staff Modificado');
      expect(userAfterNameChange.password, '11223344');

      // Edit WITH changing document number -> password resets to the new document number!
      await auth.updateUserByAdmin(
        userId: user.id,
        firstName: 'Staff Modificado',
        lastName: 'Uno',
        email: 'staff1@vuelocontrolado.org',
        documentType: 'DNI',
        documentNumber: '55667788',
        phone: '99999999',
      );
      final userAfterDocChange = auth.users.firstWhere((u) => u.id == user.id);
      expect(userAfterDocChange.documentNumber, '55667788');
      expect(userAfterDocChange.password, '55667788');
    });

    test('deleteUser deletes user and forbids deleting superadmin', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();
      final auth = AuthService(storage);

      // Attempt to delete superadmin
      final superadmin = auth.users.firstWhere((u) => u.isSuperAdmin);
      final deletedSuperadmin = await auth.deleteUser(superadmin.id);
      expect(deletedSuperadmin, isFalse);
      expect(auth.users.any((u) => u.id == superadmin.id), isTrue);

      // Create and delete regular user
      await auth.createUser(
        email: 'todelete@vuelocontrolado.org',
        firstName: 'Borrar',
        lastName: 'Test',
        documentType: 'DNI',
        documentNumber: '99887766',
        birthDate: DateTime(1996, 2, 2),
        phone: '112233',
        initialRoles: [AppRoles.miembro],
      );
      final createdUser = auth.users.firstWhere((u) => u.email == 'todelete@vuelocontrolado.org');
      expect(auth.users.any((u) => u.id == createdUser.id), isTrue);

      final deleted = await auth.deleteUser(createdUser.id);
      expect(deleted, isTrue);
      expect(auth.users.any((u) => u.id == createdUser.id), isFalse);
    });

    test('updateUserPhoto updates user photoUrl successfully', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();
      final auth = AuthService(storage);

      final user = auth.users.first;
      expect(user.photoUrl, isNull);

      final ok = await auth.updateUserPhoto(
        userId: user.id,
        photoUrl: 'data:image/jpeg;base64,mockphotodata',
      );
      expect(ok, isTrue);
      final updatedUser = auth.users.firstWhere((u) => u.id == user.id);
      expect(updatedUser.photoUrl, 'data:image/jpeg;base64,mockphotodata');
    });
  });

  group('EventService CRUD & Permission Tests', () {
    test('createEvent, updateEvent, and deleteEvent with permissions', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();
      final auth = AuthService(storage);
      final eventService = EventService(storage);

      final superadmin = auth.users.firstWhere((u) => u.isSuperAdmin);

      // Create event
      final created = await eventService.createEvent(
        name: 'Event Original',
        date: DateTime(2026, 12, 1),
        startTime: '14:00',
        doorsOpenTime: '16:00',
        endTime: '01:00',
        location: 'Club Hípico',
        address: 'Av. Libertador 1000',
        requiredStaffCount: 20,
        currentUser: superadmin,
      );
      expect(created, isTrue);
      final event = eventService.events.firstWhere((e) => e.name == 'Event Original');
      expect(event.location, 'Club Hípico');
      expect(event.requiredStaffCount, 20);

      // Update event
      final updated = await eventService.updateEvent(
        eventId: event.id,
        name: 'Event Modificado',
        date: DateTime(2026, 12, 2),
        startTime: '15:00',
        doorsOpenTime: '17:00',
        endTime: '02:00',
        location: 'Costanera',
        address: 'Av. Costanera 500',
        requiredStaffCount: 25,
        currentUser: superadmin,
      );
      expect(updated, isTrue);
      final eventAfterUpdate = eventService.getEventById(event.id)!;
      expect(eventAfterUpdate.name, 'Event Modificado');
      expect(eventAfterUpdate.location, 'Costanera');
      expect(eventAfterUpdate.requiredStaffCount, 25);

      // Non-authorized member cannot delete
      final memberUser = UserModel(
        id: 'regular_member',
        email: 'member@vuelocontrolado.org',
        password: 'pass',
        firstName: 'Member',
        lastName: 'Regular',
        documentType: 'DNI',
        documentNumber: '111',
        birthDate: DateTime(1995, 1, 1),
        phone: '123',
        roles: [AppRoles.miembro],
        createdAt: DateTime.now(),
      );

      final unauthorizedDelete = await eventService.deleteEvent(event.id, memberUser);
      expect(unauthorizedDelete, isFalse);
      expect(eventService.getEventById(event.id), isNotNull);

      // Superadmin can delete
      final authorizedDelete = await eventService.deleteEvent(event.id, superadmin);
      expect(authorizedDelete, isTrue);
      expect(eventService.getEventById(event.id), isNull);
    });
  });
}
