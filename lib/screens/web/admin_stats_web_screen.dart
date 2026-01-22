import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/colors.dart';

class AdminStatsWebScreen extends StatelessWidget {
  const AdminStatsWebScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Resumen general de la plataforma',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),

            // Tarjetas de estadísticas
            StreamBuilder<Map<String, int>>(
              stream: _getStats(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final stats = snapshot.data ?? {};

                return Column(
                  children: [
                    // Primera fila de stats
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth > 1200
                            ? 4
                            : constraints.maxWidth > 800
                                ? 3
                                : constraints.maxWidth > 500
                                    ? 2
                                    : 1;

                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.8,
                          children: [
                            _StatCard(
                              title: 'Usuarios Totales',
                              value: '${stats['users'] ?? 0}',
                              icon: Icons.people,
                              color: Colors.blue,
                            ),
                            _StatCard(
                              title: 'Publicaciones',
                              value: '${stats['posts'] ?? 0}',
                              icon: Icons.article,
                              color: Colors.green,
                            ),
                            _StatCard(
                              title: 'Árboles Plantados',
                              value: '${stats['trees'] ?? 0}',
                              icon: Icons.park,
                              color: Colors.teal,
                            ),
                            _StatCard(
                              title: 'Intercambios',
                              value: '${stats['exchanges'] ?? 0}',
                              icon: Icons.swap_horiz,
                              color: Colors.orange,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Segunda fila de stats
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth > 1200
                            ? 4
                            : constraints.maxWidth > 800
                                ? 3
                                : constraints.maxWidth > 500
                                    ? 2
                                    : 1;

                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.8,
                          children: [
                            _StatCard(
                              title: 'Publicaciones Pendientes',
                              value: '${stats['pendingPosts'] ?? 0}',
                              icon: Icons.pending,
                              color: Colors.amber,
                            ),
                            _StatCard(
                              title: 'Árboles Pendientes',
                              value: '${stats['pendingTrees'] ?? 0}',
                              icon: Icons.hourglass_empty,
                              color: Colors.deepOrange,
                            ),
                            _StatCard(
                              title: 'Retos Pendientes',
                              value: '${stats['pendingChallenges'] ?? 0}',
                              icon: Icons.emoji_events,
                              color: Colors.purple,
                            ),
                            _StatCard(
                              title: 'Canjes Pendientes',
                              value: '${stats['pendingRedemptions'] ?? 0}',
                              icon: Icons.shopping_bag,
                              color: Colors.pink,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 40),

            // Actividad reciente
            const Text(
              'Actividad Reciente',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _RecentActivityWidget(),
          ],
        ),
      ),
    );
  }

  Stream<Map<String, int>> _getStats() {
    final firestore = FirebaseFirestore.instance;

    return Stream.periodic(const Duration(seconds: 5)).asyncMap((_) async {
      final stats = <String, int>{};

      // Contar usuarios
      final usersSnapshot = await firestore.collection('users').get();
      stats['users'] = usersSnapshot.docs.length;

      // Contar publicaciones
      final postsSnapshot = await firestore.collection('posts').get();
      stats['posts'] = postsSnapshot.docs.length;

      // Contar publicaciones pendientes
      final pendingPostsSnapshot = await firestore
          .collection('posts')
          .where('status', isEqualTo: 'pending')
          .get();
      stats['pendingPosts'] = pendingPostsSnapshot.docs.length;

      // Contar árboles
      final treesSnapshot = await firestore.collection('tree_plantings').get();
      stats['trees'] = treesSnapshot.docs.length;

      // Contar árboles pendientes
      final pendingTreesSnapshot = await firestore
          .collection('tree_plantings')
          .where('status', isEqualTo: 'pending')
          .get();
      stats['pendingTrees'] = pendingTreesSnapshot.docs.length;

      // Contar intercambios completados
      final exchangesSnapshot = await firestore
          .collection('exchanges')
          .where('isCompleted', isEqualTo: true)
          .get();
      stats['exchanges'] = exchangesSnapshot.docs.length;

      // Contar retos pendientes
      final pendingChallengesSnapshot = await firestore
          .collection('challenge_completions')
          .where('status', isEqualTo: 'pending')
          .get();
      stats['pendingChallenges'] = pendingChallengesSnapshot.docs.length;

      // Contar canjes pendientes
      final pendingRedemptionsSnapshot = await firestore
          .collection('reward_redemptions')
          .where('status', isEqualTo: 'pending')
          .get();
      stats['pendingRedemptions'] = pendingRedemptionsSnapshot.docs.length;

      return stats;
    }).asBroadcastStream();
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentActivityWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No hay actividad reciente',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: snapshot.data!.docs.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final article = data['article'] as Map<String, dynamic>?;
              final user = data['user'] as Map<String, dynamic>?;

              return ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.article,
                    color: AppColors.primary,
                  ),
                ),
                title: Text(
                  article?['title'] ?? 'Sin título',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  'Publicado por ${user?['name'] ?? 'Usuario desconocido'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(data['status'] as String?)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(data['status'] as String?),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(data['status'] as String?),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'approved':
        return 'Aprobada';
      case 'pending':
        return 'Pendiente';
      case 'rejected':
        return 'Rechazada';
      default:
        return 'Desconocido';
    }
  }
}
