import 'package:cloud_firestore/cloud_firestore.dart';

enum ExchangeStatus {
  pending, // Propuesto por un usuario, esperando confirmación del otro
  confirmed, // Ambos usuarios confirmaron
  cancelled, // Cancelado
}

extension ExchangeStatusExtension on ExchangeStatus {
  String get label {
    switch (this) {
      case ExchangeStatus.pending:
        return 'Pendiente';
      case ExchangeStatus.confirmed:
        return 'Confirmado';
      case ExchangeStatus.cancelled:
        return 'Cancelado';
    }
  }
}

// Modelo de Intercambio
class ExchangeModel {
  final String id;
  final String chatId; // Chat donde se acordó el intercambio
  final String postId; // Publicación relacionada
  final String user1Id; // ID del usuario que propuso
  final String user1Name;
  final String user1ImageUrl;
  final String user2Id; // ID del otro usuario
  final String user2Name;
  final String user2ImageUrl;
  final ExchangeStatus status;
  final bool user1Confirmed; // Si user1 confirmó el intercambio
  final bool user2Confirmed; // Si user2 confirmó el intercambio
  final DateTime? user1ConfirmedAt;
  final DateTime? user2ConfirmedAt;
  final String? notes; // Notas del intercambio
  final String? proofImageUrl; // Foto de evidencia (opcional)
  final DateTime createdAt;
  final DateTime? completedAt; // Cuando ambos confirmaron

  ExchangeModel({
    required this.id,
    required this.chatId,
    required this.postId,
    required this.user1Id,
    required this.user1Name,
    required this.user1ImageUrl,
    required this.user2Id,
    required this.user2Name,
    required this.user2ImageUrl,
    this.status = ExchangeStatus.pending,
    this.user1Confirmed = false,
    this.user2Confirmed = false,
    this.user1ConfirmedAt,
    this.user2ConfirmedAt,
    this.notes,
    this.proofImageUrl,
    required this.createdAt,
    this.completedAt,
  });

  bool get isCompleted => status == ExchangeStatus.confirmed;
  bool get isPending => status == ExchangeStatus.pending;

  // Convertir a JSON para Firestore
  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'postId': postId,
      'user1Id': user1Id,
      'user1Name': user1Name,
      'user1ImageUrl': user1ImageUrl,
      'user2Id': user2Id,
      'user2Name': user2Name,
      'user2ImageUrl': user2ImageUrl,
      'status': status.name,
      'user1Confirmed': user1Confirmed,
      'user2Confirmed': user2Confirmed,
      'user1ConfirmedAt': user1ConfirmedAt != null ? Timestamp.fromDate(user1ConfirmedAt!) : null,
      'user2ConfirmedAt': user2ConfirmedAt != null ? Timestamp.fromDate(user2ConfirmedAt!) : null,
      'notes': notes,
      'proofImageUrl': proofImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  // Crear desde JSON de Firestore
  factory ExchangeModel.fromJson(Map<String, dynamic> json, String id) {
    return ExchangeModel(
      id: id,
      chatId: json['chatId'] as String? ?? '',
      postId: json['postId'] as String? ?? '',
      user1Id: json['user1Id'] as String? ?? '',
      user1Name: json['user1Name'] as String? ?? '',
      user1ImageUrl: json['user1ImageUrl'] as String? ?? '',
      user2Id: json['user2Id'] as String? ?? '',
      user2Name: json['user2Name'] as String? ?? '',
      user2ImageUrl: json['user2ImageUrl'] as String? ?? '',
      status: ExchangeStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ExchangeStatus.pending,
      ),
      user1Confirmed: json['user1Confirmed'] as bool? ?? false,
      user2Confirmed: json['user2Confirmed'] as bool? ?? false,
      user1ConfirmedAt: (json['user1ConfirmedAt'] as Timestamp?)?.toDate(),
      user2ConfirmedAt: (json['user2ConfirmedAt'] as Timestamp?)?.toDate(),
      notes: json['notes'] as String?,
      proofImageUrl: json['proofImageUrl'] as String?,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (json['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  ExchangeModel copyWith({
    String? id,
    String? chatId,
    String? postId,
    String? user1Id,
    String? user1Name,
    String? user1ImageUrl,
    String? user2Id,
    String? user2Name,
    String? user2ImageUrl,
    ExchangeStatus? status,
    bool? user1Confirmed,
    bool? user2Confirmed,
    DateTime? user1ConfirmedAt,
    DateTime? user2ConfirmedAt,
    String? notes,
    String? proofImageUrl,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return ExchangeModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      postId: postId ?? this.postId,
      user1Id: user1Id ?? this.user1Id,
      user1Name: user1Name ?? this.user1Name,
      user1ImageUrl: user1ImageUrl ?? this.user1ImageUrl,
      user2Id: user2Id ?? this.user2Id,
      user2Name: user2Name ?? this.user2Name,
      user2ImageUrl: user2ImageUrl ?? this.user2ImageUrl,
      status: status ?? this.status,
      user1Confirmed: user1Confirmed ?? this.user1Confirmed,
      user2Confirmed: user2Confirmed ?? this.user2Confirmed,
      user1ConfirmedAt: user1ConfirmedAt ?? this.user1ConfirmedAt,
      user2ConfirmedAt: user2ConfirmedAt ?? this.user2ConfirmedAt,
      notes: notes ?? this.notes,
      proofImageUrl: proofImageUrl ?? this.proofImageUrl,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
