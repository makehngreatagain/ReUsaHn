class RewardModel {
  final String id;
  final String name;
  final String description;
  final int pointsCost;
  final String imageUrl;
  final int stock;
  final RewardCategory category;

  RewardModel({
    required this.id,
    required this.name,
    required this.description,
    required this.pointsCost,
    required this.imageUrl,
    required this.stock,
    required this.category,
  });
}

enum RewardCategory {
  merchandise('Merchandising'),
  ecofriendly('Eco-Friendly'),
  plants('Plantas'),
  educational('Educativo');

  final String displayName;
  const RewardCategory(this.displayName);
}
