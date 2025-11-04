import 'package:uuid/uuid.dart';
import '../../../core/database/tables.dart';

/// Note data model
/// Represents a markdown note with metadata
class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a new note with auto-generated ID and title extraction
  factory Note.create(String content) {
    final now = DateTime.now();
    final title = _extractTitle(content);

    return Note(
      id: const Uuid().v4(),
      title: title,
      content: content,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Extract title from the first line of content
  /// Removes markdown heading syntax and returns clean title
  static String _extractTitle(String content) {
    if (content.isEmpty) return 'Untitled Note';

    final firstLine = content.split('\n').first.trim();

    // Remove markdown heading syntax (# ## ### etc.)
    final cleanTitle = firstLine.replaceAll(RegExp(r'^#+\s*'), '');

    // If still empty or just whitespace, return default
    if (cleanTitle.isEmpty) return 'Untitled Note';

    // Truncate if too long (max 50 characters for display)
    if (cleanTitle.length > 50) {
      return '${cleanTitle.substring(0, 47)}...';
    }

    return cleanTitle;
  }

  /// Convert Note to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      Tables.columnId: id,
      Tables.columnTitle: title,
      Tables.columnContent: content,
      Tables.columnCreatedAt: createdAt.millisecondsSinceEpoch,
      Tables.columnUpdatedAt: updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Create Note from database Map
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map[Tables.columnId] as String,
      title: map[Tables.columnTitle] as String? ?? 'Untitled Note',
      content: map[Tables.columnContent] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map[Tables.columnCreatedAt] as int,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map[Tables.columnUpdatedAt] as int,
      ),
    );
  }

  /// Create a copy of this note with optional field updates
  Note copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Update note content and auto-extract new title
  Note updateContent(String newContent) {
    return copyWith(
      content: newContent,
      title: _extractTitle(newContent),
      updatedAt: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Note &&
        other.id == id &&
        other.title == title &&
        other.content == content &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        content.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }

  @override
  String toString() {
    return 'Note(id: $id, title: $title, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
