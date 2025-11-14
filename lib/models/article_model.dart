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

  ArticleModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.interestedInExchangeFor,
    this.category = ArticleCategory.otros,
  });
}
