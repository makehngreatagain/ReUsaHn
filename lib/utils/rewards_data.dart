import '../models/reward_model.dart';

class RewardsData {
  static final List<RewardModel> rewards = [
    RewardModel(
      id: 'reward1',
      name: 'Lápices de Cartón Reciclado',
      description: 'Set de 5 lápices hechos con cartón reciclado. Perfectos para escribir y ayudar al planeta.',
      pointsCost: 50,
      imageUrl: '',
      stock: 25,
      category: RewardCategory.educational,
    ),
    RewardModel(
      id: 'reward2',
      name: 'Planta Suculenta',
      description: 'Pequeña planta suculenta en maceta biodegradable. Fácil de cuidar.',
      pointsCost: 100,
      imageUrl: '',
      stock: 15,
      category: RewardCategory.plants,
    ),
    RewardModel(
      id: 'reward3',
      name: 'Camiseta ReUsa Honduras',
      description: 'Camiseta 100% algodón orgánico con el logo de ReUsa Honduras.',
      pointsCost: 200,
      imageUrl: '',
      stock: 20,
      category: RewardCategory.merchandise,
    ),
    RewardModel(
      id: 'reward4',
      name: 'Taza Térmica Reutilizable',
      description: 'Taza térmica de acero inoxidable con el logo de ReUsa Honduras. Mantiene tu bebida caliente o fría.',
      pointsCost: 150,
      imageUrl: '',
      stock: 30,
      category: RewardCategory.merchandise,
    ),
    RewardModel(
      id: 'reward5',
      name: 'Bolsa de Tela Reutilizable',
      description: 'Bolsa de tela resistente y reutilizable. Perfecta para tus compras.',
      pointsCost: 75,
      imageUrl: '',
      stock: 40,
      category: RewardCategory.ecofriendly,
    ),
    RewardModel(
      id: 'reward6',
      name: 'Cuaderno Reciclado',
      description: 'Cuaderno de 100 hojas hecho con papel reciclado.',
      pointsCost: 80,
      imageUrl: '',
      stock: 35,
      category: RewardCategory.educational,
    ),
  ];
}
