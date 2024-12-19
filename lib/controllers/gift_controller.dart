import 'package:sqflite/sqflite.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../database/db_helper.dart';
import '../models/gift_model.dart';

class GiftController {
  final DBHelper _dbHelper = DBHelper();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // Add a new gift to SQLite
  Future<void> addGift(GiftModel gift) async {
    final db = await _dbHelper.database;

    if (gift.eventFirebaseId.isEmpty || gift.userId.isEmpty) {
      throw Exception("Event ID and User ID are required for adding a gift.");
    }

    await db.insert(
      'gifts',
      gift.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('Gift added: ${gift.name}, Event ID: ${gift.eventFirebaseId}, User ID: ${gift.userId}');
  }

  // Update an existing gift in SQLite
  Future<void> updateGift(GiftModel gift) async {
    final db = await _dbHelper.database;

    if (gift.id == null) {
      throw Exception("Gift ID is required for updating.");
    }

    await db.update(
      'gifts',
      gift.toMap(),
      where: 'id = ?',
      whereArgs: [gift.id],
    );
    print('Gift updated: ${gift.name}');
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

  // Fetch all gifts from SQLite for a specific user
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

  // Fetch gifts filtered by eventFirebaseId and userId
  Future<List<GiftModel>> getGiftsByEventAndUser(String eventFirebaseId, String userId) async {
    final db = await _dbHelper.database;

    try {
      final List<Map<String, dynamic>> result = await db.query(
        'gifts',
        where: 'eventFirebaseId = ? AND userId = ?',
        whereArgs: [eventFirebaseId, userId],
      );
      return result.map((e) => GiftModel.fromMap(e)).toList();
    } catch (e) {
      print('Error fetching gifts by event and user: $e');
      throw Exception("Error fetching gifts by event and user: $e");
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

  // Sync gifts from Firestore to SQLite for a specific user
  Future<void> syncGiftsFromFirestore(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('gifts')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in querySnapshot.docs) {
        final gift = GiftModel(
          name: doc['name'] ?? '',
          description: doc['description'] ?? '',
          category: doc['category'] ?? '',
          price: (doc['price'] as num?)?.toDouble() ?? 0.0,
          status: doc['status'] ?? 'Available',
          userId: doc['userId'] ?? '',
          giftFirebaseId: doc.id,
          eventFirebaseId: doc['eventFirebaseId'] ?? '',
          published: doc['published'] ?? false,
        );

        await _insertOrUpdateGift(gift);
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
        await db.insert('gifts', gift.toMap());
        print('Inserted gift: ${gift.name}');
      } else {
        await db.update(
          'gifts',
          gift.toMap(),
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

  // Publish a gift to Firestore
  Future<void> publishGift(GiftModel gift) async {
    if (gift.eventFirebaseId.isEmpty) {
      throw Exception("Event ID is required to publish the gift.");
    }

    try {
      final userUID = await _secureStorage.read(key: 'userUID');
      if (userUID == null) {
        throw Exception("User UID not found. Cannot publish gift.");
      }

      final giftData = {
        'name': gift.name,
        'description': gift.description,
        'category': gift.category,
        'price': gift.price,
        'status': gift.status,
        'userId': userUID,
        'eventFirebaseId': gift.eventFirebaseId,
        'published': true,
      };

      if (gift.giftFirebaseId.isNotEmpty) {
        await _firestore.collection('gifts').doc(gift.giftFirebaseId).set(giftData);
        print('Updated gift in Firestore: ${gift.name}');
      } else {
        final docRef = await _firestore.collection('gifts').add(giftData);
        await updateGift(gift.copyWith(
          giftFirebaseId: docRef.id,
          published: true,
          userId: userUID,
        ));
        print('Published new gift to Firestore: ${gift.name}');
      }
    } catch (e) {
      print('Error publishing gift: $e');
      throw Exception("Error publishing gift: $e");
    }
  }

  // Unpublish a gift (remove from Firestore)
  Future<void> unpublishGift(GiftModel gift) async {
    try {
      if (gift.giftFirebaseId.isNotEmpty) {
        await _firestore.collection('gifts').doc(gift.giftFirebaseId).delete();
        print('Gift removed from Firestore: ${gift.name}');
        await updateGift(gift.copyWith(published: false));
      }
    } catch (e) {
      print('Error unpublishing gift: $e');
      throw Exception("Error unpublishing gift: $e");
    }
  }
}
