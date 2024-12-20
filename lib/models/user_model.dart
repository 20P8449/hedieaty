class UserModel {
  final String name;
  final String email;
  final String firebaseId;
  final String preferences;
  final String mobile; // Added mobile field

  UserModel({
    required this.name,
    required this.email,
    required this.firebaseId,
    required this.preferences,
    required this.mobile,
  });

  // Convert to Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'firebaseId': firebaseId,
      'preferences': preferences,
      'mobile': mobile, // Added mobile to map
    };
  }

  // Create UserModel from Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      name: map['name'],
      email: map['email'],
      firebaseId: map['firebaseId'],
      preferences: map['preferences'],
      mobile: map['mobile'], // Added mobile from map
    );
  }

  // Create a new UserModel with updated fields
  UserModel copyWith({
    String? name,
    String? email,
    String? firebaseId,
    String? preferences,
    String? mobile,
  }) {
    return UserModel(
      name: name ?? this.name,
      email: email ?? this.email,
      firebaseId: firebaseId ?? this.firebaseId,
      preferences: preferences ?? this.preferences,
      mobile: mobile ?? this.mobile,
    );
  }
}
