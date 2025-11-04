/// Application-wide constants
class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  // App Information
  static const String appName = 'Markdown Notes';
  static const String appVersion = '0.1.0';

  // Database
  static const String databaseName = 'notes.db';
  static const int databaseVersion = 1;

  // Table Names
  static const String notesTable = 'notes';

  // Auto-save Configuration
  static const Duration autoSaveDuration = Duration(seconds: 2);

  // Editor Configuration
  static const int maxNoteLength = 100000; // 100k characters
  static const String defaultNoteTitle = 'Untitled Note';

  // Date Formats
  static const String dateFormatDisplay = 'MMM d, y';
  static const String dateFormatFull = 'MMMM d, y h:mm a';

  // iOS Shortcuts
  static const String defaultShortcutName = 'SendToClaude';
  static const int urlMaxLength = 2000; // URL scheme length limit

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double cardElevation = 2.0;
  static const double borderRadius = 12.0;

  // Preview Configuration
  static const int previewMaxLines = 3;
  static const int previewMaxLength = 200;
}
