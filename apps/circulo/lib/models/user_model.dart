class AppRegions {
  static const String allRegions = 'Todas las regiones';
  static const String buenosAires = 'Buenos Aires';
  static const String cordoba = 'Córdoba';
  static const String rosario = 'Rosario';
  static const String mendoza = 'Mendoza';
  static const String patagonia = 'Patagonia';
  static const String noa = 'NOA';
  static const String madrid = 'Madrid';
  static const String barcelona = 'Barcelona';
  static const String cdmx = 'Ciudad de México';
  static const String saoPaulo = 'São Paulo';
  static const String paris = 'Paris';
  static const String milano = 'Milano';
  static const String berlin = 'Berlin';

  static const List<String> all = [
    buenosAires,
    cordoba,
    rosario,
    mendoza,
    patagonia,
    noa,
    madrid,
    barcelona,
    cdmx,
    saoPaulo,
    paris,
    milano,
    berlin,
  ];
}

class AppRoles {
  static const String superAdminEmail = 'leobenveniste@vuelocontrolado.org';
  static const String miembro = 'Miembro';
  static const String moderador = 'Moderador';
}

class AppGenders {
  static const String female = 'female';
  static const String male = 'male';
  static const String nonBinary = 'non_binary';
  static const String preferNotToSay = 'prefer_not_to_say';

  static const List<String> all = [
    female,
    male,
    nonBinary,
    preferNotToSay,
  ];
}

class GroupRoles {
  static const String organizer = 'organizer';
  static const String connector = 'connector';
  static const String explorer = 'explorer';
  static const String chill = 'chill';

  static const List<String> all = [
    organizer,
    connector,
    explorer,
    chill,
  ];

  static String getIcon(String role) {
    switch (role) {
      case organizer:
        return '🎯';
      case connector:
        return '💬';
      case explorer:
        return '🧭';
      case chill:
      default:
        return '☕';
    }
  }
}

class AppInterests {
  static const String musicLive = 'music_live';
  static const String specialtyCoffee = 'specialty_coffee';
  static const String boardGames = 'board_games';
  static const String craftBeer = 'craft_beer';
  static const String runningFitness = 'running_fitness';
  static const String cinemaSeries = 'cinema_series';
  static const String techAi = 'tech_ai';
  static const String outdoorMate = 'outdoor_mate';
  static const String cookingFoodie = 'cooking_foodie';
  static const String artMuseums = 'art_museums';
  static const String travelWeekend = 'travel_weekend';
  static const String photography = 'photography';
  static const String booksReading = 'books_reading';
  static const String videoGames = 'video_games';
  static const String languagesExchange = 'languages_exchange';

  static const List<String> all = [
    musicLive,
    specialtyCoffee,
    boardGames,
    craftBeer,
    runningFitness,
    cinemaSeries,
    techAi,
    outdoorMate,
    cookingFoodie,
    artMuseums,
    travelWeekend,
    photography,
    booksReading,
    videoGames,
    languagesExchange,
  ];
}

class AppPlans {
  static const String coffee = 'coffee';
  static const String beer = 'beer';
  static const String boardgames = 'boardgames';
  static const String parkMate = 'park_mate';
  static const String sport = 'sport';
  static const String dinner = 'dinner';
  static const String cinemaMusic = 'cinema_music';

  static const List<String> all = [
    coffee,
    beer,
    boardgames,
    parkMate,
    sport,
    dinner,
    cinemaMusic,
  ];
}

class AppVibes {
  static const String chill = 'chill';
  static const String balanced = 'balanced';
  static const String active = 'active';

  static const List<String> all = [chill, balanced, active];
}

class AvailabilitySlots {
  static const String weekdayAfternoon = 'weekday_afternoon';
  static const String weekdayNight = 'weekday_night';
  static const String weekendDay = 'weekend_day';
  static const String weekendNight = 'weekend_night';

  static const List<String> all = [
    weekdayAfternoon,
    weekdayNight,
    weekendDay,
    weekendNight,
  ];
}

