import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/challenge_model.dart';
import '../models/challenge_completion_model.dart';
import 'storage_service.dart';
import 'notification_service.dart';

class ChallengeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();
  final NotificationService _notificationService = NotificationService();

  // ============ GESTIÓN DE RETOS (PLANTILLAS) ============

  // Obtener todos los retos activos
  Stream<List<ChallengeModel>> getActiveChallenges() {
    return _firestore
        .collection('challenges')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChallengeModel.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  // Obtener todos los retos (activos e inactivos)
  Stream<List<ChallengeModel>> getAllChallenges() {
    return _firestore
        .collection('challenges')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChallengeModel.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  // Obtener un reto específico
  Future<ChallengeModel?> getChallengeById(String challengeId) async {
    try {
      final doc = await _firestore.collection('challenges').doc(challengeId).get();
      if (!doc.exists) return null;
      return ChallengeModel.fromJson(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Error al obtener reto: ${e.toString()}');
    }
  }

  // Crear un nuevo reto (solo admin)
  Future<String> createChallenge(ChallengeModel challenge) async {
    try {
      final docRef = await _firestore.collection('challenges').add(challenge.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear reto: ${e.toString()}');
    }
  }

  // Actualizar un reto existente (solo admin)
  Future<void> updateChallenge(String challengeId, ChallengeModel challenge) async {
    try {
      await _firestore.collection('challenges').doc(challengeId).update(challenge.toJson());
    } catch (e) {
      throw Exception('Error al actualizar reto: ${e.toString()}');
    }
  }

  // Eliminar un reto (solo admin)
  Future<void> deleteChallenge(String challengeId) async {
    try {
      await _firestore.collection('challenges').doc(challengeId).delete();
    } catch (e) {
      throw Exception('Error al eliminar reto: ${e.toString()}');
    }
  }

  // Activar/desactivar un reto (solo admin)
  Future<void> toggleChallengeStatus(String challengeId, bool isActive) async {
    try {
      await _firestore.collection('challenges').doc(challengeId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al cambiar estado del reto: ${e.toString()}');
    }
  }

  // Resetear progreso de todos los usuarios en un reto específico (solo admin)
  Future<void> resetChallengeProgress(String challengeId) async {
    try {
      final completions = await _firestore
          .collection('challenge_completions')
          .where('challengeId', isEqualTo: challengeId)
          .get();

      final batch = _firestore.batch();
      for (var doc in completions.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Error al resetear progreso del reto: ${e.toString()}');
    }
  }

  // Resetear progreso de un usuario específico en un reto (solo admin)
  Future<void> resetUserChallengeProgress(String completionId) async {
    try {
      await _firestore.collection('challenge_completions').doc(completionId).delete();
    } catch (e) {
      throw Exception('Error al resetear progreso del usuario: ${e.toString()}');
    }
  }

  // ============ PROGRESO DEL USUARIO EN RETOS ============

  // Obtener o crear progreso de un usuario en un reto
  Future<ChallengeCompletionModel> getOrCreateUserProgress({
    required String userId,
    required String challengeId,
  }) async {
    try {
      // Buscar si ya existe un progreso para este usuario y reto
      final querySnapshot = await _firestore
          .collection('challenge_completions')
          .where('userId', isEqualTo: userId)
          .where('challengeId', isEqualTo: challengeId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Ya existe, retornar
        final doc = querySnapshot.docs.first;
        return ChallengeCompletionModel.fromJson(doc.data(), doc.id);
      }

      // No existe, crear uno nuevo
      final newCompletion = ChallengeCompletionModel(
        id: '',
        userId: userId,
        challengeId: challengeId,
        currentCount: 0,
        status: CompletionStatus.inProgress,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection('challenge_completions')
          .add(newCompletion.toJson());

      return newCompletion.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Error al obtener progreso del reto: ${e.toString()}');
    }
  }

  // Obtener todos los progresos de un usuario
  Stream<List<ChallengeCompletionModel>> getUserChallengeProgress(String userId) {
    return _firestore
        .collection('challenge_completions')
        .where('userId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChallengeCompletionModel.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  // Actualizar progreso automático (para retos como "hacer publicaciones")
  Future<void> updateAutomaticProgress({
    required String userId,
    required String challengeId,
    required int newCount,
    required int targetCount,
  }) async {
    try {
      final progress = await getOrCreateUserProgress(
        userId: userId,
        challengeId: challengeId,
      );

      // Si ya completó este reto, no hacer nada
      if (progress.isCompleted) return;

      // Actualizar el conteo
      final updates = <String, dynamic>{
        'currentCount': newCount,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Si alcanzó el objetivo, marcarlo como aprobado (listo para reclamar)
      if (newCount >= targetCount && progress.status == CompletionStatus.inProgress) {
        // Marcar como aprobado, el usuario deberá reclamar los puntos manualmente
        updates['status'] = CompletionStatus.approved.name;
        updates['completedAt'] = FieldValue.serverTimestamp();
        updates['reviewedAt'] = FieldValue.serverTimestamp();
        updates['notes'] = 'Completado automáticamente al aprobar publicaciones. Reclama tus puntos en la pantalla de Retos.';
      }

      // Si no se completó, solo actualizar el progreso
      await _firestore
          .collection('challenge_completions')
          .doc(progress.id)
          .update(updates);
    } catch (e) {
      throw Exception('Error al actualizar progreso: ${e.toString()}');
    }
  }

  // Enviar evidencia para retos que requieren aprobación
  Future<void> submitProof({
    required String userId,
    required String challengeId,
    required List<File> proofImages,
  }) async {
    try {
      final progress = await getOrCreateUserProgress(
        userId: userId,
        challengeId: challengeId,
      );

      // Subir imágenes a Firebase Storage
      final imageUrls = <String>[];
      for (final image in proofImages) {
        final url = await _storageService.uploadChallengeProof(
          image,
          userId,
          challengeId,
        );
        imageUrls.add(url);
      }

      // Actualizar el progreso con las imágenes y cambiar estado
      await _firestore.collection('challenge_completions').doc(progress.id).update({
        'proofImageUrls': FieldValue.arrayUnion(imageUrls),
        'status': CompletionStatus.pendingApproval.name,
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al enviar evidencia: ${e.toString()}');
    }
  }

  // ============ PANEL DE ADMIN - REVISIÓN DE EVIDENCIAS ============

  // Obtener todos los retos pendientes de aprobación
  Stream<List<ChallengeCompletionModel>> getPendingApprovals() {
    return _firestore
        .collection('challenge_completions')
        .where('status', isEqualTo: CompletionStatus.pendingApproval.name)
        .orderBy('completedAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChallengeCompletionModel.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  // Aprobar evidencia de reto
  Future<void> approveChallenge({
    required String completionId,
    required String adminId,
  }) async {
    try {
      await _firestore.collection('challenge_completions').doc(completionId).update({
        'status': CompletionStatus.approved.name,
        'reviewedBy': adminId,
        'reviewedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al aprobar reto: ${e.toString()}');
    }
  }

  // Rechazar evidencia de reto
  Future<void> rejectChallenge({
    required String completionId,
    required String adminId,
    required String reason,
  }) async {
    try {
      await _firestore.collection('challenge_completions').doc(completionId).update({
        'status': CompletionStatus.rejected.name,
        'reviewedBy': adminId,
        'reviewedAt': FieldValue.serverTimestamp(),
        'rejectionReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al rechazar reto: ${e.toString()}');
    }
  }

  // ============ RECLAMAR PUNTOS ============

  // Reclamar puntos de un reto completado y aprobado
  Future<void> claimReward({
    required String userId,
    required String completionId,
    required int pointsReward,
  }) async {
    try {
      String challengeId = '';

      // Usar transacción para asegurar consistencia
      await _firestore.runTransaction((transaction) async {
        // Obtener el progreso del reto
        final completionRef = _firestore.collection('challenge_completions').doc(completionId);
        final completionDoc = await transaction.get(completionRef);

        if (!completionDoc.exists) {
          throw Exception('El reto no existe');
        }

        final completion = ChallengeCompletionModel.fromJson(
          completionDoc.data()!,
          completionDoc.id,
        );

        challengeId = completion.challengeId;

        // Verificar que esté aprobado y no reclamado
        if (completion.status != CompletionStatus.approved) {
          throw Exception('El reto no está aprobado');
        }

        if (completion.isCompleted) {
          throw Exception('Los puntos ya fueron reclamados');
        }

        // Marcar como reclamado
        transaction.update(completionRef, {
          'status': CompletionStatus.claimed.name,
          'claimedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Actualizar puntos del usuario
        final userRef = _firestore.collection('users').doc(userId);
        transaction.update(userRef, {
          'greenPoints': FieldValue.increment(pointsReward),
          'challengesCompleted': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      // Obtener el título del reto para la notificación
      String challengeTitle = 'Reto';
      if (challengeId.isNotEmpty) {
        final challengeDoc = await _firestore
            .collection('challenges')
            .doc(challengeId)
            .get();
        if (challengeDoc.exists) {
          challengeTitle = challengeDoc.data()?['title'] as String? ?? 'Reto';
        }
      }

      // Crear notificación en el buzón
      await _notificationService.createChallengeNotification(
        userId: userId,
        challengeTitle: challengeTitle,
        pointsEarned: pointsReward,
        challengeId: challengeId,
      );
    } catch (e) {
      throw Exception('Error al reclamar puntos: ${e.toString()}');
    }
  }

  // ============ ESTADÍSTICAS ============

  // Obtener estadísticas de retos de un usuario
  Future<Map<String, int>> getUserChallengeStats(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('challenge_completions')
          .where('userId', isEqualTo: userId)
          .get();

      int inProgress = 0;
      int completed = 0;
      int pending = 0;

      for (var doc in snapshot.docs) {
        final completion = ChallengeCompletionModel.fromJson(doc.data(), doc.id);
        switch (completion.status) {
          case CompletionStatus.inProgress:
            inProgress++;
            break;
          case CompletionStatus.pendingApproval:
            pending++;
            break;
          case CompletionStatus.claimed:
            completed++;
            break;
          case CompletionStatus.approved:
            // Aprobado pero no reclamado, contar como pendiente
            pending++;
            break;
          case CompletionStatus.rejected:
            // No contar rechazados
            break;
        }
      }

      return {
        'inProgress': inProgress,
        'completed': completed,
        'pending': pending,
        'total': snapshot.docs.length,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas: ${e.toString()}');
    }
  }
}
