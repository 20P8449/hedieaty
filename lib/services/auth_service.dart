import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '../controllers/event_controller.dart';
import '../controllers/gift_controller.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage(); // Secure Storage Instance
  final EventController _eventController = EventController();
  final GiftController _giftController = GiftController();

  // Sign Up and return UserModel
  Future<UserModel?> signUp(
      String email, String password, String name, String preferences) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        UserModel newUser = UserModel(
          name: name,
          email: email,
          firebaseId: user.uid,
          preferences: preferences,
        );

        // Add user data to Firestore
        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());

        // Store UID securely after sign-up
        await _secureStorage.write(key: 'userUID', value: user.uid);

        print("User signed up successfully and UID stored securely: ${user.uid}");
        return newUser;
      }
    } catch (e) {
      print("Error in signUp: $e");
    }
    return null;
  }

  // Login and fetch UserModel from Firestore
  Future<UserModel?> login(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        // Fetch user data from Firestore
        final doc = await _firestore.collection('users').doc(user.uid).get();

        if (doc.exists) {
          // Create UserModel
          UserModel loggedInUser = UserModel(
            name: doc.data()?['name'] ?? '',
            email: doc.data()?['email'] ?? '',
            firebaseId: user.uid,
            preferences: doc.data()?['preferences'] ?? '',
          );

          // Store UID in secure storage
          await _secureStorage.write(key: 'userUID', value: user.uid);

          // Sync Events and Gifts from Firestore to SQLite
          await _eventController.syncEventsFromFirestore();
          await _giftController.syncGiftsFromFirestore();

          print("User logged in and UID stored securely: ${user.uid}");
          return loggedInUser;
        } else {
          print("User data not found in Firestore.");
        }
      }
    } catch (e) {
      print("Error in login: $e");
    }
    return null;
  }

  // Logout and clear Secure Storage
  Future<void> logout() async {
    try {
      await _auth.signOut();
      await _secureStorage.delete(key: 'userUID'); // Remove UID from secure storage
      print("User logged out and UID removed from secure storage.");
    } catch (e) {
      print("Error during logout: $e");
    }
  }
}
