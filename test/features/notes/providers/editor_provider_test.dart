import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noteprompt/features/notes/providers/editor_provider.dart';

void main() {
  group('EditorState Tests', () {
    test('EditorState should have correct default values', () {
      const state = EditorState();

      expect(state.isMarkdownView, isFalse);
      expect(state.hasUnsavedChanges, isFalse);
      expect(state.currentNoteId, isNull);
    });

    test('EditorState.copyWith should update only specified fields', () {
      const state = EditorState();

      final updated = state.copyWith(
        isMarkdownView: true,
        hasUnsavedChanges: true,
      );

      expect(updated.isMarkdownView, isTrue);
      expect(updated.hasUnsavedChanges, isTrue);
      expect(updated.currentNoteId, isNull); // Should remain null
    });

    test('EditorState.copyWith should preserve unchanged fields', () {
      const state = EditorState(
        isMarkdownView: true,
        hasUnsavedChanges: true,
        currentNoteId: 'test-id',
      );

      final updated = state.copyWith(isMarkdownView: false);

      expect(updated.isMarkdownView, isFalse);
      expect(updated.hasUnsavedChanges, isTrue); // Preserved
      expect(updated.currentNoteId, equals('test-id')); // Preserved
    });

    test('EditorState equality should work correctly', () {
      const state1 = EditorState(
        isMarkdownView: true,
        hasUnsavedChanges: false,
        currentNoteId: 'test-id',
      );
      const state2 = EditorState(
        isMarkdownView: true,
        hasUnsavedChanges: false,
        currentNoteId: 'test-id',
      );

      expect(state1, equals(state2));
      expect(state1.hashCode, equals(state2.hashCode));
    });

    test('EditorState equality should detect differences', () {
      const state1 = EditorState(isMarkdownView: true);
      const state2 = EditorState(isMarkdownView: false);

      expect(state1, isNot(equals(state2)));
    });
  });

  group('EditorStateNotifier Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('EditorStateNotifier should initialize with default state', () {
      final state = container.read(editorStateProvider);

      expect(state.isMarkdownView, isFalse);
      expect(state.hasUnsavedChanges, isFalse);
      expect(state.currentNoteId, isNull);
    });

    test('toggleView should switch between formatted and markdown view', () {
      final notifier = container.read(editorStateProvider.notifier);

      // Initially should be in formatted view (false)
      expect(container.read(editorStateProvider).isMarkdownView, isFalse);

      // Toggle to markdown view
      notifier.toggleView();
      expect(container.read(editorStateProvider).isMarkdownView, isTrue);

      // Toggle back to formatted view
      notifier.toggleView();
      expect(container.read(editorStateProvider).isMarkdownView, isFalse);
    });

    test('markAsModified should set hasUnsavedChanges to true', () {
      final notifier = container.read(editorStateProvider.notifier);

      expect(container.read(editorStateProvider).hasUnsavedChanges, isFalse);

      notifier.markAsModified();

      expect(container.read(editorStateProvider).hasUnsavedChanges, isTrue);
    });

    test('markAsModified should be idempotent', () {
      final notifier = container.read(editorStateProvider.notifier);

      notifier.markAsModified();
      expect(container.read(editorStateProvider).hasUnsavedChanges, isTrue);

      // Call again
      notifier.markAsModified();
      expect(container.read(editorStateProvider).hasUnsavedChanges, isTrue);
    });

    test('markAsSaved should set hasUnsavedChanges to false', () {
      final notifier = container.read(editorStateProvider.notifier);

      // First mark as modified
      notifier.markAsModified();
      expect(container.read(editorStateProvider).hasUnsavedChanges, isTrue);

      // Then mark as saved
      notifier.markAsSaved();
      expect(container.read(editorStateProvider).hasUnsavedChanges, isFalse);
    });

    test('markAsSaved should be idempotent', () {
      final notifier = container.read(editorStateProvider.notifier);

      notifier.markAsSaved();
      expect(container.read(editorStateProvider).hasUnsavedChanges, isFalse);

      // Call again
      notifier.markAsSaved();
      expect(container.read(editorStateProvider).hasUnsavedChanges, isFalse);
    });

    test('setCurrentNote should set note ID and clear unsaved changes', () {
      final notifier = container.read(editorStateProvider.notifier);

      // Mark as modified first
      notifier.markAsModified();
      expect(container.read(editorStateProvider).hasUnsavedChanges, isTrue);

      // Set current note
      notifier.setCurrentNote('test-note-id');

      final state = container.read(editorStateProvider);
      expect(state.currentNoteId, equals('test-note-id'));
      expect(state.hasUnsavedChanges, isFalse); // Should be cleared
    });

    test('reset should restore default state', () {
      final notifier = container.read(editorStateProvider.notifier);

      // Modify state
      notifier.toggleView();
      notifier.markAsModified();
      notifier.setCurrentNote('test-note-id');

      // Verify state is modified
      var state = container.read(editorStateProvider);
      expect(state.isMarkdownView, isTrue);
      expect(state.hasUnsavedChanges, isFalse); // setCurrentNote clears this
      expect(state.currentNoteId, equals('test-note-id'));

      // Reset
      notifier.reset();

      // Should be back to default
      state = container.read(editorStateProvider);
      expect(state.isMarkdownView, isFalse);
      expect(state.hasUnsavedChanges, isFalse);
      expect(state.currentNoteId, isNull);
    });

    test('state transitions should work correctly in sequence', () {
      final notifier = container.read(editorStateProvider.notifier);

      // Sequence: Set note -> Edit -> Toggle view -> Save
      notifier.setCurrentNote('note-1');
      expect(container.read(editorStateProvider).currentNoteId, equals('note-1'));
      expect(container.read(editorStateProvider).hasUnsavedChanges, isFalse);

      notifier.markAsModified();
      expect(container.read(editorStateProvider).hasUnsavedChanges, isTrue);

      notifier.toggleView();
      expect(container.read(editorStateProvider).isMarkdownView, isTrue);
      expect(container.read(editorStateProvider).hasUnsavedChanges, isTrue); // Still unsaved

      notifier.markAsSaved();
      expect(container.read(editorStateProvider).hasUnsavedChanges, isFalse);
      expect(container.read(editorStateProvider).isMarkdownView, isTrue); // View mode preserved
    });

    test('multiple containers should have independent state', () {
      final container1 = ProviderContainer();
      final container2 = ProviderContainer();

      final notifier1 = container1.read(editorStateProvider.notifier);
      final notifier2 = container2.read(editorStateProvider.notifier);

      // Modify state in container1
      notifier1.toggleView();
      notifier1.markAsModified();

      // container1 should be modified
      expect(container1.read(editorStateProvider).isMarkdownView, isTrue);
      expect(container1.read(editorStateProvider).hasUnsavedChanges, isTrue);

      // container2 should still be in default state
      expect(container2.read(editorStateProvider).isMarkdownView, isFalse);
      expect(container2.read(editorStateProvider).hasUnsavedChanges, isFalse);

      container1.dispose();
      container2.dispose();
    });
  });

  group('EditorStateProvider Integration Tests', () {
    test('editorStateProvider should be a StateNotifierProvider', () {
      final container = ProviderContainer();

      final provider = editorStateProvider;
      expect(provider, isA<StateNotifierProvider<EditorStateNotifier, EditorState>>());

      container.dispose();
    });

    test('editorStateProvider should provide fresh instance per container', () {
      final container1 = ProviderContainer();
      final container2 = ProviderContainer();

      final notifier1 = container1.read(editorStateProvider.notifier);
      final notifier2 = container2.read(editorStateProvider.notifier);

      expect(identical(notifier1, notifier2), isFalse);

      container1.dispose();
      container2.dispose();
    });
  });
}
