import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/colors.dart';
import '../models/post_model.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../screens/chat_detail_screen.dart';

class ChatButton extends StatelessWidget {
  final PostModel post;

  const ChatButton({
    super.key,
    required this.post,
  });

  Future<void> _openChat(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final chatService = ChatService();
    final currentUserId = authService.currentUser?.uid ?? '';

    if (currentUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para chatear'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // No permitir chatear con uno mismo
    if (currentUserId == post.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes chatear con tu propia publicación'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Crear o obtener el chat existente
      final chatId = await chatService.getOrCreateChat(
        currentUserId: currentUserId,
        otherUserId: post.userId,
        postId: post.id,
        postTitle: post.article.title,
        postImageUrl: post.article.imageUrl,
      );

      // Cerrar el diálogo de carga
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Navegar al chat
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(
              chatId: chatId,
              currentUserId: currentUserId,
            ),
          ),
        );
      }
    } catch (e) {
      // Cerrar el diálogo de carga si está abierto
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Mostrar error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir chat: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
