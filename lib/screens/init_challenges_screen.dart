import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/challenges_data.dart';
import '../utils/colors.dart';

class InitChallengesScreen extends StatefulWidget {
  const InitChallengesScreen({super.key});

  @override
  State<InitChallengesScreen> createState() => _InitChallengesScreenState();
}

class _InitChallengesScreenState extends State<InitChallengesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  String _message = '';
  final List<String> _logs = [];

  Future<void> _initializeChallenges() async {
    setState(() {
      _isLoading = true;
      _message = 'Inicializando retos...';
      _logs.clear();
    });

    try {
      _addLog('🔵 Iniciando proceso de inicialización...');

      // Verificar si ya existen retos
      final existingChallenges = await _firestore.collection('challenges').get();

      if (existingChallenges.docs.isNotEmpty) {
        _addLog('⚠️ Ya existen ${existingChallenges.docs.length} retos en Firestore');

        if (!mounted) return;
        final shouldContinue = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Retos existentes'),
            content: Text(
              'Ya hay ${existingChallenges.docs.length} retos en la base de datos.\n\n¿Deseas agregar los retos de ejemplo de todas formas?'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Continuar'),
              ),
            ],
          ),
        );

        if (shouldContinue != true) {
          setState(() {
            _isLoading = false;
            _message = 'Operación cancelada';
          });
          return;
        }
      }

      _addLog('📝 Preparando ${ChallengesData.initialChallenges.length} retos...');

      int successCount = 0;
      int errorCount = 0;

      for (var i = 0; i < ChallengesData.initialChallenges.length; i++) {
        final challengeData = ChallengesData.initialChallenges[i];

        try {
          // Agregar timestamps
          final data = {
            ...challengeData,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          };

          final docRef = await _firestore.collection('challenges').add(data);

          _addLog('✅ Reto ${i + 1}/${ChallengesData.initialChallenges.length}: "${challengeData['title']}" creado (ID: ${docRef.id})');
          successCount++;
        } catch (e) {
          _addLog('❌ Error al crear reto ${i + 1}: $e');
          errorCount++;
        }
      }

      _addLog('');
      _addLog('📊 Resumen:');
      _addLog('✅ Creados exitosamente: $successCount');
      if (errorCount > 0) {
        _addLog('❌ Errores: $errorCount');
      }
      _addLog('');
      _addLog('🎉 ¡Inicialización completada!');

      setState(() {
        _isLoading = false;
        _message = '¡Completado! $successCount retos creados.';
      });

      // Mostrar diálogo de éxito
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('✅ Éxito'),
            content: Text('Se crearon $successCount retos exitosamente.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // Volver a la pantalla anterior
                },
                child: const Text('Aceptar'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      _addLog('❌ Error general: $e');
      setState(() {
        _isLoading = false;
        _message = 'Error: ${e.toString()}';
      });
    }
  }

  void _addLog(String log) {
    setState(() {
      _logs.add(log);
    });
  }

  Future<void> _deleteAllChallenges() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Confirmar eliminación'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar TODOS los retos de la base de datos?\n\nEsta acción NO se puede deshacer.'
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

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _message = 'Eliminando retos...';
      _logs.clear();
    });

    try {
      _addLog('🔵 Obteniendo todos los retos...');
      final challenges = await _firestore.collection('challenges').get();

      _addLog('📝 Encontrados ${challenges.docs.length} retos');

      if (challenges.docs.isEmpty) {
        _addLog('ℹ️ No hay retos para eliminar');
        setState(() {
          _isLoading = false;
          _message = 'No hay retos para eliminar';
        });
        return;
      }

      final batch = _firestore.batch();
      for (var doc in challenges.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      _addLog('✅ ${challenges.docs.length} retos eliminados exitosamente');

      setState(() {
        _isLoading = false;
        _message = '${challenges.docs.length} retos eliminados';
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
          'Inicializar Retos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Información
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      const Text(
                        'Información',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Esta pantalla te permite inicializar la base de datos con ${ChallengesData.initialChallenges.length} retos de ejemplo.\n\n'
                    'Esto es útil para empezar a probar el sistema de retos.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Botones de acción
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _initializeChallenges,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.add_task),
              label: Text(
                _isLoading ? 'Creando retos...' : 'Crear Retos de Ejemplo',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: _isLoading ? null : _deleteAllChallenges,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.delete_forever),
              label: const Text(
                'Eliminar Todos los Retos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Mensaje de estado
            if (_message.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Text(
                  _message,
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 16),

            // Logs
            if (_logs.isNotEmpty) ...[
              const Text(
                'Registro de actividad:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          _logs[index],
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
