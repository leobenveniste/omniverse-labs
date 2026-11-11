import '../models/user_model.dart';
import '../models/event_model.dart';
import '../models/event_pair.dart';
import '../models/event_round_log.dart';
import '../models/event_unified_report.dart';
import '../models/case_model.dart';

/// Datos simulados (mock/sandbox) para el proceso de revisión de Google Play.
/// Permite al revisor interactuar con toda la funcionalidad de la app
/// sin acceder a datos reales ni persistir registros en la base de datos de producción.
class DemoData {
  static const String demoUserId = 'demo_user_google_play';
  static const String demoEmail = 'demo@vuelocontrolado.org';
  static const String demoPassword = 'demo1234';

  /// Valida si las credenciales ingresadas corresponden al usuario demo de Google Play
  static bool isDemoLogin(String email, String password) {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    final allowedEmails = [
      demoEmail,
      'demo@vuelocontrolado.com',
      'demo@googleplay.com',
      'demo',
    ];

    final allowedPasswords = [
      demoPassword,
      'demo2026',
      'demo',
      'vuelo2026',
    ];

    return allowedEmails.contains(cleanEmail) &&
        allowedPasswords.contains(cleanPassword);
  }

  /// Retorna el usuario principal de la cuenta demo con todos los permisos (Superadmin)
  static UserModel getDemoUser() {
    return UserModel(
      id: demoUserId,
      email: demoEmail,
      password: demoPassword,
      firstName: 'Revisor',
      lastName: 'Google Play',
      documentType: 'DNI',
      documentNumber: '99999999',
      birthDate: DateTime(1995, 5, 20),
      phone: '+5491100000000',
      instagram: 'vuelocontrolado',
      roles: AppRoles.allRoles,
      region: AppRegions.buenosAires,
      manualAttendanceCount: 12,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  /// Retorna una lista de miembros de staff simulados para gestión de equipo y rondas
  static List<UserModel> getDemoUsers() {
    return [
      getDemoUser(),
      UserModel(
        id: 'demo_staff_leo',
        email: 'leob@vuelocontrolado.org',
        password: 'password',
        firstName: 'Leo',
        lastName: 'Benveniste',
        documentType: 'DNI',
        documentNumber: '29583026',
        birthDate: DateTime(1990, 8, 15),
        phone: '+5491155550001',
        instagram: 'vuelocontrolado',
        roles: const [AppRoles.miembro, AppRoles.organizacion],
        region: AppRegions.buenosAires,
        manualAttendanceCount: 25,
        createdAt: DateTime(2025, 3, 10),
      ),
      UserModel(
        id: 'demo_staff_camila',
        email: 'camila.r@vuelocontrolado.org',
        password: 'password',
        firstName: 'Camila',
        lastName: 'Rodríguez',
        documentType: 'DNI',
        documentNumber: '38123456',
        birthDate: DateTime(1996, 11, 4),
        phone: '+5491155550002',
        instagram: 'camilarodriguez',
        roles: const [AppRoles.miembro, AppRoles.investigacion],
        region: AppRegions.buenosAires,
        manualAttendanceCount: 18,
        createdAt: DateTime(2025, 4, 1),
      ),
      UserModel(
        id: 'demo_staff_sofia',
        email: 'sofia.m@vuelocontrolado.org',
        password: 'password',
        firstName: 'Sofía',
        lastName: 'Martínez',
        documentType: 'DNI',
        documentNumber: '40987654',
        birthDate: DateTime(1998, 2, 19),
        phone: '+5493415550003',
        instagram: 'sofiamartinez',
        roles: const [AppRoles.miembro, AppRoles.recursosHumanos],
        region: AppRegions.rosario,
        manualAttendanceCount: 14,
        createdAt: DateTime(2025, 5, 12),
      ),
      UserModel(
        id: 'demo_staff_mateo',
        email: 'mateo.s@vuelocontrolado.org',
        password: 'password',
        firstName: 'Mateo',
        lastName: 'Silva',
        documentType: 'DNI',
        documentNumber: '36456789',
        birthDate: DateTime(1993, 7, 28),
        phone: '+5493515550004',
        instagram: 'mateosilva',
        roles: const [AppRoles.miembro, AppRoles.produccion],
        region: AppRegions.cordoba,
        manualAttendanceCount: 20,
        createdAt: DateTime(2025, 2, 20),
      ),
      UserModel(
        id: 'demo_staff_lucas',
        email: 'lucas.f@vuelocontrolado.org',
        password: 'password',
        firstName: 'Lucas',
        lastName: 'Fernández',
        documentType: 'DNI',
        documentNumber: '42345678',
        birthDate: DateTime(2000, 9, 3),
        phone: '+5491155550005',
        instagram: 'lucasfernandez',
        roles: const [AppRoles.miembro, AppRoles.comunicacion, AppRoles.comercial],
        region: AppRegions.buenosAires,
        manualAttendanceCount: 9,
        createdAt: DateTime(2025, 8, 15),
      ),
    ];
  }

  /// Retorna eventos simulados que abarcan los estados En curso, Próximo y Pasado
  static List<EventModel> getDemoEvents() {
    final now = DateTime.now();

    return [
      // 1. Evento En Curso (Hoy)
      EventModel(
        id: 'demo_event_today',
        name: 'Festival Mandarine Nocturna 2026',
        date: DateTime(now.year, now.month, now.day),
        startTime: '22:00',
        doorsOpenTime: '23:00',
        endTime: '07:00',
        location: 'Mandarine Park',
        address: 'Av. Costanera Norte y Sarmiento, CABA',
        region: AppRegions.buenosAires,
        requiredStaffCount: 12,
        staffIds: const [
          demoUserId,
          'demo_staff_leo',
          'demo_staff_camila',
          'demo_staff_sofia',
          'demo_staff_mateo',
        ],
        confirmedStaffIds: const [
          demoUserId,
          'demo_staff_leo',
          'demo_staff_camila',
        ],
        absentStaffIds: const [],
        createdBy: demoUserId,
        createdByName: 'Revisor Google Play',
        createdAt: now.subtract(const Duration(days: 3)),
        isManuallyStarted: true,
        isManuallyClosed: false,
        pairs: [
          EventPair(
            id: 'demo_pair_1',
            user1Id: demoUserId,
            user1Name: 'Revisor Google Play',
            user2Id: 'demo_staff_camila',
            user2Name: 'Camila Rodríguez',
            createdAt: now.subtract(const Duration(hours: 2)),
          ),
          EventPair(
            id: 'demo_pair_2',
            user1Id: 'demo_staff_leo',
            user1Name: 'Leo Benveniste',
            user2Id: 'demo_staff_mateo',
            user2Name: 'Mateo Silva',
            createdAt: now.subtract(const Duration(hours: 2)),
          ),
        ],
        roundLogs: [
          EventRoundLog(
            id: 'demo_round_1',
            timestamp: now.subtract(const Duration(hours: 2)),
            memberId: demoUserId,
            memberName: 'Revisor Google Play',
            partnerId: 'demo_staff_camila',
            partnerName: 'Camila Rodríguez',
            detectedCasesCount: 1,
            callsCount: 0,
            observations: 'Apertura sin incidentes. Puntos de hidratación funcionando correctamente.',
          ),
          EventRoundLog(
            id: 'demo_round_2',
            timestamp: now.subtract(const Duration(hours: 1)),
            memberId: 'demo_staff_leo',
            memberName: 'Leo Benveniste',
            partnerId: 'demo_staff_mateo',
            partnerName: 'Mateo Silva',
            detectedCasesCount: 1,
            callsCount: 1,
            observations: 'Buena ventilación general. Entregados 50 folletos de reducción de daños.',
          ),
        ],
      ),

      // 2. Evento Próximo
      EventModel(
        id: 'demo_event_upcoming',
        name: 'Club Undergroove - Edición Invierno',
        date: DateTime(now.year, now.month, now.day).add(const Duration(days: 6)),
        startTime: '23:30',
        doorsOpenTime: '00:00',
        endTime: '06:30',
        location: 'Niceto Club',
        address: 'Niceto Vega 5510, Palermo, CABA',
        region: AppRegions.buenosAires,
        requiredStaffCount: 8,
        staffIds: const [
          demoUserId,
          'demo_staff_leo',
          'demo_staff_lucas',
        ],
        confirmedStaffIds: const [demoUserId],
        absentStaffIds: const [],
        createdBy: demoUserId,
        createdByName: 'Revisor Google Play',
        createdAt: now.subtract(const Duration(days: 1)),
        isManuallyStarted: false,
        isManuallyClosed: false,
        pairs: const [],
        roundLogs: const [],
      ),

      // 3. Evento Pasado y Concluido
      EventModel(
        id: 'demo_event_past',
        name: 'Open Air Vuelo Controlado #14',
        date: DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7)),
        startTime: '18:00',
        doorsOpenTime: '18:00',
        endTime: '02:00',
        location: 'Complejo Art Media',
        address: 'Av. Corrientes 6271, Chacarita, CABA',
        region: AppRegions.buenosAires,
        requiredStaffCount: 10,
        staffIds: const [
          demoUserId,
          'demo_staff_camila',
          'demo_staff_sofia',
        ],
        confirmedStaffIds: const [
          demoUserId,
          'demo_staff_camila',
          'demo_staff_sofia',
        ],
        absentStaffIds: const [],
        createdBy: demoUserId,
        createdByName: 'Revisor Google Play',
        createdAt: now.subtract(const Duration(days: 14)),
        isManuallyStarted: true,
        isManuallyClosed: true,
        pairs: const [],
        roundLogs: const [],
        unifiedReport: EventUnifiedReport(
          durationTotal: '8 horas',
          producer: 'Producción General Vuelo',
          eventType: 'Festival',
          timeSlot: 'Nocturno',
          spaceType: 'Outdoor',
          dayNumber: 'Única',
          perceivedDensity: 'Media',
          weatherTypes: const ['Templado', 'Despejado'],
          medicalAttendedCount: 5,
          medicalTransferredCount: 0,
          vcAttendedCount: 3,
          medicalComposition: const {'Médicos': 2, 'Enfermeros': 2, 'Socorristas': 4},
          vueloVolunteersCount: '8 voluntarios',
          vueloFruitQuantity: '4 cajones',
          otherRelevantInfo: 'Operativo sin traslados médicos. Excelente articulación con producción.',
          completedByUserId: demoUserId,
          completedByUserName: 'Revisor Google Play',
          completedAt: now.subtract(const Duration(days: 6)),
        ),
      ),
    ];
  }

