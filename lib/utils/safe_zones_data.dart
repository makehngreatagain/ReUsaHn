import 'package:latlong2/latlong.dart';
import '../models/safe_zone_model.dart';

class SafeZonesData {
  // Zonas seguras para intercambio en Tegucigalpa, Honduras
  static final List<SafeZoneModel> zones = [
    // Zona 1: UNAH (Universidad Nacional Autónoma de Honduras)
    SafeZoneModel(
      id: 'zone_001',
      name: 'UNAH - Ciudad Universitaria',
      description: 'Campus de la Universidad Nacional. Zona segura con presencia de seguridad universitaria, buena iluminación y alto tráfico de personas durante el día.',
      polygonPoints: SafeZoneModel.createCirclePolygon(
        const LatLng(14.084610, -87.162086),
        300, // Radio de 300 metros
      ),
      center: const LatLng(14.084610, -87.162086),
      address: 'Boulevard Suyapa, Tegucigalpa',
      hours: '7:00 AM - 6:00 PM',
      type: SafeZoneType.educational,
      isActive: true,
    ),

    // Zona 2: Torre Metrópolis (Centro Comercial - a la izquierda de Almacenes Xtra)
    SafeZoneModel(
      id: 'zone_002',
      name: 'Torre Metrópolis',
      description: 'Centro comercial con seguridad privada 24/7, cámaras de vigilancia, estacionamiento y área de food court. Ideal para intercambios seguros.',
      polygonPoints: SafeZoneModel.createCirclePolygon(
        const LatLng(14.086169, -87.186375),
        250, // Radio de 250 metros
      ),
      center: const LatLng(14.086169, -87.186375),
      address: 'Boulevard Suyapa, Tegucigalpa',
      hours: '10:00 AM - 8:00 PM',
      type: SafeZoneType.commercial,
      isActive: true,
    ),
  ];

  // Centro del mapa para visualizar ambas zonas
  static const LatLng tegucigalpaCenter = LatLng(14.0853895, -87.1742305);

  // Zoom inicial recomendado
  static const double initialZoom = 13.0;

  // Obtener zona por ID
  static SafeZoneModel? getZoneById(String id) {
    try {
      return zones.firstWhere((zone) => zone.id == id);
    } catch (e) {
      return null;
    }
  }

  // Filtrar zonas por tipo
  static List<SafeZoneModel> getZonesByType(SafeZoneType type) {
    return zones.where((zone) => zone.type == type).toList();
  }

  // Obtener solo zonas activas
  static List<SafeZoneModel> getActiveZones() {
    return zones.where((zone) => zone.isActive).toList();
  }
}
