import 'package:flutter/material.dart';
import '../models/reward_model.dart';
import '../utils/colors.dart';
import '../utils/rewards_data.dart';

class RewardsStoreScreen extends StatefulWidget {
  const RewardsStoreScreen({super.key});

  @override
  State<RewardsStoreScreen> createState() => _RewardsStoreScreenState();
}

class _RewardsStoreScreenState extends State<RewardsStoreScreen> {
  // Puntos de los Usuarios
  int userPoints = 0;
  RewardCategory? _selectedCategory;
  List<RewardModel> filteredRewards = [];

  @override
  void initState() {
    super.initState();
    filteredRewards = RewardsData.rewards;
  }

  void _filterRewards() {
    setState(() {
      if (_selectedCategory == null) {
        filteredRewards = RewardsData.rewards;
      } else {
        filteredRewards = RewardsData.rewards
            .where((reward) => reward.category == _selectedCategory)
            .toList();
      }
    });
  }

  void _redeemReward(RewardModel reward) {
    if (userPoints >= reward.pointsCost && reward.stock > 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Canjear Recompensa'),
          content: Text(
            '¿Deseas canjear "${reward.name}" por ${reward.pointsCost} puntos verdes?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  userPoints -= reward.pointsCost;
                  // Aquí se actualizaría el stock en una base de datos real
                });
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('¡Recompensa canjeada! Te quedan $userPoints puntos'),
                        ),
                      ],
                    ),
                    backgroundColor: AppColors.primary,
                    duration: const Duration(seconds: 3),
                  ),
                );
              },
              child: const Text(
                'Canjear',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    } else if (userPoints < reward.pointsCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Text('No tienes suficientes puntos'),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Text('Producto agotado'),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Tienda de Recompensas',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header con puntos del usuario
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
                const Text(
                  'Tus Puntos Verdes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.eco,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$userPoints',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Filtros de categoría
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Opción "Todas"
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('Todas'),
                      selected: _selectedCategory == null,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = null;
                          _filterRewards();
                        });
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor: AppColors.chipBackground,
                      labelStyle: TextStyle(
                        color: _selectedCategory == null
                            ? AppColors.chipText
                            : AppColors.textSecondary,
                        fontWeight: _selectedCategory == null
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  // Categorías
                  ...RewardCategory.values.map((category) {
                    final isSelected = _selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category.displayName),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = selected ? category : null;
                            _filterRewards();
                          });
                        },
                        backgroundColor: Colors.grey[200],
                        selectedColor: AppColors.chipBackground,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.chipText
                              : AppColors.textSecondary,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Lista de recompensas
          Expanded(
            child: filteredRewards.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.card_giftcard,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay recompensas en esta categoría',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: filteredRewards.length,
                    itemBuilder: (context, index) {
                      final reward = filteredRewards[index];
                      final canAfford = userPoints >= reward.pointsCost;
                      final hasStock = reward.stock > 0;

                      return Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: canAfford && hasStock
                              ? () => _redeemReward(reward)
                              : null,
                          borderRadius: BorderRadius.circular(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Imagen del producto
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      topRight: Radius.circular(12),
                                    ),
                                  ),
                                  child: reward.imageUrl.isEmpty
                                      ? Icon(
                                          Icons.card_giftcard,
                                          size: 48,
                                          color: Colors.grey[400],
                                        )
                                      : ClipRRect(
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(12),
                                            topRight: Radius.circular(12),
                                          ),
                                          child: Image.network(
                                            reward.imageUrl,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                ),
                              ),

                              // Información del producto
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Nombre
                                    Text(
                                      reward.name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),

                                    // Stock
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.inventory_2,
                                          size: 12,
                                          color: hasStock
                                              ? AppColors.primary
                                              : Colors.red,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          hasStock
                                              ? 'Stock: ${reward.stock}'
                                              : 'Agotado',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: hasStock
                                                ? AppColors.textSecondary
                                                : Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),

                                    // Puntos
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: canAfford && hasStock
                                            ? AppColors.primary
                                            : Colors.grey,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.eco,
                                            size: 12,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${reward.pointsCost}',
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
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