  /// Retorna fichas de caso simuladas y verosímiles de reducción de daños
  static List<CaseModel> getDemoCases() {
    final now = DateTime.now();

    return [
      CaseModel(
        id: 'demo_case_1',
        eventId: 'demo_event_today',
        eventName: 'Festival Mandarine Nocturna 2026',
        registeredByUserId: demoUserId,
        registeredByUserName: 'Revisor Google Play',
        timestamp: now.subtract(const Duration(hours: 1, minutes: 15)),
        gender: 'Femenino',
        ageRange: '18 – 25',
        moment: 'Main',
        duration: 'hasta 30\'',
        arrivalMode: 'Traído por amigxs',
        accompaniedBy: 'Amistades',
        consumedSubstances: 'Si',
        substanceEntries: const {'Alcohol': '2 vasos', 'MDMA / Éxtasis': '1/2 pasti'},
        isFirstTimeConsuming: 'No',
        physicalSymptoms: const ['Sed intensa', 'Sudoración leve', 'Cansancio'],
        psychologicalSymptoms: const ['Calma', 'Orientado/a'],
        healthTeamIntervened: false,
        isComplexCase: false,
        resolution: 'Recuperación íntegra',
        attendingStaff: 'Revisor Google Play',
        relevantInfo:
            'Se suministró agua fresca y pautas de cuidado. Se retira compensada y acompañada por su grupo.',
        isSyncedToDrive: false,
      ),
      CaseModel(
        id: 'demo_case_2',
        eventId: 'demo_event_today',
        eventName: 'Festival Mandarine Nocturna 2026',
        registeredByUserId: 'demo_staff_camila',
        registeredByUserName: 'Camila Rodríguez',
        timestamp: now.subtract(const Duration(hours: 2, minutes: 40)),
        gender: 'Masculino',
        ageRange: '26 – 35',
        moment: 'Main',
        duration: 'hasta 1h',
        arrivalMode: 'Detectado en ronda',
        accompaniedBy: 'Staff de Vuelo Controlado',
        consumedSubstances: 'Si',
        substanceEntries: const {'Cannabis': '1 cigarrillo'},
        isFirstTimeConsuming: 'Si',
        physicalSymptoms: const ['Palpitaciones', 'Mareos'],
        psychologicalSymptoms: const ['Ansiedad', 'Angustia'],
        healthTeamIntervened: false,
        isComplexCase: false,
        resolution: 'Recuperación íntegra',
        attendingStaff: 'Camila Rodríguez',
        relevantInfo:
            'Ejercicios de respiración guiada en carpa de descanso. Evolución favorable. Regresa a pista tranquilo.',
        isSyncedToDrive: false,
      ),
      CaseModel(
        id: 'demo_case_3',
        eventId: 'demo_event_past',
        eventName: 'Open Air Vuelo Controlado #14',
        registeredByUserId: 'demo_staff_sofia',
        registeredByUserName: 'Sofía Martínez',
        timestamp: now.subtract(const Duration(days: 7, hours: 3)),
        gender: 'No binario',
        ageRange: '18 – 25',
        moment: 'Final',
        duration: 'hasta 30\'',
        arrivalMode: 'Solx',
        accompaniedBy: 'Solo/a',
        consumedSubstances: 'Si',
        substanceEntries: const {'Alcohol': 'Cerveza'},
        isFirstTimeConsuming: 'No',
        physicalSymptoms: const ['Mareos'],
        psychologicalSymptoms: const ['Orientado/a'],
        healthTeamIntervened: false,
        isComplexCase: false,
        resolution: 'Recuperación íntegra',
        attendingStaff: 'Sofía Martínez',
        relevantInfo:
            'Se esperó la llegada del transporte solicitado junto a la persona.',
        isSyncedToDrive: true,
      ),
    ];
  }
}
