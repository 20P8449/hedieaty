import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/friend_model.dart';

class FriendController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a friend (both users' friend lists are updated)
  Future<void> addFriend(String myUid, FriendModel friend) async {
    final friendUid = friend.uid;

    // Update my friends list
    await _firestore.collection('users').doc(myUid).update({
      'friends': FieldValue.arrayUnion([friendUid]),
    });

    // Update friend's friends list
    await _firestore.collection('users').doc(friendUid).update({
      'friends': FieldValue.arrayUnion([myUid]),
    });
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
