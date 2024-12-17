import '../services/auth_service.dart';
import '../database/db_helper.dart';
import '../models/user_model.dart';

class UserController {
  final AuthService _authService = AuthService();
  final DBHelper _dbHelper = DBHelper();

  Future<UserModel?> signUp(String email, String password, String name, String preferences) async {
    UserModel? user = await _authService.signUp(email, password, name, preferences);
    if (user != null) {
      await _dbHelper.insertUser(user);
    }
    return user;
  }

  Future<UserModel?> login(String email, String password) async {
    UserModel? user = await _authService.login(email, password);
    if (user != null) {
      final localUser = await _dbHelper.getUserByFirebaseId(user.firebaseId);
      if (localUser == null) {
        await _dbHelper.insertUser(user);
      }
    }
    return user;
  }

  Future<void> updatePreferences(String firebaseId, String preferences) async {
    await _dbHelper.updateUserPreferences(firebaseId, preferences);
  }
}
