enum RedemptionStatus {
  pending,
  approved,
  delivered,
  cancelled,
}

class RewardRedemptionModel {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String rewardId;
  final String rewardName;
  final int pointsSpent;
  final RedemptionStatus status;
  final DateTime redeemedAt;
  final DateTime? processedAt;
  final String? processedBy;
  final String? notes;
  final String? deliveryAddress;
  final String? phoneNumber;

  RewardRedemptionModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.rewardId,
    required this.rewardName,
    required this.pointsSpent,
    required this.status,
    required this.redeemedAt,
    this.processedAt,
    this.processedBy,
    this.notes,
    this.deliveryAddress,
    this.phoneNumber,
  });

  // Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'rewardId': rewardId,
      'rewardName': rewardName,
      'pointsSpent': pointsSpent,
      'status': status.name,
      'redeemedAt': redeemedAt,
      'processedAt': processedAt,
      'processedBy': processedBy,
      'notes': notes,
      'deliveryAddress': deliveryAddress,
      'phoneNumber': phoneNumber,
    };
  }

  // Crear desde Map de Firestore
  factory RewardRedemptionModel.fromMap(String id, Map<String, dynamic> map) {
    return RewardRedemptionModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      rewardId: map['rewardId'] ?? '',
      rewardName: map['rewardName'] ?? '',
      pointsSpent: map['pointsSpent'] ?? 0,
      status: _statusFromString(map['status'] ?? 'pending'),
      redeemedAt: (map['redeemedAt'] as dynamic)?.toDate() ?? DateTime.now(),
      processedAt: (map['processedAt'] as dynamic)?.toDate(),
      processedBy: map['processedBy'],
      notes: map['notes'],
      deliveryAddress: map['deliveryAddress'],
      phoneNumber: map['phoneNumber'],
    );
  }

  static RedemptionStatus _statusFromString(String status) {
    switch (status) {
      case 'approved':
        return RedemptionStatus.approved;
      case 'delivered':
        return RedemptionStatus.delivered;
      case 'cancelled':
        return RedemptionStatus.cancelled;
      default:
        return RedemptionStatus.pending;
    }
  }

  String get statusDisplayName {
    switch (status) {
      case RedemptionStatus.pending:
        return 'Pendiente';
      case RedemptionStatus.approved:
        return 'Aprobado';
      case RedemptionStatus.delivered:
        return 'Entregado';
      case RedemptionStatus.cancelled:
        return 'Cancelado';
    }
  }
}
