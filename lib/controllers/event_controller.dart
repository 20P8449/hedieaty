import 'package:sqflite/sqflite.dart';
import '../database/db_helper.dart';
import '../models/event_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EventController {
  final DBHelper _dbHelper = DBHelper();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();


  // Sync Events from Firestore to Local SQLite
  Future<void> syncEventsFromFirestore() async {
    try {
      // Retrieve user UID from Secure Storage
      String? userUID = await _secureStorage.read(key: 'userUID');
      print("aaaaaaaaaaaaaaaaaaaaaaaaaaaa");
      print(userUID);
      if (userUID == null) {
        print('User UID not found. Cannot sync events.');
        return;
      }

      // Fetch events from Firestore
      QuerySnapshot querySnapshot = await _firestore
          .collection('events')
          .where('userId', isEqualTo: userUID)
          .get();

      // Convert Firestore documents to EventModel and insert/update SQLite
      for (var doc in querySnapshot.docs) {
        EventModel event = EventModel(
          name: doc['name'],
          date: doc['date'],
          location: doc['location'],
          description: doc['description'],
          userId: doc['userId'],
          eventFirebaseId: doc.id,
          published: (doc['published'] is bool)
              ? doc['published']
              : doc['published'] == 1, // Handles int -> bool conversion
        );

        print(event.toMap());

        // Insert or Update event in SQLite
        await _insertOrUpdateEvent(event);
      }

      print('Events synchronized from Firestore to SQLite.');
    } catch (e) {
      print('Error syncing events from Firestore: $e');
    }
  }

  // Helper: Insert or Update Event in SQLite
  Future<void> _insertOrUpdateEvent(EventModel event) async {
    final db = await _dbHelper.database;

    // Check if event with the same Firebase ID exists in SQLite
    final existingEvents = await db.query(
      'events',
      where: 'eventFirebaseId = ?',
      whereArgs: [event.eventFirebaseId],
    );

    if (existingEvents.isEmpty) {
      // Insert new event
      await db.insert('events', event.toMap());
    } else {
      // Update existing event
      await db.update(
        'events',
        event.toMap(),
        where: 'eventFirebaseId = ?',
        whereArgs: [event.eventFirebaseId],
      );
    }
  }
  // Add Event
  Future<void> addEvent(EventModel event) async {
    final db = await _dbHelper.database;
    await db.insert('events', event.toMap());
  }

  // Fetch All Events
  Future<List<EventModel>> getAllEvents() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> result = await db.query('events');
    return result.map((e) => EventModel.fromMap(e)).toList();
  }

  // Update Event
  Future<void> updateEvent(EventModel event) async {
    final db = await _dbHelper.database;
    await db.update(
      'events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
    print(event.published);
    if(event.published== true){
      await _firestore
          .collection('events')
          .doc(event.eventFirebaseId)
          .update(event.toMap());
    }
  }

  // Toggle Published Status
  Future<void> togglePublished(EventModel event) async {
    final db = await _dbHelper.database;
    final isPublished = !event.published;

    // Update local SQLite
    await db.update(
      'events',
      {'published': isPublished ? 1 : 0},
      where: 'id = ?',
      whereArgs: [event.id],
    );

    if (isPublished) {
      // Publish to Firestore
      await _publishEventToFirestore(event);
    } else {
      // Remove from Firestore
      await _removeEventFromFirestore(event);
    }
  }

  // Publish Event to Firestore
  Future<void> _publishEventToFirestore(EventModel event) async {
    try {
      // Retrieve user UID from secure storage
      String? userUID = await _secureStorage.read(key: 'userUID');
      if (userUID == null) {
        print('User UID not found in secure storage.');
        return;
      }

      // Prepare event data
      Map<String, dynamic> eventData = {
        'name': event.name,
        'date': event.date,
        'location': event.location,
        'description': event.description,
        'userId': userUID,
        'published': true,
      };

      if (event.eventFirebaseId.isNotEmpty) {
        // Update existing event in Firestore
        await _firestore
            .collection('events')
            .doc(event.eventFirebaseId)
            .set(eventData);

        // Update local SQLite to confirm published status
        await updateEvent(event.copyWith(
          published: true,
          userId: userUID,
        ));

        print('Event updated in Firestore with ID: ${event.eventFirebaseId}');
      } else {
        // Create new document in Firestore
        DocumentReference docRef =
        await _firestore.collection('events').add(eventData);

        // Update eventFirebaseId and userId in local SQLite
        await updateEvent(event.copyWith(
          published: true,
          eventFirebaseId: docRef.id,
          userId: userUID,
        ));

        print('Event published to Firestore with new ID: ${docRef.id}');
      }
    } catch (e) {
      print('Error publishing event to Firestore: $e');
    }
  }


  // Remove Event from Firestore
  Future<void> _removeEventFromFirestore(EventModel event) async {
    try {
      if (event.eventFirebaseId.isEmpty) {
        print('Event Firebase ID is empty. Cannot remove from Firestore.');
        return;
      }

      // Delete event from Firestore
      await _firestore.collection('events').doc(event.eventFirebaseId).delete();

      // Clear eventFirebaseId and userId in local SQLite
      await updateEvent(event.copyWith(
        published: false, // Update published to true
      ));

      print('Event removed from Firestore with ID: ${event.eventFirebaseId}');
    } catch (e) {
      print('Error removing event from Firestore: $e');
    }
  }

  // Delete Event
  Future<void> deleteEvent(int id) async {
    final db = await _dbHelper.database;
    // Fetch event to check if published
    EventModel? event = await getEventById(id);
    if (event != null && event.published && event.eventFirebaseId.isNotEmpty) {
      // Remove from Firestore if published
      await _removeEventFromFirestore(event);
    }
    await db.delete('events', where: 'id = ?', whereArgs: [id]);
  }

  // Get Event by ID
  Future<EventModel?> getEventById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query('events', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return EventModel.fromMap(result.first);
    }
    return null;
  }
}
