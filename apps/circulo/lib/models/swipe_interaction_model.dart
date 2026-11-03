import 'user_model.dart';
import 'circle_group_model.dart';

class SwipeInteractionModel {
  final String id;
  final String fromUserId;
  final String targetId;
  final String targetType; // 'user' | 'circle'
  final String action; // 'like' | 'superlike' | 'pass'
  final DateTime timestamp;

  SwipeInteractionModel({
    required this.id,
    required this.fromUserId,
    required this.targetId,
    required this.targetType,
    required this.action,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromUserId': fromUserId,
      'targetId': targetId,
      'targetType': targetType,
      'action': action,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SwipeInteractionModel.fromJson(Map<String, dynamic> map) {
    return SwipeInteractionModel(
      id: map['id'] ?? '',
      fromUserId: map['fromUserId'] ?? '',
      targetId: map['targetId'] ?? '',
      targetType: map['targetType'] ?? 'user',
      action: map['action'] ?? 'like',
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
    );
  }
}

class ReportModel {
  final String id;
  final String reporterUserId;
  final String reportedUserId;
  final String? groupId;
  final String reason;
  final String details;
  final String status; // 'pending' | 'resolved'
  final DateTime createdAt;

  ReportModel({
    required this.id,
    required this.reporterUserId,
    required this.reportedUserId,
    this.groupId,
    required this.reason,
    this.details = '',
    this.status = 'pending',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporterUserId': reporterUserId,
      'reportedUserId': reportedUserId,
      'groupId': groupId,
      'reason': reason,
      'details': details,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ReportModel.fromJson(Map<String, dynamic> map) {
    return ReportModel(
      id: map['id'] ?? '',
      reporterUserId: map['reporterUserId'] ?? '',
      reportedUserId: map['reportedUserId'] ?? '',
      groupId: map['groupId'],
      reason: map['reason'] ?? '',
      details: map['details'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }
}

enum DeckCandidateType {
  individual,
  formingCircle,
  expandedGroup,
}

class DeckCandidateItem {
  final DeckCandidateType type;
  final UserModel? user;
  final CircleGroupModel? group;
  final List<UserModel> groupMembers;
  final int affinityScore; // 0 a 100
  final List<String> sharedInterests;
  final List<String> sharedPlans;

  const DeckCandidateItem({
    required this.type,
    this.user,
    this.group,
    this.groupMembers = const [],
    required this.affinityScore,
    this.sharedInterests = const [],
    this.sharedPlans = const [],
  });

  String get id => type == DeckCandidateType.individual
      ? (user?.id ?? '')
      : (group?.id ?? '');

  bool get isCircle => type != DeckCandidateType.individual;
}
