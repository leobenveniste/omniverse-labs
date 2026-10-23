import 'package:flutter_test/flutter_test.dart';
import 'package:vuelo_controlado_staff/models/user_model.dart';
import 'package:vuelo_controlado_staff/models/event_model.dart';
import 'package:vuelo_controlado_staff/models/case_model.dart';

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
        staffIds: ['u1', 'u2'],
        createdBy: 'u1',
        createdByName: 'Leo',
        createdAt: DateTime.now(),
        isManuallyStarted: false,
      );

      expect(event.isUserInStaff('u1'), isTrue);
      expect(event.isUserInStaff('u2'), isTrue);
      expect(event.isUserInStaff('u99'), isFalse);

      final startedEvent = event.copyWith(isManuallyStarted: true);
      expect(startedEvent.hasStarted, isTrue);
      expect(startedEvent.statusText, 'En Curso');

      final closedEvent = startedEvent.copyWith(isManuallyClosed: true);
      expect(closedEvent.hasStarted, isFalse);
      expect(closedEvent.statusText, 'Finalizado');
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
        personName: 'Camila',
        personAge: '22',
        personGender: 'Femenino',
        interventionType: 'Contención emocional',
        substances: ['Alcohol', 'Cannabis'],
        symptoms: 'Ansiedad y mareos leves',
        actionsTaken: 'Agua fresca, escucha activa, reposo 15 min',
        observations: 'Se retiró en buen estado',
        isSyncedToDrive: false,
      );

      final row = caseItem.toSpreadsheetRow();
      expect(row.length, equals(CaseModel.spreadsheetHeaders.length));
      expect(row[0], 'c1');
      expect(row[2], 'Festival Test');
      expect(row[3], 'Camila');
      expect(row[4], '22');
      expect(row[6], 'Contención emocional');
      expect(row[7], 'Alcohol; Cannabis');
      expect(row[11], 'Leo Benveniste');
      expect(row[12], 'Pendiente');

      final synced = caseItem.copyWith(isSyncedToDrive: true);
      expect(synced.isSyncedToDrive, isTrue);
      expect(synced.toSpreadsheetRow()[12], 'Sincronizado');
    });
  });
}
