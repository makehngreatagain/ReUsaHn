import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../utils/colors.dart';
import '../utils/safe_zones_data.dart';
import '../models/safe_zone_model.dart';

class MapaVerdeScreen extends StatefulWidget {
  const MapaVerdeScreen({super.key});

  @override
  State<MapaVerdeScreen> createState() => _MapaVerdeScreenState();
}

class _MapaVerdeScreenState extends State<MapaVerdeScreen> {
  final MapController _mapController = MapController();
  SafeZoneModel? _selectedZone;
  bool _isLoading = true;
  LatLng? _clickedCoordinates;

  @override
  void initState() {
    super.initState();
    // Simular carga inicial
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _onZoneTap(SafeZoneModel zone) {
    setState(() {
      _selectedZone = zone;
      _clickedCoordinates = null; // Cerrar coordenadas al seleccionar zona
    });
  }

  void _resetView() {
    _mapController.move(
      SafeZonesData.tegucigalpaCenter,
      SafeZonesData.initialZoom,
    );
    setState(() {
      _selectedZone = null;
    });
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(
      _mapController.camera.center,
      currentZoom + 1,
    );
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(
      _mapController.camera.center,
      currentZoom - 1,
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
      body: Stack(
        children: [
          // Mapa
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: SafeZonesData.tegucigalpaCenter,
              initialZoom: SafeZonesData.initialZoom,
              minZoom: 10,
              maxZoom: 18,
              onTap: (tapPosition, point) {
                setState(() {
                  _clickedCoordinates = point;
                  _selectedZone = null; // Cerrar zona seleccionada al hacer clic
                });
              },
            ),
            children: [
              // Capa de tiles de OpenStreetMap
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.prueba_android',
              ),

              // Capa de polígonos (zonas seguras)
              PolygonLayer(
                polygons: SafeZonesData.getActiveZones().map((zone) {
                  final isSelected = _selectedZone?.id == zone.id;
                  return Polygon(
                    points: zone.polygonPoints,
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.4) // Más oscuro si está seleccionado
                        : AppColors.primary.withValues(alpha: 0.25), // Verde semi-transparente
                    borderColor: AppColors.primary,
                    borderStrokeWidth: isSelected ? 3.0 : 2.0,
                  );
                }).toList(),
              ),

              // Capa de marcadores
              MarkerLayer(
                markers: SafeZonesData.getActiveZones().map((zone) {
                  return Marker(
                    point: zone.center,
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () => _onZoneTap(zone),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Controles del mapa
          Positioned(
            right: 16,
            top: 16,
            child: Column(
              children: [
                // Botón Zoom In
                FloatingActionButton(
                  heroTag: 'zoom_in',
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: _zoomIn,
                  child: const Icon(Icons.add, color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                // Botón Zoom Out
                FloatingActionButton(
                  heroTag: 'zoom_out',
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: _zoomOut,
                  child: const Icon(Icons.remove, color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                // Botón Reset
                FloatingActionButton(
                  heroTag: 'reset',
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: _resetView,
                  child: const Icon(Icons.my_location, color: AppColors.primary),
                ),
              ],
            ),
          ),

          // Leyenda
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      border: Border.all(color: AppColors.primary, width: 2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Zonas Verdes Para Intercambio',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.white.withValues(alpha: 0.8),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
            ),

          // Coordenadas del clic
          if (_clickedCoordinates != null)
            Positioned(
              bottom: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_clickedCoordinates!.latitude.toStringAsFixed(6)}, ${_clickedCoordinates!.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _clickedCoordinates = null;
                        });
                      },
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Info card de zona seleccionada
          if (_selectedZone != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedZone!.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              _selectedZone = null;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _selectedZone!.typeLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selectedZone!.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _selectedZone!.address,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _selectedZone!.hours,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
