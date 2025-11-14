import '../models/user_ranking_model.dart';

class RankingsData {
  static final List<UserRankingModel> rankings = [
    UserRankingModel(
      id: 'user1',
      name: 'María Medina',
      profileImageUrl: '',
      greenPoints: 98,
      challengesCompleted: 42,
      articlesExchanged: 28,
    ),
    UserRankingModel(
      id: 'user2',
      name: 'Carlos Montero',
      profileImageUrl: '',
      greenPoints: 72,
      challengesCompleted: 38,
      articlesExchanged: 25,
    ),
    UserRankingModel(
      id: 'user3',
      name: 'Ana Pineda',
      profileImageUrl: '',
      greenPoints: 65,
      challengesCompleted: 35,
      articlesExchanged: 22,
    ),
    UserRankingModel(
      id: 'user4',
      name: 'Oscar Manzanares',
      profileImageUrl: '',
      greenPoints: 49,
      challengesCompleted: 30,
      articlesExchanged: 19,
    ),
    UserRankingModel(
      id: 'user5',
      name: 'Papi a La Orden',
      profileImageUrl: '',
      greenPoints: 12,
      challengesCompleted: 28,
      articlesExchanged: 18,
    ),
  ];
}
