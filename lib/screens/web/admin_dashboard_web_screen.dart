import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/colors.dart';
import 'admin_posts_web_screen.dart';
import 'admin_trees_web_screen.dart';
import 'admin_rewards_web_screen.dart';
import 'admin_stats_web_screen.dart';
import 'admin_challenges_web_screen.dart';
import 'admin_users_web_screen.dart';
import 'admin_tickets_web_screen.dart';
import 'admin_login_web_screen.dart';

class AdminDashboardWebScreen extends StatefulWidget {
  const AdminDashboardWebScreen({super.key});

  @override
  State<AdminDashboardWebScreen> createState() =>
      _AdminDashboardWebScreenState();
}

class _AdminDashboardWebScreenState extends State<AdminDashboardWebScreen> {
  int _selectedIndex = 0;
  bool _isDrawerExpanded = true;

  final List<_NavigationItem> _navigationItems = [
    _NavigationItem(
      icon: Icons.dashboard,
      label: 'Dashboard',
      index: 0,
    ),
    _NavigationItem(
      icon: Icons.people,
      label: 'Usuarios',
      index: 1,
    ),
    _NavigationItem(
      icon: Icons.article,
      label: 'Publicaciones',
      index: 2,
    ),
    _NavigationItem(
      icon: Icons.park,
      label: 'Árboles',
      index: 3,
    ),
    _NavigationItem(
      icon: Icons.emoji_events,
      label: 'Retos',
      index: 4,
    ),
    _NavigationItem(
      icon: Icons.card_giftcard,
      label: 'Recompensas',
      index: 5,
    ),
    _NavigationItem(
      icon: Icons.support_agent,
      label: 'Soporte',
      index: 6,
    ),
  ];

  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return const AdminStatsWebScreen();
      case 1:
        return const AdminUsersWebScreen();
      case 2:
        return const AdminPostsWebScreen();
      case 3:
        return const AdminTreesWebScreen();
      case 4:
        return const AdminChallengesWebScreen();
      case 5:
        return const AdminRewardsWebScreen();
      case 6:
        return const AdminTicketsWebScreen();
      default:
        return const AdminStatsWebScreen();
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signOut();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const AdminLoginWebScreen(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Navegación lateral
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isDrawerExpanded ? 250 : 70,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Container(
                  height: 80,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  child: Row(
                    children: [
                      Icon(
                        Icons.admin_panel_settings,
                        color: Colors.white,
                        size: _isDrawerExpanded ? 32 : 28,
                      ),
                      if (_isDrawerExpanded) ...[
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Admin Panel',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'ReUsa Honduras',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Navegación
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: _navigationItems.map((item) {
                      final isSelected = _selectedIndex == item.index;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedIndex = item.index;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: _isDrawerExpanded ? 16 : 8,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    item.icon,
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.grey[600],
                                    size: 24,
                                  ),
                                  if (_isDrawerExpanded) ...[
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        item.label,
                                        style: TextStyle(
                                          color: isSelected
                                              ? AppColors.primary
                                              : Colors.grey[800],
                                          fontSize: 14,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Usuario y logout
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Toggle drawer
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _isDrawerExpanded = !_isDrawerExpanded;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isDrawerExpanded
                                      ? Icons.chevron_left
                                      : Icons.chevron_right,
                                  color: Colors.grey[600],
                                ),
                                if (_isDrawerExpanded) ...[
                                  const SizedBox(width: 8),
                                  const Flexible(
                                    child: Text(
                                      'Contraer',
                                      style: TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Logout
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _logout,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.logout,
                                  color: Colors.red[700],
                                ),
                                if (_isDrawerExpanded) ...[
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          user?.email ?? 'Admin',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'Cerrar sesión',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.red[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Contenido principal
          Expanded(
            child: _getSelectedScreen(),
          ),
        ],
      ),
    );
  }
}

class _NavigationItem {
  final IconData icon;
  final String label;
  final int index;

  _NavigationItem({
    required this.icon,
    required this.label,
    required this.index,
  });
}
