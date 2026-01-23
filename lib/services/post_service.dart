import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/post_model.dart';
import '../models/challenge_model.dart';
import 'challenge_service.dart';
import 'notification_service.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ChallengeService _challengeService = ChallengeService();
  final NotificationService _notificationService = NotificationService();

  // Crear un nuevo post (automáticamente en estado pending)
  Future<String> createPost(PostModel post) async {
    try {
      final docRef = await _firestore.collection('posts').add(post.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear publicación: ${e.toString()}');
    }
  }

  // Obtener todos los posts aprobados (para usuarios normales)
  Stream<List<PostModel>> getApprovedPosts() {
    return _firestore
        .collection('posts')
        .where('status', isEqualTo: 'approved')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final posts = <PostModel>[];

      for (var doc in snapshot.docs) {
        try {
          final post = await PostModel.fromJson(doc.data(), doc.id);
          posts.add(post);
        } catch (e) {
          // Error al cargar post - se omite silenciosamente
          // En producción se podría enviar a un servicio de logging como Sentry
        }
      }

      return posts;
    });
  }

  // Obtener posts pendientes de aprobación (solo para admins)
  Stream<List<PostModel>> getPendingPosts() {
    return _firestore
        .collection('posts')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .asyncMap((snapshot) async {
      final posts = <PostModel>[];

      for (var doc in snapshot.docs) {
        try {
          final post = await PostModel.fromJson(doc.data(), doc.id);
          posts.add(post);
        } catch (e) {
          // Error al cargar post pendiente - se omite silenciosamente
          // En producción se podría enviar a un servicio de logging como Sentry
        }
      }

      return posts;
    });
  }

  // Obtener todos los posts (solo para admins)
  Stream<List<PostModel>> getAllPosts() {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final posts = <PostModel>[];

      for (var doc in snapshot.docs) {
        try {
          final post = await PostModel.fromJson(doc.data(), doc.id);
          posts.add(post);
        } catch (e) {
          // Error al cargar post - se omite silenciosamente
        }
      }

      return posts;
    });
  }

  // Obtener posts de un usuario específico
  Stream<List<PostModel>> getUserPosts(String userId) {
    return _firestore
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final posts = <PostModel>[];

      for (var doc in snapshot.docs) {
        try {
          final post = await PostModel.fromJson(doc.data(), doc.id);
          posts.add(post);
        } catch (e) {
          // Error al cargar post del usuario - se omite silenciosamente
          // En producción se podría enviar a un servicio de logging como Sentry
        }
      }

      return posts;
    });
  }

  // Aprobar un post (solo admins)
  Future<void> approvePost(String postId, String adminId) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'status': 'approved',
        'reviewedBy': adminId,
        'reviewedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Enviar notificación al usuario
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      final postData = postDoc.data();
      if (postData != null) {
        final userId = postData['userId'] as String;
        final postTitle = postData['title'] as String? ?? 'Sin título';

        // Crear notificación en el buzón
        await _notificationService.createPublicationNotification(
          userId: userId,
          postTitle: postTitle,
          postId: postId,
        );

        // También enviar notificación push
        await _createNotification(
          userId: userId,
          title: 'Publicación Aprobada',
          message: 'Tu publicación "$postTitle" ha sido aprobada y ahora es visible para todos.',
          type: 'post_approved',
          relatedId: postId,
        );

        // Actualizar progreso de retos de "hacer publicaciones"
        await _updatePublicationChallenges(userId);
      }
    } catch (e) {
      throw Exception('Error al aprobar publicación: ${e.toString()}');
    }
  }

  // Actualizar progreso de retos de hacer publicaciones
  Future<void> _updatePublicationChallenges(String userId) async {
    try {
      debugPrint('🔍 Actualizando retos de publicaciones para usuario: $userId');

      // Obtener todos los retos activos de tipo "makePublications"
      final challengesSnapshot = await _firestore
          .collection('challenges')
          .where('isActive', isEqualTo: true)
          .where('type', isEqualTo: ChallengeType.makePublications.name)
          .get();

      debugPrint('📋 Retos de publicaciones encontrados: ${challengesSnapshot.docs.length}');

      // Contar las publicaciones aprobadas del usuario
      final postsSnapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'approved')
          .get();

      final approvedPostsCount = postsSnapshot.docs.length;
      debugPrint('✅ Publicaciones aprobadas del usuario: $approvedPostsCount');

      // Actualizar el progreso de cada reto de publicaciones
      for (var challengeDoc in challengesSnapshot.docs) {
        final challengeData = challengeDoc.data();
        final targetCount = challengeData['targetCount'] as int? ?? 1;
        debugPrint('🎯 Actualizando reto: ${challengeData['title']} - Progreso: $approvedPostsCount/$targetCount');

        await _challengeService.updateAutomaticProgress(
          userId: userId,
          challengeId: challengeDoc.id,
          newCount: approvedPostsCount,
          targetCount: targetCount,
        );
      }

      debugPrint('✨ Actualización de retos completada');
    } catch (e) {
      // Error al actualizar retos - no es crítico, continuar
      debugPrint('❌ Error al actualizar retos de publicaciones: $e');
    }
  }

  // Rechazar un post (solo admins)
  Future<void> rejectPost(String postId, String adminId, String reason) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'status': 'rejected',
        'reviewedBy': adminId,
        'reviewedAt': FieldValue.serverTimestamp(),
        'rejectionReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Enviar notificación al usuario
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      final postData = postDoc.data();
      if (postData != null) {
        final userId = postData['userId'] as String;
        await _createNotification(
          userId: userId,
          title: 'Publicación Rechazada',
          message: 'Tu publicación ha sido rechazada. Razón: $reason',
          type: 'post_rejected',
          relatedId: postId,
        );
      }
    } catch (e) {
      throw Exception('Error al rechazar publicación: ${e.toString()}');
    }
  }

  // Eliminar un post
  Future<void> deletePost(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).delete();
    } catch (e) {
      throw Exception('Error al eliminar publicación: ${e.toString()}');
    }
  }

  // Actualizar un post
  Future<void> updatePost(String postId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('posts').doc(postId).update(updates);
    } catch (e) {
      throw Exception('Error al actualizar publicación: ${e.toString()}');
    }
  }

  // Obtener un post por ID
  Future<PostModel?> getPostById(String postId) async {
    try {
      final doc = await _firestore.collection('posts').doc(postId).get();

      if (!doc.exists) return null;

      return await PostModel.fromJson(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Error al obtener publicación: ${e.toString()}');
    }
  }

  // Obtener estadísticas de posts de un usuario
  Future<Map<String, int>> getUserPostStats(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .get();

      int approved = 0;
      int pending = 0;
      int rejected = 0;

      for (var doc in snapshot.docs) {
        final status = doc.data()['status'] as String?;
        if (status == 'approved') approved++;
        if (status == 'pending') pending++;
        if (status == 'rejected') rejected++;
      }

      return {
        'total': snapshot.docs.length,
        'approved': approved,
        'pending': pending,
        'rejected': rejected,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas: ${e.toString()}');
    }
  }

  // Método auxiliar para crear notificaciones
  Future<void> _createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? relatedId,
  }) async {
    try {
      // Usar el NotificationService para enviar notificaciones push
      await _notificationService.sendNotificationToUser(
        userId: userId,
        title: title,
        body: message,
        type: type,
        data: relatedId != null ? {'relatedId': relatedId} : null,
      );
    } catch (e) {
      // Error al crear notificación - se omite silenciosamente
      // No es crítico si falla, el usuario puede revisar el estado del post directamente
    }
  }
}
