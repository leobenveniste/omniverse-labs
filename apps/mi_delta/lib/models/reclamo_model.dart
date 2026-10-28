enum ReclamoStatus {
  recibido,
  enRevision,
  enCuadrilla,
  resuelto,
}

class ReclamoModel {
  final String id;
  final String code;
  final String title;
  final String category;
  final String address;
  final String locality;
  final String description;
  final ReclamoStatus status;
  final String statusLabel;
  final String date;
  final String updatedAt;

  const ReclamoModel({
    required this.id,
    required this.code,
    required this.title,
    required this.category,
    required this.address,
    required this.locality,
    required this.description,
    required this.status,
    required this.statusLabel,
    required this.date,
    required this.updatedAt,
  });

  int get stepNumber {
    switch (status) {
      case ReclamoStatus.recibido:
        return 1;
      case ReclamoStatus.enRevision:
        return 2;
      case ReclamoStatus.enCuadrilla:
        return 3;
      case ReclamoStatus.resuelto:
        return 4;
    }
  }

  static List<ReclamoModel> initialList = [
    const ReclamoModel(
      id: 'rec-01',
      code: 'REC-8491',
      title: 'Luminaria LED intermitente / apagada',
      category: 'Luminarias y Alumbrado',
      address: 'Av. del Puerto 580',
      locality: 'Rincón Náutico',
      description: 'La columna de alumbrado no enciende desde el fin de semana. Zona oscura frente a la parada de colectivo.',
      status: ReclamoStatus.enCuadrilla,
      statusLabel: 'Cuadrilla Asignada',
      date: '28 Sep 2026',
      updatedAt: 'Hace 3 horas',
    ),
    const ReclamoModel(
      id: 'rec-02',
      code: 'REC-8230',
      title: 'Bache profundo en calzada',
      category: 'Bacheo y Pavimento',
      address: 'Calle Los Ceibos esq. Rivadavia',
      locality: 'Delta Centro',
      description: 'Rotura de asfalto luego de la última lluvia. Peligro para motos y ciclistas.',
      status: ReclamoStatus.enRevision,
      statusLabel: 'En Inspección Técnica',
      date: '25 Sep 2026',
      updatedAt: 'Ayer',
    ),
    const ReclamoModel(
      id: 'rec-03',
      code: 'REC-7910',
      title: 'Despeje de ramas caídas por viento',
      category: 'Poda y Arbolado',
      address: 'Paseo de la Ribera Isleña 230',
      locality: 'Islas del Paraná',
      description: 'Rama grande obstaculizaba la pasarela peatonal.',
      status: ReclamoStatus.resuelto,
      statusLabel: 'Resuelto por Cuadrilla',
      date: '18 Sep 2026',
      updatedAt: '20 Sep 2026',
    ),
  ];
}
