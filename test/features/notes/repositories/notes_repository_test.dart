import 'package:flutter_test/flutter_test.dart';
import 'package:noteprompt/core/database/database_helper.dart';
import 'package:noteprompt/features/notes/models/note_model.dart';
import 'package:noteprompt/features/notes/repositories/notes_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Initialize sqflite_ffi for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('NotesRepository Tests', () {
    late NotesRepository repository;
    late DatabaseHelper databaseHelper;

    setUp(() async {
      // Create a fresh database for each test
      databaseHelper = DatabaseHelper.instance;
      await databaseHelper.deleteDb();
      repository = NotesRepository(databaseHelper);
    });

    tearDown(() async {
      // Clean up after each test
      repository.dispose();
      await databaseHelper.deleteDb();
      await databaseHelper.close();
    });

    test('insertNote should add a note to the database', () async {
      final note = Note.create('# Test Note\nTest content');

      final id = await repository.insertNote(note);

      expect(id, equals(note.id));

      final retrievedNote = await repository.getNoteById(id);
      expect(retrievedNote, isNotNull);
      expect(retrievedNote!.title, equals('Test Note'));
      expect(retrievedNote.content, equals('# Test Note\nTest content'));
    });

    test('getAllNotes should return all notes sorted by updatedAt', () async {
      // Create notes with different timestamps
      final note1 = Note.create('First Note');
      await repository.insertNote(note1);

      // Small delay to ensure different timestamp
      await Future.delayed(const Duration(milliseconds: 10));
      final note2 = Note.create('Second Note');
      await repository.insertNote(note2);

      await Future.delayed(const Duration(milliseconds: 10));
      final note3 = Note.create('Third Note');
      await repository.insertNote(note3);

      final notes = await repository.getAllNotes();

      expect(notes.length, equals(3));
      // Should be sorted by updated_at DESC (most recent first)
      expect(notes[0].title, equals('Third Note'));
      expect(notes[1].title, equals('Second Note'));
      expect(notes[2].title, equals('First Note'));
    });

    test('getNoteById should return null for non-existent note', () async {
      final note = await repository.getNoteById('non-existent-id');

      expect(note, isNull);
    });

    test('updateNote should modify existing note', () async {
      final note = Note.create('Original Content');
      await repository.insertNote(note);

      final updatedNote = note.updateContent('# Updated Content\nNew text');
      final rowsAffected = await repository.updateNote(updatedNote);

      expect(rowsAffected, equals(1));

      final retrievedNote = await repository.getNoteById(note.id);
      expect(retrievedNote!.content, equals('# Updated Content\nNew text'));
      expect(retrievedNote.title, equals('Updated Content'));
    });

    test('deleteNote should remove note from database', () async {
      final note = Note.create('Note to delete');
      await repository.insertNote(note);

      final rowsAffected = await repository.deleteNote(note.id);

      expect(rowsAffected, equals(1));

      final retrievedNote = await repository.getNoteById(note.id);
      expect(retrievedNote, isNull);
    });

    test('deleteNote should return 0 for non-existent note', () async {
      final rowsAffected = await repository.deleteNote('non-existent-id');

      expect(rowsAffected, equals(0));
    });

    test('watchAllNotes should emit notes when data changes', () async {
      final stream = repository.watchAllNotes();

      // Create a note
      final note = Note.create('Test Note');

      // Listen for stream updates
      final streamValues = <List<Note>>[];
      final subscription = stream.listen((notes) {
        streamValues.add(notes);
      });

      // Wait for initial emission
      await Future.delayed(const Duration(milliseconds: 100));

      // Insert note and wait for stream update
      await repository.insertNote(note);
      await Future.delayed(const Duration(milliseconds: 100));

      // Delete note and wait for stream update
      await repository.deleteNote(note.id);
      await Future.delayed(const Duration(milliseconds: 100));

      // Should have at least 3 emissions: initial (empty), after insert, after delete
      expect(streamValues.length, greaterThanOrEqualTo(3));
      expect(streamValues.first.length, equals(0)); // Initial empty state

      await subscription.cancel();
    });

    test('searchNotes should find notes by title', () async {
      await repository.insertNote(Note.create('Flutter Tutorial'));
      await repository.insertNote(Note.create('Dart Guide'));
      await repository.insertNote(Note.create('Flutter Widgets'));

      final results = await repository.searchNotes('Flutter');

      expect(results.length, equals(2));
      expect(results.any((n) => n.title == 'Flutter Tutorial'), isTrue);
      expect(results.any((n) => n.title == 'Flutter Widgets'), isTrue);
    });

    test('searchNotes should find notes by content', () async {
      await repository.insertNote(Note.create('Title 1\nFlutter is awesome'));
      await repository.insertNote(Note.create('Title 2\nDart is great'));
      await repository.insertNote(Note.create('Title 3\nFlutter widgets rock'));

      final results = await repository.searchNotes('Flutter');

      expect(results.length, equals(2));
    });

    test('searchNotes with empty query should return all notes', () async {
      await repository.insertNote(Note.create('Note 1'));
      await repository.insertNote(Note.create('Note 2'));

      final results = await repository.searchNotes('');

      expect(results.length, equals(2));
    });

    test('getNotesCount should return correct count', () async {
      expect(await repository.getNotesCount(), equals(0));

      await repository.insertNote(Note.create('Note 1'));
      expect(await repository.getNotesCount(), equals(1));

      await repository.insertNote(Note.create('Note 2'));
      await repository.insertNote(Note.create('Note 3'));
      expect(await repository.getNotesCount(), equals(3));
    });

    test('deleteAllNotes should remove all notes', () async {
      await repository.insertNote(Note.create('Note 1'));
      await repository.insertNote(Note.create('Note 2'));
      await repository.insertNote(Note.create('Note 3'));

      expect(await repository.getNotesCount(), equals(3));

      final rowsAffected = await repository.deleteAllNotes();
      expect(rowsAffected, equals(3));
      expect(await repository.getNotesCount(), equals(0));
    });

    test('multiple operations should maintain data integrity', () async {
      // Insert multiple notes
      final note1 = Note.create('First');
      final note2 = Note.create('Second');
      final note3 = Note.create('Third');

      await repository.insertNote(note1);
      await repository.insertNote(note2);
      await repository.insertNote(note3);

      // Update one note
      final updatedNote2 = note2.updateContent('Updated Second');
      await repository.updateNote(updatedNote2);

      // Delete one note
      await repository.deleteNote(note1.id);

      // Verify final state
      final allNotes = await repository.getAllNotes();
      expect(allNotes.length, equals(2));

      final retrievedNote2 = await repository.getNoteById(note2.id);
      expect(retrievedNote2!.content, equals('Updated Second'));

      final deletedNote = await repository.getNoteById(note1.id);
      expect(deletedNote, isNull);
    });
  });
}
