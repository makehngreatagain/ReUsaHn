import '../models/user_model.dart';

class CurrentUserData {
  static UserModel _currentUser = UserModel(
    id: 'user_current',
    name: 'Usuario Actual',
    email: 'usuario@reusahn.com',
    profileImageUrl: '',
    bio: 'Amante del medio ambiente y el reciclaje. Comprometido con un futuro más verde para Honduras.',
    phone: '+504 9999-9999',
    greenPoints: 450,
    joinedDate: DateTime(2024, 1, 15),
    createdAt: DateTime(2024, 1, 15),
    updatedAt: DateTime(2024, 1, 15),
  );

  static UserModel getCurrentUser() {
    return _currentUser;
  }

  static void updateUser(UserModel user) {
    _currentUser = user;
  }

  static void addGreenPoints(int points) {
    _currentUser = _currentUser.copyWith(
      greenPoints: _currentUser.greenPoints + points,
    );
  }
}
