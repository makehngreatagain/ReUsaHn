import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import 'notification_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Crear o obtener un chat existente entre dos usuarios sobre una publicación
  Future<String> getOrCreateChat({
    required String currentUserId,
    required String otherUserId,
    required String postId,
    required String postTitle,
    String? postImageUrl,
  }) async {
    try {
      // Buscar si ya existe un chat entre estos usuarios sobre esta publicación
      final existingChats = await _firestore
          .collection('chats')
          .where('participantIds', arrayContains: currentUserId)
          .where('postId', isEqualTo: postId)
          .get();

      for (var doc in existingChats.docs) {
        final chat = ChatModel.fromJson(doc.data(), doc.id);
        if (chat.participantIds.contains(otherUserId)) {
          return doc.id; // Chat ya existe
        }
      }

      // Si no existe, crear uno nuevo
      final newChat = ChatModel(
        id: '',
        participantIds: [currentUserId, otherUserId],
        postId: postId,
        postTitle: postTitle,
        postImageUrl: postImageUrl,
        lastMessage: 'Conversación iniciada',
        lastMessageSenderId: currentUserId,
        lastMessageTime: DateTime.now(),
        unreadCount: {
          currentUserId: 0,
          otherUserId: 0,
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await _firestore.collection('chats').add(newChat.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear/obtener chat: ${e.toString()}');
    }
  }

  // Obtener todos los chats de un usuario
  Stream<List<ChatModel>> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participantIds', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatModel.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  // Obtener un chat específico
  Stream<ChatModel?> getChat(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return ChatModel.fromJson(doc.data()!, doc.id);
    });
  }

  // Obtener mensajes de un chat
  Stream<List<MessageModel>> getChatMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  // Enviar un mensaje
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
    String? imageUrl,
  }) async {
    try {
      final message = MessageModel(
        id: '',
        senderId: senderId,
        text: text,
        timestamp: DateTime.now(),
        isRead: false,
        imageUrl: imageUrl,
      );

      // Agregar mensaje a la subcolección
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(message.toJson());

      // Obtener el chat actual para actualizar unreadCount
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      final chat = ChatModel.fromJson(chatDoc.data()!, chatId);

      // Incrementar contador de no leídos del otro usuario
      final otherUserId = chat.getOtherUserId(senderId);
      final updatedUnreadCount = Map<String, int>.from(chat.unreadCount);
      updatedUnreadCount[otherUserId] = (updatedUnreadCount[otherUserId] ?? 0) + 1;

      // Actualizar el chat con el último mensaje
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': text.isEmpty ? '📷 Imagen' : text,
        'lastMessageSenderId': senderId,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': updatedUnreadCount,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Enviar notificación al otro usuario
      final senderDoc = await _firestore.collection('users').doc(senderId).get();
      final senderName = senderDoc.data()?['name'] as String? ?? 'Alguien';

      await _notificationService.sendNotificationToUser(
        userId: otherUserId,
        title: senderName,
        body: text.isEmpty ? '📷 Te envió una imagen' : text,
        type: 'chat_message',
        data: {
          'chatId': chatId,
          'senderId': senderId,
        },
      );
    } catch (e) {
      throw Exception('Error al enviar mensaje: ${e.toString()}');
    }
  }

  // Marcar mensajes como leídos
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      // Obtener mensajes no leídos del otro usuario
      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      // Marcar cada mensaje como leído
      final batch = _firestore.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      // Resetear contador de no leídos del usuario actual
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (!chatDoc.exists) return;

      final chat = ChatModel.fromJson(chatDoc.data()!, chatId);
      final updatedUnreadCount = Map<String, int>.from(chat.unreadCount);
      updatedUnreadCount[userId] = 0;

      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount': updatedUnreadCount,
      });
    } catch (e) {
      // Error al marcar mensajes como leídos - se omite silenciosamente
    }
  }

  // Eliminar un chat
  Future<void> deleteChat(String chatId) async {
    try {
      // Eliminar todos los mensajes primero
      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      final batch = _firestore.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Eliminar el chat
      await _firestore.collection('chats').doc(chatId).delete();
    } catch (e) {
      throw Exception('Error al eliminar chat: ${e.toString()}');
    }
  }

  // Obtener el contador total de mensajes no leídos de un usuario
  Stream<int> getTotalUnreadCount(String userId) {
    return _firestore
        .collection('chats')
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      int total = 0;
      for (var doc in snapshot.docs) {
        final chat = ChatModel.fromJson(doc.data(), doc.id);
        total += chat.getUnreadCountForUser(userId);
      }
      return total;
    });
  }
}
