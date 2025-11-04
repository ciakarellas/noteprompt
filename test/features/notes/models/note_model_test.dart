import 'package:flutter_test/flutter_test.dart';
import 'package:noteprompt/features/notes/models/note_model.dart';

void main() {
  group('Note Model Tests', () {
    test('Note.create should generate a new note with auto-generated ID and title', () {
      const content = '# My First Note\nThis is the content';

      final note = Note.create(content);

      expect(note.id, isNotEmpty);
      expect(note.title, equals('My First Note'));
      expect(note.content, equals(content));
      expect(note.createdAt, isNotNull);
      expect(note.updatedAt, isNotNull);
      expect(note.createdAt, equals(note.updatedAt));
    });

    test('Note should extract title from content without markdown syntax', () {
      const content = '## Getting Started\nLorem ipsum';
      final note = Note.create(content);

      expect(note.title, equals('Getting Started'));
    });

    test('Note should handle empty content with default title', () {
      const content = '';
      final note = Note.create(content);

      expect(note.title, equals('Untitled Note'));
    });

    test('Note should handle content with only whitespace', () {
      const content = '   \n\n  ';
      final note = Note.create(content);

      expect(note.title, equals('Untitled Note'));
    });

    test('Note should truncate long titles', () {
      const content = 'This is a very long title that exceeds fifty characters and should be truncated';
      final note = Note.create(content);

      expect(note.title.length, lessThanOrEqualTo(50));
      expect(note.title.endsWith('...'), isTrue);
    });

    test('Note should handle plain text without markdown heading', () {
      const content = 'Plain text note\nWith more content';
      final note = Note.create(content);

      expect(note.title, equals('Plain text note'));
    });

    test('Note.toMap should convert note to database map', () {
      final now = DateTime(2024, 1, 1, 12, 0, 0);
      final note = Note(
        id: 'test-id',
        title: 'Test Note',
        content: 'Test Content',
        createdAt: now,
        updatedAt: now,
      );

      final map = note.toMap();

      expect(map['id'], equals('test-id'));
      expect(map['title'], equals('Test Note'));
      expect(map['content'], equals('Test Content'));
      expect(map['created_at'], equals(now.millisecondsSinceEpoch));
      expect(map['updated_at'], equals(now.millisecondsSinceEpoch));
    });

    test('Note.fromMap should create note from database map', () {
      final now = DateTime(2024, 1, 1, 12, 0, 0);
      final map = {
        'id': 'test-id',
        'title': 'Test Note',
        'content': 'Test Content',
        'created_at': now.millisecondsSinceEpoch,
        'updated_at': now.millisecondsSinceEpoch,
      };

      final note = Note.fromMap(map);

      expect(note.id, equals('test-id'));
      expect(note.title, equals('Test Note'));
      expect(note.content, equals('Test Content'));
      expect(note.createdAt, equals(now));
      expect(note.updatedAt, equals(now));
    });

    test('Note.fromMap should handle missing title with default', () {
      final now = DateTime(2024, 1, 1, 12, 0, 0);
      final map = {
        'id': 'test-id',
        'content': 'Test Content',
        'created_at': now.millisecondsSinceEpoch,
        'updated_at': now.millisecondsSinceEpoch,
      };

      final note = Note.fromMap(map);

      expect(note.title, equals('Untitled Note'));
    });

    test('Note.copyWith should create a copy with updated fields', () {
      final now = DateTime(2024, 1, 1, 12, 0, 0);
      final note = Note(
        id: 'test-id',
        title: 'Test Note',
        content: 'Test Content',
        createdAt: now,
        updatedAt: now,
      );

      final updatedNote = note.copyWith(
        title: 'Updated Title',
        content: 'Updated Content',
      );

      expect(updatedNote.id, equals(note.id));
      expect(updatedNote.title, equals('Updated Title'));
      expect(updatedNote.content, equals('Updated Content'));
      expect(updatedNote.createdAt, equals(note.createdAt));
      expect(updatedNote.updatedAt, equals(note.updatedAt));
    });

    test('Note.updateContent should update content and title with new timestamp', () {
      final now = DateTime(2024, 1, 1, 12, 0, 0);
      final note = Note(
        id: 'test-id',
        title: 'Old Title',
        content: 'Old Content',
        createdAt: now,
        updatedAt: now,
      );

      // Small delay to ensure different timestamp
      final updatedNote = note.updateContent('# New Title\nNew Content');

      expect(updatedNote.content, equals('# New Title\nNew Content'));
      expect(updatedNote.title, equals('New Title'));
      expect(updatedNote.updatedAt.isAfter(note.updatedAt), isTrue);
      expect(updatedNote.createdAt, equals(note.createdAt));
    });

    test('Note equality should work correctly', () {
      final now = DateTime(2024, 1, 1, 12, 0, 0);
      final note1 = Note(
        id: 'test-id',
        title: 'Test Note',
        content: 'Test Content',
        createdAt: now,
        updatedAt: now,
      );
      final note2 = Note(
        id: 'test-id',
        title: 'Test Note',
        content: 'Test Content',
        createdAt: now,
        updatedAt: now,
      );

      expect(note1, equals(note2));
      expect(note1.hashCode, equals(note2.hashCode));
    });

    test('Note toString should return readable string', () {
      final now = DateTime(2024, 1, 1, 12, 0, 0);
      final note = Note(
        id: 'test-id',
        title: 'Test Note',
        content: 'Test Content',
        createdAt: now,
        updatedAt: now,
      );

      final string = note.toString();

      expect(string, contains('test-id'));
      expect(string, contains('Test Note'));
    });

    test('Note serialization round-trip should preserve data', () {
      const content = '# My Note\nSome content here';
      final originalNote = Note.create(content);

      final map = originalNote.toMap();
      final deserializedNote = Note.fromMap(map);

      expect(deserializedNote.id, equals(originalNote.id));
      expect(deserializedNote.title, equals(originalNote.title));
      expect(deserializedNote.content, equals(originalNote.content));
      expect(deserializedNote.createdAt, equals(originalNote.createdAt));
      expect(deserializedNote.updatedAt, equals(originalNote.updatedAt));
    });
  });
}
