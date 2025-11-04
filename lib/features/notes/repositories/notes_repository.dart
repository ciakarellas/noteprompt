import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/database/tables.dart';
import '../models/note_model.dart';

/// Repository for notes database operations
/// Implements CRUD operations and provides streams for real-time updates
class NotesRepository {
  final DatabaseHelper _databaseHelper;

  // StreamController for broadcasting note changes
  final _notesController = StreamController<List<Note>>.broadcast();

  NotesRepository(this._databaseHelper);

  /// Get reference to the database
  Future<Database> get _db async => await _databaseHelper.database;

  /// Get all notes sorted by updated_at (most recent first)
  Future<List<Note>> getAllNotes() async {
    final db = await _db;

    final List<Map<String, dynamic>> maps = await db.query(
      Tables.notes,
      orderBy: '${Tables.columnUpdatedAt} DESC',
    );

    return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
  }

  /// Get a single note by ID
  /// Returns null if note doesn't exist
  Future<Note?> getNoteById(String id) async {
    final db = await _db;

    final List<Map<String, dynamic>> maps = await db.query(
      Tables.notes,
      where: '${Tables.columnId} = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return Note.fromMap(maps.first);
  }

  /// Insert a new note
  /// Returns the ID of the inserted note
  Future<String> insertNote(Note note) async {
    final db = await _db;

    await db.insert(
      Tables.notes,
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Notify listeners about the change
    _notifyListeners();

    return note.id;
  }

  /// Update an existing note
  /// Returns the number of rows affected (should be 1)
  Future<int> updateNote(Note note) async {
    final db = await _db;

    final rowsAffected = await db.update(
      Tables.notes,
      note.toMap(),
      where: '${Tables.columnId} = ?',
      whereArgs: [note.id],
    );

    // Notify listeners about the change
    _notifyListeners();

    return rowsAffected;
  }

  /// Delete a note by ID
  /// Returns the number of rows affected (should be 1)
  Future<int> deleteNote(String id) async {
    final db = await _db;

    final rowsAffected = await db.delete(
      Tables.notes,
      where: '${Tables.columnId} = ?',
      whereArgs: [id],
    );

    // Notify listeners about the change
    _notifyListeners();

    return rowsAffected;
  }

  /// Watch all notes for real-time updates
  /// Returns a stream that emits the current list of notes whenever data changes
  Stream<List<Note>> watchAllNotes() {
    // Emit initial data
    _notifyListeners();

    return _notesController.stream;
  }

  /// Notify all stream listeners about data changes
  Future<void> _notifyListeners() async {
    final notes = await getAllNotes();
    if (!_notesController.isClosed) {
      _notesController.add(notes);
    }
  }

  /// Search notes by title or content
  /// Returns notes that match the query
  Future<List<Note>> searchNotes(String query) async {
    if (query.isEmpty) {
      return getAllNotes();
    }

    final db = await _db;
    final searchPattern = '%$query%';

    final List<Map<String, dynamic>> maps = await db.query(
      Tables.notes,
      where: '${Tables.columnTitle} LIKE ? OR ${Tables.columnContent} LIKE ?',
      whereArgs: [searchPattern, searchPattern],
      orderBy: '${Tables.columnUpdatedAt} DESC',
    );

    return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
  }

  /// Get count of all notes
  Future<int> getNotesCount() async {
    final db = await _db;
    final result = await db.rawQuery('SELECT COUNT(*) FROM ${Tables.notes}');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Delete all notes (useful for testing)
  Future<int> deleteAllNotes() async {
    final db = await _db;
    final rowsAffected = await db.delete(Tables.notes);

    // Notify listeners about the change
    _notifyListeners();

    return rowsAffected;
  }

  /// Close the stream controller
  void dispose() {
    _notesController.close();
  }
}
