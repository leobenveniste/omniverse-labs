class CaseModel {
  final String id;
  final String eventId;
  final String eventName;
  final String registeredByUserId;
  final String registeredByUserName;
  final DateTime timestamp;

  // 1. Perfil de la persona & Contexto (PDF 1)
  final String gender; // M, F, No binario
  final String ageRange; // -18, 18 – 25, 26 – 35, 36 – 45, +45
  final String moment; // Inicio, Main, Final
  final String duration; // 5', hasta 30', hasta 1h, más de 1h
  final String arrivalMode; // Solx, Traído por amigxs, Detectado en ronda, Acompañadx
  final String? accompaniedBy;

  // 2. Consumo de Sustancias (PDF 1)
  final String consumedSubstances; // Si, No, No sabe si consumió, Desconocido
  final Map<String, String> substanceEntries; // Sustancia -> Cantidad
  final String? mdmaPillName; // ¿cuál? en MDMA Pastilla
  final String? otherSubstanceName; // Nombre si seleccionó Otro
  final String isFirstTimeConsuming; // Si, No, Desconocido
  final String underlyingCondition; // No, Desconocido, o Si: [detalle]

  // 3. Signos y Síntomas Físicos (PDF 1)
  final List<String> physicalSymptoms;
  final String? otherPhysicalSymptoms;

  // 4. Signos Psicológicos / Emocionales (PDF 1)
  final List<String> psychologicalSymptoms;

  // 5. Intervención, Complejidad y Resolución (PDF 1)
  final bool healthTeamIntervened; // Si / No
  final bool isComplexCase; // Si / No
  final String resolution; // Recuperación íntegra, Deriva al servicio sanitario, Otro
  final String? otherResolution;
  final String attendingStaff; // Vuelo que atendió
  final String relevantInfo; // Info relevante

  // Sincronización
  final bool isSyncedToDrive;
  final DateTime? syncedAt;

  CaseModel({
    required this.id,
    required this.eventId,
    required this.eventName,
    required this.registeredByUserId,
    required this.registeredByUserName,
    required this.timestamp,
    String? gender,
    String? ageRange,
    String? moment,
    String? duration,
    String? arrivalMode,
    this.accompaniedBy,
    String? consumedSubstances,
    Map<String, String>? substanceEntries,
    this.mdmaPillName,
    this.otherSubstanceName,
    String? isFirstTimeConsuming,
    String? underlyingCondition,
    List<String>? physicalSymptoms,
    this.otherPhysicalSymptoms,
    List<String>? psychologicalSymptoms,
    this.healthTeamIntervened = false,
    this.isComplexCase = false,
    String? resolution,
    this.otherResolution,
    String? attendingStaff,
    String? relevantInfo,
    this.isSyncedToDrive = false,
    this.syncedAt,
    // Compatibilidad con invocaciones legacy:
    String? personName,
    String? personAge,
    String? personGender,
    String? interventionType,
    List<String>? substances,
    String? symptoms,
    String? actionsTaken,
    String? observations,
  })  : gender = gender ?? personGender ?? 'No especifica',
        ageRange = ageRange ?? personAge ?? '18 – 25',
        moment = moment ?? 'Main',
        duration = duration ?? 'hasta 30\'',
        arrivalMode = arrivalMode ?? 'Solx',
        consumedSubstances = consumedSubstances ??
            ((substances != null && substances.isNotEmpty) ? 'Si' : 'No'),
        substanceEntries = substanceEntries ??
            {for (final s in (substances ?? <String>[])) s: ''},
        isFirstTimeConsuming = isFirstTimeConsuming ?? 'No',
        underlyingCondition = underlyingCondition ?? 'No',
        physicalSymptoms = physicalSymptoms ??
            (symptoms != null && symptoms.isNotEmpty ? [symptoms] : const []),
        psychologicalSymptoms = psychologicalSymptoms ?? const [],
        resolution = resolution ?? interventionType ?? 'Recuperación íntegra',
        attendingStaff = attendingStaff ?? registeredByUserName,
        relevantInfo = relevantInfo ?? observations ?? '';

  // Getters de retrocompatibilidad con vistas previas, filtros y exportadores
  String get personName => gender.isNotEmpty ? '$gender ($ageRange)' : 'Atención';
  String get personAge => ageRange;
  String get personGender => gender;
  String get interventionType => resolution.isNotEmpty ? resolution : 'Atención';
  List<String> get substances => substanceEntries.keys.toList();
  String get symptoms {
    final list = [...physicalSymptoms, ...psychologicalSymptoms];
    if (otherPhysicalSymptoms != null && otherPhysicalSymptoms!.isNotEmpty) {
      list.add('Otro físico: $otherPhysicalSymptoms');
    }
    return list.join(', ');
  }
  String get actionsTaken => healthTeamIntervened
      ? 'Intervención con equipo de salud • $resolution'
      : resolution;
  String get observations => relevantInfo;

  CaseModel copyWith({
    String? gender,
    String? ageRange,
    String? moment,
    String? duration,
    String? arrivalMode,
    String? accompaniedBy,
    String? consumedSubstances,
    Map<String, String>? substanceEntries,
    String? mdmaPillName,
    String? otherSubstanceName,
    String? isFirstTimeConsuming,
    String? underlyingCondition,
    List<String>? physicalSymptoms,
    String? otherPhysicalSymptoms,
    List<String>? psychologicalSymptoms,
    bool? healthTeamIntervened,
    bool? isComplexCase,
    String? resolution,
    String? otherResolution,
    String? attendingStaff,
    String? relevantInfo,
    bool? isSyncedToDrive,
    DateTime? syncedAt,
  }) {
    return CaseModel(
      id: id,
      eventId: eventId,
      eventName: eventName,
      registeredByUserId: registeredByUserId,
      registeredByUserName: registeredByUserName,
      timestamp: timestamp,
      gender: gender ?? this.gender,
      ageRange: ageRange ?? this.ageRange,
      moment: moment ?? this.moment,
      duration: duration ?? this.duration,
      arrivalMode: arrivalMode ?? this.arrivalMode,
      accompaniedBy: accompaniedBy ?? this.accompaniedBy,
      consumedSubstances: consumedSubstances ?? this.consumedSubstances,
      substanceEntries: substanceEntries ?? this.substanceEntries,
      mdmaPillName: mdmaPillName ?? this.mdmaPillName,
      otherSubstanceName: otherSubstanceName ?? this.otherSubstanceName,
      isFirstTimeConsuming: isFirstTimeConsuming ?? this.isFirstTimeConsuming,
      underlyingCondition: underlyingCondition ?? this.underlyingCondition,
      physicalSymptoms: physicalSymptoms ?? this.physicalSymptoms,
      otherPhysicalSymptoms: otherPhysicalSymptoms ?? this.otherPhysicalSymptoms,
      psychologicalSymptoms: psychologicalSymptoms ?? this.psychologicalSymptoms,
      healthTeamIntervened: healthTeamIntervened ?? this.healthTeamIntervened,
      isComplexCase: isComplexCase ?? this.isComplexCase,
      resolution: resolution ?? this.resolution,
      otherResolution: otherResolution ?? this.otherResolution,
      attendingStaff: attendingStaff ?? this.attendingStaff,
      relevantInfo: relevantInfo ?? this.relevantInfo,
      isSyncedToDrive: isSyncedToDrive ?? this.isSyncedToDrive,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'eventName': eventName,
      'registeredByUserId': registeredByUserId,
      'registeredByUserName': registeredByUserName,
      'timestamp': timestamp.toIso8601String(),
      'gender': gender,
      'ageRange': ageRange,
      'moment': moment,
      'duration': duration,
      'arrivalMode': arrivalMode,
      'accompaniedBy': accompaniedBy,
      'consumedSubstances': consumedSubstances,
      'substanceEntries': substanceEntries,
      'mdmaPillName': mdmaPillName,
      'otherSubstanceName': otherSubstanceName,
      'isFirstTimeConsuming': isFirstTimeConsuming,
      'underlyingCondition': underlyingCondition,
      'physicalSymptoms': physicalSymptoms,
      'otherPhysicalSymptoms': otherPhysicalSymptoms,
      'psychologicalSymptoms': psychologicalSymptoms,
      'healthTeamIntervened': healthTeamIntervened,
      'isComplexCase': isComplexCase,
      'resolution': resolution,
      'otherResolution': otherResolution,
      'attendingStaff': attendingStaff,
      'relevantInfo': relevantInfo,
      'isSyncedToDrive': isSyncedToDrive,
      'syncedAt': syncedAt?.toIso8601String(),
      // Campos legacy en json para compatibilidad con backend existente
      'personName': personName,
      'personAge': personAge,
      'personGender': personGender,
      'interventionType': interventionType,
      'substances': substances,
      'symptoms': symptoms,
      'actionsTaken': actionsTaken,
      'observations': observations,
    };
  }

  factory CaseModel.fromJson(Map<String, dynamic> map) {
    // Reconstruir mapa de sustancias
    final Map<String, String> parsedSubstances = {};
    if (map['substanceEntries'] is Map) {
      (map['substanceEntries'] as Map).forEach((k, v) {
        parsedSubstances[k.toString()] = v.toString();
      });
    } else if (map['substances'] is List) {
      for (final s in (map['substances'] as List)) {
        parsedSubstances[s.toString()] = '';
      }
    }

    return CaseModel(
      id: map['id'] ?? '',
      eventId: map['eventId'] ?? '',
      eventName: map['eventName'] ?? '',
      registeredByUserId: map['registeredByUserId'] ?? '',
      registeredByUserName: map['registeredByUserName'] ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
      gender: map['gender'] ?? map['personGender'] ?? 'No especifica',
      ageRange: map['ageRange'] ?? map['personAge']?.toString() ?? '18 – 25',
      moment: map['moment'] ?? 'Main',
      duration: map['duration'] ?? 'hasta 30\'',
      arrivalMode: map['arrivalMode'] ?? 'Solx',
      accompaniedBy: map['accompaniedBy'],
      consumedSubstances: map['consumedSubstances'] ?? 'Si',
      substanceEntries: parsedSubstances,
      mdmaPillName: map['mdmaPillName'],
      otherSubstanceName: map['otherSubstanceName'],
      isFirstTimeConsuming: map['isFirstTimeConsuming'] ?? 'No',
      underlyingCondition: map['underlyingCondition'] ?? 'No',
      physicalSymptoms: List<String>.from(map['physicalSymptoms'] ?? []),
      otherPhysicalSymptoms: map['otherPhysicalSymptoms'],
      psychologicalSymptoms: List<String>.from(map['psychologicalSymptoms'] ?? []),
      healthTeamIntervened: map['healthTeamIntervened'] ?? false,
      isComplexCase: map['isComplexCase'] ?? false,
      resolution: map['resolution'] ?? map['interventionType'] ?? 'Recuperación íntegra',
      otherResolution: map['otherResolution'],
      attendingStaff: map['attendingStaff'] ?? map['registeredByUserName'] ?? '',
      relevantInfo: map['relevantInfo'] ?? map['observations'] ?? '',
      isSyncedToDrive: map['isSyncedToDrive'] ?? false,
      syncedAt: map['syncedAt'] != null
          ? DateTime.parse(map['syncedAt'])
          : null,
    );
  }

  /// Convierte la ficha en una fila para la planilla de cálculo CSV / Google Sheets
  List<dynamic> toSpreadsheetRow() {
    final substancesText = substanceEntries.entries
        .map((e) => e.value.isNotEmpty ? '${e.key} (${e.value})' : e.key)
        .join('; ');

    return [
      id,
      timestamp.toIso8601String(),
      eventName,
      gender,
      ageRange,
      moment,
      duration,
      arrivalMode + (accompaniedBy != null && accompaniedBy!.isNotEmpty ? ': $accompaniedBy' : ''),
      consumedSubstances,
      substancesText + (mdmaPillName != null && mdmaPillName!.isNotEmpty ? ' [Pastilla: $mdmaPillName]' : ''),
      isFirstTimeConsuming,
      underlyingCondition,
      physicalSymptoms.join('; ') + (otherPhysicalSymptoms != null && otherPhysicalSymptoms!.isNotEmpty ? '; $otherPhysicalSymptoms' : ''),
      psychologicalSymptoms.join('; '),
      healthTeamIntervened ? 'Si' : 'No',
      isComplexCase ? 'Si' : 'No',
      resolution + (otherResolution != null && otherResolution!.isNotEmpty ? ': $otherResolution' : ''),
      attendingStaff,
      relevantInfo,
      isSyncedToDrive ? 'Sincronizado' : 'Pendiente',
    ];
  }

  static List<String> get spreadsheetHeaders => [
        'ID Caso',
        'Fecha y Hora',
        'Evento',
        'Género',
        'Rango Edad',
        'Momento',
        'Duración',
        '¿Cómo llega?',
        '¿Consumió algo?',
        'Sustancias y Cantidad',
        '¿Primera vez?',
        'Enfermedad de Base',
        'Signos Físicos',
        'Signos Emocionales / Conductuales',
        'Intervino Salud',
        'Caso Complejo',
        'Resolución del Caso',
        'Vuelo que Atendió',
        'Info Relevante',
        'Estado de Sincronización',
      ];
}
