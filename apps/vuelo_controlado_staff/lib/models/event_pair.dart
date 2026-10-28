class EventPair {
  final String id;
  final String user1Id;
  final String user1Name;
  final String user2Id;
  final String user2Name;
  final DateTime createdAt;

  EventPair({
    required this.id,
    required this.user1Id,
    required this.user1Name,
    required this.user2Id,
    required this.user2Name,
    required this.createdAt,
  });

  bool containsUser(String userId) => user1Id == userId || user2Id == userId;

  String? getPartnerId(String userId) {
    if (user1Id == userId) return user2Id;
    if (user2Id == userId) return user1Id;
    return null;
  }

  String? getPartnerName(String userId) {
    if (user1Id == userId) return user2Name;
    if (user2Id == userId) return user1Name;
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user1Id': user1Id,
      'user1Name': user1Name,
      'user2Id': user2Id,
      'user2Name': user2Name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory EventPair.fromJson(Map<String, dynamic> json) {
    return EventPair(
      id: json['id'] as String? ?? '',
      user1Id: json['user1Id'] as String? ?? '',
      user1Name: json['user1Name'] as String? ?? '',
      user2Id: json['user2Id'] as String? ?? '',
      user2Name: json['user2Name'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  EventPair copyWith({
    String? id,
    String? user1Id,
    String? user1Name,
    String? user2Id,
    String? user2Name,
    DateTime? createdAt,
  }) {
    return EventPair(
      id: id ?? this.id,
      user1Id: user1Id ?? this.user1Id,
      user1Name: user1Name ?? this.user1Name,
      user2Id: user2Id ?? this.user2Id,
      user2Name: user2Name ?? this.user2Name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
