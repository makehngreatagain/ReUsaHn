class RewardModel {
  final String id;
  final String name;
  final String description;
  final int pointsCost;
  final String imageUrl;
  final int stock;
  final RewardCategory category;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  RewardModel({
    required this.id,
    required this.name,
    required this.description,
    required this.pointsCost,
    required this.imageUrl,
    required this.stock,
    required this.category,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  // Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'pointsCost': pointsCost,
      'imageUrl': imageUrl,
      'stock': stock,
      'category': category.name,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Crear desde Map de Firestore
  factory RewardModel.fromMap(String id, Map<String, dynamic> map) {
    return RewardModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      pointsCost: map['pointsCost'] ?? 0,
      imageUrl: map['imageUrl'] ?? '',
      stock: map['stock'] ?? 0,
      category: _categoryFromString(map['category'] ?? 'merchandise'),
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as dynamic)?.toDate(),
    );
  }

  static RewardCategory _categoryFromString(String category) {
    switch (category) {
      case 'ecofriendly':
        return RewardCategory.ecofriendly;
      case 'plants':
        return RewardCategory.plants;
      case 'educational':
        return RewardCategory.educational;
      default:
        return RewardCategory.merchandise;
    }
  }

  // Copiar con cambios
  RewardModel copyWith({
    String? id,
    String? name,
    String? description,
    int? pointsCost,
    String? imageUrl,
    int? stock,
    RewardCategory? category,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RewardModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      pointsCost: pointsCost ?? this.pointsCost,
      imageUrl: imageUrl ?? this.imageUrl,
      stock: stock ?? this.stock,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum RewardCategory {
  merchandise('Merchandising'),
  ecofriendly('Eco-Friendly'),
  plants('Plantas'),
  educational('Educativo');

  final String displayName;
  const RewardCategory(this.displayName);
}
