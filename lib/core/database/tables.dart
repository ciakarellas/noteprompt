/// Database table schemas and constants
class Tables {
  // Table names
  static const String notes = 'notes';

  // Notes table columns
  static const String columnId = 'id';
  static const String columnTitle = 'title';
  static const String columnContent = 'content';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';

  // Create table SQL
  static const String createNotesTable = '''
    CREATE TABLE $notes (
      $columnId TEXT PRIMARY KEY,
      $columnTitle TEXT,
      $columnContent TEXT NOT NULL,
      $columnCreatedAt INTEGER NOT NULL,
      $columnUpdatedAt INTEGER NOT NULL
    )
  ''';

  // Create index for faster sorting by updated_at
  static const String createUpdatedAtIndex = '''
    CREATE INDEX idx_notes_updated_at ON $notes($columnUpdatedAt DESC)
  ''';
}
