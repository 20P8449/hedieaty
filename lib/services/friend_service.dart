import 'package:cloud_firestore/cloud_firestore.dart';

class FriendService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch friends for the current user from Firestore
  static Future<List<Map<String, dynamic>>> getFriendsFromFirestore(
      String currentUserId) async {
    try {
      // Retrieve the current user's document
      final currentUserDoc =
      await _firestore.collection('users').doc(currentUserId).get();

      if (currentUserDoc.exists) {
        List<dynamic> friendIds = currentUserDoc.data()?['friends'] ?? [];

        // Fetch details of each friend by their ID
        List<Map<String, dynamic>> friendDetails = [];
        for (String friendId in friendIds) {
          final friendDoc =
          await _firestore.collection('users').doc(friendId).get();
          if (friendDoc.exists) {
            final data = friendDoc.data();
            final upcomingEventCount = await getUpcomingEventCount(friendId);
            friendDetails.add({
              'id': friendId,
              'name': data?['name'] ?? 'Unknown',
              'mobile': data?['mobile'],
              'upcomingEventCount': upcomingEventCount,
            });
          }
        }
        return friendDetails;
      }
      return [];
    } catch (e) {
      print("Error fetching friends: $e");
      return [];
    }
  }

  /// Search users by mobile number in Firestore
  static Future<List<Map<String, dynamic>>> searchUsersByMobile(
      String phoneNumber) async {
    try {
      // Query Firestore for users with the specified mobile number
      final query = await _firestore
          .collection('users')
          .where('mobile', isEqualTo: phoneNumber)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown',
          'mobile': data['mobile'],
        };
      }).toList();
    } catch (e) {
      print("Error searching users by mobile: $e");
      return [];
    }
  }

  /// Add a friend to the current user's friend list and vice versa
  static Future<void> addFriend(String currentUserId, String friendId) async {
    try {
      final batch = _firestore.batch();

      // Add the friend to the current user's friends list
      final currentUserRef = _firestore.collection('users').doc(currentUserId);
      batch.update(currentUserRef, {
        'friends': FieldValue.arrayUnion([friendId]),
      });

      // Add the current user to the friend's friends list
      final friendRef = _firestore.collection('users').doc(friendId);
      batch.update(friendRef, {
        'friends': FieldValue.arrayUnion([currentUserId]),
      });

      await batch.commit();
      print("Friend added successfully: $friendId");
    } catch (e) {
      print("Error adding friend: $e");
      throw Exception("Failed to add friend.");
    }
  }

  /// Remove a friend from the current user's friend list and vice versa
  static Future<void> removeFriend(String currentUserId, String friendId) async {
    try {
      final batch = _firestore.batch();

      // Remove the friend from the current user's friends list
      final currentUserRef = _firestore.collection('users').doc(currentUserId);
      batch.update(currentUserRef, {
        'friends': FieldValue.arrayRemove([friendId]),
      });

      // Remove the current user from the friend's friends list
      final friendRef = _firestore.collection('users').doc(friendId);
      batch.update(friendRef, {
        'friends': FieldValue.arrayRemove([currentUserId]),
      });

      await batch.commit();
      print("Friend removed successfully: $friendId");
    } catch (e) {
      print("Error removing friend: $e");
      throw Exception("Failed to remove friend.");
    }
  }

  /// Get the count of upcoming events for a specific friend ID
  static Future<int> getUpcomingEventCount(String friendId) async {
    try {
      final now = DateTime.now();

      // Query Firestore for future events associated with the friend
      final query = await _firestore
          .collection('events')
          .where('userId', isEqualTo: friendId)
          .where('date', isGreaterThan: now.toIso8601String())
          .get();

      return query.docs.length;
    } catch (e) {
      print("Error fetching upcoming events for friendId $friendId: $e");
      return 0;
    }
  }
}
