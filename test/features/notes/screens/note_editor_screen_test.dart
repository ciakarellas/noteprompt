import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noteprompt/core/database/database_helper.dart';
import 'package:noteprompt/features/notes/models/note_model.dart';
import 'package:noteprompt/features/notes/providers/editor_provider.dart';
import 'package:noteprompt/features/notes/providers/notes_provider.dart';
import 'package:noteprompt/features/notes/screens/note_editor_screen.dart';
import 'package:noteprompt/features/notes/widgets/markdown_editor.dart';
import 'package:noteprompt/features/notes/widgets/view_mode_toggle.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Initialize sqflite_ffi for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('NoteEditorScreen Widget Tests', () {
    late DatabaseHelper databaseHelper;
    late ProviderContainer container;
    late Note testNote;

    setUp(() async {
      databaseHelper = DatabaseHelper.instance;
      await databaseHelper.deleteDb();

      container = ProviderContainer();

      // Create and insert a test note
      testNote = Note.create('# Test Note\nTest content');
      final repository = container.read(notesRepositoryProvider);
      await repository.insertNote(testNote);
    });

    tearDown(() async {
      container.dispose();
      await databaseHelper.deleteDb();
      await databaseHelper.close();
    });

    Widget createTestWidget(String noteId) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: NoteEditorScreen(noteId: noteId),
        ),
      );
    }

    testWidgets('should display loading indicator initially', (tester) async {
      await tester.pumpWidget(createTestWidget(testNote.id));

      // Should show loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading...'), findsOneWidget);
    });

    testWidgets('should load and display note content', (tester) async {
      await tester.pumpWidget(createTestWidget(testNote.id));
      await tester.pumpAndSettle();

      // Should display note title
      expect(find.text(testNote.title), findsOneWidget);

      // Should display MarkdownEditor
      expect(find.byType(MarkdownEditor), findsOneWidget);

      // Should show "Saved" status
      expect(find.text('Saved'), findsOneWidget);
    });

    testWidgets('should display ViewModeToggle and Save buttons', (tester) async {
      await tester.pumpWidget(createTestWidget(testNote.id));
      await tester.pumpAndSettle();

      // Should have ViewModeToggle
      expect(find.byType(ViewModeToggle), findsOneWidget);

      // Should have save button
      expect(find.widgetWithIcon(IconButton, Icons.save), findsOneWidget);
    });

    testWidgets('should show error and pop when note not found', (tester) async {
      await tester.pumpWidget(createTestWidget('non-existent-id'));
      await tester.pumpAndSettle();

      // Should show error snackbar
      expect(find.text('Note not found'), findsOneWidget);

      // Screen should have popped (back to empty route)
      expect(find.byType(NoteEditorScreen), findsNothing);
    });

    testWidgets('should mark as modified when text changes', (tester) async {
      await tester.pumpWidget(createTestWidget(testNote.id));
      await tester.pumpAndSettle();

      // Initially should show "Saved"
      expect(find.text('Saved'), findsOneWidget);

      // Find and tap the text field to edit
      final textField = find.byType(TextField).first;
      await tester.tap(textField);
      await tester.pumpAndSettle();

      // Enter new text
      await tester.enterText(textField, '# Updated Note\nUpdated content');
      await tester.pump();

      // Should show "Unsaved changes"
      expect(find.text('Unsaved changes'), findsOneWidget);

      // EditorState should reflect unsaved changes
      final editorState = container.read(editorStateProvider);
      expect(editorState.hasUnsavedChanges, isTrue);
    });

    testWidgets('should manually save note when save button pressed', (tester) async {
      await tester.pumpWidget(createTestWidget(testNote.id));
      await tester.pumpAndSettle();

      // Modify text
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, '# Manual Save Test\nNew content');
      await tester.pump();

      // Tap save button
      final saveButton = find.widgetWithIcon(IconButton, Icons.save);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Should show "Note saved" snackbar
      expect(find.text('Note saved'), findsOneWidget);

      // Should show "Saved" status
      expect(find.text('Saved'), findsOneWidget);

      // Verify note was saved in database
      final repository = container.read(notesRepositoryProvider);
      final savedNote = await repository.getNoteById(testNote.id);
      expect(savedNote?.content, equals('# Manual Save Test\nNew content'));
      expect(savedNote?.title, equals('Manual Save Test'));
    });

    testWidgets('should auto-save after 2 seconds of inactivity', (tester) async {
      await tester.pumpWidget(createTestWidget(testNote.id));
      await tester.pumpAndSettle();

      // Modify text
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, '# Auto Save Test\nAuto-saved content');
      await tester.pump();

      // Wait for auto-save debounce (2 seconds)
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Should be marked as saved
      expect(find.text('Saved'), findsOneWidget);

      // Verify note was auto-saved
      final repository = container.read(notesRepositoryProvider);
      final savedNote = await repository.getNoteById(testNote.id);
      expect(savedNote?.content, equals('# Auto Save Test\nAuto-saved content'));
    });

    testWidgets('should debounce auto-save correctly', (tester) async {
      await tester.pumpWidget(createTestWidget(testNote.id));
      await tester.pumpAndSettle();

      final textField = find.byType(TextField).first;

      // Type first change
      await tester.enterText(textField, 'First');
      await tester.pump();

      // Wait 1 second (less than debounce time)
      await tester.pump(const Duration(seconds: 1));

      // Type second change
      await tester.enterText(textField, 'Second');
      await tester.pump();

      // Wait 1 more second (total 2 seconds from last change)
      await tester.pump(const Duration(seconds: 1));

      // Should still show unsaved
      expect(find.text('Unsaved changes'), findsOneWidget);

      // Wait 1 more second (total 2 seconds from last edit)
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Now should be saved
      expect(find.text('Saved'), findsOneWidget);
    });

    testWidgets('should show unsaved changes dialog when back pressed with changes', (tester) async {
      await tester.pumpWidget(createTestWidget(testNote.id));
      await tester.pumpAndSettle();

      // Modify text
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, 'Modified content');
      await tester.pump();

      // Try to go back
      final backButton = find.byType(BackButton);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Should show unsaved changes dialog
      expect(find.text('Unsaved Changes'), findsOneWidget);
      expect(find.text('You have unsaved changes. Do you want to save before leaving?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('should allow back navigation when no unsaved changes', (tester) async {
      await tester.pumpWidget(createTestWidget(testNote.id));
      await tester.pumpAndSettle();

      // Don't modify anything

      // Press back
      final backButton = find.byType(BackButton);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Should not show dialog, should just pop
      expect(find.text('Unsaved Changes'), findsNothing);
      expect(find.byType(NoteEditorScreen), findsNothing);
    });

    testWidgets('should cancel back navigation when Cancel pressed in dialog', (tester) async {
      await tester.pumpWidget(createTestWidget(testNote.id));
      await tester.pumpAndSettle();

      // Modify text
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, 'Modified');
      await tester.pump();

      // Try to go back
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Should still be on editor screen
      expect(find.byType(NoteEditorScreen), findsOneWidget);
      expect(find.text('Unsaved changes'), findsOneWidget);
    });

    testWidgets('should discard changes and pop when Discard pressed', (tester) async {
      await tester.pumpWidget(createTestWidget(testNote.id));
      await tester.pumpAndSettle();

      // Modify text
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, '# Discarded\nThis should be discarded');
      await tester.pump();

      // Try to go back
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Tap Discard
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      // Should have popped
      expect(find.byType(NoteEditorScreen), findsNothing);

      // Verify changes were not saved
      final repository = container.read(notesRepositoryProvider);
      final note = await repository.getNoteById(testNote.id);
      expect(note?.content, equals(testNote.content)); // Original content
    });

    testWidgets('should save changes and pop when Save pressed in dialog', (tester) async {
      await tester.pumpWidget(createTestWidget(testNote.id));
      await tester.pumpAndSettle();

      // Modify text
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, '# Saved on Exit\nSaved content');
      await tester.pump();

      // Try to go back
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Tap Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Should have popped
      expect(find.byType(NoteEditorScreen), findsNothing);

      // Verify changes were saved
      final repository = container.read(notesRepositoryProvider);
      final note = await repository.getNoteById(testNote.id);
      expect(note?.content, equals('# Saved on Exit\nSaved content'));
    });

    testWidgets('should disable save button when saving', (tester) async {
      await tester.pumpWidget(createTestWidget(testNote.id));
      await tester.pumpAndSettle();

      // Modify text
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, 'Modified');
      await tester.pump();

      // Find save button before tapping
      final saveButton = find.widgetWithIcon(IconButton, Icons.save);
      final saveIconButton = tester.widget<IconButton>(saveButton);
      expect(saveIconButton.onPressed, isNotNull);

      // Tap save (but don't wait for it to complete)
      await tester.tap(saveButton);
      await tester.pump(); // Just one pump to show "Saving..."

      // Should show "Saving..." status
      expect(find.text('Saving...'), findsOneWidget);
    });

    testWidgets('should set current note ID in editor state on init', (tester) async {
      await tester.pumpWidget(createTestWidget(testNote.id));
      await tester.pumpAndSettle();

      final editorState = container.read(editorStateProvider);
      expect(editorState.currentNoteId, equals(testNote.id));
    });

    testWidgets('should reset editor state when disposed', (tester) async {
      await tester.pumpWidget(createTestWidget(testNote.id));
      await tester.pumpAndSettle();

      // Modify state
      container.read(editorStateProvider.notifier).toggleView();
      container.read(editorStateProvider.notifier).markAsModified();

      // Pop the screen
      final backButton = find.byType(BackButton);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Discard changes
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      // Editor state should be reset
      final editorState = container.read(editorStateProvider);
      expect(editorState.isMarkdownView, isFalse);
      expect(editorState.hasUnsavedChanges, isFalse);
      expect(editorState.currentNoteId, isNull);
    });

    testWidgets('should handle save errors gracefully', (tester) async {
      // Close database to force an error
      await databaseHelper.close();

      await tester.pumpWidget(createTestWidget(testNote.id));

      // Should show loading then error
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      // Should show error and pop
      expect(find.textContaining('Error loading note'), findsOneWidget);
    });

    testWidgets('should not save if content has not changed', (tester) async {
      await tester.pumpWidget(createTestWidget(testNote.id));
      await tester.pumpAndSettle();

      // Get initial updated timestamp
      final repository = container.read(notesRepositoryProvider);
      final initialNote = await repository.getNoteById(testNote.id);
      final initialUpdatedAt = initialNote!.updatedAt;

      // Tap save without modifying content
      final saveButton = find.widgetWithIcon(IconButton, Icons.save);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Check that updatedAt hasn't changed (no actual save occurred)
      final noteAfterSave = await repository.getNoteById(testNote.id);
      expect(noteAfterSave!.updatedAt, equals(initialUpdatedAt));
    });

    testWidgets('should update note title when content changes', (tester) async {
      await tester.pumpWidget(createTestWidget(testNote.id));
      await tester.pumpAndSettle();

      // Change content with new title
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, '# Brand New Title\nNew content');
      await tester.pump();

      // Save
      await tester.tap(find.widgetWithIcon(IconButton, Icons.save));
      await tester.pumpAndSettle();

      // Title in AppBar should update
      expect(find.text('Brand New Title'), findsOneWidget);

      // Verify in database
      final repository = container.read(notesRepositoryProvider);
      final savedNote = await repository.getNoteById(testNote.id);
      expect(savedNote?.title, equals('Brand New Title'));
    });
  });

  group('NoteEditorScreen Integration Tests', () {
    late DatabaseHelper databaseHelper;

    setUp(() async {
      databaseHelper = DatabaseHelper.instance;
      await databaseHelper.deleteDb();
    });

    tearDown(() async {
      await databaseHelper.deleteDb();
      await databaseHelper.close();
    });

    testWidgets('should handle complete user flow: create, edit, save, exit', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Create a new note
      final repository = container.read(notesRepositoryProvider);
      final newNote = Note.create('');
      await repository.insertNote(newNote);

      // Open editor
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: NoteEditorScreen(noteId: newNote.id),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Edit note
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, '# My New Note\nWith some content');
      await tester.pump();

      // Wait for auto-save
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Exit (no unsaved changes after auto-save)
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Verify saved
      final savedNote = await repository.getNoteById(newNote.id);
      expect(savedNote?.content, equals('# My New Note\nWith some content'));
      expect(savedNote?.title, equals('My New Note'));
    });
  });
}
