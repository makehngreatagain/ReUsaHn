import '../models/user_model.dart';
import '../models/article_model.dart';
import '../models/post_model.dart';
import '../models/chat_model.dart';

class DummyData {
  //ejemplo de carga de una publicacion
  static final List<PostModel> posts = [
    PostModel(
      id: '1',
      user: UserModel(
        id: 'user1',
        name: 'Usuario Prueba 1',
        profileImageUrl: '',
      ),
      article: ArticleModel(
        id: 'article1',
        title: 'Botellas plásticas reciclables',
        description: 'Botellas de plástico limpias y en buen estado. Ideales para manualidades o reciclaje.',
        imageUrl: '',
        interestedInExchangeFor: ['Bolsas reutilizables', 'Envases de vidrio', 'Papel reciclado'],
        category: ArticleCategory.plastico,
      ),
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    PostModel(
      id: '2',
      user: UserModel(
        id: 'user2',
        name: 'Usuario Prueba 2',
        profileImageUrl: '',
      ),
      article: ArticleModel(
        id: 'article2',
        title: 'Cajas de cartón',
        description: 'Cajas de cartón en perfecto estado. Pueden servir para almacenamiento o manualidades.',
        imageUrl: '',
        interestedInExchangeFor: ['Envases de vidrio', 'Papel de periódico'],
        category: ArticleCategory.papel,
      ),
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
    ),
    PostModel(
      id: '3',
      user: UserModel(
        id: 'user3',
        name: 'Usuario Prueba 3',
        profileImageUrl: '',
      ),
      article: ArticleModel(
        id: 'article3',
        title: 'Tarros de vidrio',
        description: 'Tarros de vidrio limpios y sin etiquetas. Perfectos para almacenar alimentos o decoración.',
        imageUrl: '',
        interestedInExchangeFor: ['Envases de plástico', 'Botellas'],
        category: ArticleCategory.vidrio,
      ),
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
    ),
    PostModel(
      id: '4',
      user: UserModel(
        id: 'user4',
        name: 'Usuario Prueba 4',
        profileImageUrl: '',
      ),
      article: ArticleModel(
        id: 'article4',
        title: 'Latas de aluminio',
        description: 'Latas de bebidas limpias. Ideales para reciclaje o proyectos creativos.',
        imageUrl: '',
        interestedInExchangeFor: ['Botellas de vidrio', 'Material de manualidades'],
        category: ArticleCategory.metal,
      ),
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    PostModel(
      id: '5',
      user: UserModel(
        id: 'user5',
        name: 'Usuario Prueba 5',
        profileImageUrl: '',
      ),
      article: ArticleModel(
        id: 'article5',
        title: 'Ropa usada en buen estado',
        description: 'Camisas, pantalones y vestidos en excelente condición. Perfectos para reutilizar.',
        imageUrl: '',
        interestedInExchangeFor: ['Telas', 'Botones', 'Accesorios'],
        category: ArticleCategory.textil,
      ),
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    PostModel(
      id: '6',
      user: UserModel(
        id: 'user6',
        name: 'Usuario Prueba 6',
        profileImageUrl: '',
      ),
      article: ArticleModel(
        id: 'article6',
        title: 'Electrodomésticos pequeños',
        description: 'Licuadora y tostadora que aún funcionan. Necesitan reparación menor.',
        imageUrl: '',
        interestedInExchangeFor: ['Repuestos', 'Herramientas'],
        category: ArticleCategory.electronico,
      ),
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  //ejemplo de chat
  static final List<ChatModel> chats = [];
}
