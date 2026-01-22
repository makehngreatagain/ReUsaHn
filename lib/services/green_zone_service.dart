import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/green_zone_model.dart';

class GreenZoneService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener todas las zonas verdes activas en tiempo real
  Stream<List<GreenZoneModel>> getActiveGreenZones() {
    return _firestore
        .collection('green_zones')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => GreenZoneModel.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  // Obtener todas las zonas verdes (incluyendo inactivas) - para admin
  Stream<List<GreenZoneModel>> getAllGreenZones() {
    return _firestore
        .collection('green_zones')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => GreenZoneModel.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  // Obtener una zona verde por ID
  Future<GreenZoneModel?> getGreenZoneById(String zoneId) async {
    try {
      final doc = await _firestore.collection('green_zones').doc(zoneId).get();
      if (!doc.exists) return null;
      return GreenZoneModel.fromJson(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Error al obtener zona verde: ${e.toString()}');
    }
  }

  // Crear una nueva zona verde (solo admin)
  Future<String> createGreenZone({
    required String name,
    required String description,
    required double latitude,
    required double longitude,
    required String address,
    required String adminId,
    String? imageUrl,
  }) async {
    try {
      final docRef = await _firestore.collection('green_zones').add({
        'name': name,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'imageUrl': imageUrl ?? '',
        'isActive': true,
        'createdBy': adminId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear zona verde: ${e.toString()}');
    }
  }

  // Actualizar una zona verde (solo admin)
  Future<void> updateGreenZone(
    String zoneId,
    Map<String, dynamic> updates,
  ) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('green_zones').doc(zoneId).update(updates);
    } catch (e) {
      throw Exception('Error al actualizar zona verde: ${e.toString()}');
    }
  }

  // Activar/Desactivar zona verde (solo admin)
  Future<void> toggleGreenZoneStatus(String zoneId, bool isActive) async {
    try {
      await _firestore.collection('green_zones').doc(zoneId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al cambiar estado de zona verde: ${e.toString()}');
    }
  }

  // Eliminar zona verde (solo admin)
  Future<void> deleteGreenZone(String zoneId) async {
    try {
      await _firestore.collection('green_zones').doc(zoneId).delete();
    } catch (e) {
      throw Exception('Error al eliminar zona verde: ${e.toString()}');
    }
  }
}
