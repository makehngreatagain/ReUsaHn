import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/challenge_model.dart';
import '../../models/challenge_completion_model.dart';
import '../../services/challenge_service.dart';
import '../../services/auth_service.dart';
import '../../utils/colors.dart';

class AdminChallengesWebScreen extends StatefulWidget {
  const AdminChallengesWebScreen({super.key});

  @override
  State<AdminChallengesWebScreen> createState() =>
      _AdminChallengesWebScreenState();
}

class _AdminChallengesWebScreenState extends State<AdminChallengesWebScreen>
    with SingleTickerProviderStateMixin {
  final ChallengeService _challengeService = ChallengeService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final adminId = authService.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Gestión de Retos',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Crea y administra los retos y aprueba las evidencias enviadas',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showChallengeDialog(null),
                      icon: const Icon(Icons.add),
                      label: const Text('Nuevo Reto'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Tabs
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppColors.primary,
                  tabs: const [
                    Tab(text: 'Retos Disponibles'),
                    Tab(text: 'Evidencias Pendientes'),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildChallengesTab(),
                _buildPendingApprovalsTab(adminId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengesTab() {
    return StreamBuilder<List<ChallengeModel>>(
      stream: _challengeService.getAllChallenges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final challenges = snapshot.data ?? [];

        if (challenges.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No hay retos creados',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showChallengeDialog(null),
                  icon: const Icon(Icons.add),
                  label: const Text('Crear Primer Reto'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 1400
                ? 3
                : constraints.maxWidth > 900
                    ? 2
                    : 1;

            return GridView.builder(
              padding: const EdgeInsets.all(24),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: challenges.length,
              itemBuilder: (context, index) {
                return _ChallengeCard(
                  challenge: challenges[index],
                  onEdit: () => _showChallengeDialog(challenges[index]),
                  onDelete: () => _deleteChallenge(challenges[index]),
                  onToggleStatus: () => _toggleStatus(challenges[index]),
                  onResetProgress: () => _resetProgress(challenges[index]),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPendingApprovalsTab(String adminId) {
    return StreamBuilder<List<ChallengeCompletionModel>>(
      stream: _challengeService.getPendingApprovals(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final completions = snapshot.data ?? [];

        if (completions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No hay evidencias pendientes de aprobación',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 1400
                ? 3
                : constraints.maxWidth > 900
                    ? 2
                    : 1;

            return GridView.builder(
              padding: const EdgeInsets.all(24),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.9,
              ),
              itemCount: completions.length,
              itemBuilder: (context, index) {
                return _ChallengeCompletionCard(
                  completion: completions[index],
                  onApprove: () => _approveCompletion(completions[index], adminId),
                  onReject: () => _rejectCompletion(completions[index], adminId),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showChallengeDialog(ChallengeModel? challenge) {
    showDialog(
      context: context,
      builder: (context) => _ChallengeDialog(
        challenge: challenge,
        onSave: (newChallenge) async {
          if (!mounted) return;
          final messenger = ScaffoldMessenger.of(context);

          try {
            if (challenge == null) {
              // Crear nuevo
              await _challengeService.createChallenge(newChallenge);
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Reto creado exitosamente'),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              // Actualizar existente
              await _challengeService.updateChallenge(
                  challenge.id, newChallenge);
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Reto actualizado exitosamente'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            messenger.showSnackBar(
              SnackBar(
                content: Text('Error: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _deleteChallenge(ChallengeModel challenge) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Reto'),
        content:
            Text('¿Estás seguro de eliminar el reto "${challenge.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _challengeService.deleteChallenge(challenge.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reto eliminado'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleStatus(ChallengeModel challenge) async {
    try {
      await _challengeService.toggleChallengeStatus(
          challenge.id, !challenge.isActive);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(challenge.isActive
                ? 'Reto desactivado'
                : 'Reto activado'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resetProgress(ChallengeModel challenge) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resetear Progreso'),
        content: Text(
            '¿Estás seguro de resetear el progreso de TODOS los usuarios en el reto "${challenge.title}"?\n\nEsta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Resetear'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _challengeService.resetChallengeProgress(challenge.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Progreso reseteado exitosamente'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _approveCompletion(
      ChallengeCompletionModel completion, String adminId) async {
    try {
      await _challengeService.approveChallenge(
        completionId: completion.id,
        adminId: adminId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Evidencia aprobada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectCompletion(
      ChallengeCompletionModel completion, String adminId) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar Evidencia'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Proporciona un motivo de rechazo:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Motivo del rechazo...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _challengeService.rejectChallenge(
        completionId: completion.id,
        adminId: adminId,
        reason: reasonController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Evidencia rechazada'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      reasonController.dispose();
    }
  }
}

class _ChallengeCard extends StatelessWidget {
  final ChallengeModel challenge;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;
  final VoidCallback onResetProgress;

  const _ChallengeCard({
    required this.challenge,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
    required this.onResetProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con título y estado
            Row(
              children: [
                Expanded(
                  child: Text(
                    challenge.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: challenge.isActive ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    challenge.isActive ? 'Activo' : 'Inactivo',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Descripción
            Text(
              challenge.description,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),

            // Información del reto
            Row(
              children: [
                Icon(Icons.emoji_events, size: 18, color: Colors.amber[700]),
                const SizedBox(width: 4),
                Text(
                  '${challenge.pointsReward} puntos',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[700],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.check_circle, size: 18, color: Colors.blue[700]),
                const SizedBox(width: 4),
                Text(
                  'Meta: ${challenge.targetCount}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Tipo de reto
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getIconForType(challenge.type),
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    challenge.type.label,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Editar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onToggleStatus,
                    icon: Icon(
                      challenge.isActive
                          ? Icons.visibility_off
                          : Icons.visibility,
                      size: 16,
                    ),
                    label: Text(challenge.isActive ? 'Ocultar' : 'Mostrar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          challenge.isActive ? Colors.orange : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert),
                  tooltip: 'Más opciones',
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      onTap: onResetProgress,
                      child: const Row(
                        children: [
                          Icon(Icons.refresh, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Resetear Progreso'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      onTap: onDelete,
                      child: const Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Eliminar Reto'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(ChallengeType type) {
    switch (type) {
      case ChallengeType.plantTree:
        return Icons.park;
      case ChallengeType.makePublications:
        return Icons.article;
      case ChallengeType.makeExchanges:
        return Icons.swap_horiz;
      case ChallengeType.recycling:
        return Icons.recycling;
      case ChallengeType.other:
        return Icons.eco;
    }
  }
}

class _ChallengeDialog extends StatefulWidget {
  final ChallengeModel? challenge;
  final Function(ChallengeModel) onSave;

  const _ChallengeDialog({
    this.challenge,
    required this.onSave,
  });

  @override
  State<_ChallengeDialog> createState() => _ChallengeDialogState();
}

class _ChallengeDialogState extends State<_ChallengeDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _pointsController;
  late TextEditingController _targetController;
  late ChallengeType _selectedType;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.challenge?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.challenge?.description ?? '');
    _pointsController = TextEditingController(
        text: widget.challenge?.pointsReward.toString() ?? '100');
    _targetController = TextEditingController(
        text: widget.challenge?.targetCount.toString() ?? '1');
    _selectedType = widget.challenge?.type ?? ChallengeType.other;
    _isActive = widget.challenge?.isActive ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.challenge == null ? 'Nuevo Reto' : 'Editar Reto'),
      content: SizedBox(
        width: 600,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Título
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título del Reto',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El título es requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Descripción
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'La descripción es requerida';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Tipo de reto
                DropdownButtonFormField<ChallengeType>(
                  initialValue: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Reto',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: ChallengeType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.label),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Puntos y meta en fila
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _pointsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Puntos de Recompensa',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.emoji_events),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Los puntos son requeridos';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Debe ser un número';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _targetController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Meta (cantidad)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.flag),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'La meta es requerida';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Debe ser un número';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Estado activo/inactivo
                SwitchListTile(
                  title: const Text('Reto Activo'),
                  subtitle: Text(_isActive
                      ? 'Los usuarios pueden ver y completar este reto'
                      : 'Este reto estará oculto para los usuarios'),
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                  activeThumbColor: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final challenge = ChallengeModel(
      id: widget.challenge?.id ?? '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      type: _selectedType,
      pointsReward: int.parse(_pointsController.text.trim()),
      targetCount: int.parse(_targetController.text.trim()),
      imageUrl: '', // No se permite subir imagen desde admin
      isActive: _isActive,
      createdAt: widget.challenge?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    widget.onSave(challenge);
    Navigator.pop(context);
  }
}

class _ChallengeCompletionCard extends StatelessWidget {
  final ChallengeCompletionModel completion;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ChallengeCompletionCard({
    required this.completion,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.person, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Usuario: ${completion.userId}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Reto ID: ${completion.challengeId}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),

            // Progreso
            if (completion.currentCount > 0) ...[
              Row(
                children: [
                  const Icon(Icons.check_circle, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    'Progreso: ${completion.currentCount}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Fecha de envío
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Enviado: ${_formatDate(completion.completedAt)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Imágenes de evidencia
            if (completion.proofImageUrls.isNotEmpty) ...[
              const Text(
                'Evidencias:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: completion.proofImageUrls.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => _showImageDialog(
                            context, completion.proofImageUrls[index]),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            completion.proofImageUrls[index],
                            width: 150,
                            height: 150,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 150,
                                height: 150,
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 150,
                                height: 150,
                                color: Colors.grey[300],
                                child: const Icon(Icons.broken_image, size: 40),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],

            const Spacer(),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Aprobar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Rechazar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Evidencia',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Flexible(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.broken_image, size: 64),
                          SizedBox(height: 8),
                          Text('Error al cargar imagen'),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
