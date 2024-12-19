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

    try {
      // Insert gift into SQLite
      final giftId = await db.insert(
        'gifts',
        {
          ...gift.toMap(),
          'published': 0, // Ensure published is set to 0 for SQLite
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Add to Firestore
      final docRef = await _firestore.collection('gifts').add({
        ...gift.toMap(),
        'published': false, // Ensure published is false in Firestore
      });

      // Update Firestore ID in SQLite
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

  // Update an existing gift in SQLite and Firestore
  Future<void> updateGift(GiftModel gift) async {
    final db = await _dbHelper.database;

    if (gift.id == null) {
      throw Exception("Gift ID is required for updating.");
    }

    try {
      // Update SQLite
      await db.update(
        'gifts',
        {
          ...gift.toMap(),
          'published': gift.published ? 1 : 0,
        },
        where: 'id = ?',
        whereArgs: [gift.id],
      );

      // Update Firestore
      if (gift.giftFirebaseId.isNotEmpty) {
        await _firestore.collection('gifts').doc(gift.giftFirebaseId).update({
          ...gift.toFirestore(),
        });
        print('Gift updated successfully in Firestore.');
      }
    } catch (e) {
      print('Error updating gift: $e');
      throw e;
    }
  }

  // Publish a gift
  Future<void> publishGift(GiftModel gift) async {
    final db = await _dbHelper.database;

    try {
      if (gift.giftFirebaseId.isEmpty) {
        throw Exception("Gift must have a valid Firestore ID to publish.");
      }

      // Update Firestore
      await _firestore.collection('gifts').doc(gift.giftFirebaseId).update({
        'published': true,
      });

      // Update SQLite
      await db.update(
        'gifts',
        {
          ...gift.toMap(),
          'published': 1,
        },
        where: 'id = ?',
        whereArgs: [gift.id],
      );

      print('Gift published successfully in both Firestore and SQLite: ${gift.name}');
    } catch (e) {
      print('Error publishing gift: $e');
      throw e;
    }
  }

  // Unpublish a gift
  Future<void> unpublishGift(GiftModel gift) async {
    final db = await _dbHelper.database;

    try {
      if (gift.giftFirebaseId.isEmpty) {
        throw Exception("Gift must have a valid Firestore ID to unpublish.");
      }

      // Update Firestore to unpublish
      await _firestore.collection('gifts').doc(gift.giftFirebaseId).update({
        'published': false,
      });

      // Update SQLite
      await db.update(
        'gifts',
        {
          ...gift.toMap(),
          'published': 0,
        },
        where: 'id = ?',
        whereArgs: [gift.id],
      );

      print('Gift unpublished successfully in both Firestore and SQLite: ${gift.name}');
    } catch (e) {
      print('Error unpublishing gift: $e');
      throw e;
    }
  }

  // Mark a gift as pledged
  Future<void> pledgeGift(GiftModel gift, String pledgerId) async {
    final db = await _dbHelper.database;

    try {
      if (gift.status == 'Pledged') {
        throw Exception("This gift is already pledged.");
      }

      // Update gift status to pledged
      final updatedGift = gift.copyWith(
        status: 'Pledged',
        pledgedBy: pledgerId, // Save the pledger's ID
      );

      await db.update(
        'gifts',
        updatedGift.toMap(),
        where: 'id = ?',
        whereArgs: [gift.id],
      );

      // Update Firestore
      if (gift.giftFirebaseId.isNotEmpty) {
        await _firestore.collection('gifts').doc(gift.giftFirebaseId).update({
          'status': 'Pledged',
          'pledgedBy': pledgerId, // Add pledger info in Firestore
        });
      }

      print('Gift pledged successfully: ${gift.name}');
    } catch (e) {
      print('Error pledging gift: $e');
      throw e;
    }
  }

  // Delete a gift
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

  // Fetch all gifts for a user
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
  Future<List<GiftModel>> getGiftsByEventAndUser({
    required String eventId,
    required String userId,
  }) async {
    final db = await _dbHelper.database;

    try {
      final List<Map<String, dynamic>> result = await db.query(
        'gifts',
        where: 'eventFirebaseId = ? AND userId = ?',
        whereArgs: [eventId, userId],
      );
      return result.map((e) => GiftModel.fromMap(e)).toList();
    } catch (e) {
      print('Error fetching gifts by event and user: $e');
      throw Exception("Error fetching gifts by event and user: $e");
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
