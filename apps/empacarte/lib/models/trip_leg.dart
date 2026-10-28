import 'trip.dart';

class TripLeg {
  final String id;
  final String destination;
  final String destinationCode;
  final DateTime startDate; // Check-in / Arrival date
  final DateTime endDate;   // Check-out / Departure date
  final DestinationClimate climate;
  final String? hotelName;
  final String? hotelAddress;
  final String? checkInTime;  // e.g. "15:00"
  final String? checkOutTime; // e.g. "11:00"
  final String? notes;

  const TripLeg({
    required this.id,
    required this.destination,
    required this.destinationCode,
    required this.startDate,
    required this.endDate,
    this.climate = DestinationClimate.temperate,
    this.hotelName,
    this.hotelAddress,
    this.checkInTime,
    this.checkOutTime,
    this.notes,
  });

  int get durationDays {
    final diff = endDate.difference(startDate).inDays;
    return diff <= 0 ? 1 : diff;
  }

  bool isCurrentlyActive(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  bool isCheckInDay(DateTime date) {
    return date.year == startDate.year &&
        date.month == startDate.month &&
        date.day == startDate.day;
  }

  bool isCheckOutDay(DateTime date) {
    return date.year == endDate.year &&
        date.month == endDate.month &&
        date.day == endDate.day;
  }

  TripLeg copyWith({
    String? destination,
    String? destinationCode,
    DateTime? startDate,
    DateTime? endDate,
    DestinationClimate? climate,
    String? hotelName,
    String? hotelAddress,
    String? checkInTime,
    String? checkOutTime,
    String? notes,
  }) {
    return TripLeg(
      id: id,
      destination: destination ?? this.destination,
      destinationCode: destinationCode ?? this.destinationCode,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      climate: climate ?? this.climate,
      hotelName: hotelName ?? this.hotelName,
      hotelAddress: hotelAddress ?? this.hotelAddress,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'destination': destination,
        'destinationCode': destinationCode,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'climate': climate.name,
        'hotelName': hotelName,
        'hotelAddress': hotelAddress,
        'checkInTime': checkInTime,
        'checkOutTime': checkOutTime,
        'notes': notes,
      };

  factory TripLeg.fromJson(Map<String, dynamic> json) => TripLeg(
        id: json['id'] as String,
        destination: json['destination'] as String,
        destinationCode: json['destinationCode'] as String? ?? 'DEST',
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: DateTime.parse(json['endDate'] as String),
        climate: DestinationClimate.values.firstWhere(
          (e) => e.name == json['climate'],
          orElse: () => DestinationClimate.temperate,
        ),
        hotelName: json['hotelName'] as String?,
        hotelAddress: json['hotelAddress'] as String?,
        checkInTime: json['checkInTime'] as String?,
        checkOutTime: json['checkOutTime'] as String?,
        notes: json['notes'] as String?,
      );
}
