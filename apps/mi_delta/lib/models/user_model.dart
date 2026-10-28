class UserModel {
  final String id;
  final String name;
  final String email;
  final String dni;
  final String address;
  final String locality;
  final String memberNumber;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.dni,
    required this.address,
    required this.locality,
    required this.memberNumber,
  });

  static const UserModel demoUser = UserModel(
    id: 'usr_demo_01',
    name: 'Leonardo Benveniste',
    email: 'leo.benveniste@gmail.com',
    dni: '29.583.026',
    address: 'Av. Las Palmeras 1240',
    locality: 'Rincón Náutico',
    memberNumber: 'SD-84920',
  );
}
