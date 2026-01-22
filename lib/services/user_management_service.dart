import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserManagementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obtener todos los usuarios (con paginación opcional)
  Stream<List<UserModel>> getAllUsers({int? limit}) {
    Query query = _firestore.collection('users').orderBy('createdAt', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  // Buscar usuarios por nombre o email
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final snapshot = await _firestore.collection('users').get();

      final users = snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data(), doc.id))
          .where((user) =>
              user.name.toLowerCase().contains(query.toLowerCase()) ||
              user.email.toLowerCase().contains(query.toLowerCase()))
          .toList();

      return users;
    } catch (e) {
      throw Exception('Error al buscar usuarios: ${e.toString()}');
    }
  }

  // Obtener estadísticas de un usuario
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      // Obtener publicaciones del usuario
      final postsSnapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .get();

      final approvedPosts = postsSnapshot.docs
          .where((doc) => doc.data()['status'] == 'approved')
          .length;

      // Obtener árboles plantados
      final treesSnapshot = await _firestore
          .collection('tree_plantings')
          .where('userId', isEqualTo: userId)
          .get();

      final approvedTrees = treesSnapshot.docs
          .where((doc) => doc.data()['status'] == 'approved')
          .length;

      // Obtener retos completados
      final challengesSnapshot = await _firestore
          .collection('challenge_completions')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'approved')
          .get();

      // Obtener intercambios
      final exchanges1 = await _firestore
          .collection('exchanges')
          .where('user1Id', isEqualTo: userId)
          .where('status', isEqualTo: 'confirmed')
          .get();

      final exchanges2 = await _firestore
          .collection('exchanges')
          .where('user2Id', isEqualTo: userId)
          .where('status', isEqualTo: 'confirmed')
          .get();

      final totalExchanges = exchanges1.docs.length + exchanges2.docs.length;

      // Obtener recompensas canjeadas
      final redemptionsSnapshot = await _firestore
          .collection('reward_redemptions')
          .where('userId', isEqualTo: userId)
          .get();

      return {
        'totalPosts': postsSnapshot.docs.length,
        'approvedPosts': approvedPosts,
        'totalTrees': treesSnapshot.docs.length,
        'approvedTrees': approvedTrees,
        'completedChallenges': challengesSnapshot.docs.length,
        'totalExchanges': totalExchanges,
        'totalRedemptions': redemptionsSnapshot.docs.length,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas: ${e.toString()}');
    }
  }

  // Actualizar rol de usuario
  Future<void> updateUserRole(String userId, String role) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': role,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al actualizar rol: ${e.toString()}');
    }
  }

  // Actualizar puntos verdes de un usuario
  Future<void> updateGreenPoints(String userId, int points) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'greenPoints': points,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al actualizar puntos: ${e.toString()}');
    }
  }

  // Actualizar información de perfil
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? bio,
    String? phone,
  }) async {
    try {
      final Map<String, dynamic> updates = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updates['name'] = name;
      if (bio != null) updates['bio'] = bio;
      if (phone != null) updates['phone'] = phone;

      await _firestore.collection('users').doc(userId).update(updates);
    } catch (e) {
      throw Exception('Error al actualizar perfil: ${e.toString()}');
    }
  }

  // Eliminar usuario (requiere Cloud Functions para eliminar auth)
  Future<void> deleteUser(String userId) async {
    try {
      // Nota: Esto solo elimina el documento de Firestore
      // Para eliminar el usuario de Firebase Auth, necesitas una Cloud Function
      await _firestore.collection('users').doc(userId).delete();
    } catch (e) {
      throw Exception('Error al eliminar usuario: ${e.toString()}');
    }
  }

  // Crear nuevo usuario (requiere Cloud Functions para crear en Auth)
  Future<String> createUser({
    required String email,
    required String password,
    required String name,
    String role = 'user',
  }) async {
    try {
      // Crear usuario en Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = userCredential.user!.uid;

      // Crear documento en Firestore
      await _firestore.collection('users').doc(userId).set({
        'name': name,
        'email': email,
        'role': role,
        'profileImageUrl': '',
        'bio': '',
        'phone': '',
        'greenPoints': 0,
        'challengesCompleted': 0,
        'articlesExchanged': 0,
        'exchangesCompleted': 0,
        'fcmToken': '',
        'joinedDate': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return userId;
    } catch (e) {
      throw Exception('Error al crear usuario: ${e.toString()}');
    }
  }

  // Obtener actividad reciente del usuario
  Future<List<Map<String, dynamic>>> getUserActivity(String userId) async {
    try {
      final List<Map<String, dynamic>> activities = [];

      // Publicaciones recientes
      final postsSnapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      for (var doc in postsSnapshot.docs) {
        activities.add({
          'type': 'post',
          'title': 'Publicó un artículo',
          'description': doc.data()['article']['title'],
          'timestamp': (doc.data()['createdAt'] as Timestamp).toDate(),
          'status': doc.data()['status'],
        });
      }

      // Árboles plantados recientes
      final treesSnapshot = await _firestore
          .collection('tree_plantings')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      for (var doc in treesSnapshot.docs) {
        activities.add({
          'type': 'tree',
          'title': 'Plantó un árbol',
          'description': doc.data()['treeType'],
          'timestamp': (doc.data()['createdAt'] as Timestamp).toDate(),
          'status': doc.data()['status'],
        });
      }

      // Retos completados recientes
      final challengesSnapshot = await _firestore
          .collection('challenge_completions')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      for (var doc in challengesSnapshot.docs) {
        activities.add({
          'type': 'challenge',
          'title': 'Completó un reto',
          'description': 'Reto ID: ${doc.data()['challengeId']}',
          'timestamp': (doc.data()['createdAt'] as Timestamp).toDate(),
          'status': doc.data()['status'],
        });
      }

      // Ordenar por fecha
      activities.sort((a, b) =>
          (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));

      return activities.take(10).toList();
    } catch (e) {
      throw Exception('Error al obtener actividad: ${e.toString()}');
    }
  }

  // Obtener conteo total de usuarios
  Future<int> getTotalUsersCount() async {
    try {
      final snapshot = await _firestore.collection('users').count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      throw Exception('Error al contar usuarios: ${e.toString()}');
    }
  }

  // Obtener usuarios por rol
  Stream<List<UserModel>> getUsersByRole(String role) {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: role)
        .snapshots()
        .map((snapshot) {
      final users = snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data(), doc.id))
          .toList();

      // Ordenar en memoria por createdAt descendente
      users.sort((a, b) => b.joinedDate.compareTo(a.joinedDate));

      return users;
    });
  }
}
