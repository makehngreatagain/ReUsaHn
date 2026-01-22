import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener stream de datos de usuario en tiempo real
  Stream<UserModel?> getUserStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      return UserModel.fromJson(snapshot.data()!, snapshot.id);
    });
  }

  // Obtener datos de usuario una vez
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      return UserModel.fromJson(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Error al obtener usuario: ${e.toString()}');
    }
  }

  // Actualizar datos de usuario
  Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('users').doc(userId).update(updates);
    } catch (e) {
      throw Exception('Error al actualizar usuario: ${e.toString()}');
    }
  }

  // Obtener ranking de usuarios por puntos verdes
  Stream<List<UserModel>> getTopUsers({int limit = 10}) {
    return _firestore
        .collection('users')
        .orderBy('greenPoints', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data(), doc.id))
          .toList();
    });
  }
}
