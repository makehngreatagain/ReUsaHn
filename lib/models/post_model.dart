import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';
import 'article_model.dart';

enum PostStatus {
  pending,   // Pendiente de aprobación
  approved,  // Aprobado por admin
  rejected,  // Rechazado por admin
}

class PostModel {
  final String id;
  final String userId;           // ID del usuario que creó el post
  final UserModel user;          // Datos del usuario (para mostrar)
  final ArticleModel article;
  final PostStatus status;
  final String? rejectionReason; // Razón del rechazo (si aplica)
  final String? reviewedBy;      // ID del admin que revisó
  final DateTime? reviewedAt;    // Fecha de revisión
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? location;        // Localidad desde donde se publicó

  PostModel({
    required this.id,
    required this.userId,
    required this.user,
    required this.article,
    this.status = PostStatus.pending,
    this.rejectionReason,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
    required this.updatedAt,
    this.location,
  });

  // Convertir a JSON para Firestore
  Map<String, dynamic> toJson() {
    return {
      'postId': id,
      'userId': userId,
      'article': article.toJson(),
      'status': status.name,
      'rejectionReason': rejectionReason,
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'location': location,
    };
  }

  // Crear desde JSON de Firestore
  static Future<PostModel> fromJson(Map<String, dynamic> json, String id) async {
    // Obtener datos del usuario desde Firestore
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(json['userId'] as String)
        .get();

    final userData = userDoc.exists
        ? UserModel.fromJson(userDoc.data()!, userDoc.id)
        : UserModel(
            id: json['userId'] as String,
            name: 'Usuario eliminado',
            email: '',
            joinedDate: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

    return PostModel(
      id: id,
      userId: json['userId'] as String? ?? '',
      user: userData,
      article: ArticleModel.fromJson(json['article'] as Map<String, dynamic>),
      status: PostStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PostStatus.pending,
      ),
      rejectionReason: json['rejectionReason'] as String?,
      reviewedBy: json['reviewedBy'] as String?,
      reviewedAt: (json['reviewedAt'] as Timestamp?)?.toDate(),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: json['location'] as String?,
    );
  }

  // Factory sincrónico para cuando ya tenemos el UserModel
  factory PostModel.fromJsonWithUser(
    Map<String, dynamic> json,
    String id,
    UserModel user,
  ) {
    return PostModel(
      id: id,
      userId: json['userId'] as String? ?? '',
      user: user,
      article: ArticleModel.fromJson(json['article'] as Map<String, dynamic>),
      status: PostStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PostStatus.pending,
      ),
      rejectionReason: json['rejectionReason'] as String?,
      reviewedBy: json['reviewedBy'] as String?,
      reviewedAt: (json['reviewedAt'] as Timestamp?)?.toDate(),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: json['location'] as String?,
    );
  }

  // Método copyWith
  PostModel copyWith({
    String? id,
    String? userId,
    UserModel? user,
    ArticleModel? article,
    PostStatus? status,
    String? rejectionReason,
    String? reviewedBy,
    DateTime? reviewedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? location,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      user: user ?? this.user,
      article: article ?? this.article,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      location: location ?? this.location,
    );
  }

  // Getters útiles
  bool get isPending => status == PostStatus.pending;
  bool get isApproved => status == PostStatus.approved;
  bool get isRejected => status == PostStatus.rejected;
}
