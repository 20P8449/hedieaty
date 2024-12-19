import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    return await openDatabase(
      join(dbPath, 'app_databasee.db'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            email TEXT,
            firebaseId TEXT,
            mobile TEXT, -- Added mobile field
            preferences TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            date TEXT,
            location TEXT,
            description TEXT,
            userId TEXT,
            eventFirebaseId TEXT,
            published INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE gifts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          description TEXT,
          category TEXT,
          price REAL NOT NULL,
          status TEXT,
          eventFirebaseId TEXT NOT NULL,
          userId TEXT NOT NULL,
          giftFirebaseId TEXT UNIQUE,
          published INTEGER NOT NULL DEFAULT 0
        );

        ''');
      },
      version: 1,
    );
  }

  // Insert User into SQLite
  Future<void> insertUser(UserModel user) async {
    final db = await database;
    await db.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Fetch User by Firebase ID
  Future<UserModel?> getUserByFirebaseId(String firebaseId) async {
    final db = await database;
    final result = await db.query('users', where: 'firebaseId = ?', whereArgs: [firebaseId]);
    if (result.isNotEmpty) {
      return UserModel.fromMap(result.first);
    }
    return null;
  }

  // Fetch User by Mobile Phone in SQLite
  Future<UserModel?> getUserByMobile(String mobile) async {
    final db = await database;
    final result = await db.query('users', where: 'mobile = ?', whereArgs: [mobile]);
    if (result.isNotEmpty) {
      return UserModel.fromMap(result.first);
    }
    return null;
  }

  // Update User Preferences in SQLite
  Future<void> updateUserPreferences(String firebaseId, String preferences) async {
    final db = await database;
    await db.update(
      'users',
      {'preferences': preferences},
      where: 'firebaseId = ?',
      whereArgs: [firebaseId],
    );
  }

  // Search for a User in Firestore by Mobile Phone
  Future<DocumentSnapshot?> searchUserByPhone(String phone) async {
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('mobile', isEqualTo: phone)
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first;
    }
    return null;
  }

  // Add Friend to Firestore
  Future<void> addFriend(String myUid, String friendUid) async {
    final firestore = FirebaseFirestore.instance;

    // Update my friends array
    await firestore.collection('users').doc(myUid).update({
      'friends': FieldValue.arrayUnion([friendUid]),
    });

    // Update friend's friends array
    await firestore.collection('users').doc(friendUid).update({
      'friends': FieldValue.arrayUnion([myUid]),
    });
  }
}
