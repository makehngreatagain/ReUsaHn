import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  challengeCompleted,    // Reto completado y puntos acreditados
  publicationApproved,   // Publicación aprobada
  treeApproved,          // Árbol aprobado
  rewardRedeemed,        // Canje de recompensa aprobado
}

extension NotificationTypeExtension on NotificationType {
  String get title {
    switch (this) {
      case NotificationType.challengeCompleted:
        return 'Reto Completado';
      case NotificationType.publicationApproved:
        return 'Publicación Aprobada';
      case NotificationType.treeApproved:
        return 'Árbol Aprobado';
      case NotificationType.rewardRedeemed:
        return 'Canje Aprobado';
    }
  }

  String get icon {
    switch (this) {
      case NotificationType.challengeCompleted:
        return 'emoji_events';
      case NotificationType.publicationApproved:
        return 'check_circle';
      case NotificationType.treeApproved:
        return 'park';
      case NotificationType.rewardRedeemed:
        return 'redeem';
    }
  }
}

class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final int? pointsEarned;       // Puntos ganados (si aplica)
  final String? referenceId;     // ID del reto, publicación, árbol o canje
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.pointsEarned,
    this.referenceId,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json, String docId) {
    return NotificationModel(
      id: docId,
      userId: json['userId'] as String? ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.challengeCompleted,
      ),
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      pointsEarned: json['pointsEarned'] as int?,
      referenceId: json['referenceId'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'type': type.name,
      'title': title,
      'message': message,
      'pointsEarned': pointsEarned,
      'referenceId': referenceId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    int? pointsEarned,
    String? referenceId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      referenceId: referenceId ?? this.referenceId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
