import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

enum SafeZoneType {
  educational,
  commercial,
  publicPark,
  government,
}

class SafeZoneModel {
  final String id;
  final String name;
  final String description;
  final List<LatLng> polygonPoints;
  final LatLng center;
  final String address;
  final String hours;
  final SafeZoneType type;
  final bool isActive;

  const SafeZoneModel({
    required this.id,
    required this.name,
    required this.description,
    required this.polygonPoints,
    required this.center,
    required this.address,
    required this.hours,
    required this.type,
    this.isActive = true,
  });

  String get typeLabel {
    switch (type) {
      case SafeZoneType.educational:
        return 'Institución Educativa';
      case SafeZoneType.commercial:
        return 'Centro Comercial';
      case SafeZoneType.publicPark:
        return 'Parque Público';
      case SafeZoneType.government:
        return 'Institución Gubernamental';
    }
  }

  // Helper para crear círculo aproximado desde un centro y radio
  static List<LatLng> createCirclePolygon(
    LatLng center,
    double radiusInMeters, {
    int numberOfPoints = 32,
  }) {
    final List<LatLng> points = [];
    const earthRadius = 6371000.0; // Radio de la tierra en metros

    for (int i = 0; i < numberOfPoints; i++) {
      final angle = (i * 360 / numberOfPoints) * (math.pi / 180);

      final dx = radiusInMeters * math.cos(angle);
      final dy = radiusInMeters * math.sin(angle);

      final deltaLat = dy / earthRadius;
      final deltaLng = dx / (earthRadius * math.cos(center.latitude * math.pi / 180));

      final lat = center.latitude + (deltaLat * 180 / math.pi);
      final lng = center.longitude + (deltaLng * 180 / math.pi);

      points.add(LatLng(lat, lng));
    }

    return points;
  }
}