class UserModel {
  final String id;
  final String email;
  final String passwordHash;
  final String authProvider; // 'email' | 'google'
  final String firstName;
  final String lastName;
  final DateTime birthDate;
  final String gender;
  final String phone;
  final String? instagram;
  final String? photoUrl;
  final List<String> photoGallery;
  final String bio;
  final String region;
  final String neighborhood;
  final String groupRole; // organizer, connector, explorer, chill
  final List<String> interests;
  final List<String> favoritePlans;
  final String socialVibe; // chill, balanced, active
  final List<String> availabilitySlots;
  final String duoInviteCode;
  final String? duoPartnerId;
  final int completedMeetupsCount;
  final int? manualMeetupCount;
  final List<String> sharedContactGroupIds;
  final bool isDiscoveryPaused;
  final bool onboardingCompleted;
  final List<String> blockedUserIds;
  final List<String> roles;
  // Monetización Freemium & Círculo Plus
  final bool isPlusActive;
  final DateTime? plusExpiresAt;
  final int dailySwipesRemaining;
  final DateTime? lastSwipeResetDate;
  final int remainingBoosts;
  final DateTime? activeBoostUntil;
  final int remainingSuperOndas;
  final List<String> whoLikedMeUserIds;
  final int totalSwipesCounter;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.passwordHash,
    this.authProvider = 'email',
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    this.gender = '',
    this.phone = '',
    this.instagram,
    this.photoUrl,
    this.photoGallery = const [],
    this.bio = '',
    this.region = AppRegions.buenosAires,
    this.neighborhood = '',
    this.groupRole = GroupRoles.chill,
    this.interests = const [],
    this.favoritePlans = const [],
    this.socialVibe = AppVibes.balanced,
    this.availabilitySlots = const [],
    required this.duoInviteCode,
    this.duoPartnerId,
    this.completedMeetupsCount = 0,
    this.manualMeetupCount,
    this.sharedContactGroupIds = const [],
    this.isDiscoveryPaused = false,
    this.onboardingCompleted = false,
    this.blockedUserIds = const [],
    this.roles = const [AppRoles.miembro],
    this.isPlusActive = false,
    this.plusExpiresAt,
    this.dailySwipesRemaining = 30,
    this.lastSwipeResetDate,
    this.remainingBoosts = 0,
    this.activeBoostUntil,
    this.remainingSuperOndas = 0,
    this.whoLikedMeUserIds = const [],
    this.totalSwipesCounter = 0,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName'.trim();

