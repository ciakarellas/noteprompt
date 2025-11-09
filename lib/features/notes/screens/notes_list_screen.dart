import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/empty_state.dart';
import '../models/note_model.dart';
import '../providers/notes_provider.dart';
import '../widgets/note_card.dart';
import 'note_editor_screen.dart';

/// Home screen displaying the list of all notes
class NotesListScreen extends ConsumerWidget {
  const NotesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Notes'),
        elevation: 0,
      ),
      body: notesAsync.when(
        data: (notes) {
          if (notes.isEmpty) {
            return const EmptyState();
          }

          // Sort notes by updatedAt (most recent first)
          final sortedNotes = List<Note>.from(notes)
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

          return ListView.builder(
            itemCount: sortedNotes.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              final note = sortedNotes[index];
              return NoteCard(
                note: note,
                onTap: () => _navigateToEditor(context, note.id),
                onDelete: () => _deleteNote(ref, note.id),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading notes',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNewNote(context, ref),
        tooltip: 'Create New Note',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Navigate to the editor screen for an existing note
  void _navigateToEditor(BuildContext context, String noteId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(noteId: noteId),
      ),
    );
  }

  /// Create a new note and navigate to editor
  Future<void> _createNewNote(BuildContext context, WidgetRef ref) async {
    try {
      final repository = ref.read(notesRepositoryProvider);
      final newNote = Note.create('');
      await repository.insertNote(newNote);

      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => NoteEditorScreen(noteId: newNote.id),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating note: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Delete a note with confirmation
  Future<void> _deleteNote(WidgetRef ref, String noteId) async {
    try {
      final repository = ref.read(notesRepositoryProvider);
      await repository.deleteNote(noteId);
    } catch (e) {
      // Error handling - could show a snackbar but we don't have context here
      debugPrint('Error deleting note: $e');
    }
  }
}
