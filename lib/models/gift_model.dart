class GiftModel {
  int? id; // SQLite auto-increment ID
  String name; // Gift name
  String description; // Gift description
  String category; // Gift category
  double price; // Gift price
  String status; // Gift status (e.g., "Available", "Pledged")
  String eventFirebaseId; // Firebase event ID associated with the gift
  String userId; // Firebase user ID (owner of the gift)
  String pledgedBy; // Firebase user ID (user who pledged the gift)
  String giftFirebaseId; // Firestore document ID
  bool published; // Indicates whether the gift is published
  String? photoLink; // Optional photo link for the gift

  GiftModel({
    this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.status,
    this.eventFirebaseId = '',
    this.userId = '',
    this.pledgedBy = '', // Default empty if no one has pledged the gift
    this.giftFirebaseId = '',
    this.published = false,
    this.photoLink, // Initialize as null if not provided
  });

  /// Convert the GiftModel to a Map for SQLite or Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'status': status,
      'eventFirebaseId': eventFirebaseId,
      'userId': userId,
      'pledgedBy': pledgedBy, // Add pledgedBy for tracking
      'giftFirebaseId': giftFirebaseId,
      'published': published ? 1 : 0, // SQLite compatibility
      'photoLink': photoLink, // Include photo link
    }..removeWhere((key, value) => value == null || value == '');
  }

  /// Create a GiftModel instance from a Map (SQLite row or Firestore document)
  factory GiftModel.fromMap(Map<String, dynamic> map) {
    return GiftModel(
      id: map['id'],
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? '',
      eventFirebaseId: map['eventFirebaseId'] ?? '',
      userId: map['userId'] ?? '',
      pledgedBy: map['pledgedBy'] ?? '', // Retrieve pledgedBy field
      giftFirebaseId: map['giftFirebaseId'] ?? '',
      published: (map['published'] == 1 || map['published'] == true),
      photoLink: map['photoLink'], // Retrieve photoLink field
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
    String? pledgedBy,
    String? giftFirebaseId,
    bool? published,
    String? photoLink, // Add photoLink for copying
  }) {
    return GiftModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      status: status ?? this.status,
      eventFirebaseId: eventFirebaseId ?? this.eventFirebaseId,
      userId: userId ?? this.userId,
      pledgedBy: pledgedBy ?? this.pledgedBy, // Maintain existing pledgedBy field
      giftFirebaseId: giftFirebaseId ?? this.giftFirebaseId,
      published: published ?? this.published,
      photoLink: photoLink ?? this.photoLink, // Copy photoLink
    );
  }

  /// Convert the GiftModel to a Firestore-compatible Map
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'status': status,
      'eventFirebaseId': eventFirebaseId,
      'userId': userId,
      'pledgedBy': pledgedBy, // Include pledgedBy in Firestore data
      'published': published,
      'photoLink': photoLink, // Include photo link in Firestore
    }..removeWhere((key, value) => value == null || value == '');
  }

  /// Create a GiftModel instance from Firestore data
  factory GiftModel.fromFirestore(Map<String, dynamic> map) {
    return GiftModel(
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? '',
      eventFirebaseId: map['eventFirebaseId'] ?? '',
      userId: map['userId'] ?? '',
      pledgedBy: map['pledgedBy'] ?? '', // Retrieve pledgedBy from Firestore
      giftFirebaseId: map['giftFirebaseId'] ?? '',
      published: map['published'] == true,
      photoLink: map['photoLink'], // Retrieve photoLink from Firestore
    );
  }

  /// Convert the GiftModel to a JSON-compatible Map (for APIs or backups)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'status': status,
      'eventFirebaseId': eventFirebaseId,
      'userId': userId,
      'pledgedBy': pledgedBy, // Include pledgedBy in JSON
      'giftFirebaseId': giftFirebaseId,
      'published': published,
      'photoLink': photoLink, // Include photo link in JSON
    };
  }

  /// Create a GiftModel instance from JSON data
  factory GiftModel.fromJson(Map<String, dynamic> json) {
    return GiftModel(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? '',
      eventFirebaseId: json['eventFirebaseId'] ?? '',
      userId: json['userId'] ?? '',
      pledgedBy: json['pledgedBy'] ?? '', // Retrieve pledgedBy from JSON
      giftFirebaseId: json['giftFirebaseId'] ?? '',
      published: json['published'] == true,
      photoLink: json['photoLink'], // Retrieve photo link from JSON
    );
  }
}
