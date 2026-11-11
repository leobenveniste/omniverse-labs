import 'event_model.dart';

class AppRegions {
  static const String buenosAires = 'Buenos Aires';
  static const String patagonia = 'Patagonia';
  static const String noa = 'NOA';
  static const String rosario = 'Rosario';
  static const String cordoba = 'Córdoba';
  static const String mendoza = 'Mendoza';

  static const String allRegions = 'Todas las regiones';

  static const List<String> all = [
    buenosAires,
    patagonia,
    noa,
    rosario,
    cordoba,
    mendoza,
  ];
}

class AppRoles {
  static const String superAdminEmail = 'leobenveniste@vuelocontrolado.org';

  static const String miembro = 'Miembro';
  static const String organizacion = 'Organización';
  static const String comunicacion = 'Comunicación';
  static const String investigacion = 'Investigación';
  static const String recursosHumanos = 'Recursos Humanos';
  static const String rrhh = 'RRHH'; // Alias de compatibilidad
  static const String comercial = 'Comercial';
  static const String produccion = 'Producción';

  static const List<String> allRoles = [
    miembro,
    organizacion,
    comunicacion,
    investigacion,
    recursosHumanos,
    comercial,
    produccion,
  ];

  static const List<String> assignableRoles = [
    organizacion,
    comunicacion,
    investigacion,
    recursosHumanos,
    comercial,
    produccion,
  ];
}

class UserModel {
  final String id;
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String documentType;
  final String documentNumber;
  final DateTime birthDate;
  final String phone;
  final String? instagram;
  final String? photoUrl;
  final List<String> roles;
  final String region;
  final int? manualAttendanceCount;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.documentType,
    required this.documentNumber,
    required this.birthDate,
    required this.phone,
    this.instagram,
    this.photoUrl,
    required this.roles,
    this.region = AppRegions.buenosAires,
    this.manualAttendanceCount,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName'.trim();

  /// Cantidad de asistencias confirmadas y cumplidas en eventos registrados dentro de la app
  int getAutomaticAttendanceCount(List<EventModel> allEvents) {
    return allEvents.where((e) => e.isUserAttended(id)).length;
  }

  /// Total combinado de asistencias: suma de eventos automáticos más asistencias manuales acreditadas
  int getAttendanceCount(List<EventModel> allEvents) {
    final autoCount = getAutomaticAttendanceCount(allEvents);
    final manual = manualAttendanceCount ?? 0;
    return autoCount + manual;
  }

  bool get isDemoUser =>
      id == 'demo_user_google_play' ||
      email.trim().toLowerCase() == 'demo@vuelocontrolado.org';

  bool get isSuperAdmin =>
      email.trim().toLowerCase() == AppRoles.superAdminEmail.toLowerCase() ||
      isDemoUser;

  bool hasRole(String role) {
    if (isSuperAdmin) return true;
    if (role == AppRoles.recursosHumanos || role == AppRoles.rrhh) {
      return roles.contains(AppRoles.recursosHumanos) ||
          roles.contains(AppRoles.rrhh);
    }
    return roles.contains(role);
  }

  bool get canCreateEvents =>
      isSuperAdmin ||
      roles.contains(AppRoles.organizacion) ||
      roles.contains(AppRoles.produccion);

  bool get canManageUsers => isSuperAdmin;

  bool get canCreateUsers =>
      isSuperAdmin ||
      roles.contains(AppRoles.recursosHumanos) ||
      roles.contains(AppRoles.rrhh);

  bool get canViewCommercial =>
      isSuperAdmin || roles.contains(AppRoles.comercial);

  UserModel copyWith({
    String? email,
    String? password,
    String? firstName,
    String? lastName,
    String? documentType,
    String? documentNumber,
    DateTime? birthDate,
    String? phone,
    String? instagram,
    String? photoUrl,
    bool clearPhoto = false,
    List<String>? roles,
    String? region,
    int? manualAttendanceCount,
    bool clearManualAttendance = false,
  }) {
    final updatedRoles = roles != null
        ? (roles.contains(AppRoles.miembro)
            ? roles
            : [AppRoles.miembro, ...roles])
        : this.roles;

    return UserModel(
      id: id,
      email: email ?? this.email,
      password: password ?? this.password,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      documentType: documentType ?? this.documentType,
      documentNumber: documentNumber ?? this.documentNumber,
      birthDate: birthDate ?? this.birthDate,
      phone: phone ?? this.phone,
      instagram: instagram ?? this.instagram,
      photoUrl: clearPhoto ? null : (photoUrl ?? this.photoUrl),
      roles: updatedRoles,
      region: region ?? this.region,
      manualAttendanceCount: clearManualAttendance
          ? null
          : (manualAttendanceCount ?? this.manualAttendanceCount),
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
      'documentType': documentType,
      'documentNumber': documentNumber,
      'birthDate': birthDate.toIso8601String(),
      'phone': phone,
      'instagram': instagram,
      'photoUrl': photoUrl,
      'roles': roles.contains(AppRoles.miembro)
          ? roles
          : [AppRoles.miembro, ...roles],
      'region': region,
      'manualAttendanceCount': manualAttendanceCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> map) {
    final rawRoles = List<String>.from(map['roles'] ?? []);
    if (!rawRoles.contains(AppRoles.miembro)) {
      rawRoles.insert(0, AppRoles.miembro);
    }

    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      documentType: map['documentType'] ?? 'DNI',
      documentNumber: map['documentNumber'] ?? '',
      birthDate: map['birthDate'] != null
          ? DateTime.parse(map['birthDate'])
          : DateTime(2000, 1, 1),
      phone: map['phone'] ?? '',
      instagram: map['instagram'],
      photoUrl: map['photoUrl'],
      roles: rawRoles,
      region: map['region'] ?? AppRegions.buenosAires,
      manualAttendanceCount: map['manualAttendanceCount'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }
}
