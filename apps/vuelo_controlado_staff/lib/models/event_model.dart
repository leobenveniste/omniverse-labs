class EventModel {
  final String id;
  final String name;
  final DateTime date;
  final String startTime;
  final String doorsOpenTime;
  final String endTime;
  final String? location;
  final List<String> staffIds;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final bool isManuallyStarted;
  final bool isManuallyClosed;

  EventModel({
    required this.id,
    required this.name,
    required this.date,
    required this.startTime,
    required this.doorsOpenTime,
    required this.endTime,
    this.location,
    required this.staffIds,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    this.isManuallyStarted = false,
    this.isManuallyClosed = false,
  });

  bool isUserInStaff(String userId) {
    return staffIds.contains(userId);
  }

  /// Verifica si el evento ya está comenzado.
  /// Se considera comenzado si:
  /// 1. Fue iniciado manualmente por Organización/Producción, O
  /// 2. La fecha y hora actual es igual o posterior a la hora de apertura de puertas / inicio programado.
  bool get hasStarted {
    if (isManuallyClosed) return false;
    if (isManuallyStarted) return true;

    final now = DateTime.now();
    // Comparar fecha
    final eventDay = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);

    if (now.isAfter(eventDay)) {
      // Parse doorsOpenTime o startTime si es el mismo día
      if (today.isAtSameMomentAs(eventDay)) {
        try {
          final parts = (doorsOpenTime.isNotEmpty ? doorsOpenTime : startTime)
              .split(':');
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          final startDateTime =
              DateTime(date.year, date.month, date.day, hour, minute);
          return now.isAfter(startDateTime) ||
              now.isAtSameMomentAs(startDateTime);
        } catch (_) {
          return true;
        }
      } else {
        return true;
      }
    }
    return false;
  }

  String get statusText {
    if (isManuallyClosed) return 'Finalizado';
    if (hasStarted) return 'En Curso';
    return 'Próximo';
  }

  EventModel copyWith({
    String? name,
    DateTime? date,
    String? startTime,
    String? doorsOpenTime,
    String? endTime,
    String? location,
    List<String>? staffIds,
    bool? isManuallyStarted,
    bool? isManuallyClosed,
  }) {
    return EventModel(
      id: id,
      name: name ?? this.name,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      doorsOpenTime: doorsOpenTime ?? this.doorsOpenTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      staffIds: staffIds ?? this.staffIds,
      createdBy: createdBy,
      createdByName: createdByName,
      createdAt: createdAt,
      isManuallyStarted: isManuallyStarted ?? this.isManuallyStarted,
      isManuallyClosed: isManuallyClosed ?? this.isManuallyClosed,
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
      'staffIds': staffIds,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': createdAt.toIso8601String(),
      'isManuallyStarted': isManuallyStarted,
      'isManuallyClosed': isManuallyClosed,
    };
  }

  factory EventModel.fromJson(Map<String, dynamic> map) {
    return EventModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      date: map['date'] != null
          ? DateTime.parse(map['date'])
          : DateTime.now(),
      startTime: map['startTime'] ?? '22:00',
      doorsOpenTime: map['doorsOpenTime'] ?? '21:00',
      endTime: map['endTime'] ?? '06:00',
      location: map['location'],
      staffIds: List<String>.from(map['staffIds'] ?? []),
      createdBy: map['createdBy'] ?? '',
      createdByName: map['createdByName'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      isManuallyStarted: map['isManuallyStarted'] ?? false,
      isManuallyClosed: map['isManuallyClosed'] ?? false,
    );
  }
}
