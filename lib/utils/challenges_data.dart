import '../models/challenge_model.dart';

class ChallengesData {
  // Retos de ejemplo para inicializar Firestore
  static final List<Map<String, dynamic>> initialChallenges = [
    {
      'title': 'Planta 5 Árboles',
      'description':
          'Ayuda al medio ambiente plantando 5 árboles. Toma fotos de cada árbol plantado como evidencia. Un administrador revisará tu evidencia.',
      'type': ChallengeType.plantTree.name,
      'pointsReward': 250,
      'targetCount': 5,
      'imageUrl': '',
      'isActive': true,
    },
    {
      'title': 'Haz 10 Publicaciones',
      'description':
          'Comparte artículos para intercambiar. Publica 10 artículos que ya no uses para darles una segunda vida.',
      'type': ChallengeType.makePublications.name,
      'pointsReward': 100,
      'targetCount': 10,
      'imageUrl': '',
      'isActive': true,
    },
    {
      'title': 'Completa 5 Intercambios',
      'description':
          'Realiza 5 intercambios exitosos con otros usuarios. Toma fotos de tus intercambios como evidencia.',
      'type': ChallengeType.makeExchanges.name,
      'pointsReward': 200,
      'targetCount': 5,
      'imageUrl': '',
      'isActive': true,
    },
    {
      'title': 'Recicla 10 kg de Material',
      'description':
          'Recolecta y lleva al menos 10 kg de material reciclable a un centro de reciclaje. Toma foto del recibo o evidencia.',
      'type': ChallengeType.recycling.name,
      'pointsReward': 150,
      'targetCount': 1,
      'imageUrl': '',
      'isActive': true,
    },
    {
      'title': 'Principiante: Haz tu Primera Publicación',
      'description':
          '¡Comienza tu viaje verde! Publica tu primer artículo para intercambiar y gana puntos.',
      'type': ChallengeType.makePublications.name,
      'pointsReward': 20,
      'targetCount': 1,
      'imageUrl': '',
      'isActive': true,
    },
    {
      'title': 'Experto Verde: 20 Publicaciones',
      'description':
          'Conviértete en un experto del intercambio sostenible. Publica 20 artículos y ayuda a la comunidad.',
      'type': ChallengeType.makePublications.name,
      'pointsReward': 300,
      'targetCount': 20,
      'imageUrl': '',
      'isActive': true,
    },
    {
      'title': 'Planta 1 Árbol',
      'description':
          'Da tu primer paso hacia un planeta más verde. Planta un árbol y toma una foto como evidencia.',
      'type': ChallengeType.plantTree.name,
      'pointsReward': 50,
      'targetCount': 1,
      'imageUrl': '',
      'isActive': true,
    },
    {
      'title': 'Realiza tu Primer Intercambio',
      'description':
          '¡Completa tu primer intercambio! Encuentra un artículo que necesites y haz el intercambio.',
      'type': ChallengeType.makeExchanges.name,
      'pointsReward': 30,
      'targetCount': 1,
      'imageUrl': '',
      'isActive': true,
    },
  ];

  // Función helper para crear los retos iniciales en Firestore
  // Esta función se puede llamar desde un script de inicialización
  static Map<String, dynamic> createChallengeData(Map<String, dynamic> challenge) {
    return {
      ...challenge,
      'createdAt': DateTime.now(),
      'updatedAt': DateTime.now(),
    };
  }
}
