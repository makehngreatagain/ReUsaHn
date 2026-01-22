import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/green_zone_model.dart';
import '../models/tree_planting_model.dart';
import '../services/green_zone_service.dart';
import '../services/tree_planting_service.dart';
import '../utils/colors.dart';
import 'plant_tree_dialog.dart';

class MapaVerdeScreen extends StatefulWidget {
  const MapaVerdeScreen({super.key});

  @override
  State<MapaVerdeScreen> createState() => _MapaVerdeScreenState();
}

class _MapaVerdeScreenState extends State<MapaVerdeScreen> {
  final GreenZoneService _greenZoneService = GreenZoneService();
  final TreePlantingService _treePlantingService = TreePlantingService();
  final MapController _mapController = MapController();

  // Coordenadas del centro de Tegucigalpa, Honduras
  static const LatLng _tegucigalpaCenter = LatLng(14.0723, -87.1921);
  static const double _initialZoom = 12.0;

  // Función para encontrar la zona verde más cercana
  GreenZoneModel? _findNearestZone(LatLng location, List<GreenZoneModel> zones) {
    if (zones.isEmpty) return null;

    GreenZoneModel? nearest;
    double minDistance = double.infinity;

    for (var zone in zones) {
      final zoneLocation = LatLng(zone.latitude, zone.longitude);
      final distance = _calculateDistance(location, zoneLocation);

      if (distance < minDistance && distance < 1000) {
        // Dentro de 1km
        minDistance = distance;
        nearest = zone;
      }
    }

    return nearest;
  }

