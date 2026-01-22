import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // "user" o "admin"
  final String profileImageUrl;
  final String bio;
  final String phone;
  final int greenPoints;
  final int challengesCompleted;
  final int articlesExchanged;
  final int exchangesCompleted; // Contador de intercambios confirmados
  final DateTime joinedDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String fcmToken; // Token para notificaciones push

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'user',
    this.profileImageUrl = '',
    this.bio = '',
    this.phone = '',
    this.greenPoints = 0,
    this.challengesCompleted = 0,
    this.articlesExchanged = 0,
    this.exchangesCompleted = 0,
    required this.joinedDate,
    required this.createdAt,
    required this.updatedAt,
    this.fcmToken = '',
  });

  // Método copyWith actualizado
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? profileImageUrl,
    String? bio,
    String? phone,
    int? greenPoints,
    int? challengesCompleted,
    int? articlesExchanged,
    int? exchangesCompleted,
    DateTime? joinedDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? fcmToken,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      greenPoints: greenPoints ?? this.greenPoints,
      challengesCompleted: challengesCompleted ?? this.challengesCompleted,
      articlesExchanged: articlesExchanged ?? this.articlesExchanged,
      exchangesCompleted: exchangesCompleted ?? this.exchangesCompleted,
      joinedDate: joinedDate ?? this.joinedDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  // Convertir a JSON para Firestore
  Map<String, dynamic> toJson() {
    return {
      'userId': id,
      'name': name,
      'email': email,
      'role': role,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'phone': phone,
      'greenPoints': greenPoints,
      'challengesCompleted': challengesCompleted,
      'articlesExchanged': articlesExchanged,
      'exchangesCompleted': exchangesCompleted,
      'joinedDate': Timestamp.fromDate(joinedDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'fcmToken': fcmToken,
    };
  }

  // Crear desde JSON de Firestore
  factory UserModel.fromJson(Map<String, dynamic> json, String id) {
    return UserModel(
      id: id,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      profileImageUrl: json['profileImageUrl'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      greenPoints: json['greenPoints'] as int? ?? 0,
      challengesCompleted: json['challengesCompleted'] as int? ?? 0,
      articlesExchanged: json['articlesExchanged'] as int? ?? 0,
      exchangesCompleted: json['exchangesCompleted'] as int? ?? 0,
      joinedDate: (json['joinedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fcmToken: json['fcmToken'] as String? ?? '',
    );
  }

  // Verificar si es administrador
  bool get isAdmin => role == 'admin';
}
