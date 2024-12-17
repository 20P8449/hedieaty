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
      join(dbPath, 'app_database111223.db'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            email TEXT,
            firebaseId TEXT,
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
        // Create gifts table
        await db.execute('''
          CREATE TABLE gifts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            description TEXT,
            category TEXT,
            price REAL,
            status TEXT,
            eventFirebaseId TEXT,
            userId TEXT,
            giftFirebaseId TEXT,
            published INTEGER
          )
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

  // Update User Preferences
  Future<void> updateUserPreferences(String firebaseId, String preferences) async {
    final db = await database;
    await db.update(
      'users',
      {'preferences': preferences},
      where: 'firebaseId = ?',
      whereArgs: [firebaseId],
    );
  }
}
