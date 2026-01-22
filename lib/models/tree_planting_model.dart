import 'package:cloud_firestore/cloud_firestore.dart';

enum TreePlantingStatus {
  pending,
  approved,
  rejected,
}

class TreePlantingModel {
  final String id;
  final String userId;
  final String userName;
  final String userProfileImageUrl;
  final String greenZoneId;
  final String greenZoneName;
  final double latitude;
  final double longitude;
  final String photoUrl;
  final String notes;
  final TreePlantingStatus status;
  final DateTime plantedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? reviewNotes;

  TreePlantingModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userProfileImageUrl = '',
    required this.greenZoneId,
    required this.greenZoneName,
    required this.latitude,
    required this.longitude,
    required this.photoUrl,
    this.notes = '',
    required this.status,
    required this.plantedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.reviewNotes,
  });

  factory TreePlantingModel.fromJson(Map<String, dynamic> json, String id) {
    return TreePlantingModel(
      id: id,
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userProfileImageUrl: json['userProfileImageUrl'] ?? '',
      greenZoneId: json['greenZoneId'] ?? '',
      greenZoneName: json['greenZoneName'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      photoUrl: json['photoUrl'] ?? '',
      notes: json['notes'] ?? '',
      status: _statusFromString(json['status'] ?? 'pending'),
      plantedAt: (json['plantedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewedAt: (json['reviewedAt'] as Timestamp?)?.toDate(),
      reviewedBy: json['reviewedBy'],
      reviewNotes: json['reviewNotes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userProfileImageUrl': userProfileImageUrl,
      'greenZoneId': greenZoneId,
      'greenZoneName': greenZoneName,
      'latitude': latitude,
      'longitude': longitude,
      'photoUrl': photoUrl,
      'notes': notes,
      'status': _statusToString(status),
      'plantedAt': Timestamp.fromDate(plantedAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewedBy': reviewedBy,
      'reviewNotes': reviewNotes,
    };
  }

  static TreePlantingStatus _statusFromString(String status) {
    switch (status) {
      case 'approved':
        return TreePlantingStatus.approved;
      case 'rejected':
        return TreePlantingStatus.rejected;
      default:
        return TreePlantingStatus.pending;
    }
  }

  static String _statusToString(TreePlantingStatus status) {
    switch (status) {
      case TreePlantingStatus.approved:
        return 'approved';
      case TreePlantingStatus.rejected:
        return 'rejected';
      case TreePlantingStatus.pending:
        return 'pending';
    }
  }

  TreePlantingModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userProfileImageUrl,
    String? greenZoneId,
    String? greenZoneName,
    double? latitude,
    double? longitude,
    String? photoUrl,
    String? notes,
    TreePlantingStatus? status,
    DateTime? plantedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? reviewNotes,
  }) {
    return TreePlantingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userProfileImageUrl: userProfileImageUrl ?? this.userProfileImageUrl,
      greenZoneId: greenZoneId ?? this.greenZoneId,
      greenZoneName: greenZoneName ?? this.greenZoneName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      photoUrl: photoUrl ?? this.photoUrl,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      plantedAt: plantedAt ?? this.plantedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewNotes: reviewNotes ?? this.reviewNotes,
    );
  }
}
