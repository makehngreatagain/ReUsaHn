import 'package:cloud_firestore/cloud_firestore.dart';

enum ChallengeType {
  plantTree, // Requiere aprobación admin
  makePublications, // Automático
  makeExchanges, // Requiere aprobación admin (evidencia de intercambio)
  recycling, // Requiere aprobación admin
  other,
}

extension ChallengeTypeExtension on ChallengeType {
  String get label {
    switch (this) {
      case ChallengeType.plantTree:
        return 'Plantar Árbol';
      case ChallengeType.makePublications:
        return 'Hacer Publicaciones';
      case ChallengeType.makeExchanges:
        return 'Realizar Intercambios';
      case ChallengeType.recycling:
        return 'Reciclaje';
      case ChallengeType.other:
        return 'Otro';
    }
  }

  String get icon {
    switch (this) {
      case ChallengeType.plantTree:
        return 'park';
      case ChallengeType.makePublications:
        return 'article';
      case ChallengeType.makeExchanges:
        return 'swap_horiz';
      case ChallengeType.recycling:
        return 'recycling';
      case ChallengeType.other:
        return 'eco';
    }
  }

  bool get requiresApproval {
    switch (this) {
      case ChallengeType.plantTree:
      case ChallengeType.makeExchanges:
      case ChallengeType.recycling:
        return true;
      case ChallengeType.makePublications:
      case ChallengeType.other:
        return false;
    }
  }
}

// Modelo de Reto (plantilla global)
class ChallengeModel {
  final String id;
  final String title;
  final String description;
  final ChallengeType type;
  final int pointsReward;
  final int targetCount; // Cantidad objetivo (ej: 5 árboles, 10 publicaciones)
  final String imageUrl; // Imagen del reto
  final bool isActive; // Si el reto está disponible
  final DateTime createdAt;
  final DateTime updatedAt;

  ChallengeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.pointsReward,
    required this.targetCount,
    this.imageUrl = '',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get requiresApproval => type.requiresApproval;

  // Convertir a JSON para Firestore
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'type': type.name,
      'pointsReward': pointsReward,
      'targetCount': targetCount,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Crear desde JSON de Firestore
  factory ChallengeModel.fromJson(Map<String, dynamic> json, String id) {
    return ChallengeModel(
      id: id,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      type: ChallengeType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ChallengeType.other,
      ),
      pointsReward: json['pointsReward'] as int? ?? 0,
      targetCount: json['targetCount'] as int? ?? 1,
      imageUrl: json['imageUrl'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  ChallengeModel copyWith({
    String? id,
    String? title,
    String? description,
    ChallengeType? type,
    int? pointsReward,
    int? targetCount,
    String? imageUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChallengeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      pointsReward: pointsReward ?? this.pointsReward,
      targetCount: targetCount ?? this.targetCount,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
