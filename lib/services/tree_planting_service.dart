import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tree_planting_model.dart';
import 'notification_service.dart';

class TreePlantingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Obtener todos los árboles aprobados en tiempo real
  Stream<List<TreePlantingModel>> getApprovedTrees() {
    return _firestore
        .collection('tree_plantings')
        .where('status', isEqualTo: 'approved')
        .orderBy('plantedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TreePlantingModel.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  // Obtener árboles de un usuario específico
  Stream<List<TreePlantingModel>> getUserTrees(String userId) {
    return _firestore
        .collection('tree_plantings')
        .where('userId', isEqualTo: userId)
        .orderBy('plantedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TreePlantingModel.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  // Obtener árboles de una zona verde específica
  Stream<List<TreePlantingModel>> getZoneTrees(String greenZoneId) {
    return _firestore
        .collection('tree_plantings')
        .where('greenZoneId', isEqualTo: greenZoneId)
        .where('status', isEqualTo: 'approved')
        .orderBy('plantedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TreePlantingModel.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  // Obtener árboles pendientes de aprobación (para admin)
  Stream<List<TreePlantingModel>> getPendingTrees() {
    return _firestore
        .collection('tree_plantings')
        .where('status', isEqualTo: 'pending')
        .orderBy('plantedAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TreePlantingModel.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  // Obtener todos los árboles (para admin)
  Stream<List<TreePlantingModel>> getAllTrees() {
    return _firestore
        .collection('tree_plantings')
        .orderBy('plantedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TreePlantingModel.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  // Obtener un árbol por ID
  Future<TreePlantingModel?> getTreeById(String treeId) async {
    try {
      final doc = await _firestore.collection('tree_plantings').doc(treeId).get();
      if (!doc.exists) return null;
      return TreePlantingModel.fromJson(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Error al obtener árbol: ${e.toString()}');
    }
  }

  // Registrar plantación de árbol (usuario)
  Future<String> plantTree({
    required String userId,
    required String userName,
    required String userProfileImageUrl,
    required String greenZoneId,
    required String greenZoneName,
    required double latitude,
    required double longitude,
    required String photoUrl,
    String notes = '',
  }) async {
    try {
      final docRef = await _firestore.collection('tree_plantings').add({
        'userId': userId,
        'userName': userName,
        'userProfileImageUrl': userProfileImageUrl,
        'greenZoneId': greenZoneId,
        'greenZoneName': greenZoneName,
        'latitude': latitude,
        'longitude': longitude,
        'photoUrl': photoUrl,
        'notes': notes,
        'status': 'pending',
        'plantedAt': FieldValue.serverTimestamp(),
        'reviewedAt': null,
        'reviewedBy': null,
        'reviewNotes': null,
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Error al registrar árbol: ${e.toString()}');
    }
  }

  // Aprobar árbol (admin) y dar puntos al usuario
  Future<void> approveTree(String treeId, String adminId, {String? notes}) async {
    try {
      String userId = '';
      String photoUrl = '';

      await _firestore.runTransaction((transaction) async {
        // Obtener el documento del árbol
        final treeDoc = await transaction.get(
          _firestore.collection('tree_plantings').doc(treeId),
        );

        if (!treeDoc.exists) {
          throw Exception('Árbol no encontrado');
        }

        final treeData = treeDoc.data()!;
        userId = treeData['userId'] as String;
        photoUrl = treeData['photoUrl'] as String;

        // Actualizar estado del árbol
        transaction.update(
          _firestore.collection('tree_plantings').doc(treeId),
          {
            'status': 'approved',
            'reviewedAt': FieldValue.serverTimestamp(),
            'reviewedBy': adminId,
            'reviewNotes': notes,
          },
        );

        // Dar puntos verdes al usuario (50 puntos por plantar un árbol)
        final userDoc = _firestore.collection('users').doc(userId);
        transaction.update(userDoc, {
          'greenPoints': FieldValue.increment(50),
        });
      });

      // Después de la transacción, completar retos activos de tipo plantTree
      await _completeTreePlantingChallenges(userId, photoUrl);

      // Crear notificación en el buzón
      await _notificationService.createTreeNotification(
        userId: userId,
        pointsEarned: 50,
        treeId: treeId,
      );

      // También enviar notificación push
      await _notificationService.sendNotificationToUser(
        userId: userId,
        title: '¡Árbol Aprobado!',
        body: 'Tu árbol plantado ha sido aprobado. Has ganado 50 puntos verdes.',
        type: 'tree_approved',
        data: {'treeId': treeId},
      );
    } catch (e) {
      throw Exception('Error al aprobar árbol: ${e.toString()}');
    }
  }

  // Completar retos de plantación de árboles del usuario
  Future<void> _completeTreePlantingChallenges(String userId, String photoUrl) async {
    try {
      // Buscar todos los retos activos de tipo 'plantTree'
      final challengesSnapshot = await _firestore
          .collection('challenges')
          .where('type', isEqualTo: 'plantTree')
          .where('isActive', isEqualTo: true)
          .get();

      for (var challengeDoc in challengesSnapshot.docs) {
        final challengeId = challengeDoc.id;
        final challengeData = challengeDoc.data();
        final targetCount = challengeData['targetCount'] as int;

        // Buscar si el usuario tiene este reto (en cualquier estado)
        final userChallengeSnapshot = await _firestore
            .collection('challenge_completions')
            .where('userId', isEqualTo: userId)
            .where('challengeId', isEqualTo: challengeId)
            .limit(1)
            .get();

        if (userChallengeSnapshot.docs.isNotEmpty) {
          // El usuario ya tiene este reto
          final userChallengeDoc = userChallengeSnapshot.docs.first;
          final userChallengeData = userChallengeDoc.data();
          final status = userChallengeData['status'] as String;

          // Solo actualizar si está en progreso
          if (status == 'inProgress') {
            final currentCount = userChallengeData['currentCount'] as int;
            final newCount = currentCount + 1;

            // Actualizar progreso
            if (newCount >= targetCount) {
              // Completar el reto y marcarlo listo para reclamar
              await _firestore
                  .collection('challenge_completions')
                  .doc(userChallengeDoc.id)
                  .update({
                'currentCount': newCount,
                'status': 'approved',
                'completedAt': FieldValue.serverTimestamp(),
                'reviewedAt': FieldValue.serverTimestamp(),
                'notes': 'Completado automáticamente al plantar árbol en zona verde. Reclama tus puntos en la pantalla de Retos.',
                'updatedAt': FieldValue.serverTimestamp(),
              });
            } else {
              // Solo actualizar progreso
              await _firestore
                  .collection('challenge_completions')
                  .doc(userChallengeDoc.id)
                  .update({
                'currentCount': newCount,
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }
          }
        } else {
          // El usuario NO tiene este reto, iniciarlo automáticamente
          final newCount = 1;

          if (newCount >= targetCount) {
            // Si con 1 árbol ya completó el reto, marcarlo como aprobado
            await _firestore.collection('challenge_completions').add({
              'userId': userId,
              'challengeId': challengeId,
              'currentCount': newCount,
              'status': 'approved',
              'completedAt': FieldValue.serverTimestamp(),
              'reviewedAt': FieldValue.serverTimestamp(),
              'notes': 'Completado automáticamente al plantar árbol en zona verde. Reclama tus puntos en la pantalla de Retos.',
              'proofImageUrls': [photoUrl],
              'rejectionReason': null,
              'reviewedBy': null,
              'claimedAt': null,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          } else {
            // Iniciar el reto con progreso 1
            await _firestore.collection('challenge_completions').add({
              'userId': userId,
              'challengeId': challengeId,
              'currentCount': newCount,
              'status': 'inProgress',
              'completedAt': null,
              'reviewedAt': null,
              'notes': null,
              'proofImageUrls': [photoUrl],
              'rejectionReason': null,
              'reviewedBy': null,
              'claimedAt': null,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      }
    } catch (e) {
      // No lanzar error para no afectar la aprobación del árbol
      // El error se registra pero no se propaga
    }
  }

  // Rechazar árbol (admin)
  Future<void> rejectTree(String treeId, String adminId, {String? notes}) async {
    try {
      await _firestore.collection('tree_plantings').doc(treeId).update({
        'status': 'rejected',
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': adminId,
        'reviewNotes': notes ?? 'No cumple con los requisitos',
      });
    } catch (e) {
      throw Exception('Error al rechazar árbol: ${e.toString()}');
    }
  }

  // Eliminar árbol (admin)
  Future<void> deleteTree(String treeId) async {
    try {
      await _firestore.collection('tree_plantings').doc(treeId).delete();
    } catch (e) {
      throw Exception('Error al eliminar árbol: ${e.toString()}');
    }
  }

  // Obtener estadísticas de árboles
  Future<Map<String, int>> getTreeStats() async {
    try {
      final allTrees = await _firestore.collection('tree_plantings').get();

      int total = allTrees.docs.length;
      int approved = 0;
      int pending = 0;
      int rejected = 0;

      for (var doc in allTrees.docs) {
        final status = doc.data()['status'] as String;
        if (status == 'approved') {
          approved++;
        } else if (status == 'pending') {
          pending++;
        } else if (status == 'rejected') {
          rejected++;
        }
      }

      return {
        'total': total,
        'approved': approved,
        'pending': pending,
        'rejected': rejected,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas: ${e.toString()}');
    }
  }
}
