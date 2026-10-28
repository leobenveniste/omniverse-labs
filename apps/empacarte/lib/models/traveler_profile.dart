class TravelerProfile {
  final String fullName;
  final String nationality;
  final String passportNumber;
  final DateTime expiryDate;
  final String avatarIcon;
  final String emergencyContactName;
  final String emergencyPhone;

  const TravelerProfile({
    required this.fullName,
    required this.nationality,
    required this.passportNumber,
    required this.expiryDate,
    this.avatarIcon = '✈️',
    this.emergencyContactName = '',
    this.emergencyPhone = '',
  });

  bool get isExpiringSoon {
    final now = DateTime.now();
    final difference = expiryDate.difference(now).inDays;
    return difference < 180; // less than 6 months
  }

  String get mrzLine1 {
    final cleanName = fullName.toUpperCase().replaceAll(' ', '<');
    final cleanNat = nationality.toUpperCase().padRight(3, '<').substring(0, 3);
    return 'P<$cleanNat$cleanName'.padRight(44, '<');
  }

  String get mrzLine2 {
    final cleanNum = passportNumber.toUpperCase().replaceAll(' ', '');
    final cleanNat = nationality.toUpperCase().padRight(3, '<').substring(0, 3);
    return '$cleanNum<0$cleanNat<<<<<<<<<<<<<<<<<<'.padRight(44, '<');
  }

  String get formattedMrz => '$mrzLine1\n$mrzLine2';

  bool get isConfigured => fullName.trim().isNotEmpty && passportNumber.trim().isNotEmpty;

  factory TravelerProfile.empty() {
    return TravelerProfile(
      fullName: '',
      nationality: 'ARG',
      passportNumber: '',
      expiryDate: DateTime.now().add(const Duration(days: 365 * 5)),
      avatarIcon: '✈️',
      emergencyContactName: '',
      emergencyPhone: '',
    );
  }

  factory TravelerProfile.defaultProfile() {
    return TravelerProfile(
      fullName: 'ALEX VOYAGER',
      nationality: 'ARG',
      passportNumber: 'PA984721',
      expiryDate: DateTime.now().add(const Duration(days: 365 * 4)),
      avatarIcon: '🧳',
      emergencyContactName: 'Consular Assistance',
      emergencyPhone: '+1-800-555-0199',
    );
  }

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'nationality': nationality,
        'passportNumber': passportNumber,
        'expiryDate': expiryDate.toIso8601String(),
        'avatarIcon': avatarIcon,
        'emergencyContactName': emergencyContactName,
        'emergencyPhone': emergencyPhone,
      };

  factory TravelerProfile.fromJson(Map<String, dynamic> json) => TravelerProfile(
        fullName: json['fullName'] as String? ?? '',
        nationality: json['nationality'] as String? ?? 'ARG',
        passportNumber: json['passportNumber'] as String? ?? '',
        expiryDate: json['expiryDate'] != null
            ? DateTime.parse(json['expiryDate'] as String)
            : DateTime.now().add(const Duration(days: 365 * 4)),
        avatarIcon: json['avatarIcon'] as String? ?? '✈️',
        emergencyContactName: json['emergencyContactName'] as String? ?? '',
        emergencyPhone: json['emergencyPhone'] as String? ?? '',
      );

  TravelerProfile copyWith({
    String? fullName,
    String? nationality,
    String? passportNumber,
    DateTime? expiryDate,
    String? avatarIcon,
    String? emergencyContactName,
    String? emergencyPhone,
  }) {
    return TravelerProfile(
      fullName: fullName ?? this.fullName,
      nationality: nationality ?? this.nationality,
      passportNumber: passportNumber ?? this.passportNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      avatarIcon: avatarIcon ?? this.avatarIcon,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
    );
  }
}
