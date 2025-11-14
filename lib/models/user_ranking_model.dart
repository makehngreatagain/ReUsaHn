class UserRankingModel {
  final String id;
  final String name;
  final String profileImageUrl;
  final int greenPoints;
  final int challengesCompleted;
  final int articlesExchanged;

  UserRankingModel({
    required this.id,
    required this.name,
    required this.profileImageUrl,
    required this.greenPoints,
    required this.challengesCompleted,
    required this.articlesExchanged,
  });
}
