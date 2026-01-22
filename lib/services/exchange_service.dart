import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/exchange_model.dart';
import 'notification_service.dart';

class ExchangeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Crear propuesta de intercambio
  Future<String> proposeExchange({
    required String chatId,
    required String postId,
    required String user1Id,
    required String user1Name,
    required String user1ImageUrl,
    required String user2Id,
    required String user2Name,
    required String user2ImageUrl,
    String? notes,
  }) async {
    try {
      final docRef = await _firestore.collection('exchanges').add({
        'chatId': chatId,
        'postId': postId,
        'user1Id': user1Id,
        'user1Name': user1Name,
        'user1ImageUrl': user1ImageUrl,
        'user2Id': user2Id,
        'user2Name': user2Name,
        'user2ImageUrl': user2ImageUrl,
        'status': ExchangeStatus.pending.name,
        'user1Confirmed': true, // El que propone ya confirmó
        'user2Confirmed': false,
        'user1ConfirmedAt': FieldValue.serverTimestamp(),
        'user2ConfirmedAt': null,
        'notes': notes,
        'proofImageUrl': null,
        'createdAt': FieldValue.serverTimestamp(),
        'completedAt': null,
      });

      // Enviar notificación al usuario 2 (quien recibe la propuesta)
      await _notificationService.sendNotificationToUser(
        userId: user2Id,
        title: '💱 Nueva Propuesta de Intercambio',
        body: '$user1Name te propone un intercambio. Revisa tu chat para confirmar.',
        type: 'exchange_proposed',
        data: {
          'exchangeId': docRef.id,
          'chatId': chatId,
          'proposerId': user1Id,
        },
      );

      return docRef.id;
    } catch (e) {
      throw Exception('Error al proponer intercambio: ${e.toString()}');
    }
  }

  // Confirmar intercambio (el segundo usuario)
  Future<void> confirmExchange({
    required String exchangeId,
    required String userId,
    String? proofImageUrl,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final exchangeDoc = await transaction.get(
          _firestore.collection('exchanges').doc(exchangeId),
        );

        if (!exchangeDoc.exists) {
          throw Exception('Intercambio no encontrado');
        }

        final exchange = ExchangeModel.fromJson(exchangeDoc.data()!, exchangeDoc.id);

        // Determinar qué usuario está confirmando
        bool isUser1 = userId == exchange.user1Id;
        bool isUser2 = userId == exchange.user2Id;

        if (!isUser1 && !isUser2) {
          throw Exception('No tienes permiso para confirmar este intercambio');
        }

        Map<String, dynamic> updateData = {};

        if (isUser2 && !exchange.user2Confirmed) {
          // User2 confirma por primera vez
          updateData = {
            'user2Confirmed': true,
            'user2ConfirmedAt': FieldValue.serverTimestamp(),
            'status': ExchangeStatus.confirmed.name,
            'completedAt': FieldValue.serverTimestamp(),
          };

          if (proofImageUrl != null) {
            updateData['proofImageUrl'] = proofImageUrl;
          }

          // Actualizar el intercambio
          transaction.update(
            _firestore.collection('exchanges').doc(exchangeId),
            updateData,
          );

          // Incrementar contador de intercambios completados para ambos usuarios
          transaction.update(
            _firestore.collection('users').doc(exchange.user1Id),
            {'exchangesCompleted': FieldValue.increment(1)},
          );

          transaction.update(
            _firestore.collection('users').doc(exchange.user2Id),
            {'exchangesCompleted': FieldValue.increment(1)},
          );
        } else if (isUser1 && !exchange.user1Confirmed) {
          // User1 confirma (poco probable ya que propone automáticamente confirmado)
          updateData = {
            'user1Confirmed': true,
            'user1ConfirmedAt': FieldValue.serverTimestamp(),
          };

          transaction.update(
            _firestore.collection('exchanges').doc(exchangeId),
            updateData,
          );
        }
      });

      // Después de confirmar el intercambio, actualizar retos de intercambio
      final exchangeDoc = await _firestore.collection('exchanges').doc(exchangeId).get();
      final exchange = ExchangeModel.fromJson(exchangeDoc.data()!, exchangeDoc.id);

      if (exchange.isCompleted) {
        await _completeExchangeChallenges(exchange.user1Id);
        await _completeExchangeChallenges(exchange.user2Id);

        // Marcar la publicación como intercambiada (isAvailable = false)
        await _markPostAsExchanged(exchange.postId);

        // Notificar a user1 que el intercambio fue confirmado
        await _notificationService.sendNotificationToUser(
          userId: exchange.user1Id,
          title: '✅ Intercambio Confirmado',
          body: '${exchange.user2Name} ha confirmado el intercambio. ¡Felicidades!',
          type: 'exchange_confirmed',
          data: {
            'exchangeId': exchangeId,
            'chatId': exchange.chatId,
          },
        );
      }
    } catch (e) {
      throw Exception('Error al confirmar intercambio: ${e.toString()}');
    }
  }

  // Marcar publicación como intercambiada
  Future<void> _markPostAsExchanged(String postId) async {
    try {
      // Obtener el documento del post directamente
      final postDoc = await _firestore.collection('posts').doc(postId).get();

      if (postDoc.exists) {
        final postData = postDoc.data();
        if (postData != null) {
          final article = postData['article'] as Map<String, dynamic>;

          // Actualizar el campo isAvailable del artículo a false
          article['isAvailable'] = false;

          await _firestore.collection('posts').doc(postId).update({
            'article': article,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      // No lanzar error para no afectar la confirmación del intercambio
      debugPrint('Error al marcar post como intercambiado: $e');
    }
  }

  // Completar retos de intercambio para un usuario
  Future<void> _completeExchangeChallenges(String userId) async {
    try {
      // Buscar todos los retos activos de tipo 'makeExchanges'
      final challengesSnapshot = await _firestore
          .collection('challenges')
          .where('type', isEqualTo: 'makeExchanges')
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
                'notes': 'Completado automáticamente al confirmar intercambio. Reclama tus puntos en la pantalla de Retos.',
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
            // Si con 1 intercambio ya completó el reto, marcarlo como aprobado
            await _firestore.collection('challenge_completions').add({
              'userId': userId,
              'challengeId': challengeId,
              'currentCount': newCount,
              'status': 'approved',
              'completedAt': FieldValue.serverTimestamp(),
              'reviewedAt': FieldValue.serverTimestamp(),
              'notes': 'Completado automáticamente al confirmar intercambio. Reclama tus puntos en la pantalla de Retos.',
              'proofImageUrls': [],
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
              'proofImageUrls': [],
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
      // No lanzar error para no afectar la confirmación del intercambio
    }
  }

  // Cancelar intercambio
  Future<void> cancelExchange(String exchangeId) async {
    try {
      await _firestore.collection('exchanges').doc(exchangeId).update({
        'status': ExchangeStatus.cancelled.name,
      });
    } catch (e) {
      throw Exception('Error al cancelar intercambio: ${e.toString()}');
    }
  }

  // Obtener intercambio activo para un chat específico
  Future<ExchangeModel?> getActiveExchangeForChat(String chatId) async {
    try {
      final snapshot = await _firestore
          .collection('exchanges')
          .where('chatId', isEqualTo: chatId)
          .where('status', whereIn: [ExchangeStatus.pending.name, ExchangeStatus.confirmed.name])
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return ExchangeModel.fromJson(snapshot.docs.first.data(), snapshot.docs.first.id);
    } catch (e) {
      throw Exception('Error al obtener intercambio: ${e.toString()}');
    }
  }

  // Obtener intercambio activo como stream (tiempo real)
  Stream<ExchangeModel?> getActiveExchangeStream(String chatId) {
    return _firestore
        .collection('exchanges')
        .where('chatId', isEqualTo: chatId)
        .where('status', whereIn: [ExchangeStatus.pending.name, ExchangeStatus.confirmed.name])
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return ExchangeModel.fromJson(snapshot.docs.first.data(), snapshot.docs.first.id);
    });
  }

  // Obtener todos los intercambios de un usuario
  Stream<List<ExchangeModel>> getUserExchanges(String userId) {
    return _firestore
        .collection('exchanges')
        .where('user1Id', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot1) async {
      final exchanges1 = snapshot1.docs
          .map((doc) => ExchangeModel.fromJson(doc.data(), doc.id))
          .toList();

      final snapshot2 = await _firestore
          .collection('exchanges')
          .where('user2Id', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final exchanges2 = snapshot2.docs
          .map((doc) => ExchangeModel.fromJson(doc.data(), doc.id))
          .toList();

      // Combinar y ordenar
      final allExchanges = [...exchanges1, ...exchanges2];
      allExchanges.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return allExchanges;
    });
  }

  // Obtener estadísticas de intercambios de un usuario
  Future<Map<String, int>> getUserExchangeStats(String userId) async {
    try {
      final snapshot1 = await _firestore
          .collection('exchanges')
          .where('user1Id', isEqualTo: userId)
          .get();

      final snapshot2 = await _firestore
          .collection('exchanges')
          .where('user2Id', isEqualTo: userId)
          .get();

      int total = snapshot1.docs.length + snapshot2.docs.length;
      int confirmed = 0;
      int pending = 0;
      int cancelled = 0;

      for (var doc in [...snapshot1.docs, ...snapshot2.docs]) {
        final status = doc.data()['status'] as String;
        if (status == ExchangeStatus.confirmed.name) {
          confirmed++;
        } else if (status == ExchangeStatus.pending.name) {
          pending++;
        } else if (status == ExchangeStatus.cancelled.name) {
          cancelled++;
        }
      }

      return {
        'total': total,
        'confirmed': confirmed,
        'pending': pending,
        'cancelled': cancelled,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas: ${e.toString()}');
    }
  }
}
