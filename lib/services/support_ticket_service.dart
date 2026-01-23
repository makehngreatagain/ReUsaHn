import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/support_ticket_model.dart';

class SupportTicketService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'support_tickets';

  // Crear un nuevo ticket
  Future<String> createTicket({
    required String userId,
    required String userName,
    required String userEmail,
    required String subject,
    required String description,
    required TicketCategory category,
    TicketPriority priority = TicketPriority.medium,
  }) async {
    try {
      final docRef = _firestore.collection(_collection).doc();
      final now = DateTime.now();

      final ticket = SupportTicketModel(
        id: docRef.id,
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        subject: subject,
        description: description,
        category: category,
        priority: priority,
        status: TicketStatus.open,
        messages: [],
        createdAt: now,
        updatedAt: now,
      );

      await docRef.set(ticket.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear ticket: $e');
    }
  }

  // Obtener tickets de un usuario
  Stream<List<SupportTicketModel>> getUserTickets(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SupportTicketModel.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  // Obtener todos los tickets (para admin)
  Stream<List<SupportTicketModel>> getAllTickets() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SupportTicketModel.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  // Obtener tickets por estado (para admin)
  Stream<List<SupportTicketModel>> getTicketsByStatus(TicketStatus status) {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SupportTicketModel.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  // Obtener un ticket específico
  Stream<SupportTicketModel?> getTicket(String ticketId) {
    return _firestore
        .collection(_collection)
        .doc(ticketId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return SupportTicketModel.fromJson(doc.data()!, doc.id);
      }
      return null;
    });
  }

  // Agregar mensaje a un ticket
  Future<void> addMessage({
    required String ticketId,
    required String senderId,
    required String senderName,
    required String message,
    required bool isAdmin,
  }) async {
    try {
      final ticketDoc = _firestore.collection(_collection).doc(ticketId);
      final ticketSnapshot = await ticketDoc.get();

      if (!ticketSnapshot.exists) {
        throw Exception('Ticket no encontrado');
      }

      final newMessage = TicketMessage(
        id: const Uuid().v4(),
        senderId: senderId,
        senderName: senderName,
        message: message,
        timestamp: DateTime.now(),
        isAdmin: isAdmin,
      );

      await ticketDoc.update({
        'messages': FieldValue.arrayUnion([newMessage.toJson()]),
        'updatedAt': FieldValue.serverTimestamp(),
        // Si un admin responde, cambiar estado a "en progreso"
        if (isAdmin && ticketSnapshot.data()?['status'] == 'open')
          'status': TicketStatus.inProgress.name,
      });
    } catch (e) {
      throw Exception('Error al agregar mensaje: $e');
    }
  }

  // Actualizar estado del ticket
  Future<void> updateTicketStatus(String ticketId, TicketStatus status) async {
    try {
      await _firestore.collection(_collection).doc(ticketId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al actualizar estado: $e');
    }
  }

  // Asignar admin a un ticket
  Future<void> assignAdmin({
    required String ticketId,
    required String adminId,
    required String adminName,
  }) async {
    try {
      await _firestore.collection(_collection).doc(ticketId).update({
        'assignedAdminId': adminId,
        'assignedAdminName': adminName,
        'status': TicketStatus.inProgress.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al asignar admin: $e');
    }
  }

  // Obtener estadísticas de tickets
  Future<Map<String, int>> getTicketStats() async {
    try {
      final allTickets = await _firestore.collection(_collection).get();

      int open = 0;
      int inProgress = 0;
      int resolved = 0;
      int closed = 0;

      for (var doc in allTickets.docs) {
        final status = doc.data()['status'] as String?;
        switch (status) {
          case 'open':
            open++;
            break;
          case 'inProgress':
            inProgress++;
            break;
          case 'resolved':
            resolved++;
            break;
          case 'closed':
            closed++;
            break;
        }
      }

      return {
        'total': allTickets.docs.length,
        'open': open,
        'inProgress': inProgress,
        'resolved': resolved,
        'closed': closed,
      };
    } catch (e) {
      return {
        'total': 0,
        'open': 0,
        'inProgress': 0,
        'resolved': 0,
        'closed': 0,
      };
    }
  }

  // Eliminar ticket (solo admin)
  Future<void> deleteTicket(String ticketId) async {
    try {
      await _firestore.collection(_collection).doc(ticketId).delete();
    } catch (e) {
      throw Exception('Error al eliminar ticket: $e');
    }
  }
}
