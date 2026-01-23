import 'package:cloud_firestore/cloud_firestore.dart';

enum TicketStatus {
  open('Abierto'),
  inProgress('En Progreso'),
  resolved('Resuelto'),
  closed('Cerrado');

  final String displayName;
  const TicketStatus(this.displayName);
}

enum TicketPriority {
  low('Baja'),
  medium('Media'),
  high('Alta');

  final String displayName;
  const TicketPriority(this.displayName);
}

enum TicketCategory {
  general('Consulta General'),
  technical('Problema Técnico'),
  account('Cuenta'),
  exchange('Intercambios'),
  suggestion('Sugerencia'),
  complaint('Queja');

  final String displayName;
  const TicketCategory(this.displayName);
}

class TicketMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final bool isAdmin;

  TicketMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    required this.isAdmin,
  });

  factory TicketMessage.fromJson(Map<String, dynamic> json) {
    return TicketMessage(
      id: json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      message: json['message'] ?? '',
      timestamp: json['timestamp'] is Timestamp
          ? (json['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      isAdmin: json['isAdmin'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isAdmin': isAdmin,
    };
  }
}

class SupportTicketModel {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String subject;
  final String description;
  final TicketCategory category;
  final TicketPriority priority;
  final TicketStatus status;
  final List<TicketMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? assignedAdminId;
  final String? assignedAdminName;

  SupportTicketModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.subject,
    required this.description,
    required this.category,
    this.priority = TicketPriority.medium,
    this.status = TicketStatus.open,
    this.messages = const [],
    required this.createdAt,
    required this.updatedAt,
    this.assignedAdminId,
    this.assignedAdminName,
  });

  factory SupportTicketModel.fromJson(Map<String, dynamic> json, String docId) {
    // Parse messages
    List<TicketMessage> messagesList = [];
    if (json['messages'] != null) {
      messagesList = (json['messages'] as List)
          .map((m) => TicketMessage.fromJson(m as Map<String, dynamic>))
          .toList();
    }

    // Parse category
    TicketCategory category = TicketCategory.general;
    if (json['category'] != null) {
      try {
        category = TicketCategory.values.firstWhere(
          (c) => c.name == json['category'],
          orElse: () => TicketCategory.general,
        );
      } catch (_) {}
    }

    // Parse priority
    TicketPriority priority = TicketPriority.medium;
    if (json['priority'] != null) {
      try {
        priority = TicketPriority.values.firstWhere(
          (p) => p.name == json['priority'],
          orElse: () => TicketPriority.medium,
        );
      } catch (_) {}
    }

    // Parse status
    TicketStatus status = TicketStatus.open;
    if (json['status'] != null) {
      try {
        status = TicketStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => TicketStatus.open,
        );
      } catch (_) {}
    }

    return SupportTicketModel(
      id: docId,
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userEmail: json['userEmail'] ?? '',
      subject: json['subject'] ?? '',
      description: json['description'] ?? '',
      category: category,
      priority: priority,
      status: status,
      messages: messagesList,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      assignedAdminId: json['assignedAdminId'],
      assignedAdminName: json['assignedAdminName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'subject': subject,
      'description': description,
      'category': category.name,
      'priority': priority.name,
      'status': status.name,
      'messages': messages.map((m) => m.toJson()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'assignedAdminId': assignedAdminId,
      'assignedAdminName': assignedAdminName,
    };
  }

  SupportTicketModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    String? subject,
    String? description,
    TicketCategory? category,
    TicketPriority? priority,
    TicketStatus? status,
    List<TicketMessage>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? assignedAdminId,
    String? assignedAdminName,
  }) {
    return SupportTicketModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      assignedAdminId: assignedAdminId ?? this.assignedAdminId,
      assignedAdminName: assignedAdminName ?? this.assignedAdminName,
    );
  }
}
