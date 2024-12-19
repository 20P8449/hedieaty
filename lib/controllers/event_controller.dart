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
          name: doc['name'] ?? '',
          date: doc['date'] ?? '',
          location: doc['location'] ?? '',
          description: doc['description'] ?? '',
          userId: doc['userId'] ?? '',
          eventFirebaseId: doc.id,
          published: (doc['published'] is bool)
              ? doc['published']
              : (doc['published'] == 1),
        );

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

    // Validate user ID
    if (event.userId.isEmpty) {
      throw Exception("User ID is required to add an event.");
    }

    // Insert event into SQLite
    final eventId = await db.insert(
      'events',
      event.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Add event to Firestore
    try {
      final eventData = event.toMap();
      final docRef = await _firestore.collection('events').add(eventData);
      final eventFirebaseId = docRef.id;

      // Update SQLite with Firestore ID
      await db.update(
        'events',
        {'eventFirebaseId': eventFirebaseId},
        where: 'id = ?',
        whereArgs: [eventId],
      );

      print('Event added successfully to Firestore and SQLite.');
    } catch (e) {
      print('Error adding event to Firestore: $e');
      throw e;
    }
  }

  // Fetch Events by User ID
  Future<List<EventModel>> getEventsByUserId(String userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> result = await db.query(
      'events',
      where: 'userId = ?',
      whereArgs: [userId],
    );
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

    if (event.published) {
      // Update event in Firestore
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
      String? userUID = await _secureStorage.read(key: 'userUID');
      if (userUID == null) {
        print('User UID not found in secure storage.');
        return;
      }

      final eventData = {
        ...event.toMap(),
        'userId': userUID,
        'published': true,
      };

      if (event.eventFirebaseId.isNotEmpty) {
        // Update existing event in Firestore
        await _firestore.collection('events').doc(event.eventFirebaseId).set(eventData);
        print('Event updated in Firestore with ID: ${event.eventFirebaseId}');
      } else {
        // Create new document in Firestore
        final docRef = await _firestore.collection('events').add(eventData);
        await updateEvent(event.copyWith(
          eventFirebaseId: docRef.id,
          published: true,
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

      await _firestore.collection('events').doc(event.eventFirebaseId).delete();
      await updateEvent(event.copyWith(published: false));

      print('Event removed from Firestore with ID: ${event.eventFirebaseId}');
    } catch (e) {
      print('Error removing event from Firestore: $e');
    }
  }

  // Delete Event
  Future<void> deleteEvent(int id) async {
    final db = await _dbHelper.database;
    final event = await getEventById(id);

    if (event != null && event.published && event.eventFirebaseId.isNotEmpty) {
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
