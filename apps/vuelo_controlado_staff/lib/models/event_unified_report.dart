class EventUnifiedReport {
  final String durationTotal;
  final String producer;
  final bool vueloPresent;
  final String eventType;
  final String? otherEventType;
  final String timeSlot;
  final String? otherTimeSlot;
  final String spaceType;
  final String dayNumber;
  final String? otherDayNumber;
  final bool hasFreeWater;
  final String perceivedDensity;
  final List<String> weatherTypes;
  final int medicalAttendedCount;
  final int medicalTransferredCount;
  final int vcAttendedCount;
  final Map<String, int> medicalComposition;
  final String? medicalOther1Name;
  final int? medicalOther1Count;
  final String? medicalOther2Name;
  final int? medicalOther2Count;
  final String vueloVolunteersCount;
  final String vueloFruitQuantity;
  final String otherRelevantInfo;
  final String completedByUserId;
  final String completedByUserName;
  final DateTime completedAt;

  const EventUnifiedReport({
    required this.durationTotal,
    required this.producer,
    this.vueloPresent = true,
    required this.eventType,
    this.otherEventType,
    required this.timeSlot,
    this.otherTimeSlot,
    required this.spaceType,
    required this.dayNumber,
    this.otherDayNumber,
    this.hasFreeWater = true,
    required this.perceivedDensity,
    required this.weatherTypes,
    this.medicalAttendedCount = 0,
    this.medicalTransferredCount = 0,
    this.vcAttendedCount = 0,
    required this.medicalComposition,
    this.medicalOther1Name,
    this.medicalOther1Count,
    this.medicalOther2Name,
    this.medicalOther2Count,
    this.vueloVolunteersCount = '',
    this.vueloFruitQuantity = '',
    this.otherRelevantInfo = '',
    required this.completedByUserId,
    required this.completedByUserName,
    required this.completedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'durationTotal': durationTotal,
      'producer': producer,
      'vueloPresent': vueloPresent,
      'eventType': eventType,
      'otherEventType': otherEventType,
      'timeSlot': timeSlot,
      'otherTimeSlot': otherTimeSlot,
      'spaceType': spaceType,
      'dayNumber': dayNumber,
      'otherDayNumber': otherDayNumber,
      'hasFreeWater': hasFreeWater,
      'perceivedDensity': perceivedDensity,
      'weatherTypes': weatherTypes,
      'medicalAttendedCount': medicalAttendedCount,
      'medicalTransferredCount': medicalTransferredCount,
      'vcAttendedCount': vcAttendedCount,
      'medicalComposition': medicalComposition,
      'medicalOther1Name': medicalOther1Name,
      'medicalOther1Count': medicalOther1Count,
      'medicalOther2Name': medicalOther2Name,
      'medicalOther2Count': medicalOther2Count,
      'vueloVolunteersCount': vueloVolunteersCount,
      'vueloFruitQuantity': vueloFruitQuantity,
      'otherRelevantInfo': otherRelevantInfo,
      'completedByUserId': completedByUserId,
      'completedByUserName': completedByUserName,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  factory EventUnifiedReport.fromJson(Map<String, dynamic> map) {
    final rawComp = map['medicalComposition'];
    final Map<String, int> comp = {};
    if (rawComp is Map) {
      rawComp.forEach((k, v) {
        comp[k.toString()] = int.tryParse(v.toString()) ?? 0;
      });
    }

    return EventUnifiedReport(
      durationTotal: map['durationTotal']?.toString() ?? '',
      producer: map['producer']?.toString() ?? '',
      vueloPresent: map['vueloPresent'] ?? true,
      eventType: map['eventType']?.toString() ?? 'Festival',
      otherEventType: map['otherEventType']?.toString(),
      timeSlot: map['timeSlot']?.toString() ?? 'Nocturno',
      otherTimeSlot: map['otherTimeSlot']?.toString(),
      spaceType: map['spaceType']?.toString() ?? 'Outdoor',
      dayNumber: map['dayNumber']?.toString() ?? 'Única',
      otherDayNumber: map['otherDayNumber']?.toString(),
      hasFreeWater: map['hasFreeWater'] ?? true,
      perceivedDensity: map['perceivedDensity']?.toString() ?? 'Media',
      weatherTypes: List<String>.from(map['weatherTypes'] ?? []),
      medicalAttendedCount: int.tryParse(map['medicalAttendedCount']?.toString() ?? '0') ?? 0,
      medicalTransferredCount: int.tryParse(map['medicalTransferredCount']?.toString() ?? '0') ?? 0,
      vcAttendedCount: int.tryParse(map['vcAttendedCount']?.toString() ?? '0') ?? 0,
      medicalComposition: comp,
      medicalOther1Name: map['medicalOther1Name']?.toString(),
      medicalOther1Count: int.tryParse(map['medicalOther1Count']?.toString() ?? ''),
      medicalOther2Name: map['medicalOther2Name']?.toString(),
      medicalOther2Count: int.tryParse(map['medicalOther2Count']?.toString() ?? ''),
      vueloVolunteersCount: map['vueloVolunteersCount']?.toString() ?? '',
      vueloFruitQuantity: map['vueloFruitQuantity']?.toString() ?? '',
      otherRelevantInfo: map['otherRelevantInfo']?.toString() ?? '',
      completedByUserId: map['completedByUserId']?.toString() ?? '',
      completedByUserName: map['completedByUserName']?.toString() ?? '',
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'])
          : DateTime.now(),
    );
  }
}
