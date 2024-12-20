import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SQLiteService {
  static final SQLiteService _instance = SQLiteService._internal();
  static Database? _database;

  SQLiteService._internal();

  factory SQLiteService() {
    return _instance;
  }

  // Initialize the database
  Future<Database> _getDatabase() async {
    if (_database != null) {
      return _database!;
    }

    // Get the database path
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'friends.db');

    // Open the database
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE friends (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            myUid TEXT NOT NULL,
            friendUid TEXT NOT NULL
          )
        ''');
      },
    );

    return _database!;
  }

  // Add a friend to the SQLite database
  Future<void> addFriend(String myUid, String friendUid) async {
    final db = await _getDatabase();

    await db.insert(
      'friends',
      {'myUid': myUid, 'friendUid': friendUid},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    print("Friend added to SQLite: $friendUid");
  }

  // Get all friends for a specific user
  Future<List<Map<String, dynamic>>> getFriends(String myUid) async {
    final db = await _getDatabase();
    return await db.query(
      'friends',
      where: 'myUid = ?',
      whereArgs: [myUid],
    );
  }

  // Remove a friend from SQLite
  Future<void> removeFriend(String myUid, String friendUid) async {
    final db = await _getDatabase();

    await db.delete(
      'friends',
      where: 'myUid = ? AND friendUid = ?',
      whereArgs: [myUid, friendUid],
    );
    print("Friend removed from SQLite: $friendUid");
  }

  // Close the database connection
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
