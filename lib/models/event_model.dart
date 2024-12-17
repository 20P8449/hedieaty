class EventModel {
  int? id; // SQLite Auto-incremented ID
  String name;
  String date;
  String location;
  String description;
  String userId; // Firebase User ID
  String eventFirebaseId; // Firebase Event ID
  bool published; // True if published, false otherwise

  EventModel({
    this.id,
    required this.name,
    required this.date,
    required this.location,
    required this.description,
    this.userId = '',
    this.eventFirebaseId = '',
    this.published = false,
  });

  // Convert EventModel to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'date': date,
      'location': location,
      'description': description,
      'userId': userId,
      'eventFirebaseId': eventFirebaseId,
      'published': published ? 1 : 0,
    };
  }

  // Create EventModel from Map
  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      id: map['id'],
      name: map['name'],
      date: map['date'],
      location: map['location'],
      description: map['description'],
      userId: map['userId'] ?? '',
      eventFirebaseId: map['eventFirebaseId'] ?? '',
      published: map['published'] == 1,
    );
  }

  // Copy with method for updating fields
  EventModel copyWith({
    int? id,
    String? name,
    String? date,
    String? location,
    String? description,
    String? userId,
    String? eventFirebaseId,
    bool? published,
  }) {
    return EventModel(
      id: id ?? this.id,
      name: name ?? this.name,
      date: date ?? this.date,
      location: location ?? this.location,
      description: description ?? this.description,
      userId: userId ?? this.userId,
      eventFirebaseId: eventFirebaseId ?? this.eventFirebaseId,
      published: published ?? this.published,
    );
  }
}
