import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/challenge_model.dart';
import '../models/challenge_completion_model.dart';
import '../services/auth_service.dart';
import '../services/challenge_service.dart';
import '../utils/colors.dart';
import 'challenge_detail_screen.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  final ChallengeService _challengeService = ChallengeService();

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Retos Ecológicos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<ChallengeModel>>(
        stream: _challengeService.getActiveChallenges(),
        builder: (context, challengesSnapshot) {
          if (challengesSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (challengesSnapshot.hasError) {
            return Center(
              child: Text('Error: ${challengesSnapshot.error}'),
            );
          }

          final challenges = challengesSnapshot.data ?? [];

          if (challenges.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.eco_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay retos disponibles',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pronto habrá nuevos retos ecológicos',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          // Obtener el progreso del usuario en paralelo
          return StreamBuilder<List<ChallengeCompletionModel>>(
            stream: _challengeService.getUserChallengeProgress(currentUserId),
            builder: (context, progressSnapshot) {
              final userProgress = progressSnapshot.data ?? [];

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: challenges.length,
                itemBuilder: (context, index) {
                  final challenge = challenges[index];

                  // Buscar si el usuario tiene progreso en este reto
                  final progress = userProgress.firstWhere(
                    (p) => p.challengeId == challenge.id,
                    orElse: () => ChallengeCompletionModel(
                      id: '',
                      userId: currentUserId,
                      challengeId: challenge.id,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    ),
                  );

                  return _buildChallengeCard(
                    context,
                    challenge,
                    progress,
                    currentUserId,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildChallengeCard(
    BuildContext context,
    ChallengeModel challenge,
    ChallengeCompletionModel progress,
    String currentUserId,
  ) {
    // Determinar el ícono según el tipo de reto
    IconData iconData;
    switch (challenge.type) {
      case ChallengeType.plantTree:
        iconData = Icons.park;
        break;
      case ChallengeType.makePublications:
        iconData = Icons.article;
        break;
      case ChallengeType.makeExchanges:
        iconData = Icons.swap_horiz;
        break;
      case ChallengeType.recycling:
        iconData = Icons.recycling;
        break;
      case ChallengeType.other:
        iconData = Icons.eco;
        break;
    }

    // Determinar el color según el estado del progreso
    Color statusColor;
    String statusLabel;

    if (progress.isCompleted) {
      statusColor = Colors.green;
      statusLabel = 'Completado';
    } else if (progress.canClaim) {
      statusColor = Colors.blue;
      statusLabel = 'Listo para reclamar';
    } else if (progress.needsReview) {
      statusColor = Colors.orange;
      statusLabel = 'En revisión';
    } else if (progress.status == CompletionStatus.rejected) {
      statusColor = Colors.red;
      statusLabel = 'Rechazado';
    } else if (progress.currentCount > 0) {
      statusColor = Colors.amber;
      statusLabel = 'En progreso';
    } else {
      statusColor = AppColors.primary;
      statusLabel = 'Disponible';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChallengeDetailScreen(
                challenge: challenge,
                currentUserId: currentUserId,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icono del reto
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  iconData,
                  color: statusColor,
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              // Contenido del reto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    Text(
                      challenge.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Descripción
                    Text(
                      challenge.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    // Progreso
                    if (progress.currentCount > 0 && !progress.isCompleted)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '${progress.currentCount}/${challenge.targetCount}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: progress.currentCount / challenge.targetCount,
                                      backgroundColor: Colors.grey[200],
                                      valueColor: AlwaysStoppedAnimation(statusColor),
                                      minHeight: 6,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    // Info adicional
                    Row(
                      children: [
                        // Estado
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 11,
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Puntos
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.eco,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '+${challenge.pointsReward}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
