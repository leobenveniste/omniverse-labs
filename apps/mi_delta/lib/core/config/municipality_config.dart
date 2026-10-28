class EmergencyLine {
  final String id;
  final String title;
  final String subtitle;
  final String phone;
  final String type;

  const EmergencyLine({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.phone,
    required this.type,
  });
}

class MunicipalityConfig {
  static const String name = 'Municipalidad de Altos del Delta';
  static const String shortName = 'Altos del Delta';
  static const String appName = 'Mi Delta';
  static const String slogan = 'Tu municipio en tus manos';
  static const String benefitCardName = 'Soy Delta';
  static const String emergencyCenterName = 'COD';
  static const String emergencyCenterFullName = 'Centro de Operaciones Delta';

  static const List<EmergencyLine> emergencyLines = [
    EmergencyLine(
      id: 'same',
      title: 'SAME Delta (107)',
      subtitle: 'Emergencias médicas y ambulancias',
      phone: '107',
      type: 'medical',
    ),
    EmergencyLine(
      id: 'cod',
      title: 'COD Seguridad (0800-DELTA)',
      subtitle: 'Centro de Operaciones y Móviles',
      phone: '0800-333-3358',
      type: 'security',
    ),
    EmergencyLine(
      id: 'bomberos',
      title: 'Bomberos Voluntarios (100)',
      subtitle: 'Incendios y rescate náutico fluvial',
      phone: '100',
      type: 'fire',
    ),
    EmergencyLine(
      id: 'genero',
      title: 'Línea DAMA - Asistencia Género',
      subtitle: 'Guardia 24hs contención y socorro',
      phone: '144',
      type: 'gender',
    ),
  ];

  static const List<String> localities = [
    'Delta Centro',
    'Islas del Paraná',
    'Rincón Náutico',
    'Dique Luján',
    'Los Aromos',
    'Parque Isleño',
  ];

  static const List<String> categories = [
    'Luminarias y Alumbrado',
    'Bacheo y Pavimento',
    'Poda y Arbolado',
    'Residuos y Microbasurales',
    'Pluviales y Zanjas',
    'Semáforos y Tránsito',
    'Animales y Zoonosis',
  ];
}
