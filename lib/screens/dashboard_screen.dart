import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../utils/colors.dart';
import 'publications_screen.dart';
import 'chats_screen.dart';
import 'mapa_verde_screen.dart';
import 'rewards_store_screen.dart';
import 'rankings_screen.dart';
import 'challenges_screen.dart';
import 'profile_screen.dart';
import 'admin_posts_screen.dart';
import 'init_challenges_screen.dart';
import 'init_green_zones_screen.dart';
import 'admin_trees_screen.dart';
import 'admin_rewards_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isAdmin = false;
  String _userName = 'Usuario';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userData = await authService.getCurrentUserData();

    if (mounted && userData != null) {
      setState(() {
        _userName = userData.name;
        _isAdmin = userData.isAdmin;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'ReUsa Honduras',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminPostsScreen(),
                  ),
                );
              },
              tooltip: 'Panel de Administración',
            ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            iconSize: 32,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
            tooltip: 'Mi Perfil',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bienvenido, $_userName!',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Selecciona una sección para comenzar',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (_isAdmin) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'ADMIN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 32),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _DashboardCard(
                    title: 'Mercado de Intercambios',
                    subtitle: 'Intercambia artículos',
                    icon: Icons.swap_horiz,
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PublicationsScreen(),
                        ),
                      );
                    },
                  ),
                  _DashboardCard(
                    title: 'Chats',
                    subtitle: 'Mensajes y conversaciones',
                    icon: Icons.chat,
                    color: const Color(0xFF2196F3),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChatsScreen(),
                        ),
                      );
                    },
                  ),
                  _DashboardCard(
                    title: 'Mapa Verde',
                    subtitle: 'Puntos seguros y eventos',
                    icon: Icons.map,
                    color: const Color(0xFF4CAF50),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MapaVerdeScreen(),
                        ),
                      );
                    },
                  ),
                  _DashboardCard(
                    title: 'Retos',
                    subtitle: 'Desafíos ecológicos',
                    icon: Icons.emoji_events,
                    color: const Color(0xFFFF9800),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChallengesScreen(),
                        ),
                      );
                    },
                  ),
                  _DashboardCard(
                    title: 'Ranking',
                    subtitle: 'Clasificación de usuarios',
                    icon: Icons.leaderboard,
                    color: const Color(0xFF9C27B0),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RankingsScreen(),
                        ),
                      );
                    },
                  ),
                  _DashboardCard(
                    title: 'Tienda de Recompensas',
                    subtitle: 'Canjea tus puntos',
                    icon: Icons.store,
                    color: const Color(0xFFE91E63),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RewardsStoreScreen(),
                        ),
                      );
                    },
                  ),
                  // Tarjetas especiales para admins
                  if (_isAdmin) ...[
                    _DashboardCard(
                      title: 'Inicializar Retos',
                      subtitle: 'Cargar retos de ejemplo',
                      icon: Icons.settings_backup_restore,
                      color: const Color(0xFF607D8B),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const InitChallengesScreen(),
                          ),
                        );
                      },
                    ),
                    _DashboardCard(
                      title: 'Inicializar Zonas Verdes',
                      subtitle: 'Cargar zonas del mapa',
                      icon: Icons.add_location_alt,
                      color: const Color(0xFF4CAF50),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const InitGreenZonesScreen(),
                          ),
                        );
                      },
                    ),
                    _DashboardCard(
                      title: 'Gestión de Árboles',
                      subtitle: 'Revisar árboles plantados',
                      icon: Icons.park,
                      color: const Color(0xFF66BB6A),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminTreesScreen(),
                          ),
                        );
                      },
                    ),
                    _DashboardCard(
                      title: 'Gestión de Recompensas',
                      subtitle: 'Administrar tienda',
                      icon: Icons.card_giftcard,
                      color: const Color(0xFFE91E63),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminRewardsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color,
                color.withValues(alpha: 0.7),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 40,
                color: Colors.white,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
