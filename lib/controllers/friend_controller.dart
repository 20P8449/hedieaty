import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/friend_model.dart';
import '../services/sqlite_service.dart'; // Ensure SQLite service exists
import '../services/notification_service.dart'; // Ensure Notification service exists

class FriendController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SQLiteService _sqliteService = SQLiteService(); // Create an instance of SQLiteService
  final NotificationService _notificationService = NotificationService(); // Create an instance of NotificationService

  // Add a friend (both users' friend lists are updated)
  Future<void> addFriend(String myUid, FriendModel friend) async {
    final friendUid = friend.uid;

    if (myUid == friendUid) {
      throw Exception("You cannot add yourself as a friend.");
    }

    final userDoc = await _firestore.collection('users').doc(myUid).get();
    if (userDoc.exists) {
      List<dynamic> friendUids = userDoc.data()?['friends'] ?? [];
      if (friendUids.contains(friendUid)) {
        print("The user is already added as a friend.");
        return;
      }
    }

    // Update my friends list
    await _firestore.collection('users').doc(myUid).update({
      'friends': FieldValue.arrayUnion([friendUid]),
    });

    // Update friend's friends list
    await _firestore.collection('users').doc(friendUid).update({
      'friends': FieldValue.arrayUnion([myUid]),
    });
  }

  // Add a friend to Firestore
  Future<void> addFriendToFirestore(String myUid, String friendUid) async {
    try {
      if (myUid == friendUid) {
        throw Exception("You cannot add yourself as a friend.");
      }

      final userDoc = await _firestore.collection('users').doc(myUid).get();
      if (userDoc.exists) {
        List<dynamic> friendUids = userDoc.data()?['friends'] ?? [];
        if (friendUids.contains(friendUid)) {
          print("The user is already added as a friend.");
          return;
        }
      }

      await _firestore.collection('users').doc(myUid).update({
        'friends': FieldValue.arrayUnion([friendUid]),
      });
      print("Friend added to Firestore: $friendUid");
    } catch (e) {
      print("Error adding friend to Firestore: $e");
      throw Exception("Error adding friend to Firestore.");
    }
  }

  // Add a friend to SQLite
  Future<void> addFriendToSQLite(String myUid, String friendUid) async {
    try {
      if (myUid == friendUid) {
        throw Exception("You cannot add yourself as a friend.");
      }

      final userDoc = await _firestore.collection('users').doc(myUid).get();
      if (userDoc.exists) {
        List<dynamic> friendUids = userDoc.data()?['friends'] ?? [];
        if (friendUids.contains(friendUid)) {
          print("The user is already added as a friend.");
          return;
        }
      }

      await _sqliteService.addFriend(myUid, friendUid); // Use instance of SQLiteService
      print("Friend added to SQLite: $friendUid");
    } catch (e) {
      print("Error adding friend to SQLite: $e");
      throw Exception("Error adding friend to SQLite.");
    }
  }

  // Send a notification to a user
  Future<void> addNotification(String recipientUid, String message) async {
    try {
      await _notificationService.sendNotification(recipientUid, message); // Use instance of NotificationService
      print("Notification sent to $recipientUid: $message");
    } catch (e) {
      print("Error sending notification: $e");
      throw Exception("Error sending notification.");
    }
  }

  // Get all friends of a user
  Future<List<FriendModel>> getFriends(String userUid) async {
    final userDoc = await _firestore.collection('users').doc(userUid).get();

    if (userDoc.exists) {
      List<dynamic> friendUids = userDoc.data()?['friends'] ?? [];

      List<FriendModel> friends = [];
      for (String friendUid in friendUids) {
        final friendDoc = await _firestore.collection('users').doc(friendUid).get();
        if (friendDoc.exists) {
          friends.add(FriendModel.fromMap(friendDoc.data()!));
        }
      }
      return friends;
    }
    return [];
  }

  // Search for a user by phone
  Future<FriendModel?> searchUserByPhone(String phone) async {
    final query = await _firestore
        .collection('users')
        .where('mobile', isEqualTo: phone)
        .get();

    if (query.docs.isNotEmpty) {
      final data = query.docs.first.data();
      return FriendModel.fromMap(data..addAll({'uid': query.docs.first.id}));
    }
    return null;
  }
}
