import 'user_model.dart';
import 'message_model.dart';

class ChatModel {
  final String id;
  final UserModel otherUser; // El usuario con quien estás chateando
  final String articleTitle; // Título de la publicación
  final String articleId; // ID de la publicación
  final List<MessageModel> messages;
  final DateTime lastMessageTime;

  ChatModel({
    required this.id,
    required this.otherUser,
    required this.articleTitle,
    required this.articleId,
    required this.messages,
    required this.lastMessageTime,
  });

  // Obtener el último mensaje
  String get lastMessage {
    if (messages.isEmpty) return 'Sin mensajes';
    return messages.last.text;
  }

  // Cantidad de mensajes no leídos
  int get unreadCount {
    return messages.where((msg) => !msg.isRead && msg.senderId == otherUser.id).length;
  }
}
