import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Editor state model
/// Manages the state of the note editor including view mode and unsaved changes
class EditorState {
  final bool isMarkdownView; // false = formatted view, true = raw markdown view
  final bool hasUnsavedChanges;
  final String? currentNoteId;

  const EditorState({
    this.isMarkdownView = false,
    this.hasUnsavedChanges = false,
    this.currentNoteId,
  });

  EditorState copyWith({
    bool? isMarkdownView,
    bool? hasUnsavedChanges,
    String? currentNoteId,
  }) {
    return EditorState(
      isMarkdownView: isMarkdownView ?? this.isMarkdownView,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      currentNoteId: currentNoteId ?? this.currentNoteId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is EditorState &&
        other.isMarkdownView == isMarkdownView &&
        other.hasUnsavedChanges == hasUnsavedChanges &&
        other.currentNoteId == currentNoteId;
  }

  @override
  int get hashCode =>
      isMarkdownView.hashCode ^
      hasUnsavedChanges.hashCode ^
      currentNoteId.hashCode;
}

/// Editor state notifier
/// Manages editor state changes and provides methods to update state
class EditorStateNotifier extends StateNotifier<EditorState> {
  EditorStateNotifier() : super(const EditorState());

  /// Toggle between formatted and markdown view
  void toggleView() {
    state = state.copyWith(
      isMarkdownView: !state.isMarkdownView,
    );
  }

  /// Mark content as modified (unsaved changes)
  void markAsModified() {
    if (!state.hasUnsavedChanges) {
      state = state.copyWith(hasUnsavedChanges: true);
    }
  }

  /// Mark content as saved
  void markAsSaved() {
    if (state.hasUnsavedChanges) {
      state = state.copyWith(hasUnsavedChanges: false);
    }
  }

  /// Set the current note ID being edited
  void setCurrentNote(String noteId) {
    state = state.copyWith(
      currentNoteId: noteId,
      hasUnsavedChanges: false,
    );
  }

  /// Reset editor state (when leaving editor screen)
  void reset() {
    state = const EditorState();
  }
}

/// Editor State Provider
/// Provides access to editor state throughout the widget tree
final editorStateProvider =
    StateNotifierProvider<EditorStateNotifier, EditorState>((ref) {
  return EditorStateNotifier();
});
