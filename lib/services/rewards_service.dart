import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reward_model.dart';
import '../models/reward_redemption_model.dart';

class RewardsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener todas las recompensas activas
  Stream<List<RewardModel>> getActiveRewards() {
    return _firestore
        .collection('rewards')
        .where('isActive', isEqualTo: true)
        .where('stock', isGreaterThan: 0)
        .orderBy('stock')
        .orderBy('pointsCost')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RewardModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  // Obtener todas las recompensas (para admin)
  Stream<List<RewardModel>> getAllRewards() {
    return _firestore
        .collection('rewards')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RewardModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  // Obtener recompensa por ID
  Future<RewardModel?> getRewardById(String rewardId) async {
    try {
      final doc = await _firestore.collection('rewards').doc(rewardId).get();
      if (!doc.exists) {
        return null;
      }
      return RewardModel.fromMap(doc.id, doc.data()!);
    } catch (e) {
      throw Exception('Error al obtener recompensa: ${e.toString()}');
    }
  }

  // Crear nueva recompensa (admin)
  Future<String> createReward({
    required String name,
    required String description,
    required int pointsCost,
    required String imageUrl,
    required int stock,
    required RewardCategory category,
  }) async {
    try {
      final docRef = await _firestore.collection('rewards').add({
        'name': name,
        'description': description,
        'pointsCost': pointsCost,
        'imageUrl': imageUrl,
        'stock': stock,
        'category': category.name,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': null,
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear recompensa: ${e.toString()}');
    }
  }

  // Actualizar recompensa (admin)
  Future<void> updateReward(String rewardId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('rewards').doc(rewardId).update(updates);
    } catch (e) {
      throw Exception('Error al actualizar recompensa: ${e.toString()}');
    }
  }

  // Activar/Desactivar recompensa (admin)
  Future<void> toggleRewardStatus(String rewardId, bool isActive) async {
    try {
      await _firestore.collection('rewards').doc(rewardId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al cambiar estado: ${e.toString()}');
    }
  }

  // Actualizar stock (admin)
  Future<void> updateStock(String rewardId, int newStock) async {
    try {
      await _firestore.collection('rewards').doc(rewardId).update({
        'stock': newStock,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al actualizar stock: ${e.toString()}');
    }
  }

  // Canjear recompensa (usuario)
  Future<void> redeemReward({
    required String userId,
    required String userName,
    required String userEmail,
    required String rewardId,
    required String rewardName,
    required int pointsCost,
    String? deliveryAddress,
    String? phoneNumber,
    String? notes,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // Verificar stock de la recompensa
        final rewardDoc = await transaction.get(
          _firestore.collection('rewards').doc(rewardId),
        );

        if (!rewardDoc.exists) {
          throw Exception('La recompensa no existe');
        }

        final rewardData = rewardDoc.data()!;
        final currentStock = rewardData['stock'] as int;
        final isActive = rewardData['isActive'] as bool;

        if (!isActive) {
          throw Exception('Esta recompensa no está disponible');
        }

        if (currentStock <= 0) {
          throw Exception('No hay stock disponible');
        }

        // Verificar puntos del usuario
        final userDoc = await transaction.get(
          _firestore.collection('users').doc(userId),
        );

        if (!userDoc.exists) {
          throw Exception('Usuario no encontrado');
        }

        final userData = userDoc.data()!;
        final currentPoints = userData['greenPoints'] as int;

        if (currentPoints < pointsCost) {
          throw Exception('No tienes suficientes puntos verdes');
        }

        // Crear registro de canje
        final redemptionRef = _firestore.collection('reward_redemptions').doc();
        transaction.set(redemptionRef, {
          'userId': userId,
          'userName': userName,
          'userEmail': userEmail,
          'rewardId': rewardId,
          'rewardName': rewardName,
          'pointsSpent': pointsCost,
          'status': 'pending',
          'redeemedAt': FieldValue.serverTimestamp(),
          'processedAt': null,
          'processedBy': null,
          'notes': notes,
          'deliveryAddress': deliveryAddress,
          'phoneNumber': phoneNumber,
        });

        // Restar puntos al usuario
        transaction.update(
          _firestore.collection('users').doc(userId),
          {
            'greenPoints': FieldValue.increment(-pointsCost),
          },
        );

        // Reducir stock de la recompensa
        transaction.update(
          _firestore.collection('rewards').doc(rewardId),
          {
            'stock': FieldValue.increment(-1),
          },
        );
      });
    } catch (e) {
      throw Exception('Error al canjear recompensa: ${e.toString()}');
    }
  }

  // Obtener canjes del usuario
  Stream<List<RewardRedemptionModel>> getUserRedemptions(String userId) {
    return _firestore
        .collection('reward_redemptions')
        .where('userId', isEqualTo: userId)
        .orderBy('redeemedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RewardRedemptionModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  // Obtener todos los canjes (admin)
  Stream<List<RewardRedemptionModel>> getAllRedemptions() {
    return _firestore
        .collection('reward_redemptions')
        .orderBy('redeemedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RewardRedemptionModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  // Obtener canjes por estado (admin)
  Stream<List<RewardRedemptionModel>> getRedemptionsByStatus(
      RedemptionStatus status) {
    return _firestore
        .collection('reward_redemptions')
        .where('status', isEqualTo: status.name)
        .orderBy('redeemedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RewardRedemptionModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  // Aprobar canje (admin)
  Future<void> approveRedemption(String redemptionId, String adminId,
      {String? notes}) async {
    try {
      await _firestore.collection('reward_redemptions').doc(redemptionId).update({
        'status': 'approved',
        'processedAt': FieldValue.serverTimestamp(),
        'processedBy': adminId,
        if (notes != null) 'notes': notes,
      });
    } catch (e) {
      throw Exception('Error al aprobar canje: ${e.toString()}');
    }
  }

  // Marcar como entregado (admin)
  Future<void> markAsDelivered(String redemptionId, String adminId,
      {String? notes}) async {
    try {
      await _firestore.collection('reward_redemptions').doc(redemptionId).update({
        'status': 'delivered',
        'processedAt': FieldValue.serverTimestamp(),
        'processedBy': adminId,
        if (notes != null) 'notes': notes,
      });
    } catch (e) {
      throw Exception('Error al marcar como entregado: ${e.toString()}');
    }
  }

  // Cancelar canje y devolver puntos (admin)
  Future<void> cancelRedemption(String redemptionId, String adminId,
      {String? reason}) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final redemptionDoc = await transaction.get(
          _firestore.collection('reward_redemptions').doc(redemptionId),
        );

        if (!redemptionDoc.exists) {
          throw Exception('Canje no encontrado');
        }

        final redemptionData = redemptionDoc.data()!;
        final userId = redemptionData['userId'] as String;
        final pointsSpent = redemptionData['pointsSpent'] as int;
        final rewardId = redemptionData['rewardId'] as String;

        // Actualizar estado del canje
        transaction.update(
          _firestore.collection('reward_redemptions').doc(redemptionId),
          {
            'status': 'cancelled',
            'processedAt': FieldValue.serverTimestamp(),
            'processedBy': adminId,
            'notes': reason ?? 'Cancelado por administrador',
          },
        );

        // Devolver puntos al usuario
        transaction.update(
          _firestore.collection('users').doc(userId),
          {
            'greenPoints': FieldValue.increment(pointsSpent),
          },
        );

        // Devolver stock a la recompensa
        transaction.update(
          _firestore.collection('rewards').doc(rewardId),
          {
            'stock': FieldValue.increment(1),
          },
        );
      });
    } catch (e) {
      throw Exception('Error al cancelar canje: ${e.toString()}');
    }
  }

  // Obtener estadísticas de canjes (admin)
  Future<Map<String, int>> getRedemptionStats() async {
    try {
      final snapshot =
          await _firestore.collection('reward_redemptions').get();

      int pending = 0;
      int approved = 0;
      int delivered = 0;
      int cancelled = 0;

      for (var doc in snapshot.docs) {
        final status = doc.data()['status'] as String;
        if (status == 'pending') {
          pending++;
        } else if (status == 'approved') {
          approved++;
        } else if (status == 'delivered') {
          delivered++;
        } else if (status == 'cancelled') {
          cancelled++;
        }
      }

      return {
        'pending': pending,
        'approved': approved,
        'delivered': delivered,
        'cancelled': cancelled,
        'total': snapshot.docs.length,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas: ${e.toString()}');
    }
  }
}
