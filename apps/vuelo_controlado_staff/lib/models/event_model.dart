import 'event_unified_report.dart';
import 'event_pair.dart';
import 'event_round_log.dart';

class EventModel {
  final String id;
  final String name;
  final DateTime date;
  final String startTime;
  final String doorsOpenTime;
  final String endTime;
  final String location;
  final String? address;
  final String? imageUrl;
  final int requiredStaffCount;
  final List<String> staffIds;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final bool isManuallyStarted;
  final bool isManuallyClosed;
  final EventUnifiedReport? unifiedReport;
  final List<EventPair> pairs;
  final List<EventRoundLog> roundLogs;

  EventModel({
    required this.id,
    required this.name,
    required this.date,
    required this.startTime,
    required this.doorsOpenTime,
    required this.endTime,
    required this.location,
    this.address,
    this.imageUrl,
    this.requiredStaffCount = 4,
    required this.staffIds,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    this.isManuallyStarted = false,
    this.isManuallyClosed = false,
    this.unifiedReport,
    this.pairs = const [],
    this.roundLogs = const [],
  });

  bool isUserInStaff(String userId) {
    return staffIds.contains(userId);
  }

  /// Retorna la pareja asignada para un usuario si existe
  EventPair? getPairForUser(String userId) {
    try {
      return pairs.firstWhere((p) => p.containsUser(userId));
    } catch (_) {
      return null;
    }
  }

  int get currentStaffCount => staffIds.length;

  bool get isQuotaFull =>
      requiredStaffCount > 0 && currentStaffCount >= requiredStaffCount;

  double get quotaProgress => requiredStaffCount > 0
      ? (currentStaffCount / requiredStaffCount).clamp(0.0, 1.0)
      : 1.0;

  String get quotaText => requiredStaffCount > 0
      ? '$currentStaffCount / $requiredStaffCount staff'
      : '$currentStaffCount staff';

  /// Fecha y hora de inicio calculada
  DateTime get startDateTime {
    final timeStr = doorsOpenTime.isNotEmpty
        ? doorsOpenTime
        : (startTime.isNotEmpty ? startTime : '22:00');
    final parts = timeStr.split(':');
    final hour = int.tryParse(parts[0]) ?? 22;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  /// Fecha y hora de cierre calculada (soporta eventos nocturnos que cruzan la medianoche)
  DateTime get endDateTime {
    final timeStr = endTime.isNotEmpty ? endTime : '06:00';
    final parts = timeStr.split(':');
    final endHour = int.tryParse(parts[0]) ?? 6;
    final endMinute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

    final start = startDateTime;
    var end = DateTime(date.year, date.month, date.day, endHour, endMinute);
    if (!end.isAfter(start)) {
      end = end.add(const Duration(days: 1));
    }
    return end;
  }

  /// Evento en curso (entre horario de puertas/inicio y horario de cierre)
  bool get isOngoing {
    final now = DateTime.now();
    return (now.isAfter(startDateTime) || now.isAtSameMomentAs(startDateTime)) &&
        now.isBefore(endDateTime);
  }

  /// Evento finalizado (posterior a la hora de cierre)
  bool get isPast {
    final now = DateTime.now();
    return now.isAfter(endDateTime) || now.isAtSameMomentAs(endDateTime);
  }

  /// Evento próximo (previo al inicio)
  bool get isUpcoming => DateTime.now().isBefore(startDateTime);

  bool get hasStarted => isOngoing || isPast;

  String get statusText {
    if (isPast) return 'Finalizado';
    if (isOngoing) return 'En Curso';
    return 'Próximo';
  }

  EventModel copyWith({
    String? name,
    DateTime? date,
    String? startTime,
    String? doorsOpenTime,
    String? endTime,
    String? location,
    String? address,
    String? imageUrl,
    int? requiredStaffCount,
    List<String>? staffIds,
    bool? isManuallyStarted,
    bool? isManuallyClosed,
    EventUnifiedReport? unifiedReport,
    List<EventPair>? pairs,
    List<EventRoundLog>? roundLogs,
  }) {
    return EventModel(
      id: id,
      name: name ?? this.name,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      doorsOpenTime: doorsOpenTime ?? this.doorsOpenTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      address: address ?? this.address,
      imageUrl: imageUrl ?? this.imageUrl,
      requiredStaffCount: requiredStaffCount ?? this.requiredStaffCount,
      staffIds: staffIds ?? this.staffIds,
      createdBy: createdBy,
      createdByName: createdByName,
      createdAt: createdAt,
      isManuallyStarted: isManuallyStarted ?? this.isManuallyStarted,
      isManuallyClosed: isManuallyClosed ?? this.isManuallyClosed,
      unifiedReport: unifiedReport ?? this.unifiedReport,
      pairs: pairs ?? this.pairs,
      roundLogs: roundLogs ?? this.roundLogs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'date': date.toIso8601String(),
      'startTime': startTime,
      'doorsOpenTime': doorsOpenTime,
      'endTime': endTime,
      'location': location,
      'address': address,
      'imageUrl': imageUrl,
      'requiredStaffCount': requiredStaffCount,
      'staffIds': staffIds,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': createdAt.toIso8601String(),
      'isManuallyStarted': isManuallyStarted,
      'isManuallyClosed': isManuallyClosed,
      if (unifiedReport != null) 'unifiedReport': unifiedReport!.toJson(),
      'pairs': pairs.map((p) => p.toJson()).toList(),
      'roundLogs': roundLogs.map((r) => r.toJson()).toList(),
    };
  }

  factory EventModel.fromJson(Map<String, dynamic> map) {
    final rawPairs = map['pairs'];
    List<EventPair> parsedPairs = [];
    if (rawPairs is List) {
      parsedPairs = rawPairs
          .whereType<Map>()
          .map((item) => EventPair.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    final rawRounds = map['roundLogs'];
    List<EventRoundLog> parsedRounds = [];
    if (rawRounds is List) {
      parsedRounds = rawRounds
          .whereType<Map>()
          .map((item) =>
              EventRoundLog.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    return EventModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      date: map['date'] != null
          ? DateTime.parse(map['date'])
          : DateTime.now(),
      startTime: map['startTime'] ?? '22:00',
      doorsOpenTime: map['doorsOpenTime'] ?? '21:00',
      endTime: map['endTime'] ?? '06:00',
      location: map['location'] ?? 'Ubicación no especificada',
      address: map['address'],
      imageUrl: map['imageUrl'],
      requiredStaffCount: map['requiredStaffCount'] ?? 4,
      staffIds: List<String>.from(map['staffIds'] ?? []),
      createdBy: map['createdBy'] ?? '',
      createdByName: map['createdByName'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      isManuallyStarted: map['isManuallyStarted'] ?? false,
      isManuallyClosed: map['isManuallyClosed'] ?? false,
      unifiedReport: map['unifiedReport'] != null && map['unifiedReport'] is Map
          ? EventUnifiedReport.fromJson(
              Map<String, dynamic>.from(map['unifiedReport']))
          : null,
      pairs: parsedPairs,
      roundLogs: parsedRounds,
    );
  }
}
