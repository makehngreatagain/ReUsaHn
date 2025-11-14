import 'user_model.dart';
import 'article_model.dart';

class PostModel {
  final String id;
  final UserModel user;
  final ArticleModel article;
  final DateTime createdAt;

  PostModel({
    required this.id,
    required this.user,
    required this.article,
    required this.createdAt,
  });
}
