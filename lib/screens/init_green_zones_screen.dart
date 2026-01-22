import 'package:flutter/material.dart';
import '../services/green_zone_service.dart';
import '../services/auth_service.dart';
import '../utils/colors.dart';

class InitGreenZonesScreen extends StatefulWidget {
  const InitGreenZonesScreen({super.key});

  @override
  State<InitGreenZonesScreen> createState() => _InitGreenZonesScreenState();
}

class _InitGreenZonesScreenState extends State<InitGreenZonesScreen> {
  final GreenZoneService _greenZoneService = GreenZoneService();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String _message = '';
  final List<String> _logs = [];

  // Zonas verdes de ejemplo en Tegucigalpa, Honduras
  final List<Map<String, dynamic>> _exampleZones = [
    {
      'name': 'Parque La Leona',
      'description': 'Zona verde ubicada en el corazón de Tegucigalpa. Espacio ideal para realizar intercambios seguros de artículos reciclables. Cuenta con áreas verdes amplias y vigilancia.',
      'latitude': 14.0818,
      'longitude': -87.2068,
      'address': 'Barrio La Leona, Tegucigalpa',
    },
    {
      'name': 'Parque Central de Tegucigalpa',
      'description': 'Parque histórico en el centro de la capital. Zona segura para encuentros de intercambio ecológico. Alta afluencia de personas durante el día.',
      'latitude': 14.0995,
      'longitude': -87.2072,
      'address': 'Centro Histórico, Tegucigalpa',
    },
    {
      'name': 'Parque Naciones Unidas El Picacho',
      'description': 'Amplia zona verde con vistas panorámicas de Tegucigalpa. Espacio natural ideal para actividades ecológicas y plantación de árboles.',
      'latitude': 14.1208,
      'longitude': -87.2150,
      'address': 'El Picacho, Tegucigalpa',
    },
    {
      'name': 'Parque La Concordia',
      'description': 'Zona verde residencial segura. Perfecto para realizar intercambios de materiales reciclables en un ambiente familiar y tranquilo.',
      'latitude': 14.0889,
      'longitude': -87.1750,
      'address': 'Colonia La Concordia, Tegucigalpa',
    },
    {
      'name': 'Boulevard Morazán',
      'description': 'Área comercial con espacios verdes. Zona concurrida y segura para intercambios durante horas comerciales. Acceso fácil a transporte público.',
      'latitude': 14.0965,
      'longitude': -87.1825,
      'address': 'Boulevard Morazán, Tegucigalpa',
    },
    {
      'name': 'Parque Herrera',
      'description': 'Parque comunitario ubicado en zona céntrica. Espacio seguro con bancas y áreas verdes. Ideal para encuentros ecológicos.',
      'latitude': 14.0920,
      'longitude': -87.2010,
      'address': 'Colonia Palmira, Tegucigalpa',
    },
  ];

  void _addLog(String log) {
    setState(() {
      _logs.add(log);
    });
  }

  Future<void> _initializeGreenZones() async {
    setState(() {
      _isLoading = true;
      _message = '';
      _logs.clear();
    });

    try {
      _addLog('🚀 Iniciando proceso de inicialización...');

      // Obtener el ID del admin actual
      final adminId = _authService.currentUser?.uid;
      if (adminId == null) {
        throw Exception('No hay usuario autenticado');
      }

      _addLog('👤 Admin ID: $adminId');

      // Crear cada zona verde
      int created = 0;
      for (var zoneData in _exampleZones) {
        try {
          final zoneId = await _greenZoneService.createGreenZone(
            name: zoneData['name'],
            description: zoneData['description'],
            latitude: zoneData['latitude'],
            longitude: zoneData['longitude'],
            address: zoneData['address'],
            adminId: adminId,
          );

          created++;
          _addLog('✅ Creada: ${zoneData['name']} (ID: ${zoneId.substring(0, 8)}...)');
        } catch (e) {
          _addLog('❌ Error al crear ${zoneData['name']}: $e');
        }
      }

      _addLog('');
      _addLog('🎉 Proceso completado');
      _addLog('📊 Total de zonas creadas: $created/${_exampleZones.length}');

      setState(() {
        _isLoading = false;
        _message = '¡$created zonas verdes creadas exitosamente!';
      });
    } catch (e) {
      _addLog('');
      _addLog('❌ Error general: $e');

      setState(() {
        _isLoading = false;
        _message = 'Error: ${e.toString()}';
      });
    }
  }

  Future<void> _deleteAllGreenZones() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar TODAS las zonas verdes?\n\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar Todo'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _message = '';
      _logs.clear();
    });

    try {
      _addLog('🗑️ Iniciando eliminación de zonas verdes...');

      final zones = await _greenZoneService.getAllGreenZones().first;

      int deleted = 0;
      for (var zone in zones) {
        try {
          await _greenZoneService.deleteGreenZone(zone.id);
          deleted++;
          _addLog('🗑️ Eliminada: ${zone.name}');
        } catch (e) {
          _addLog('❌ Error al eliminar ${zone.name}: $e');
        }
      }

      _addLog('');
      _addLog('✅ Eliminación completada');
      _addLog('📊 Total eliminadas: $deleted/${zones.length}');

      setState(() {
        _isLoading = false;
        _message = '$deleted zonas eliminadas';
      });
    } catch (e) {
      _addLog('❌ Error: $e');

      setState(() {
        _isLoading = false;
        _message = 'Error: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Inicializar Zonas Verdes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Esta herramienta creará ${_exampleZones.length} zonas verdes de ejemplo en Tegucigalpa.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Botón de inicializar
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _initializeGreenZones,
                icon: const Icon(Icons.add_location),
                label: const Text(
                  'Crear Zonas de Ejemplo',
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

            const SizedBox(height: 12),

            // Botón de eliminar todo
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _deleteAllGreenZones,
                icon: const Icon(Icons.delete_forever),
                label: const Text(
                  'Eliminar Todas las Zonas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Mensaje de estado
            if (_message.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _message.contains('Error')
                      ? Colors.red[50]
                      : Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _message.contains('Error')
                        ? Colors.red[200]!
                        : Colors.green[200]!,
                  ),
                ),
                child: Text(
                  _message,
                  style: TextStyle(
                    fontSize: 14,
                    color: _message.contains('Error')
                        ? Colors.red[900]
                        : Colors.green[900],
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 24),

            // Logs
            if (_logs.isNotEmpty) ...[
              const Text(
                'Registro de Actividad',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 400),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _logs
                        .map(
                          (log) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              log,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],

            // Indicador de carga
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
