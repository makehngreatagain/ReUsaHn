import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final List<String> participantIds; // IDs de los usuarios participantes
  final String postId; // ID de la publicación relacionada
  final String postTitle; // Título de la publicación para mostrar
  final String? postImageUrl; // Imagen de la publicación
  final String lastMessage; // Último mensaje enviado
  final String lastMessageSenderId; // ID del que envió el último mensaje
  final DateTime lastMessageTime; // Timestamp del último mensaje
  final Map<String, int> unreadCount; // Contador de no leídos por usuario {userId: count}
  final Map<String, bool>? typingStatus; // Estado de escritura por usuario {userId: isTyping}
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatModel({
    required this.id,
    required this.participantIds,
    required this.postId,
    required this.postTitle,
    this.postImageUrl,
    required this.lastMessage,
    required this.lastMessageSenderId,
    required this.lastMessageTime,
    required this.unreadCount,
    this.typingStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  // Obtener el ID del otro usuario en el chat
  String getOtherUserId(String currentUserId) {
    return participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  // Obtener cantidad de mensajes no leídos para un usuario específico
  int getUnreadCountForUser(String userId) {
    return unreadCount[userId] ?? 0;
  }

  // Verificar si el otro usuario está escribiendo
  bool isOtherUserTyping(String currentUserId) {
    if (typingStatus == null) return false;
    final otherUserId = getOtherUserId(currentUserId);
    return typingStatus![otherUserId] ?? false;
  }

  // Convertir a JSON para Firestore
  Map<String, dynamic> toJson() {
    return {
      'participantIds': participantIds,
      'postId': postId,
      'postTitle': postTitle,
      'postImageUrl': postImageUrl,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'unreadCount': unreadCount,
      'typingStatus': typingStatus ?? {},
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Crear desde JSON de Firestore
  factory ChatModel.fromJson(Map<String, dynamic> json, String id) {
    return ChatModel(
      id: id,
      participantIds: List<String>.from(json['participantIds'] as List? ?? []),
      postId: json['postId'] as String? ?? '',
      postTitle: json['postTitle'] as String? ?? '',
      postImageUrl: json['postImageUrl'] as String?,
      lastMessage: json['lastMessage'] as String? ?? '',
      lastMessageSenderId: json['lastMessageSenderId'] as String? ?? '',
      lastMessageTime: (json['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCount: Map<String, int>.from(json['unreadCount'] as Map? ?? {}),
      typingStatus: Map<String, bool>.from(json['typingStatus'] as Map? ?? {}),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Crear copia con campos actualizados
  ChatModel copyWith({
    String? id,
    List<String>? participantIds,
    String? postId,
    String? postTitle,
    String? postImageUrl,
    String? lastMessage,
    String? lastMessageSenderId,
    DateTime? lastMessageTime,
    Map<String, int>? unreadCount,
    Map<String, bool>? typingStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatModel(
      id: id ?? this.id,
      participantIds: participantIds ?? this.participantIds,
      postId: postId ?? this.postId,
      postTitle: postTitle ?? this.postTitle,
      postImageUrl: postImageUrl ?? this.postImageUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      typingStatus: typingStatus ?? this.typingStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
