import 'package:cloud_firestore/cloud_firestore.dart';

enum CompletionStatus {
  inProgress, // Usuario trabajando en el reto
  pendingApproval, // Enviado evidencia, esperando aprobación admin
  approved, // Aprobado por admin
  rejected, // Rechazado por admin
  claimed, // Puntos reclamados por el usuario
}

extension CompletionStatusExtension on CompletionStatus {
  String get label {
    switch (this) {
      case CompletionStatus.inProgress:
        return 'En Progreso';
      case CompletionStatus.pendingApproval:
        return 'Pendiente de Aprobación';
      case CompletionStatus.approved:
        return 'Aprobado';
      case CompletionStatus.rejected:
        return 'Rechazado';
      case CompletionStatus.claimed:
        return 'Completado';
    }
  }
}

// Modelo de Reto Completado por Usuario
class ChallengeCompletionModel {
  final String id;
  final String userId; // Usuario que está completando el reto
  final String challengeId; // Reto que está completando
  final int currentCount; // Progreso actual (ej: 3 de 5 árboles)
  final CompletionStatus status;
  final List<String> proofImageUrls; // Evidencias (fotos)
  final String? rejectionReason; // Razón de rechazo si fue rechazado
  final String? reviewedBy; // ID del admin que revisó
  final DateTime? reviewedAt; // Cuando fue revisado
  final DateTime? completedAt; // Cuando completó el objetivo
  final DateTime? claimedAt; // Cuando reclamó los puntos
  final DateTime createdAt;
  final DateTime updatedAt;

  ChallengeCompletionModel({
    required this.id,
    required this.userId,
    required this.challengeId,
    this.currentCount = 0,
    this.status = CompletionStatus.inProgress,
    this.proofImageUrls = const [],
    this.rejectionReason,
    this.reviewedBy,
    this.reviewedAt,
    this.completedAt,
    this.claimedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isCompleted => status == CompletionStatus.claimed;
  bool get canClaim => status == CompletionStatus.approved;
  bool get needsReview => status == CompletionStatus.pendingApproval;

  // Convertir a JSON para Firestore
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'challengeId': challengeId,
      'currentCount': currentCount,
      'status': status.name,
      'proofImageUrls': proofImageUrls,
      'rejectionReason': rejectionReason,
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'claimedAt': claimedAt != null ? Timestamp.fromDate(claimedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Crear desde JSON de Firestore
  factory ChallengeCompletionModel.fromJson(Map<String, dynamic> json, String id) {
    return ChallengeCompletionModel(
      id: id,
      userId: json['userId'] as String? ?? '',
      challengeId: json['challengeId'] as String? ?? '',
      currentCount: json['currentCount'] as int? ?? 0,
      status: CompletionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => CompletionStatus.inProgress,
      ),
      proofImageUrls: (json['proofImageUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      rejectionReason: json['rejectionReason'] as String?,
      reviewedBy: json['reviewedBy'] as String?,
      reviewedAt: (json['reviewedAt'] as Timestamp?)?.toDate(),
      completedAt: (json['completedAt'] as Timestamp?)?.toDate(),
      claimedAt: (json['claimedAt'] as Timestamp?)?.toDate(),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  ChallengeCompletionModel copyWith({
    String? id,
    String? userId,
    String? challengeId,
    int? currentCount,
    CompletionStatus? status,
    List<String>? proofImageUrls,
    String? rejectionReason,
    String? reviewedBy,
    DateTime? reviewedAt,
    DateTime? completedAt,
    DateTime? claimedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChallengeCompletionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      challengeId: challengeId ?? this.challengeId,
      currentCount: currentCount ?? this.currentCount,
      status: status ?? this.status,
      proofImageUrls: proofImageUrls ?? this.proofImageUrls,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      completedAt: completedAt ?? this.completedAt,
      claimedAt: claimedAt ?? this.claimedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
