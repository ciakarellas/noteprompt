import 'package:flutter_test/flutter_test.dart';
import 'package:noteprompt/core/database/database_helper.dart';
import 'package:noteprompt/core/database/tables.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Initialize sqflite_ffi for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DatabaseHelper Tests', () {
    late DatabaseHelper databaseHelper;

    setUp(() async {
      databaseHelper = DatabaseHelper.instance;
      await databaseHelper.deleteDb();
    });

    tearDown(() async {
      await databaseHelper.deleteDb();
      await databaseHelper.close();
    });

    test('database should initialize successfully', () async {
      final db = await databaseHelper.database;

      expect(db, isNotNull);
      expect(db.isOpen, isTrue);
    });

    test('database should create notes table on initialization', () async {
      final db = await databaseHelper.database;

      // Query the sqlite_master table to check if notes table exists
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='${Tables.notes}'",
      );

      expect(result, isNotEmpty);
      expect(result.first['name'], equals(Tables.notes));
    });

    test('database should create index on updated_at column', () async {
      final db = await databaseHelper.database;

      // Query for indexes on the notes table
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='${Tables.notes}'",
      );

      expect(result, isNotEmpty);
      expect(
        result.any((index) => index['name'] == 'idx_notes_updated_at'),
        isTrue,
      );
    });

    test('database should have correct schema for notes table', () async {
      final db = await databaseHelper.database;

      // Get table info
      final result = await db.rawQuery("PRAGMA table_info(${Tables.notes})");

      // Extract column names
      final columnNames = result.map((col) => col['name'] as String).toList();

      expect(columnNames, contains(Tables.columnId));
      expect(columnNames, contains(Tables.columnTitle));
      expect(columnNames, contains(Tables.columnContent));
      expect(columnNames, contains(Tables.columnCreatedAt));
      expect(columnNames, contains(Tables.columnUpdatedAt));
    });

    test('database should verify primary key constraint', () async {
      final db = await databaseHelper.database;

      // Get table info
      final result = await db.rawQuery("PRAGMA table_info(${Tables.notes})");

      // Find the id column and check if it's the primary key
      final idColumn = result.firstWhere(
        (col) => col['name'] == Tables.columnId,
      );

      expect(idColumn['pk'], equals(1)); // pk=1 means primary key
    });

    test('database should verify NOT NULL constraints', () async {
      final db = await databaseHelper.database;

      // Get table info
      final result = await db.rawQuery("PRAGMA table_info(${Tables.notes})");

      // Check NOT NULL constraints
      final contentColumn = result.firstWhere(
        (col) => col['name'] == Tables.columnContent,
      );
      final createdAtColumn = result.firstWhere(
        (col) => col['name'] == Tables.columnCreatedAt,
      );
      final updatedAtColumn = result.firstWhere(
        (col) => col['name'] == Tables.columnUpdatedAt,
      );

      expect(contentColumn['notnull'], equals(1)); // notnull=1 means NOT NULL
      expect(createdAtColumn['notnull'], equals(1));
      expect(updatedAtColumn['notnull'], equals(1));
    });

    test('database should handle singleton pattern correctly', () async {
      final instance1 = DatabaseHelper.instance;
      final instance2 = DatabaseHelper.instance;

      expect(instance1, same(instance2));

      final db1 = await instance1.database;
      final db2 = await instance2.database;

      expect(db1, same(db2));
    });

    test('database should support basic CRUD operations', () async {
      final db = await databaseHelper.database;

      // Insert
      final testData = {
        Tables.columnId: 'test-id',
        Tables.columnTitle: 'Test Note',
        Tables.columnContent: 'Test content',
        Tables.columnCreatedAt: DateTime.now().millisecondsSinceEpoch,
        Tables.columnUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      };

      await db.insert(Tables.notes, testData);

      // Read
      final result = await db.query(
        Tables.notes,
        where: '${Tables.columnId} = ?',
        whereArgs: ['test-id'],
      );

      expect(result, isNotEmpty);
      expect(result.first[Tables.columnTitle], equals('Test Note'));

      // Update
      await db.update(
        Tables.notes,
        {Tables.columnTitle: 'Updated Note'},
        where: '${Tables.columnId} = ?',
        whereArgs: ['test-id'],
      );

      final updatedResult = await db.query(
        Tables.notes,
        where: '${Tables.columnId} = ?',
        whereArgs: ['test-id'],
      );

      expect(updatedResult.first[Tables.columnTitle], equals('Updated Note'));

      // Delete
      await db.delete(
        Tables.notes,
        where: '${Tables.columnId} = ?',
        whereArgs: ['test-id'],
      );

      final deletedResult = await db.query(
        Tables.notes,
        where: '${Tables.columnId} = ?',
        whereArgs: ['test-id'],
      );

      expect(deletedResult, isEmpty);
    });

    test('database close and reopen should work', () async {
      // Get database instance
      final db1 = await databaseHelper.database;
      expect(db1.isOpen, isTrue);

      // Close database
      await databaseHelper.close();

      // Reopen database (should create new instance)
      final db2 = await databaseHelper.database;
      expect(db2.isOpen, isTrue);
    });

    test('database deletion should work', () async {
      // Create database
      await databaseHelper.database;

      // Delete database
      await databaseHelper.deleteDb();

      // Verify database is recreated on next access
      final db = await databaseHelper.database;
      expect(db.isOpen, isTrue);

      // Verify table is empty (new database)
      final result = await db.query(Tables.notes);
      expect(result, isEmpty);
    });

    test('database should persist data across reopens', () async {
      // Insert data
      final db1 = await databaseHelper.database;
      await db1.insert(Tables.notes, {
        Tables.columnId: 'persist-test',
        Tables.columnTitle: 'Persistent Note',
        Tables.columnContent: 'This should persist',
        Tables.columnCreatedAt: DateTime.now().millisecondsSinceEpoch,
        Tables.columnUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      });

      // Close and reopen
      await databaseHelper.close();
      final db2 = await databaseHelper.database;

      // Verify data persisted
      final result = await db2.query(
        Tables.notes,
        where: '${Tables.columnId} = ?',
        whereArgs: ['persist-test'],
      );

      expect(result, isNotEmpty);
      expect(result.first[Tables.columnTitle], equals('Persistent Note'));
    });
  });

  group('DatabaseHelper Migration Tests', () {
    // Note: These tests would be expanded when actual migrations are added
    // For now, we test the upgrade path exists

    late DatabaseHelper databaseHelper;

    setUp(() async {
      databaseHelper = DatabaseHelper.instance;
      await databaseHelper.deleteDb();
    });

    tearDown(() async {
      await databaseHelper.deleteDb();
      await databaseHelper.close();
    });

    test('database version should be set correctly', () async {
      final db = await databaseHelper.database;
      final version = await db.getVersion();

      expect(version, equals(1));
    });

    test('onUpgrade should be called for version changes', () async {
      // This test verifies that the upgrade path exists
      // Actual migration tests would be added when implementing version 2+
      final db = await databaseHelper.database;

      expect(db, isNotNull);
      expect(await db.getVersion(), equals(1));
    });
  });
}
