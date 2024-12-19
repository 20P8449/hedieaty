class GiftModel {
  int? id;
  String name;
  String description;
  String category;
  double price;
  String status;
  String eventFirebaseId; // Link to associated event
  String userId; // Firebase user ID
  String giftFirebaseId; // Firestore document ID
  bool published; // True if published, False otherwise

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

  // Convert to Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'status': status,
      'eventFirebaseId': eventFirebaseId, // Save associated event ID
      'userId': userId,
      'giftFirebaseId': giftFirebaseId,
      'published': published ? 1 : 0, // Convert bool to int for SQLite
    };
  }

  // Create from Map for SQLite
  factory GiftModel.fromMap(Map<String, dynamic> map) {
    return GiftModel(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      category: map['category'],
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      status: map['status'],
      eventFirebaseId: map['eventFirebaseId'] ?? '', // Restore event ID
      userId: map['userId'] ?? '',
      giftFirebaseId: map['giftFirebaseId'] ?? '',
      published: map['published'] == 1, // Convert int to bool
    );
  }

  // CopyWith method for updates
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
      eventFirebaseId: eventFirebaseId ?? this.eventFirebaseId, // Update event ID
      userId: userId ?? this.userId,
      giftFirebaseId: giftFirebaseId ?? this.giftFirebaseId,
      published: published ?? this.published,
    );
  }
}