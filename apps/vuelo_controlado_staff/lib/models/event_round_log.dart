class EventRoundLog {
  final String id;
  final DateTime timestamp;
  final String memberId;
  final String memberName;
  final String? partnerId;
  final String? partnerName;
  final int detectedCasesCount;
  final int callsCount;
  final String observations;

  EventRoundLog({
    required this.id,
    required this.timestamp,
    required this.memberId,
    required this.memberName,
    this.partnerId,
    this.partnerName,
    required this.detectedCasesCount,
    required this.callsCount,
    required this.observations,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'memberId': memberId,
      'memberName': memberName,
      'partnerId': partnerId,
      'partnerName': partnerName,
      'detectedCasesCount': detectedCasesCount,
      'callsCount': callsCount,
      'observations': observations,
    };
  }

  factory EventRoundLog.fromJson(Map<String, dynamic> json) {
    return EventRoundLog(
      id: json['id'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      memberId: json['memberId'] as String? ?? '',
      memberName: json['memberName'] as String? ?? '',
      partnerId: json['partnerId'] as String?,
      partnerName: json['partnerName'] as String?,
      detectedCasesCount: (json['detectedCasesCount'] as num?)?.toInt() ?? 0,
      callsCount: (json['callsCount'] as num?)?.toInt() ?? 0,
      observations: json['observations'] as String? ?? '',
    );
  }

  EventRoundLog copyWith({
    String? id,
    DateTime? timestamp,
    String? memberId,
    String? memberName,
    String? partnerId,
    String? partnerName,
    int? detectedCasesCount,
    int? callsCount,
    String? observations,
  }) {
    return EventRoundLog(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      partnerId: partnerId ?? this.partnerId,
      partnerName: partnerName ?? this.partnerName,
      detectedCasesCount: detectedCasesCount ?? this.detectedCasesCount,
      callsCount: callsCount ?? this.callsCount,
      observations: observations ?? this.observations,
    );
  }
}
