import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Inicializar el servicio de notificaciones
  Future<void> initialize() async {
    // Solicitar permisos
    await _requestPermission();

    // Configurar notificaciones locales
    await _setupLocalNotifications();

    // Configurar handlers de FCM
    _setupFCMHandlers();

    // Obtener y guardar el token
    await _saveToken();
  }

  // Solicitar permisos de notificación
  Future<void> _requestPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Usuario autorizó notificaciones
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      // Usuario autorizó notificaciones provisionales
    } else {
      // Usuario denegó notificaciones
    }
  }

  // Configurar notificaciones locales
  Future<void> _setupLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Manejar cuando el usuario toca la notificación
        _handleNotificationTap(response.payload);
      },
    );
  }

  // Configurar handlers de Firebase Cloud Messaging
  void _setupFCMHandlers() {
    // Cuando la app está en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    // Cuando la app está en segundo plano y el usuario toca la notificación
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message.data['type']);
    });

    // Verificar si la app se abrió desde una notificación
    _checkInitialMessage();
  }

  // Verificar si la app se abrió desde una notificación
  Future<void> _checkInitialMessage() async {
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage.data['type']);
    }
  }

  // Mostrar notificación local
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'reusa_channel',
      'ReUsa Notificaciones',
      channelDescription: 'Notificaciones de la app ReUsa Honduras',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'ReUsa Honduras',
      message.notification?.body ?? '',
      notificationDetails,
      payload: message.data['type'],
    );
  }

  // Manejar cuando el usuario toca una notificación
  void _handleNotificationTap(String? notificationType) {
    if (notificationType == null) return;

    // Aquí puedes navegar a diferentes pantallas según el tipo de notificación
    // Por ejemplo: navigatorKey.currentState?.pushNamed('/chats');
  }

  // Guardar el token FCM del usuario
  Future<void> _saveToken() async {
    String? token = await _messaging.getToken();
    if (token != null) {
      // El token se guardará cuando el usuario haga login
      // Ver auth_service.dart
    }

    // Escuchar cambios en el token
    _messaging.onTokenRefresh.listen((newToken) {
      // Actualizar el token en Firestore
      // Esto se manejará en auth_service.dart
    });
  }

  // ============ BUZÓN DE NOTIFICACIONES (IN-APP) ============

  // Obtener notificaciones del usuario como modelos
  Stream<List<NotificationModel>> getUserNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationModel.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  // Obtener contador de notificaciones no leídas
  Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Crear notificación de reto completado
  Future<void> createChallengeNotification({
    required String userId,
    required String challengeTitle,
    required int pointsEarned,
    required String challengeId,
  }) async {
    try {
      final notification = NotificationModel(
        id: '',
        userId: userId,
        type: NotificationType.challengeCompleted,
        title: '¡Reto Completado!',
        message: 'Has completado el reto "$challengeTitle" y se te han acreditado $pointsEarned puntos verdes.',
        pointsEarned: pointsEarned,
        referenceId: challengeId,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('notifications').add(notification.toJson());
    } catch (e) {
      // Error silencioso - las notificaciones no deben bloquear la funcionalidad
    }
  }

  // Crear notificación de publicación aprobada
  Future<void> createPublicationNotification({
    required String userId,
    required String postTitle,
    required String postId,
  }) async {
    try {
      final notification = NotificationModel(
        id: '',
        userId: userId,
        type: NotificationType.publicationApproved,
        title: 'Publicación Aprobada',
        message: 'Tu publicación "$postTitle" ha sido aprobada y ya está visible para otros usuarios.',
        referenceId: postId,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('notifications').add(notification.toJson());
    } catch (e) {
      // Error silencioso
    }
  }

  // Crear notificación de árbol aprobado
  Future<void> createTreeNotification({
    required String userId,
    required int pointsEarned,
    required String treeId,
  }) async {
    try {
      final notification = NotificationModel(
        id: '',
        userId: userId,
        type: NotificationType.treeApproved,
        title: '¡Árbol Aprobado!',
        message: 'Tu registro de árbol ha sido aprobado y se te han acreditado $pointsEarned puntos verdes.',
        pointsEarned: pointsEarned,
        referenceId: treeId,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('notifications').add(notification.toJson());
    } catch (e) {
      // Error silencioso
    }
  }

  // Crear notificación de canje aprobado
  Future<void> createRewardNotification({
    required String userId,
    required String rewardName,
    required int pointsUsed,
    required String redemptionId,
  }) async {
    try {
      final notification = NotificationModel(
        id: '',
        userId: userId,
        type: NotificationType.rewardRedeemed,
        title: '¡Canje Aprobado!',
        message: 'Tu canje de "$rewardName" ha sido aprobado. Se te enviará próximamente.',
        pointsEarned: -pointsUsed, // Negativo porque son puntos gastados
        referenceId: redemptionId,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('notifications').add(notification.toJson());
    } catch (e) {
      // Error silencioso
    }
  }

  // Marcar notificación como leída
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      // Error silencioso
    }
  }

  // Marcar todas las notificaciones como leídas
  Future<void> markAllAsRead(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      // Error silencioso
    }
  }

  // Eliminar una notificación
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      // Error silencioso
    }
  }

  // Eliminar todas las notificaciones de un usuario
  Future<void> deleteAllNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      // Error silencioso
    }
  }

  // ============ NOTIFICACIONES PUSH (FCM) ============

  // Enviar notificación a un usuario específico
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    String? type,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Obtener el FCM token del usuario
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final fcmToken = userDoc.data()?['fcmToken'] as String?;

      if (fcmToken == null || fcmToken.isEmpty) {
        return; // Usuario no tiene token FCM
      }

      // Crear registro de notificación en Firestore
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'message': body,
        'type': type ?? 'general',
        'data': data ?? {},
        'fcmToken': fcmToken,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Nota: El envío real de la notificación push se hará mediante Cloud Functions
      // porque las notificaciones push requieren la clave del servidor de Firebase
    } catch (e) {
      // Error silencioso - las notificaciones no deben bloquear la funcionalidad
    }
  }

  // Obtener notificaciones del usuario (legacy - para compatibilidad)
  Stream<List<Map<String, dynamic>>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }
}
