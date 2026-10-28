import 'trip_leg.dart';

enum TravelMode { flight, train, car, ship, backpack }

enum TripPurpose { vacation, city, business, hiking }

enum DestinationClimate { warm, temperate, cold, rainy }

class Trip {
  final String id;
  final String destination;
  final String originCode;
  final String destinationCode;
  final DateTime startDate;
  final DateTime endDate;
  final TravelMode travelMode;
  final TripPurpose purpose;
  final DestinationClimate climate;
  final double personalItemLimitKg;
  final double carryOnLimitKg;
  final double checkedLimitKg;
  final String? airlinePreset;
  final String? hotelAddress;
  final String? insurancePolicy;
  final String? insuranceEmergencyPhone;
  final List<TripLeg> legs;

  const Trip({
    required this.id,
    required this.destination,
    this.originCode = 'ORIG',
    required this.destinationCode,
    required this.startDate,
    required this.endDate,
    this.travelMode = TravelMode.flight,
    this.purpose = TripPurpose.vacation,
    this.climate = DestinationClimate.temperate,
    this.personalItemLimitKg = 5.0,
    this.carryOnLimitKg = 10.0,
    this.checkedLimitKg = 23.0,
    this.airlinePreset,
    this.hotelAddress,
    this.insurancePolicy,
    this.insuranceEmergencyPhone,
    this.legs = const [],
  });

  bool get isMultiDestination => legs.length > 1;

  String get routeDisplay {
    if (legs.isEmpty) return destination;
    return legs.map((l) => l.destination.split(',').first.trim()).join(' ➔ ');
  }

  String get routeCodesDisplay {
    if (legs.isEmpty) return '$originCode ➔ $destinationCode';
    final codes = [originCode, ...legs.map((l) => l.destinationCode)];
    return codes.join(' ➔ ');
  }

  TripLeg? activeLeg(DateTime at) {
    if (legs.isEmpty) return null;
    for (final leg in legs) {
      if (leg.isCurrentlyActive(at)) return leg;
    }
    // Return first upcoming or last
    final upcoming = legs.where((l) => l.startDate.isAfter(at)).toList();
    if (upcoming.isNotEmpty) return upcoming.first;
    return legs.last;
  }

  Set<DestinationClimate> get allClimates {
    if (legs.isEmpty) return {climate};
    return legs.map((l) => l.climate).toSet();
  }

  int get durationDays {
    final diff = endDate.difference(startDate).inDays;
    return diff <= 0 ? 1 : diff;
  }

  int get daysUntilDeparture {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tripDay = DateTime(startDate.year, startDate.month, startDate.day);
    return tripDay.difference(today).inDays;
  }

  bool get isDepartsToday {
    return daysUntilDeparture == 0;
  }

  bool get isPast {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tripEndDay = DateTime(endDate.year, endDate.month, endDate.day);
    return tripEndDay.isBefore(today);
  }

  Trip copyWith({
    String? destination,
    String? originCode,
    String? destinationCode,
    DateTime? startDate,
    DateTime? endDate,
    TravelMode? travelMode,
    TripPurpose? purpose,
    DestinationClimate? climate,
    double? personalItemLimitKg,
    double? carryOnLimitKg,
    double? checkedLimitKg,
    String? airlinePreset,
    String? hotelAddress,
    String? insurancePolicy,
    String? insuranceEmergencyPhone,
    List<TripLeg>? legs,
  }) {
    return Trip(
      id: id,
      destination: destination ?? this.destination,
      originCode: originCode ?? this.originCode,
      destinationCode: destinationCode ?? this.destinationCode,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      travelMode: travelMode ?? this.travelMode,
      purpose: purpose ?? this.purpose,
      climate: climate ?? this.climate,
      personalItemLimitKg: personalItemLimitKg ?? this.personalItemLimitKg,
      carryOnLimitKg: carryOnLimitKg ?? this.carryOnLimitKg,
      checkedLimitKg: checkedLimitKg ?? this.checkedLimitKg,
      airlinePreset: airlinePreset ?? this.airlinePreset,
      hotelAddress: hotelAddress ?? this.hotelAddress,
      insurancePolicy: insurancePolicy ?? this.insurancePolicy,
      insuranceEmergencyPhone: insuranceEmergencyPhone ?? this.insuranceEmergencyPhone,
      legs: legs ?? this.legs,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'destination': destination,
        'originCode': originCode,
        'destinationCode': destinationCode,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'travelMode': travelMode.name,
        'purpose': purpose.name,
        'climate': climate.name,
        'personalItemLimitKg': personalItemLimitKg,
        'carryOnLimitKg': carryOnLimitKg,
        'checkedLimitKg': checkedLimitKg,
        'airlinePreset': airlinePreset,
        'hotelAddress': hotelAddress,
        'insurancePolicy': insurancePolicy,
        'insuranceEmergencyPhone': insuranceEmergencyPhone,
        'legs': legs.map((l) => l.toJson()).toList(),
      };

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
        id: json['id'] as String,
        destination: json['destination'] as String,
        originCode: json['originCode'] as String? ?? 'ORIG',
        destinationCode: json['destinationCode'] as String? ?? 'DEST',
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: DateTime.parse(json['endDate'] as String),
        travelMode: TravelMode.values.firstWhere(
          (e) => e.name == json['travelMode'],
          orElse: () => TravelMode.flight,
        ),
        purpose: TripPurpose.values.firstWhere(
          (e) => e.name == json['purpose'],
          orElse: () => TripPurpose.vacation,
        ),
        climate: DestinationClimate.values.firstWhere(
          (e) => e.name == json['climate'],
          orElse: () => DestinationClimate.temperate,
        ),
        personalItemLimitKg: (json['personalItemLimitKg'] as num?)?.toDouble() ?? 5.0,
        carryOnLimitKg: (json['carryOnLimitKg'] as num?)?.toDouble() ?? 10.0,
        checkedLimitKg: (json['checkedLimitKg'] as num?)?.toDouble() ?? 23.0,
        airlinePreset: json['airlinePreset'] as String?,
        hotelAddress: json['hotelAddress'] as String?,
        insurancePolicy: json['insurancePolicy'] as String?,
        insuranceEmergencyPhone: json['insuranceEmergencyPhone'] as String?,
        legs: (json['legs'] as List?)?.map((e) => TripLeg.fromJson(e)).toList() ?? [],
      );
}
