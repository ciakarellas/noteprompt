import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_helper.dart';
import '../models/note_model.dart';
import '../repositories/notes_repository.dart';

/// Database Provider (singleton)
final databaseProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

/// Notes Repository Provider
final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  final database = ref.watch(databaseProvider);
  final repository = NotesRepository(database);

  // Dispose the repository when provider is destroyed
  ref.onDispose(() {
    repository.dispose();
  });

  return repository;
});

/// Notes List Provider (StreamProvider for real-time updates)
/// Watches all notes and updates UI automatically when data changes
final notesListProvider = StreamProvider<List<Note>>((ref) {
  final repository = ref.watch(notesRepositoryProvider);
  return repository.watchAllNotes();
});

/// Individual Note Provider (FutureProvider with family modifier)
/// Fetches a single note by ID
final noteProvider = FutureProvider.family<Note?, String>((ref, id) async {
  final repository = ref.watch(notesRepositoryProvider);
  return repository.getNoteById(id);
});

/// Notes Count Provider
/// Provides the total count of notes
final notesCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(notesRepositoryProvider);
  return repository.getNotesCount();
});

/// Search Notes Provider (FutureProvider with family modifier)
/// Searches notes by query string
final searchNotesProvider = FutureProvider.family<List<Note>, String>((ref, query) async {
  final repository = ref.watch(notesRepositoryProvider);
  return repository.searchNotes(query);
});
