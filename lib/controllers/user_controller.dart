import '../services/auth_service.dart';
import '../database/db_helper.dart';
import '../models/user_model.dart';

class UserController {
  final AuthService _authService = AuthService();
  final DBHelper _dbHelper = DBHelper();

  // Sign Up a New User
  Future<UserModel?> signUp(
      String email,
      String password,
      String name,
      String preferences,
      String mobile,
      ) async {
    // Call AuthService to sign up the user with the additional mobile field
    UserModel? user = await _authService.signUp(email, password, name, preferences, mobile);
    if (user != null) {
      // Save the user in the local SQLite database, including mobile
      await _dbHelper.insertUser(user);
    }
    return user;
  }

  // Log in an Existing User
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

  // Update User Preferences
  Future<void> updatePreferences(String firebaseId, String preferences) async {
    await _dbHelper.updateUserPreferences(firebaseId, preferences);
  }

  // Log Out the Current User
  Future<void> logout() async {
    await _authService.logout();
  }

  // Get Current User's Firebase ID
  Future<String> getCurrentUserId() async {
    final userId = await _authService.getCurrentUserId();
    if (userId != null) {
      return userId;
    } else {
      throw Exception('User not logged in.');
    }
  }

  // Fetch the User's Name by Firebase ID (SQLite database lookup)
  Future<String> getUserName(String firebaseId) async {
    final user = await _dbHelper.getUserByFirebaseId(firebaseId);
    if (user != null) {
      return user.name;
    } else {
      throw Exception('User not found.');
    }
  }

  // Fetch the User's Name by Firebase ID (Alias for getUserName)
  Future<String> getUserNameById(String firebaseId) async {
    return await getUserName(firebaseId);
  }

  // Fetch the User's Profile Image (optional feature)
  Future<String?> getUserProfileImage(String firebaseId) async {
    final user = await _dbHelper.getUserByFirebaseId(firebaseId);
    // For this example, we assume profile image is stored in Firestore
    if (user != null) {
      final profileImage = await _authService.getUserProfileImage(firebaseId);
      return profileImage;
    }
    return null; // Return null if the profile image doesn't exist
  }
}
