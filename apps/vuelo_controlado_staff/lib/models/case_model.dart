class CaseModel {
  final String id;
  final String eventId;
  final String eventName;
  final String registeredByUserId;
  final String registeredByUserName;
  final DateTime timestamp;
  final String personName;
  final String personAge;
  final String personGender;
  final String interventionType;
  final List<String> substances;
  final String symptoms;
  final String actionsTaken;
  final String observations;
  final bool isSyncedToDrive;
  final DateTime? syncedAt;

  CaseModel({
    required this.id,
    required this.eventId,
    required this.eventName,
    required this.registeredByUserId,
    required this.registeredByUserName,
    required this.timestamp,
    required this.personName,
    required this.personAge,
    required this.personGender,
    required this.interventionType,
    required this.substances,
    required this.symptoms,
    required this.actionsTaken,
    required this.observations,
    this.isSyncedToDrive = false,
    this.syncedAt,
  });

  CaseModel copyWith({
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
      personName: personName,
      personAge: personAge,
      personGender: personGender,
      interventionType: interventionType,
      substances: substances,
      symptoms: symptoms,
      actionsTaken: actionsTaken,
      observations: observations,
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
      'personName': personName,
      'personAge': personAge,
      'personGender': personGender,
      'interventionType': interventionType,
      'substances': substances,
      'symptoms': symptoms,
      'actionsTaken': actionsTaken,
      'observations': observations,
      'isSyncedToDrive': isSyncedToDrive,
      'syncedAt': syncedAt?.toIso8601String(),
    };
  }

  factory CaseModel.fromJson(Map<String, dynamic> map) {
    return CaseModel(
      id: map['id'] ?? '',
      eventId: map['eventId'] ?? '',
      eventName: map['eventName'] ?? '',
      registeredByUserId: map['registeredByUserId'] ?? '',
      registeredByUserName: map['registeredByUserName'] ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
      personName: map['personName'] ?? '',
      personAge: map['personAge']?.toString() ?? '',
      personGender: map['personGender'] ?? 'No especifica',
      interventionType: map['interventionType'] ?? '',
      substances: List<String>.from(map['substances'] ?? []),
      symptoms: map['symptoms'] ?? '',
      actionsTaken: map['actionsTaken'] ?? '',
      observations: map['observations'] ?? '',
      isSyncedToDrive: map['isSyncedToDrive'] ?? false,
      syncedAt: map['syncedAt'] != null
          ? DateTime.parse(map['syncedAt'])
          : null,
    );
  }

  /// Convierte la ficha en una fila para la planilla de cálculo CSV / Google Sheets
  List<dynamic> toSpreadsheetRow() {
    return [
      id,
      timestamp.toIso8601String(),
      eventName,
      personName,
      personAge,
      personGender,
      interventionType,
      substances.join('; '),
      symptoms,
      actionsTaken,
      observations,
      registeredByUserName,
      isSyncedToDrive ? 'Sincronizado' : 'Pendiente',
    ];
  }

  static List<String> get spreadsheetHeaders => [
        'ID Caso',
        'Fecha y Hora',
        'Evento',
        'Persona (Nombre/Apodo)',
        'Edad',
        'Género',
        'Tipo de Intervención',
        'Sustancias Involucradas',
        'Síntomas / Estado',
        'Acciones Realizadas',
        'Observaciones / Derivación',
        'Staff Responsable',
        'Estado de Sincronización',
      ];
}
