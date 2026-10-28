enum StampShape { circular, oval, rectangular, hexagonal }

enum StampInkColor { crimson, cobalt, emerald, amber, purple }

enum StampType { entry, exit, customsCleared }

class CollectibleStamp {
  final String id;
  final String tripId;
  final String cityName;
  final String countryCode;
  final String stationCode;
  final DateTime date;
  final StampShape shape;
  final StampInkColor inkColor;
  final double rotationRadians;
  final StampType type;

  const CollectibleStamp({
    required this.id,
    required this.tripId,
    required this.cityName,
    required this.countryCode,
    required this.stationCode,
    required this.date,
    required this.shape,
    required this.inkColor,
    required this.rotationRadians,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'tripId': tripId,
        'cityName': cityName,
        'countryCode': countryCode,
        'stationCode': stationCode,
        'date': date.toIso8601String(),
        'shape': shape.name,
        'inkColor': inkColor.name,
        'rotationRadians': rotationRadians,
        'type': type.name,
      };

  factory CollectibleStamp.fromJson(Map<String, dynamic> json) => CollectibleStamp(
        id: json['id'] as String,
        tripId: json['tripId'] as String? ?? '',
        cityName: json['cityName'] as String,
        countryCode: json['countryCode'] as String? ?? '',
        stationCode: json['stationCode'] as String? ?? 'ARR',
        date: DateTime.parse(json['date'] as String),
        shape: StampShape.values.firstWhere(
          (e) => e.name == json['shape'],
          orElse: () => StampShape.circular,
        ),
        inkColor: StampInkColor.values.firstWhere(
          (e) => e.name == json['inkColor'],
          orElse: () => StampInkColor.crimson,
        ),
        rotationRadians: (json['rotationRadians'] as num?)?.toDouble() ?? 0.0,
        type: StampType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => StampType.entry,
        ),
      );
}
