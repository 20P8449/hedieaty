import '../services/auth_service.dart';
import '../database/db_helper.dart';
import '../models/user_model.dart';

class UserController {
  final AuthService _authService = AuthService();
  final DBHelper _dbHelper = DBHelper();

  Future<UserModel?> signUp(
      String email, String password, String name, String preferences, String mobile) async {
    // Call AuthService to sign up the user with the additional mobile field
    UserModel? user = await _authService.signUp(email, password, name, preferences, mobile);
    if (user != null) {
      // Save the user in the local SQLite database, including mobile
      await _dbHelper.insertUser(user);
    }
    return user;
  }

  Future<UserModel?> login(String email, String password) async {
    UserModel? user = await _authService.login(email, password);
    if (user != null) {
      final localUser = await _dbHelper.getUserByFirebaseId(user.firebaseId);
      if (localUser == null) {
        // Save user in the local SQLite database if not already present
        await _dbHelper.insertUser(user);
      }
    }
    return user;
  }

  Future<void> updatePreferences(String firebaseId, String preferences) async {
    // Update user preferences in SQLite
    await _dbHelper.updateUserPreferences(firebaseId, preferences);
  }

  Future<void> logout() async {
    // Logout the user using AuthService
    await _authService.logout();
  }

  Future<String> getCurrentUserId() async {
    // Retrieve the current user's UID from AuthService
    final userId = await _authService.getCurrentUserId();
    if (userId != null) {
      return userId;
    } else {
      throw Exception('User not logged in.');
    }
  }

  Future<String> getUserName(String firebaseId) async {
    // Fetch the user's name from the database
    final user = await _dbHelper.getUserByFirebaseId(firebaseId);
    if (user != null) {
      return user.name;
    } else {
      throw Exception('User not found.');
    }
  }

  Future<String?> getUserProfileImage(String firebaseId) async {
    // Fetch the user's profile image from Firestore or SQLite
    final user = await _dbHelper.getUserByFirebaseId(firebaseId);
    // For this example, we assume profile image is stored in Firestore
    if (user != null) {
      final profileImage = await _authService.getUserProfileImage(firebaseId);
      return profileImage;
    }
    return null; // Return null if the profile image doesn't exist
  }
}
