import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import 'package:project/controllers/event_controller.dart';
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage(); // Secure Storage Instance
  final EventController _eventController = EventController();

  // Sign Up and return UserModel
  Future<UserModel?> signUp(String email, String password, String name, String preferences) async {
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

          // Sync events from Firestore to SQLite
          await _eventController.syncEventsFromFirestore();

          print("User UID stored securely: ${user.uid}");
          return loggedInUser;
        }
      }
    } catch (e) {
      print("Error in login: $e");
    }
    return null;
  }
}
