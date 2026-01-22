enum ArticleCategory {
  plastico('Plástico'),
  papel('Papel y Cartón'),
  vidrio('Vidrio'),
  metal('Metal'),
  electronico('Electrónico'),
  textil('Textil'),
  organico('Orgánico'),
  otros('Otros');

  final String displayName;
  const ArticleCategory(this.displayName);
}

class ArticleModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final List<String> interestedInExchangeFor;
  final ArticleCategory category;
  final bool isAvailable;

  ArticleModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.interestedInExchangeFor,
    this.category = ArticleCategory.otros,
    this.isAvailable = true,
  });

  // Convertir a JSON para Firestore
  Map<String, dynamic> toJson() {
    return {
      'articleId': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'interestedInExchangeFor': interestedInExchangeFor,
      'category': category.name,
      'isAvailable': isAvailable,
    };
  }

  // Crear desde JSON de Firestore
  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    return ArticleModel(
      id: json['articleId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      interestedInExchangeFor: (json['interestedInExchangeFor'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      category: ArticleCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ArticleCategory.otros,
      ),
      isAvailable: json['isAvailable'] as bool? ?? true,
    );
  }

  // Método copyWith
  ArticleModel copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    List<String>? interestedInExchangeFor,
    ArticleCategory? category,
    bool? isAvailable,
  }) {
    return ArticleModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      interestedInExchangeFor: interestedInExchangeFor ?? this.interestedInExchangeFor,
      category: category ?? this.category,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}
