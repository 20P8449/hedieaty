class GiftModel {
  int? id; // SQLite auto-increment ID
  String name; // Gift name
  String description; // Gift description
  String category; // Gift category
  double price; // Gift price
  String status; // Gift status (e.g., "Available", "Pledged")
  String eventFirebaseId; // Firebase event ID associated with the gift
  String userId; // Firebase user ID
  String giftFirebaseId; // Firestore document ID
  bool published; // Indicates whether the gift is published

  GiftModel({
    this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.status,
    this.eventFirebaseId = '',
    this.userId = '',
    this.giftFirebaseId = '',
    this.published = false,
  });

  /// Convert the GiftModel to a Map for SQLite storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'status': status,
      'eventFirebaseId': eventFirebaseId, // Link to associated event
      'userId': userId, // Link to Firebase user
      'giftFirebaseId': giftFirebaseId, // Firestore document ID
      'published': published ? 1 : 0, // Convert bool to int for SQLite compatibility
    };
  }

  /// Create a GiftModel instance from a Map (e.g., SQLite row)
  factory GiftModel.fromMap(Map<String, dynamic> map) {
    return GiftModel(
      id: map['id'], // SQLite ID
      name: map['name'] ?? '', // Default to empty string if null
      description: map['description'] ?? '', // Default to empty string if null
      category: map['category'] ?? '', // Default to empty string if null
      price: (map['price'] as num?)?.toDouble() ?? 0.0, // Convert price to double
      status: map['status'] ?? '', // Default to empty string if null
      eventFirebaseId: map['eventFirebaseId'] ?? '', // Restore event ID
      userId: map['userId'] ?? '', // Restore user ID
      giftFirebaseId: map['giftFirebaseId'] ?? '', // Restore Firestore document ID
      published: map['published'] == 1, // Convert SQLite int to bool
    );
  }

  /// Create a new GiftModel instance with updated fields
  GiftModel copyWith({
    int? id,
    String? name,
    String? description,
    String? category,
    double? price,
    String? status,
    String? eventFirebaseId,
    String? userId,
    String? giftFirebaseId,
    bool? published,
  }) {
    return GiftModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      status: status ?? this.status,
      eventFirebaseId: eventFirebaseId ?? this.eventFirebaseId, // Maintain existing event ID if not updated
      userId: userId ?? this.userId, // Maintain existing user ID if not updated
      giftFirebaseId: giftFirebaseId ?? this.giftFirebaseId, // Maintain existing Firestore ID if not updated
      published: published ?? this.published, // Maintain existing published state if not updated
    );
  }
}
