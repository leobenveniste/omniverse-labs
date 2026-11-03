class CircleGroupModel {
  final String id;
  final String name;
  final String description;
  final String status; // 'forming_2' | 'forming_3' | 'active' | 'expanded'
  final List<String> memberIds; // 2 a 10 IDs
  final List<String> activeConfirmedMemberIds; // Anti-Fantasma
  final int maxMembers; // 4 a 10
  final bool isOpenForExpansion;
  final List<String> sharedInterests;
  final List<String> sharedPlans;
  final String region;
  final Map<String, List<String>> candidateVotes; // candidateId -> voterIds
  final String lastMessagePreview;
  final DateTime lastActivityAt;
  final DateTime createdAt;

  CircleGroupModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.status,
    required this.memberIds,
    this.activeConfirmedMemberIds = const [],
    this.maxMembers = 4,
    this.isOpenForExpansion = false,
    this.sharedInterests = const [],
    this.sharedPlans = const [],
    this.region = 'Buenos Aires',
    this.candidateVotes = const {},
    this.lastMessagePreview = '',
    required this.lastActivityAt,
    required this.createdAt,
  });

  bool get isForming => memberIds.length < 4;
  bool get isActiveGroup => memberIds.length >= 4;
  int get openSeats => (maxMembers - memberIds.length).clamp(0, 10);
  bool get canAcceptMoreMembers =>
      isActiveGroup && isOpenForExpansion && memberIds.length < maxMembers;

  List<String> get inactiveMemberIds => memberIds
      .where((id) => !activeConfirmedMemberIds.contains(id))
      .toList();

  CircleGroupModel copyWith({
    String? name,
    String? description,
    String? status,
    List<String>? memberIds,
    List<String>? activeConfirmedMemberIds,
    int? maxMembers,
    bool? isOpenForExpansion,
    List<String>? sharedInterests,
    List<String>? sharedPlans,
    String? region,
    Map<String, List<String>>? candidateVotes,
    String? lastMessagePreview,
    DateTime? lastActivityAt,
  }) {
    return CircleGroupModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      memberIds: memberIds ?? this.memberIds,
      activeConfirmedMemberIds:
          activeConfirmedMemberIds ?? this.activeConfirmedMemberIds,
      maxMembers: maxMembers ?? this.maxMembers,
      isOpenForExpansion: isOpenForExpansion ?? this.isOpenForExpansion,
      sharedInterests: sharedInterests ?? this.sharedInterests,
      sharedPlans: sharedPlans ?? this.sharedPlans,
      region: region ?? this.region,
      candidateVotes: candidateVotes ?? this.candidateVotes,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'status': status,
      'memberIds': memberIds,
      'activeConfirmedMemberIds': activeConfirmedMemberIds,
      'maxMembers': maxMembers,
      'isOpenForExpansion': isOpenForExpansion,
      'sharedInterests': sharedInterests,
      'sharedPlans': sharedPlans,
      'region': region,
      'candidateVotes': candidateVotes,
      'lastMessagePreview': lastMessagePreview,
      'lastActivityAt': lastActivityAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CircleGroupModel.fromJson(Map<String, dynamic> map) {
    final rawVotes = map['candidateVotes'] as Map<String, dynamic>? ?? {};
    final parsedVotes = <String, List<String>>{};
    rawVotes.forEach((k, v) {
      if (v is List) {
        parsedVotes[k] = List<String>.from(v);
      }
    });

    return CircleGroupModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? 'forming_2',
      memberIds: List<String>.from(map['memberIds'] ?? []),
      activeConfirmedMemberIds:
          List<String>.from(map['activeConfirmedMemberIds'] ?? []),
      maxMembers: map['maxMembers'] ?? 4,
      isOpenForExpansion: map['isOpenForExpansion'] ?? false,
      sharedInterests: List<String>.from(map['sharedInterests'] ?? []),
      sharedPlans: List<String>.from(map['sharedPlans'] ?? []),
      region: map['region'] ?? 'Buenos Aires',
      candidateVotes: parsedVotes,
      lastMessagePreview: map['lastMessagePreview'] ?? '',
      lastActivityAt: map['lastActivityAt'] != null
          ? DateTime.parse(map['lastActivityAt'])
          : DateTime.now(),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }
}