  int get age {
    final now = DateTime.now();
    int a = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      a--;
    }
    return a;
  }

  int get totalMeetupsCount => completedMeetupsCount + (manualMeetupCount ?? 0);

  bool get isSuperAdmin =>
      email.trim().toLowerCase() == AppRoles.superAdminEmail.toLowerCase();

  bool get isPlusMember =>
      isSuperAdmin ||
      (isPlusActive &&
          (plusExpiresAt == null || plusExpiresAt!.isAfter(DateTime.now())));

  bool get hasActiveBoost =>
      activeBoostUntil != null && activeBoostUntil!.isAfter(DateTime.now());

  bool get hasDuoPartner => duoPartnerId != null && duoPartnerId!.isNotEmpty;

  bool canViewContactInGroup(String groupId) =>
      sharedContactGroupIds.contains(groupId);

  UserModel copyWith({
    String? email,
    String? passwordHash,
    String? authProvider,
    String? firstName,
    String? lastName,
    DateTime? birthDate,
    String? gender,
    String? phone,
    String? instagram,
    String? photoUrl,
    bool clearPhoto = false,
    List<String>? photoGallery,
    String? bio,
    String? region,
    String? neighborhood,
    String? groupRole,
    List<String>? interests,
    List<String>? favoritePlans,
    String? socialVibe,
    List<String>? availabilitySlots,
    String? duoInviteCode,
    String? duoPartnerId,
    bool clearDuoPartner = false,
    int? completedMeetupsCount,
    int? manualMeetupCount,
    bool clearManualMeetups = false,
    List<String>? sharedContactGroupIds,
    bool? isDiscoveryPaused,
    bool? onboardingCompleted,
    List<String>? blockedUserIds,
    List<String>? roles,
    bool? isPlusActive,
    DateTime? plusExpiresAt,
    bool clearPlusExpiration = false,
    int? dailySwipesRemaining,
    DateTime? lastSwipeResetDate,
    int? remainingBoosts,
    DateTime? activeBoostUntil,
    bool clearActiveBoost = false,
    int? remainingSuperOndas,
    List<String>? whoLikedMeUserIds,
    int? totalSwipesCounter,
  }) {
    return UserModel(
      id: id,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      authProvider: authProvider ?? this.authProvider,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      instagram: instagram ?? this.instagram,
      photoUrl: clearPhoto ? null : (photoUrl ?? this.photoUrl),
      photoGallery: photoGallery ?? this.photoGallery,
      bio: bio ?? this.bio,
      region: region ?? this.region,
      neighborhood: neighborhood ?? this.neighborhood,
      groupRole: groupRole ?? this.groupRole,
      interests: interests ?? this.interests,
      favoritePlans: favoritePlans ?? this.favoritePlans,
      socialVibe: socialVibe ?? this.socialVibe,
      availabilitySlots: availabilitySlots ?? this.availabilitySlots,
      duoInviteCode: duoInviteCode ?? this.duoInviteCode,
      duoPartnerId: clearDuoPartner ? null : (duoPartnerId ?? this.duoPartnerId),
      completedMeetupsCount:
          completedMeetupsCount ?? this.completedMeetupsCount,
      manualMeetupCount: clearManualMeetups
          ? null
          : (manualMeetupCount ?? this.manualMeetupCount),
      sharedContactGroupIds:
          sharedContactGroupIds ?? this.sharedContactGroupIds,
      isDiscoveryPaused: isDiscoveryPaused ?? this.isDiscoveryPaused,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      blockedUserIds: blockedUserIds ?? this.blockedUserIds,
      roles: roles ?? this.roles,
      isPlusActive: isPlusActive ?? this.isPlusActive,
      plusExpiresAt: clearPlusExpiration
          ? null
          : (plusExpiresAt ?? this.plusExpiresAt),
      dailySwipesRemaining:
          dailySwipesRemaining ?? this.dailySwipesRemaining,
      lastSwipeResetDate: lastSwipeResetDate ?? this.lastSwipeResetDate,
      remainingBoosts: remainingBoosts ?? this.remainingBoosts,
      activeBoostUntil: clearActiveBoost
          ? null
          : (activeBoostUntil ?? this.activeBoostUntil),
      remainingSuperOndas:
          remainingSuperOndas ?? this.remainingSuperOndas,
      whoLikedMeUserIds: whoLikedMeUserIds ?? this.whoLikedMeUserIds,
      totalSwipesCounter: totalSwipesCounter ?? this.totalSwipesCounter,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'passwordHash': passwordHash,
      'authProvider': authProvider,
      'firstName': firstName,
      'lastName': lastName,
      'birthDate': birthDate.toIso8601String(),
      'gender': gender,
      'phone': phone,
      'instagram': instagram,
      'photoUrl': photoUrl,
      'photoGallery': photoGallery,
      'bio': bio,
      'region': region,
      'neighborhood': neighborhood,
      'groupRole': groupRole,
      'interests': interests,
      'favoritePlans': favoritePlans,
      'socialVibe': socialVibe,
      'availabilitySlots': availabilitySlots,
      'duoInviteCode': duoInviteCode,
      'duoPartnerId': duoPartnerId,
      'completedMeetupsCount': completedMeetupsCount,
      'manualMeetupCount': manualMeetupCount,
      'sharedContactGroupIds': sharedContactGroupIds,
      'isDiscoveryPaused': isDiscoveryPaused,
      'onboardingCompleted': onboardingCompleted,
      'blockedUserIds': blockedUserIds,
      'roles': roles,
      'isPlusActive': isPlusActive,
      'plusExpiresAt': plusExpiresAt?.toIso8601String(),
      'dailySwipesRemaining': dailySwipesRemaining,
      'lastSwipeResetDate': lastSwipeResetDate?.toIso8601String(),
      'remainingBoosts': remainingBoosts,
      'activeBoostUntil': activeBoostUntil?.toIso8601String(),
      'remainingSuperOndas': remainingSuperOndas,
      'whoLikedMeUserIds': whoLikedMeUserIds,
      'totalSwipesCounter': totalSwipesCounter,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      passwordHash: map['passwordHash'] ?? '',
      authProvider: map['authProvider'] ?? 'email',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      birthDate: map['birthDate'] != null
          ? DateTime.parse(map['birthDate'])
          : DateTime(2000, 1, 1),
      gender: map['gender'] as String? ?? '',
      phone: map['phone'] ?? '',
      instagram: map['instagram'],
      photoUrl: map['photoUrl'],
      photoGallery: List<String>.from(map['photoGallery'] ?? []),
      bio: map['bio'] ?? '',
      region: map['region'] ?? AppRegions.buenosAires,
      neighborhood: map['neighborhood'] ?? '',
      groupRole: map['groupRole'] ?? GroupRoles.chill,
      interests: List<String>.from(map['interests'] ?? []),
      favoritePlans: List<String>.from(map['favoritePlans'] ?? []),
      socialVibe: map['socialVibe'] ?? AppVibes.balanced,
      availabilitySlots: List<String>.from(map['availabilitySlots'] ?? []),
      duoInviteCode: map['duoInviteCode'] ?? '',
      duoPartnerId: map['duoPartnerId'],
      completedMeetupsCount: map['completedMeetupsCount'] ?? 0,
      manualMeetupCount: map['manualMeetupCount'],
      sharedContactGroupIds:
          List<String>.from(map['sharedContactGroupIds'] ?? []),
      isDiscoveryPaused: map['isDiscoveryPaused'] ?? false,
      onboardingCompleted: map['onboardingCompleted'] ?? false,
      blockedUserIds: List<String>.from(map['blockedUserIds'] ?? []),
      roles: List<String>.from(map['roles'] ?? [AppRoles.miembro]),
      isPlusActive: map['isPlusActive'] ?? false,
      plusExpiresAt: map['plusExpiresAt'] != null
          ? DateTime.tryParse(map['plusExpiresAt'])
          : null,
      dailySwipesRemaining: map['dailySwipesRemaining'] ?? 30,
      lastSwipeResetDate: map['lastSwipeResetDate'] != null
          ? DateTime.tryParse(map['lastSwipeResetDate'])
          : null,
      remainingBoosts: map['remainingBoosts'] ?? 0,
      activeBoostUntil: map['activeBoostUntil'] != null
          ? DateTime.tryParse(map['activeBoostUntil'])
          : null,
      remainingSuperOndas: map['remainingSuperOndas'] ?? 0,
      whoLikedMeUserIds: List<String>.from(map['whoLikedMeUserIds'] ?? []),
      totalSwipesCounter: map['totalSwipesCounter'] ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }
}
