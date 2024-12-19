import 'package:sqflite/sqflite.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../database/db_helper.dart';
import '../models/gift_model.dart';

class GiftController {
  final DBHelper _dbHelper = DBHelper();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // Add a new gift to SQLite and Firestore
  Future<void> addGift(GiftModel gift) async {
    final db = await _dbHelper.database;

    if (gift.eventFirebaseId.isEmpty || gift.userId.isEmpty) {
      throw Exception("Event ID and User ID are required for adding a gift.");
    }

    // Insert gift into SQLite
    final giftId = await db.insert(
      'gifts',
      {
        ...gift.toMap(),
        'published': 0, // Ensure published is set to 0 for SQLite
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    try {
      final giftData = {
        ...gift.toMap(),
        'published': false,
      };

      final docRef = await _firestore.collection('gifts').add(giftData);
      final giftFirebaseId = docRef.id;

      await db.update(
        'gifts',
        {'giftFirebaseId': giftFirebaseId},
        where: 'id = ?',
        whereArgs: [giftId],
      );

      print('Gift added successfully to Firestore and SQLite.');
    } catch (e) {
      print('Error adding gift to Firestore: $e');
      throw e;
    }
  }

  // Update an existing gift
  Future<void> updateGift(GiftModel gift) async {
    final db = await _dbHelper.database;

    if (gift.id == null) {
      throw Exception("Gift ID is required for updating.");
    }

    await db.update(
      'gifts',
      {
        ...gift.toMap(),
        'published': gift.published ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [gift.id],
    );

    if (gift.giftFirebaseId.isNotEmpty) {
      try {
        await _firestore.collection('gifts').doc(gift.giftFirebaseId).set({
          ...gift.toMap(),
          'published': gift.published,
        });
        print('Gift updated successfully in Firestore.');
      } catch (e) {
        print('Error updating gift in Firestore: $e');
      }
    }
  }

  // Delete a gift from SQLite and Firestore
  Future<void> deleteGift(int id) async {
    final db = await _dbHelper.database;

    try {
      final gift = await getGiftById(id);

      if (gift != null && gift.giftFirebaseId.isNotEmpty) {
        await _firestore.collection('gifts').doc(gift.giftFirebaseId).delete();
        print('Gift deleted from Firestore: ${gift.giftFirebaseId}');
      }

      await db.delete('gifts', where: 'id = ?', whereArgs: [id]);
      print('Gift deleted from SQLite with ID: $id');
    } catch (e) {
      print('Error deleting gift: $e');
      throw Exception("Error deleting gift: $e");
    }
  }

  // Get a gift by ID
  Future<GiftModel?> getGiftById(int id) async {
    final db = await _dbHelper.database;

    try {
      final result = await db.query('gifts', where: 'id = ?', whereArgs: [id]);
      if (result.isNotEmpty) {
        return GiftModel.fromMap(result.first);
      }
      return null;
    } catch (e) {
      print('Error fetching gift by ID: $e');
      throw Exception("Error fetching gift by ID: $e");
    }
  }

  // Fetch all gifts for a specific user
  Future<List<GiftModel>> getAllGifts(String userId) async {
    final db = await _dbHelper.database;

    try {
      final List<Map<String, dynamic>> result = await db.query(
        'gifts',
        where: 'userId = ?',
        whereArgs: [userId],
      );
      return result.map((e) => GiftModel.fromMap(e)).toList();
    } catch (e) {
      print('Error fetching gifts: $e');
      throw Exception("Error fetching gifts: $e");
    }
  }

  // Fetch gifts by event ID and user ID
  Future<List<GiftModel>> getGiftsByEventAndUser(String eventId, String userId) async {
    final db = await _dbHelper.database;

    try {
      final List<Map<String, dynamic>> result = await db.query(
        'gifts',
        where: 'eventFirebaseId = ? AND userId = ?',
        whereArgs: [eventId, userId],
      );
      return result.map((e) => GiftModel.fromMap(e)).toList();
    } catch (e) {
      print('Error fetching gifts: $e');
      throw Exception("Error fetching gifts: $e");
    }
  }

  // Publish a gift to Firestore
  Future<void> publishGift(GiftModel gift) async {
    if (gift.eventFirebaseId.isEmpty || gift.giftFirebaseId.isEmpty) {
      throw Exception("Event ID and Firestore ID are required to publish the gift.");
    }

    try {
      final giftData = {
        ...gift.toMap(),
        'published': true,
      };

      await _firestore.collection('gifts').doc(gift.giftFirebaseId).set(giftData);

      final db = await _dbHelper.database;
      await db.update(
        'gifts',
        {'published': 1},
        where: 'id = ?',
        whereArgs: [gift.id],
      );

      print('Gift published successfully: ${gift.name}');
    } catch (e) {
      print('Error publishing gift: $e');
      throw e;
    }
  }

  // Unpublish a gift from Firestore
  Future<void> unpublishGift(GiftModel gift) async {
    if (gift.giftFirebaseId.isEmpty) {
      throw Exception("Firestore ID is required to unpublish the gift.");
    }

    try {
      final giftData = {
        ...gift.toMap(),
        'published': false,
      };

      await _firestore.collection('gifts').doc(gift.giftFirebaseId).set(giftData);

      final db = await _dbHelper.database;
      await db.update(
        'gifts',
        {'published': 0},
        where: 'id = ?',
        whereArgs: [gift.id],
      );

      print('Gift unpublished successfully: ${gift.name}');
    } catch (e) {
      print('Error unpublishing gift: $e');
      throw e;
    }
  }

  // Sync gifts from Firestore to SQLite
  Future<void> syncGiftsFromFirestore(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('gifts')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in querySnapshot.docs) {
        final gift = GiftModel.fromMap(doc.data());
        await _insertOrUpdateGift(gift.copyWith(giftFirebaseId: doc.id));
      }

      print('Gifts synchronized from Firestore to SQLite for User ID: $userId.');
    } catch (e) {
      print('Error syncing gifts from Firestore: $e');
      throw Exception("Error syncing gifts from Firestore: $e");
    }
  }

  // Insert or update a gift in SQLite
  Future<void> _insertOrUpdateGift(GiftModel gift) async {
    final db = await _dbHelper.database;

    try {
      final existingGifts = await db.query(
        'gifts',
        where: 'giftFirebaseId = ?',
        whereArgs: [gift.giftFirebaseId],
      );

      if (existingGifts.isEmpty) {
        await db.insert('gifts', {
          ...gift.toMap(),
          'published': gift.published ? 1 : 0,
        });
        print('Inserted gift: ${gift.name}');
      } else {
        await db.update(
          'gifts',
          {
            ...gift.toMap(),
            'published': gift.published ? 1 : 0,
          },
          where: 'giftFirebaseId = ?',
          whereArgs: [gift.giftFirebaseId],
        );
        print('Updated gift: ${gift.name}');
      }
    } catch (e) {
      print('Error inserting or updating gift: $e');
      throw Exception("Error inserting or updating gift: $e");
    }
  }
}
