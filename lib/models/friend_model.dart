class FriendModel {
  final String uid;
  final String name;
  final String email;
  final String mobile;

  FriendModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.mobile,
  });

  // Computed property for friendId
  String get friendId => uid;

  // Convert FriendModel to Map (for Firestore or SQLite)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'mobile': mobile,
    };
  }

  // Create a FriendModel from Firestore or SQLite Map
  factory FriendModel.fromMap(Map<String, dynamic> map) {
    return FriendModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      mobile: map['mobile'] ?? '',
    );
  }
}
