class BeneficioModel {
  final String id;
  final String name;
  final String category;
  final String discountText;
  final String address;
  final String locality;
  final String validDays;

  const BeneficioModel({
    required this.id,
    required this.name,
    required this.category,
    required this.discountText,
    required this.address,
    required this.locality,
    required this.validDays,
  });

  static List<BeneficioModel> initialList = [
    const BeneficioModel(
      id: 'ben-01',
      name: 'Restó & Parrilla "El Muelle"',
      category: 'GASTRONOMIA',
      discountText: '20% de descuento',
      address: 'Paseo Náutico 110',
      locality: 'Delta Centro',
      validDays: 'Martes a Domingos',
    ),
    const BeneficioModel(
      id: 'ben-02',
      name: 'Farmacia Delta Central',
      category: 'FARMACIAS',
      discountText: '15% en perfumería y genéricos',
      address: 'Av. San Martín 740',
      locality: 'Delta Centro',
      validDays: 'Todos los días',
    ),
    const BeneficioModel(
      id: 'ben-03',
      name: 'Café & Bakery "Isla Bonita"',
      category: 'GASTRONOMIA',
      discountText: '2x1 en desayunos y meriendas',
      address: 'Camino de los Remeros 300',
      locality: 'Rincón Náutico',
      validDays: 'Lunes a Viernes',
    ),
    const BeneficioModel(
      id: 'ben-04',
      name: 'Náutica & Outdoor "Paraná"',
      category: 'TURISMO',
      discountText: '25% en alquiler de kayaks',
      address: 'Dique Luján Km 4',
      locality: 'Dique Luján',
      validDays: 'Fines de semana',
    ),
    const BeneficioModel(
      id: 'ben-05',
      name: 'Librería & Papelería "Delta Libros"',
      category: 'SERVICIOS',
      discountText: '10% de descuento en textos',
      address: 'Calle Mitre 620',
      locality: 'Delta Centro',
      validDays: 'Lunes a Sábados',
    ),
  ];
}
