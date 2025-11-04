import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noteprompt/core/database/database_helper.dart';
import 'package:noteprompt/features/notes/models/note_model.dart';
import 'package:noteprompt/features/notes/providers/notes_provider.dart';
import 'package:noteprompt/features/notes/repositories/notes_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Initialize sqflite_ffi for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Notes Providers Tests', () {
    late ProviderContainer container;
    late DatabaseHelper databaseHelper;

    setUp(() async {
      databaseHelper = DatabaseHelper.instance;
      await databaseHelper.deleteDb();
      container = ProviderContainer();
    });

    tearDown(() async {
      container.dispose();
      await databaseHelper.deleteDb();
      await databaseHelper.close();
    });

    test('databaseProvider should return DatabaseHelper instance', () {
      final database = container.read(databaseProvider);

      expect(database, isA<DatabaseHelper>());
      expect(database, same(DatabaseHelper.instance));
    });

    test('notesRepositoryProvider should return NotesRepository instance', () {
      final repository = container.read(notesRepositoryProvider);

      expect(repository, isA<NotesRepository>());
    });

    test('notesListProvider should provide stream of notes', () async {
      final repository = container.read(notesRepositoryProvider);

      // Insert a test note
      final note = Note.create('Test Note');
      await repository.insertNote(note);

      // Read from provider
      final notesAsync = container.read(notesListProvider);

      await expectLater(
        notesAsync.future,
        completion(isA<List<Note>>()),
      );
    });

    test('noteProvider should fetch note by ID', () async {
      final repository = container.read(notesRepositoryProvider);

      // Insert a test note
      final note = Note.create('Test Note');
      await repository.insertNote(note);

      // Fetch using provider
      final noteAsync = await container.read(noteProvider(note.id).future);

      expect(noteAsync, isNotNull);
      expect(noteAsync!.id, equals(note.id));
      expect(noteAsync.title, equals(note.title));
    });

    test('noteProvider should return null for non-existent ID', () async {
      final noteAsync = await container.read(noteProvider('non-existent').future);

      expect(noteAsync, isNull);
    });

    test('notesCountProvider should return correct count', () async {
      final repository = container.read(notesRepositoryProvider);

      // Insert multiple notes
      await repository.insertNote(Note.create('Note 1'));
      await repository.insertNote(Note.create('Note 2'));
      await repository.insertNote(Note.create('Note 3'));

      final count = await container.read(notesCountProvider.future);

      expect(count, equals(3));
    });

    test('searchNotesProvider should find matching notes', () async {
      final repository = container.read(notesRepositoryProvider);

      // Insert test notes
      await repository.insertNote(Note.create('Flutter Tutorial'));
      await repository.insertNote(Note.create('Dart Guide'));
      await repository.insertNote(Note.create('Flutter Widgets'));

      final results = await container.read(searchNotesProvider('Flutter').future);

      expect(results.length, equals(2));
      expect(results.any((n) => n.title == 'Flutter Tutorial'), isTrue);
      expect(results.any((n) => n.title == 'Flutter Widgets'), isTrue);
    });

    test('providers should be properly scoped', () {
      // Create two separate containers
      final container1 = ProviderContainer();
      final container2 = ProviderContainer();

      final database1 = container1.read(databaseProvider);
      final database2 = container2.read(databaseProvider);

      // Both should return the same singleton instance
      expect(database1, same(database2));

      container1.dispose();
      container2.dispose();
    });

    test('repository should be disposed when provider is destroyed', () async {
      // Create a new container
      final testContainer = ProviderContainer();

      // Access the repository
      final repository = testContainer.read(notesRepositoryProvider);
      expect(repository, isNotNull);

      // Dispose the container
      testContainer.dispose();

      // The repository's stream controller should be closed
      // Note: We can't directly test if dispose was called, but we can verify
      // that the container was properly disposed
      expect(testContainer.getAllProviderElements(), isEmpty);
    });
  });
}
