import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/note_model.dart';
import '../providers/editor_provider.dart';
import '../providers/notes_provider.dart';
import '../widgets/markdown_editor.dart';
import '../widgets/view_mode_toggle.dart';

/// Note Editor Screen
/// Provides a dual-mode markdown editor with auto-save functionality
class NoteEditorScreen extends ConsumerStatefulWidget {
  final String noteId;

  const NoteEditorScreen({
    super.key,
    required this.noteId,
  });

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  Timer? _debounceTimer;
  Note? _currentNote;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _lastSavedContent;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _loadNote();

    // Set current note ID in editor state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(editorStateProvider.notifier).setCurrentNote(widget.noteId);
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();

    // Reset editor state when leaving screen
    ref.read(editorStateProvider.notifier).reset();

    super.dispose();
  }

  /// Load note from database
  Future<void> _loadNote() async {
    try {
      final repository = ref.read(notesRepositoryProvider);
      final note = await repository.getNoteById(widget.noteId);

      if (note != null) {
        setState(() {
          _currentNote = note;
          _controller.text = note.content;
          _lastSavedContent = note.content;
          _isLoading = false;
        });
      } else {
        if (mounted) {
          _showError('Note not found');
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Error loading note: $e');
        Navigator.of(context).pop();
      }
    }
  }

  /// Handle text changes with debounced auto-save
  void _onTextChanged() {
    // Mark as modified
    ref.read(editorStateProvider.notifier).markAsModified();

    // Cancel previous timer
    _debounceTimer?.cancel();

    // Start new timer for auto-save (2 seconds after last keystroke)
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      _autoSave();
    });
  }

  /// Auto-save the note
  Future<void> _autoSave() async {
    final content = _controller.text;

    // Don't save if content hasn't changed
    if (content == _lastSavedContent) {
      return;
    }

    await _saveNote(showSnackbar: false);
  }

  /// Save the note to database
  Future<void> _saveNote({bool showSnackbar = true}) async {
    if (_currentNote == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final content = _controller.text;
      final updatedNote = _currentNote!.updateContent(content);

      final repository = ref.read(notesRepositoryProvider);
      await repository.updateNote(updatedNote);

      setState(() {
        _currentNote = updatedNote;
        _lastSavedContent = content;
        _isSaving = false;
      });

      // Mark as saved
      ref.read(editorStateProvider.notifier).markAsSaved();

      if (showSnackbar && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note saved'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        _showError('Error saving note: $e');
      }
    }
  }

  /// Handle back button press
  Future<bool> _onWillPop() async {
    final editorState = ref.read(editorStateProvider);

    // If no unsaved changes, allow back navigation
    if (!editorState.hasUnsavedChanges) {
      return true;
    }

    // Show confirmation dialog
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
          'You have unsaved changes. Do you want to save before leaving?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(true);
              // Don't save, just exit
            },
            child: const Text('Discard'),
          ),
          FilledButton(
            onPressed: () async {
              await _saveNote(showSnackbar: false);
              if (context.mounted) {
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  /// Show error message
  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(editorStateProvider);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Loading...'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return PopScope(
      canPop: !editorState.hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentNote?.title ?? 'Note',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (_isSaving)
                Text(
                  'Saving...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                )
              else if (editorState.hasUnsavedChanges)
                Text(
                  'Unsaved changes',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                )
              else
                Text(
                  'Saved',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                ),
            ],
          ),
          actions: [
            const ViewModeToggle(),
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Save note',
              onPressed: _isSaving ? null : () => _saveNote(),
            ),
          ],
        ),
        body: SafeArea(
          child: MarkdownEditor(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: _onTextChanged,
          ),
        ),
      ),
    );
  }
}