class GroupMessageModel {
  final String id;
  final String groupId;
  final String senderId;
  final String senderName;
  final String senderPhotoUrl;
  final String type; // 'text' | 'icebreaker' | 'plan' | 'poll' | 'system'
  final String text;
  final Map<String, dynamic> payload;
  final Map<String, List<String>> reactions;
  final DateTime timestamp;

  GroupMessageModel({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl = '',
    this.type = 'text',
    required this.text,
    this.payload = const {},
    this.reactions = const {},
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'type': type,
      'text': text,
      'payload': payload,
      'reactions': reactions,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory GroupMessageModel.fromJson(Map<String, dynamic> map) {
    final rawReactions = map['reactions'] as Map<String, dynamic>? ?? {};
    final parsedReactions = <String, List<String>>{};
    rawReactions.forEach((k, v) {
      if (v is List) {
        parsedReactions[k] = List<String>.from(v);
      }
    });

    return GroupMessageModel(
      id: map['id'] ?? '',
      groupId: map['groupId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderPhotoUrl: map['senderPhotoUrl'] ?? '',
      type: map['type'] ?? 'text',
      text: map['text'] ?? '',
      payload: Map<String, dynamic>.from(map['payload'] ?? {}),
      reactions: parsedReactions,
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
    );
  }
}

class GroupPlanModel {
  final String id;
  final String groupId;
  final String creatorId;
  final String creatorName;
  final String title;
  final String category;
  final DateTime scheduledAt;
  final String locationName;
  final Map<String, String> rsvpStatus; // userId -> 'going' | 'maybe' | 'no'
  final List<String> checkedInUserIds;
  final bool isCompleted;
  final DateTime createdAt;

  GroupPlanModel({
    required this.id,
    required this.groupId,
    required this.creatorId,
    required this.creatorName,
    required this.title,
    required this.category,
    required this.scheduledAt,
    required this.locationName,
    this.rsvpStatus = const {},
    this.checkedInUserIds = const [],
    this.isCompleted = false,
    required this.createdAt,
  });

  int get goingCount =>
      rsvpStatus.values.where((status) => status == 'going').length;

  bool isUserCheckedIn(String userId) => checkedInUserIds.contains(userId);

  GroupPlanModel copyWith({
    String? title,
    String? category,
    DateTime? scheduledAt,
    String? locationName,
    Map<String, String>? rsvpStatus,
    List<String>? checkedInUserIds,
    bool? isCompleted,
  }) {
    return GroupPlanModel(
      id: id,
      groupId: groupId,
      creatorId: creatorId,
      creatorName: creatorName,
      title: title ?? this.title,
      category: category ?? this.category,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      locationName: locationName ?? this.locationName,
      rsvpStatus: rsvpStatus ?? this.rsvpStatus,
      checkedInUserIds: checkedInUserIds ?? this.checkedInUserIds,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'title': title,
      'category': category,
      'scheduledAt': scheduledAt.toIso8601String(),
      'locationName': locationName,
      'rsvpStatus': rsvpStatus,
      'checkedInUserIds': checkedInUserIds,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory GroupPlanModel.fromJson(Map<String, dynamic> map) {
    return GroupPlanModel(
      id: map['id'] ?? '',
      groupId: map['groupId'] ?? '',
      creatorId: map['creatorId'] ?? '',
      creatorName: map['creatorName'] ?? '',
      title: map['title'] ?? '',
      category: map['category'] ?? 'coffee',
      scheduledAt: map['scheduledAt'] != null
          ? DateTime.parse(map['scheduledAt'])
          : DateTime.now().add(const Duration(days: 2)),
      locationName: map['locationName'] ?? '',
      rsvpStatus: Map<String, String>.from(map['rsvpStatus'] ?? {}),
      checkedInUserIds: List<String>.from(map['checkedInUserIds'] ?? []),
      isCompleted: map['isCompleted'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }
}
