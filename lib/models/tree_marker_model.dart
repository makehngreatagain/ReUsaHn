import 'package:latlong2/latlong.dart';

class TreeMarkerModel {
  final String id;
  final String challengeId;
  final LatLng location;
  final String userId;
  final String userName;
  final String? imageUrl;
  final DateTime plantedAt;

  TreeMarkerModel({
    required this.id,
    required this.challengeId,
    required this.location,
    required this.userId,
    required this.userName,
    this.imageUrl,
    required this.plantedAt,
  });
}