  // Calcular distancia entre dos puntos (en metros, aproximado)
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // metros
    final dLat = _toRadians(point2.latitude - point1.latitude);
    final dLng = _toRadians(point2.longitude - point1.longitude);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(point1.latitude)) *
            math.cos(_toRadians(point2.latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final c = 2 * math.asin(math.sqrt(a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }

  // Mostrar diálogo para plantar árbol
  Future<void> _showPlantTreeDialog(LatLng location, List<GreenZoneModel> zones) async {
    final nearestZone = _findNearestZone(location, zones);

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlantTreeDialog(
        location: location,
        nearestZone: nearestZone,
      ),
    );
  }

  // Mostrar detalles de un árbol plantado
  void _showTreeDetails(TreePlantingModel tree) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Foto del árbol
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: Image.network(
                tree.photoUrl,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 250,
                    color: Colors.green[100],
                    child: Icon(
                      Icons.park,
                      size: 100,
                      color: Colors.green[700],
                    ),
                  );
                },
              ),
            ),

            // Contenido
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Usuario y fecha
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[300],
                          ),
                          child: tree.userProfileImageUrl.isEmpty
                              ? Icon(Icons.person, color: Colors.grey[600])
                              : ClipOval(
                                  child: Image.network(
                                    tree.userProfileImageUrl,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tree.userName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Plantado el ${tree.plantedAt.day}/${tree.plantedAt.month}/${tree.plantedAt.year}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 20),

                    // Ubicación
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tree.greenZoneName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (tree.notes.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Notas',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tree.notes,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Mapa Verde',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<GreenZoneModel>>(
        stream: _greenZoneService.getActiveGreenZones(),
        builder: (context, zonesSnapshot) {
          if (zonesSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            );
          }

          if (zonesSnapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar zonas verdes',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          final greenZones = zonesSnapshot.data ?? [];

          // Segundo StreamBuilder para los árboles
          return StreamBuilder<List<TreePlantingModel>>(
            stream: _treePlantingService.getApprovedTrees(),
            builder: (context, treesSnapshot) {
              final trees = treesSnapshot.data ?? [];

              return Stack(
                children: [
                  // Mapa
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _tegucigalpaCenter,
                      initialZoom: _initialZoom,
                      minZoom: 10.0,
                      maxZoom: 18.0,
                      onTap: (tapPosition, point) {
                        // Al tocar el mapa, mostrar diálogo para plantar árbol
                        _showPlantTreeDialog(point, greenZones);
                      },
                    ),
                    children: [
                      // Capa de tiles del mapa (OpenStreetMap)
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.reusahn.app',
                      ),

                      // Marcadores de zonas verdes
                      MarkerLayer(
                        markers: greenZones.map((zone) {
                          return Marker(
                            point: LatLng(zone.latitude, zone.longitude),
                            width: 50,
                            height: 50,
                            child: GestureDetector(
                              onTap: () => _showZoneDetails(zone),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.green[700],
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.park,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      // Marcadores de árboles plantados
                      MarkerLayer(
                        markers: trees.map((tree) {
                          return Marker(
                            point: LatLng(tree.latitude, tree.longitude),
                            width: 40,
                            height: 40,
                            child: GestureDetector(
                              onTap: () => _showTreeDetails(tree),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.nature,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),

                  // Panel informativo superior
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.eco,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Mapa Verde',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${greenZones.length} zonas • ${trees.length} árboles',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Botón para centrar en Tegucigalpa
                  Positioned(
                    right: 16,
                    bottom: 180,
                    child: FloatingActionButton(
                      heroTag: 'center_map',
                      onPressed: () {
                        _mapController.move(_tegucigalpaCenter, _initialZoom);
                      },
                      backgroundColor: Colors.white,
                      child: const Icon(
                        Icons.my_location,
                        color: AppColors.primary,
                      ),
                    ),
                  ),

                  // Botón de ayuda para plantar árbol
                  Positioned(
                    right: 16,
                    bottom: 100,
                    child: FloatingActionButton.extended(
                      heroTag: 'plant_tree',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Toca cualquier punto del mapa para plantar un árbol'),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      },
                      backgroundColor: AppColors.primary,
                      icon: const Icon(Icons.add_location_alt, color: Colors.white),
                      label: const Text(
                        'Plantar Árbol',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  // Lista de zonas verdes (deslizable desde abajo)
                  if (greenZones.isNotEmpty)
                    DraggableScrollableSheet(
                      initialChildSize: 0.15,
                      minChildSize: 0.15,
                      maxChildSize: 0.6,
                      builder: (context, scrollController) {
                        return Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 10,
                                offset: Offset(0, -2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Indicador de arrastre
                              Container(
                                margin: const EdgeInsets.symmetric(vertical: 12),
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),

                              // Título
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      color: AppColors.primary,
                                      size: 24,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Zonas Disponibles',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 12),
                              const Divider(height: 1),

                              // Lista de zonas
                              Expanded(
                                child: ListView.builder(
                                  controller: scrollController,
                                  itemCount: greenZones.length,
                                  padding: const EdgeInsets.all(16),
                                  itemBuilder: (context, index) {
                                    return _buildZoneCard(greenZones[index]);
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildZoneCard(GreenZoneModel zone) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Mover el mapa a la zona seleccionada
          _mapController.move(LatLng(zone.latitude, zone.longitude), 15.0);
          _showZoneDetails(zone);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Ícono
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.park,
                  color: Colors.green[700],
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),

              // Información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      zone.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      zone.address,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Flecha
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showZoneDetails(GreenZoneModel zone) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Imagen de la zona
            if (zone.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Image.network(
                  zone.imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.green[100],
                      child: Icon(
                        Icons.park,
                        size: 80,
                        color: Colors.green[700],
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.park,
                    size: 80,
                    color: Colors.green[700],
                  ),
                ),
              ),

            // Contenido
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre
                    Text(
                      zone.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Dirección
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            zone.address,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 20),

                    // Descripción
                    const Text(
                      'Descripción',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      zone.description,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Botón para plantar árbol en esta zona
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showPlantTreeDialog(
                            LatLng(zone.latitude, zone.longitude),
                            [zone],
                          );
                        },
                        icon: const Icon(Icons.park),
                        label: const Text(
                          'Plantar Árbol Aquí',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
