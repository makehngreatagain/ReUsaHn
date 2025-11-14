import 'package:flutter/material.dart';
import '../models/user_ranking_model.dart';
import '../utils/colors.dart';
import '../utils/rankings_data.dart';

class RankingsScreen extends StatefulWidget {
  const RankingsScreen({super.key});

  @override
  State<RankingsScreen> createState() => _RankingsScreenState();
}

class _RankingsScreenState extends State<RankingsScreen> {
  List<UserRankingModel> rankings = [];

  @override
  void initState() {
    super.initState();
    rankings = List.from(RankingsData.rankings);
    // Ordenar por puntos de mayor a menor
    rankings.sort((a, b) => b.greenPoints.compareTo(a.greenPoints));
  }

  @override
  Widget build(BuildContext context) {
    final top3 = rankings.take(3).toList();
    final remaining = rankings.skip(3).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Usuarios Más Ecológicos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header con descripción
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.emoji_events,
                    color: Colors.amber[400],
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Top Usuarios',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Los usuarios con más puntos verdes',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Podio para top 3
            if (top3.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  height: 240,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // 2do lugar
                      if (top3.length > 1)
                        Expanded(
                          child: _buildPodiumPlace(
                            user: top3[1],
                            position: 2,
                            height: 150,
                            color: Colors.grey[400]!,
                          ),
                        ),
                      const SizedBox(width: 8),
                      // 1er lugar
                      Expanded(
                        child: _buildPodiumPlace(
                          user: top3[0],
                          position: 1,
                          height: 190,
                          color: Colors.amber[400]!,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 3er lugar
                      if (top3.length > 2)
                        Expanded(
                          child: _buildPodiumPlace(
                            user: top3[2],
                            position: 3,
                            height: 120,
                            color: Colors.brown[400]!,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 32),

            // Resto de usuarios
            if (remaining.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.leaderboard,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Otros Usuarios',
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
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: remaining.length,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  final user = remaining[index];
                  final position = index + 4; // Porque los primeros 3 están en el podio
                  return _buildRankingCard(user, position);
                },
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPodiumPlace({
    required UserRankingModel user,
    required int position,
    required double height,
    required Color color,
  }) {
    IconData positionIcon;
    if (position == 1) {
      positionIcon = Icons.looks_one;
    } else if (position == 2) {
      positionIcon = Icons.looks_two;
    } else {
      positionIcon = Icons.looks_3;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[300],
            border: Border.all(
              color: color,
              width: 2,
            ),
          ),
          child: user.profileImageUrl.isEmpty
              ? Icon(
                  Icons.person,
                  size: 24,
                  color: Colors.grey[600],
                )
              : ClipOval(
                  child: Image.network(
                    user.profileImageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
        ),
        const SizedBox(height: 4),
        // Nombre
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            user.name.split(' ')[0], // Solo el primer nombre
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 2),
        // Puntos
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.eco,
              size: 11,
              color: AppColors.primary,
            ),
            const SizedBox(width: 2),
            Text(
              '${user.greenPoints}',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Podio
        Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                positionIcon,
                size: 36,
                color: Colors.white,
              ),
              const SizedBox(height: 2),
              Text(
                '#$position',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRankingCard(UserRankingModel user, int position) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            // Posición
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$position',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Avatar
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[300],
              ),
              child: user.profileImageUrl.isEmpty
                  ? Icon(
                      Icons.person,
                      size: 24,
                      color: Colors.grey[600],
                    )
                  : ClipOval(
                      child: Image.network(
                        user.profileImageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            // Nombre y estadísticas
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        Icons.emoji_events,
                        size: 11,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${user.challengesCompleted} retos',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.swap_horiz,
                        size: 11,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          '${user.articlesExchanged} inter.',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Puntos
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.eco,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${user.greenPoints}',
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
      ),
    );
  }
}
