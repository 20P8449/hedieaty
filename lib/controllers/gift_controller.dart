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

    // Validate that eventFirebaseId is provided
    if (gift.eventFirebaseId.isEmpty) {
      print('Error: Event ID must be associated with the gift.');
      throw Exception("Event ID is required for adding a gift.");
    }

    await db.insert(
      'gifts',
      gift.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('Gift added: ${gift.name}, Event ID: ${gift.eventFirebaseId}');
  }

  // Update an existing gift in SQLite
  Future<void> updateGift(GiftModel gift) async {
    final db = await _dbHelper.database;
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
      GiftModel? gift = await getGiftById(id);

      if (gift != null && gift.giftFirebaseId.isNotEmpty) {
        await _firestore.collection('gifts').doc(gift.giftFirebaseId).delete();
        print('Gift deleted from Firestore: ${gift.giftFirebaseId}');
      }

      await db.delete('gifts', where: 'id = ?', whereArgs: [id]);
      print('Gift deleted from SQLite with ID: $id');
    } catch (e) {
      print('Error deleting gift: $e');
    }
  }

  // Fetch all gifts from SQLite
  Future<List<GiftModel>> getAllGifts() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> result = await db.query('gifts');
    return result.map((e) => GiftModel.fromMap(e)).toList();
  }

  // Get a gift by ID
  Future<GiftModel?> getGiftById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query('gifts', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return GiftModel.fromMap(result.first);
    }
    return null;
  }

  // Sync Gifts from Firestore to SQLite
  Future<void> syncGiftsFromFirestore() async {
    try {
      String? userUID = await _secureStorage.read(key: 'userUID');
      if (userUID == null) {
        print('User UID not found. Cannot sync gifts.');
        return;
      }

      QuerySnapshot querySnapshot = await _firestore
          .collection('gifts')
          .where('userId', isEqualTo: userUID)
          .get();

      for (var doc in querySnapshot.docs) {
        GiftModel gift = GiftModel(
          name: doc['name'] ?? '',
          description: doc['description'] ?? '',
          category: doc['category'] ?? '',
          price: (doc['price'] as num?)?.toDouble() ?? 0.0,
          status: doc['status'] ?? 'Available',
          userId: doc['userId'] ?? '',
          giftFirebaseId: doc.id,
          eventFirebaseId: doc['eventFirebaseId'] ?? '',
          published: (doc['published'] is bool) ? doc['published'] : (doc['published'] == 1),
        );

        await _insertOrUpdateGift(gift);
      }

      print('Gifts synchronized from Firestore to SQLite.');
    } catch (e) {
      print('Error syncing gifts from Firestore: $e');
    }
  }

  // Insert or Update Gift in SQLite
  Future<void> _insertOrUpdateGift(GiftModel gift) async {
    final db = await _dbHelper.database;

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
  }

  // Publish Gift to Firestore
  Future<void> publishGift(GiftModel gift) async {
    try {
      if (gift.eventFirebaseId.isEmpty) {
        print('Error: Gift must be associated with an event before publishing.');
        throw Exception("Event ID is required to publish the gift.");
      }

      String? userUID = await _secureStorage.read(key: 'userUID');
      if (userUID == null) {
        print('User UID not found. Cannot publish gift.');
        return;
      }

      Map<String, dynamic> giftData = {
        'name': gift.name,
        'description': gift.description,
        'category': gift.category,
        'price': gift.price,
        'status': gift.status,
        'userId': userUID,
        'eventFirebaseId': gift.eventFirebaseId,
        'published': true,
      };

      String firestoreId = gift.giftFirebaseId;

      if (firestoreId.isNotEmpty) {
        await _firestore.collection('gifts').doc(firestoreId).set(giftData);
        print('Updated gift in Firestore: ${gift.name}');
      } else {
        DocumentReference docRef = await _firestore.collection('gifts').add(giftData);
        firestoreId = docRef.id;
        print('Published new gift to Firestore: ${gift.name}');
      }

      await updateGift(gift.copyWith(
        giftFirebaseId: firestoreId,
        published: true,
        userId: userUID,
      ));
    } catch (e) {
      print('Error publishing gift: $e');
    }
  }

  // Unpublish Gift (Remove from Firestore)
  Future<void> unpublishGift(GiftModel gift) async {
    try {
      if (gift.giftFirebaseId.isNotEmpty) {
        await _firestore.collection('gifts').doc(gift.giftFirebaseId).delete();
        print('Gift removed from Firestore: ${gift.name}');

        await updateGift(gift.copyWith(published: false));
      }
    } catch (e) {
      print('Error unpublishing gift: $e');
    }
  }
}
