class UserModel {
  final String name;
  final String email;
  final String firebaseId;
  final String preferences; // Added preferences field

  UserModel({
    required this.name,
    required this.email,
    required this.firebaseId,
    required this.preferences,
  });

  // Convert to Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'firebaseId': firebaseId,
      'preferences': preferences,
    };
  }

  // Create UserModel from Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      name: map['name'],
      email: map['email'],
      firebaseId: map['firebaseId'],
      preferences: map['preferences'],
    );
  }
}
