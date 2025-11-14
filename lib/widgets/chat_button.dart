import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../models/post_model.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../utils/dummy_data.dart';
import '../screens/chat_detail_screen.dart';

class ChatButton extends StatelessWidget {
  final PostModel post;

  const ChatButton({
    super.key,
    required this.post,
  });

  void _openChat(BuildContext context) {
    // Buscar si ya existe un chat con este usuario y artículo
    final existingChat = DummyData.chats.firstWhere(
      (chat) => chat.otherUser.id == post.user.id && chat.articleId == post.article.id,
      orElse: () {
        // Si no existe, crear un nuevo chat
        final newChat = ChatModel(
          id: 'chat_${DateTime.now().millisecondsSinceEpoch}',
          otherUser: post.user,
          articleTitle: post.article.title,
          articleId: post.article.id,
          messages: [
            MessageModel(
              id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
              senderId: post.user.id,
              text: 'Hola! Estoy interesado en tu publicación "${post.article.title}"',
              timestamp: DateTime.now(),
              isRead: false,
            ),
          ],
          lastMessageTime: DateTime.now(),
        );

        // Agregar el nuevo chat a la lista
        DummyData.chats.add(newChat);
        return newChat;
      },
    );

    // Navegar al detalle del chat
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(chat: existingChat),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _openChat(context),
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text('Iniciar Chat'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
