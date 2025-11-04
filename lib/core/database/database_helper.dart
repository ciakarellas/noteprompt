import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'tables.dart';

/// SQLite database helper with singleton pattern
/// Manages database initialization, versioning, and migrations
class DatabaseHelper {
  static const String _databaseName = 'noteprompt.db';
  static const int _databaseVersion = 1;

  // Singleton pattern
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // Database instance (cached)
  static Database? _database;

  /// Get database instance, initializing if necessary
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the database
  Future<Database> _initDatabase() async {
    final String databasePath = await getDatabasesPath();
    final String path = join(databasePath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables on first run
  Future<void> _onCreate(Database db, int version) async {
    // Create notes table
    await db.execute(Tables.createNotesTable);

    // Create index for better query performance
    await db.execute(Tables.createUpdatedAtIndex);
  }

  /// Handle database migrations when version changes
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migrations will be handled here
    // Example:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE notes ADD COLUMN new_column TEXT');
    // }
    // if (oldVersion < 3) {
    //   await db.execute('CREATE TABLE new_table (...)');
    // }
  }

  /// Close the database connection
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  /// Delete the database (useful for testing)
  Future<void> deleteDb() async {
    final String databasePath = await getDatabasesPath();
    final String path = join(databasePath, _databaseName);
    await deleteDatabase(path);
    _database = null;
  }
}
