class TurnoModel {
  final String id;
  final String area;
  final String service;
  final String date;
  final String time;
  final String locationName;
  final String address;
  final String status;

  const TurnoModel({
    required this.id,
    required this.area,
    required this.service,
    required this.date,
    required this.time,
    required this.locationName,
    required this.address,
    required this.status,
  });

  static List<TurnoModel> initialList = [
    const TurnoModel(
      id: 'tur-101',
      area: 'Tránsito y Transporte',
      service: 'Renovación Licencia de Conducir',
      date: 'Mañana, 09:30 hs',
      time: '09:30',
      locationName: 'Delegación Delta Centro',
      address: 'Av. Mitre 450, Delta Centro',
      status: 'CONFIRMADO',
    ),
    const TurnoModel(
      id: 'tur-102',
      area: 'Salud Pública',
      service: 'Clínica Médica - Control Anual',
      date: 'Jueves 15 Oct, 11:15 hs',
      time: '11:15',
      locationName: 'CAPS N° 4 "El Jacarandá"',
      address: 'Calle Los Sauces 880',
      status: 'CONFIRMADO',
    ),
  ];
}
