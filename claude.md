# NoteProm pt - Flutter Markdown Notes App

## Project Overview

**NoteProm pt** is a mobile note-taking application built with Flutter that allows users to create, edit, and manage text notes with full markdown support. The app features a dual-mode editor (formatted view and markdown syntax view) and integrates with iOS Shortcuts to send note content to the Claude AI app for processing.

**Current Status:** Phase 3 Complete (Notes List & Database)
**Next Phase:** Phase 4 - Note Editor Screen Implementation

---

## Core Features

### 1. Note Management ✅
- Create multiple text notes with unique UUIDs
- Store notes persistently on device using SQLite
- Edit existing notes
- View list of all saved notes (sorted by most recent)
- Each note supports markdown formatting
- Auto-save of note timestamps

### 2. Markdown Editor 🔄 (In Progress)
- **Dual-mode editor:** Toggle between formatted view and markdown syntax view
  - Formatted View (Default): Shows rendered markdown with visual formatting
  - Markdown View: Shows raw markdown syntax for manual editing
- Real-time rendering as user types
- Both views are fully editable
- Changes sync instantly between views
- Cursor position maintenance during view switches

### 3. Formatting Toolbar 📝 (Planned - Phase 4)
Available in formatted view to help users who don't know markdown syntax:
- **Bold button** (adds `**text**`)
- **Italic button** (adds `*text*` or `_text_`)
- **Header buttons** (adds `#`, `##`, `###`)
- **List buttons** (bulleted `-` and numbered `1.`)
- **Link insertion** (adds `[text](url)`)
- **Code block insertion** (adds ` ``` `)

### 4. Markdown Support ✅
The app renders and supports:
- **Bold text:** `**bold**` or `__bold__`
- **Italic text:** `*italic*` or `_italic_`
- **Headers:** `#` to `######`
- **Lists:** Unordered (`-`, `*`, `+`) and ordered (`1.`, `2.`)
- **Links:** `[text](url)`
- **Code blocks:** ` ``` ` for multi-line code
- **Blockquotes:** `> quoted text`

### 5. iOS Shortcuts Integration 🔗 (Planned - Phase 5)
- Button to trigger iOS Shortcut with current note content
- Pass note text as input parameter to Shortcut
- iOS URL scheme: `shortcuts://run-shortcut?name=[ShortcutName]&input=text`
- Alternative: Native Intents framework integration for better UX
- Android: Alternative using Share Intent (graceful degradation)

---

## Technical Architecture

### Tech Stack

**Framework & Language:**
- Flutter 3.9.2+
- Dart 3.0+

**State Management:**
- Riverpod 2.5.1 (reactive, compile-time safe)

**Database:**
- SQLite via sqflite 2.3.2
- Persistent local storage with efficient queries

**Markdown:**
- flutter_markdown 0.6.18 (rendering)
- markdown 7.1.1 (parsing)
- flutter_markdown_editor 0.1.6 (editor components)

**Platform Integration:**
- url_launcher 6.2.2 (iOS Shortcuts, links)

**Utilities:**
- intl 0.18.1 (date/time formatting)
- uuid 4.2.2 (unique identifiers)
- shared_preferences 2.2.2 (settings storage)

**Testing:**
- flutter_test (built-in)
- mockito 5.4.4 (mocking)
- build_runner 2.4.7 (code generation)

### Data Layer Architecture

#### Database Schema (SQLite)

```sql
CREATE TABLE notes (
  id TEXT PRIMARY KEY,
  title TEXT,
  content TEXT NOT NULL,
  created_at INTEGER,
  updated_at INTEGER
);

CREATE INDEX idx_notes_updated_at ON notes(updated_at DESC);
```

**Key Design Decisions:**
- TEXT primary key using UUID (platform-independent)
- Timestamps stored as INTEGER milliseconds since epoch
- Index on `updated_at` for efficient sorting/searching
- Auto-calculated title from first line of content

#### Note Model Structure

**File:** `lib/features/notes/models/note_model.dart`

```dart
class Note {
  final String id;                    // UUID
  final String title;                 // Auto-extracted from content
  final String content;               // Markdown text
  final DateTime createdAt;           // Creation timestamp
  final DateTime updatedAt;           // Last modified timestamp
}
```

**Key Methods:**
- `Note.create(String content)` - Factory constructor for new notes
- `Note.fromMap(Map<String, dynamic>)` - Deserialize from database
- `toMap()` - Serialize to database
- `updateContent(String newContent)` - Update with auto-title extraction
- `copyWith()` - Create immutable copy with field updates

#### Repository Pattern

**File:** `lib/features/notes/repositories/notes_repository.dart`

Implements CRUD operations with streaming support:
```dart
// Create
Future<void> insertNote(Note note)

// Read
Future<Note?> getNoteById(String id)
Future<List<Note>> getAllNotes()
Stream<List<Note>> watchAllNotes()  // Real-time updates

// Update
Future<void> updateNote(Note note)

// Delete
Future<void> deleteNote(String id)
Future<void> deleteAllNotes()

// Advanced
Future<List<Note>> searchNotes(String query)
Future<int> getNotesCount()
```

### UI Layer Architecture

#### Project Structure

```
lib/
├── main.dart                              # Entry point, Riverpod setup
├── core/
│   ├── database/
│   │   ├── database_helper.dart           # SQLite singleton
│   │   └── tables.dart                    # Schema definitions
│   ├── constants/
│   │   ├── app_constants.dart             # App configuration
│   │   └── markdown_constants.dart        # Markdown syntax templates
│   └── utils/
│       ├── date_formatter.dart            # Date formatting
│       └── markdown_utils.dart            # Markdown utilities
├── features/
│   └── notes/
│       ├── models/
│       │   └── note_model.dart            # Data model
│       ├── repositories/
│       │   └── notes_repository.dart      # Database operations
│       ├── providers/
│       │   └── notes_provider.dart        # Riverpod providers
│       ├── screens/
│       │   ├── notes_list_screen.dart     # Home screen ✅
│       │   └── note_editor_screen.dart    # Editor (Planned)
│       └── widgets/
│           ├── note_card.dart             # List item ✅
│           ├── markdown_toolbar.dart      # Formatting toolbar (Planned)
│           └── view_toggle.dart           # Mode switcher (Planned)
└── shared/
    ├── theme/
    │   └── app_theme.dart                 # Theme definitions
    └── widgets/
        └── empty_state.dart               # Empty state UI
```

#### Screen Flow

```
NotesListScreen (Home)
├── Empty State (no notes)
├── Notes List
│   ├── NoteCard
│   │   ├── Title
│   │   ├── Preview
│   │   ├── Last Modified Date
│   │   └── Delete Action
│   └── FAB (Create Note)
└── Note Editor (Navigation - Planned)
    ├── Markdown Toolbar (Planned)
    ├── View Toggle (Planned)
    ├── Editor (Dual-mode)
    │   ├── Formatted View
    │   └── Markdown View
    └── Send to Claude Button (Planned)
```

#### Current Screens

**NotesListScreen** (✅ Implemented)
- `lib/features/notes/screens/notes_list_screen.dart`
- Displays all notes sorted by modification date (newest first)
- Shows empty state when no notes exist
- FAB for creating new notes
- Swipe-to-delete with confirmation
- Error handling and loading states
- Real-time updates via Riverpod StreamProvider

**NoteEditorScreen** (🔄 Planned - Phase 4)
- Dual-mode editor (formatted/markdown)
- Markdown formatting toolbar
- View toggle with smooth transitions
- Auto-save functionality
- "Send to Claude" integration
- Back/Save navigation

#### State Management (Riverpod)

**File:** `lib/features/notes/providers/notes_provider.dart`

**Key Providers:**
```dart
// Database instance
final databaseProvider = Provider((ref) => DatabaseHelper.instance);

// Repository
final notesRepositoryProvider = Provider((ref) => NotesRepository(...));

// Notes list with real-time updates
final notesListProvider = StreamProvider((ref) => repo.watchAllNotes());

// Single note
final noteProvider = FutureProvider.family<Note?, String>((ref, id)
  => repo.getNoteById(id));

// Search functionality
final searchNotesProvider = FutureProvider.family<List<Note>, String>(
  (ref, query) => repo.searchNotes(query));

// Note count
final notesCountProvider = FutureProvider((ref) => repo.getNotesCount());
```

**Benefits:**
- Compile-time safety
- Automatic dependency tracking
- Built-in caching
- Easy testing with mocking
- Real-time data synchronization

### Theme System

**File:** `lib/shared/theme/app_theme.dart`

**Light Theme:**
- Material Design 3 with blue seed color
- Rounded cards (12px border radius)
- Light background with subtle shadows
- Blue-tinted accent colors

**Dark Theme:**
- Dark color scheme maintaining visual hierarchy
- High contrast for readability
- Dark-optimized markdown styles
- Proper OLED consideration

**Markdown Styling:**
- H1-H3 heading styles with appropriate sizes
- Code blocks with monospace font and background
- Blockquotes with left border accent
- Links with underline and custom color
- Lists with proper indentation

---

## Development Phases

### Phase 1: Database Layer ✅
**Completed:** Database setup, schema design, SQLite integration
- DatabaseHelper singleton
- Note model with serialization
- SQL table creation and indexing

### Phase 2: Repository & State Management ✅
**Completed:** CRUD operations, Riverpod providers, search functionality
- Full CRUD operations
- Stream-based real-time updates
- Search and filtering
- Repository pattern implementation

### Phase 3: Notes List Screen ✅
**Completed:** UI for displaying all notes, delete functionality
- NotesListScreen with Riverpod integration
- NoteCard widget with preview
- Empty state UI
- Swipe-to-delete with confirmation
- Error handling and loading states

### Phase 4: Note Editor Screen 🔄 (Current)
**Planned:** Editor screen, dual-mode editor, formatting toolbar
- NoteEditorScreen implementation
- Markdown editor with TextField
- View toggle between formatted/markdown
- Markdown formatting toolbar
  - Bold, italic, headers
  - Lists, links, code blocks
- Auto-save functionality
- Navigation integration

### Phase 5: iOS Shortcuts Integration 🔗
**Planned:** iOS Shortcuts support, Claude integration
- "Send to Claude" button
- URL scheme implementation
- Platform channels for native integration
- Android alternative (Share Intent)
- Error handling for missing Shortcut

### Phase 6+: Future Enhancements 📅
- Cloud synchronization
- Note categories/folders
- Advanced search with filters
- Export notes (PDF, HTML, Markdown)
- Dark mode toggle (manual override)
- Rich text editor with more formatting
- Image embedding in markdown
- Note sharing between users
- Collaborative editing
- Android Tasker integration

---

## Key Implementation Details

### Auto-Title Extraction

Notes can have optional titles auto-extracted from the first line of markdown:

```dart
// In NoteModel
String _extractTitle(String content) {
  if (content.isEmpty) return 'Untitled Note';

  final firstLine = content.split('\n').first;
  // Remove markdown syntax
  final cleanTitle = firstLine.replaceAll(RegExp(r'[#\-\*]'), '').trim();

  // Truncate to 50 characters
  return cleanTitle.length > 50
    ? '${cleanTitle.substring(0, 50)}...'
    : cleanTitle;
}
```

### Real-Time Updates

The app uses Riverpod's StreamProvider for real-time updates:

```dart
// Watch all notes in real-time
final notesListProvider = StreamProvider((ref) {
  final repository = ref.watch(notesRepositoryProvider);
  return repository.watchAllNotes();
});

// In UI
ref.watch(notesListProvider).when(
  data: (notes) => NotesListView(notes: notes),
  loading: () => LoadingWidget(),
  error: (err, stack) => ErrorWidget(),
);
```

### Markdown Rendering

Using flutter_markdown for rendering:

```dart
MarkdownBody(
  data: note.content,
  styleSheet: MarkdownStyleSheet(...),
  selectable: true,
)
```

### Database Lifecycle

```dart
// SQLite connection pooling and lifecycle management
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  // Singleton pattern
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  // Lazy initialization
  Future<Database> get database async {
    _database ??= await _initDb();
    return _database!;
  }

  // Proper cleanup
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
```

---

## Code Organization Principles

### Clean Architecture
- **Presentation Layer:** Screens and widgets
- **Domain Layer:** Business logic (repositories)
- **Data Layer:** Database and local storage

### Separation of Concerns
- Models handle data structure and serialization
- Repositories handle data access
- Providers handle state and reactivity
- Screens handle UI and user interaction
- Utilities handle reusable functions

### Immutability
- Note model is immutable using final fields
- copyWith() for creating modified copies
- Prevents unintended state mutations

### Testability
- Mockito support for testing providers
- Repository pattern enables easy mocking
- Riverpod's testing utilities
- Comprehensive test coverage (Phase 3+)

---

## Important Files & Locations

| Purpose | File Path |
|---------|-----------|
| App Entry Point | `lib/main.dart` |
| Database Helper | `lib/core/database/database_helper.dart` |
| Database Schema | `lib/core/database/tables.dart` |
| Note Model | `lib/features/notes/models/note_model.dart` |
| Repository | `lib/features/notes/repositories/notes_repository.dart` |
| Riverpod Providers | `lib/features/notes/providers/notes_provider.dart` |
| Notes List Screen | `lib/features/notes/screens/notes_list_screen.dart` |
| Note Card Widget | `lib/features/notes/widgets/note_card.dart` |
| Theme Configuration | `lib/shared/theme/app_theme.dart` |
| App Constants | `lib/core/constants/app_constants.dart` |
| Markdown Constants | `lib/core/constants/markdown_constants.dart` |
| Date Formatting | `lib/core/utils/date_formatter.dart` |
| Markdown Utilities | `lib/core/utils/markdown_utils.dart` |
| Empty State Widget | `lib/shared/widgets/empty_state.dart` |
| Project Config | `pubspec.yaml` |
| Development Plan | `plan.md` |

---

## Testing

### Test Infrastructure
- Unit tests with `flutter_test`
- Integration testing with `mockito`
- Database testing with in-memory SQLite
- Provider testing with Riverpod test utilities

### Test Files Location
- `test/core/database/` - Database tests
- `test/features/notes/models/` - Model tests
- `test/features/notes/repositories/` - Repository tests
- `test/features/notes/providers/` - Provider tests

### Running Tests
```bash
flutter test                    # Run all tests
flutter test --coverage        # Generate coverage report
flutter test test/features/... # Run specific test suite
```

---

## Performance Considerations

### Optimizations Implemented
- **Lazy Loading:** Riverpod caches provider values
- **Indexing:** Database has index on `updated_at` for sorting
- **Streaming:** Real-time updates without polling
- **Singleton Pattern:** Single database instance to avoid duplicates

### Future Optimizations (Planned)
- **Pagination:** For lists with many notes
- **Debouncing:** Auto-save to prevent excessive writes
- **Virtualization:** For long markdown documents
- **Memoization:** For expensive computations
- **Memory Management:** Proper cleanup of streams and listeners

---

## Platform-Specific Notes

### iOS (Primary Target)
- **Full Support:** iOS 12.0+
- **Notable Features:**
  - iOS Shortcuts integration
  - SF Symbols for icons
  - iOS Human Interface Guidelines compliance
  - Keyboard dismissal handling
- **File:** `ios/` directory with platform configuration

### Android (Secondary Target)
- **Support:** Android API 21+
- **Graceful Degradation:**
  - Hide "Send to Claude" button (or show alternative)
  - Option: Implement share intent as alternative
  - Consider Tasker integration for automation
- **File:** `android/` directory with platform configuration

### Web & Desktop
- Builds configured for web, macOS, Windows, Linux
- Note: iOS Shortcuts integration only works on iOS

---

## Getting Started

### Prerequisites
- Flutter 3.9.2 or higher
- Dart 3.0 or higher
- iOS deployment target: 12.0+
- Android minimum SDK: 21

### Installation & Running

```bash
# Get dependencies
flutter pub get

# Run on iOS simulator
flutter run -d <device-id>

# Run on specific device
flutter run -d <device-id>

# Build for release
flutter build ios
flutter build apk
```

### Project Configuration

**pubspec.yaml** contains all dependencies:
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.1
  sqflite: ^2.3.2
  flutter_markdown: ^0.6.18
  url_launcher: ^6.2.2
  intl: ^0.18.1
  uuid: ^4.2.2
  shared_preferences: ^2.2.2
```

---

## Development Workflow

### Adding a New Feature

1. **Model Layer:** Define data structure
2. **Database Layer:** Update schema if needed
3. **Repository Layer:** Add CRUD operations
4. **State Management:** Create Riverpod providers
5. **UI Layer:** Create screens and widgets
6. **Testing:** Write tests for each layer
7. **Integration:** Connect to existing features

### Code Style & Guidelines

- Follow Dart style guide
- Use meaningful variable names
- Keep functions small and focused
- Write comprehensive comments for complex logic
- Use type annotations everywhere
- Prefer immutable objects
- Follow repository pattern for data access

### Git Workflow

```bash
# Create feature branch
git checkout -b feature/your-feature

# Commit with meaningful messages
git commit -m "feat: add note editor screen"

# Push and create pull request
git push origin feature/your-feature
```

### Pre-commit Checks
- Run `flutter analyze` for lint issues
- Run `flutter test` to ensure tests pass
- Format code with `flutter format`
- Check for unused imports

---

## Troubleshooting

### Database Issues
- **Database locked:** Ensure single DatabaseHelper instance is used
- **Schema mismatch:** Clear app data and rebuild
- **Query errors:** Check SQL syntax in `tables.dart`

### State Management Issues
- **Provider not updating:** Check if watchAllNotes() is used instead of getAllNotes()
- **Memory leaks:** Ensure streams are properly disposed
- **Test failures:** Mock dependencies properly in tests

### UI Issues
- **Markdown not rendering:** Verify flutter_markdown is imported
- **Theme not applying:** Check AppTheme is set in MaterialApp
- **Navigation not working:** Ensure routes are properly configured

### Platform Issues
- **iOS Shortcuts not working:** Verify url_launcher is in pubspec.yaml
- **Android build fails:** Run `flutter clean` and rebuild
- **Web build issues:** Check web-specific platform setup

---

## Resources & References

### Documentation
- [Flutter Official Documentation](https://flutter.dev)
- [Riverpod Documentation](https://riverpod.dev)
- [SQLite Documentation](https://www.sqlite.org)
- [Markdown Syntax Guide](https://www.markdownguide.org)
- [Material Design 3](https://m3.material.io)

### Useful Packages
- [flutter_markdown](https://pub.dev/packages/flutter_markdown)
- [sqflite](https://pub.dev/packages/sqflite)
- [flutter_riverpod](https://pub.dev/packages/flutter_riverpod)
- [url_launcher](https://pub.dev/packages/url_launcher)

### Learning Resources
- Flutter State Management Best Practices
- Clean Architecture in Flutter
- Riverpod Advanced Patterns
- SQLite Best Practices

---

## Contributing

### Before Submitting PR
1. Ensure all tests pass: `flutter test`
2. Run analysis: `flutter analyze`
3. Format code: `flutter format lib/`
4. Update documentation if needed
5. Follow commit message conventions

### Code Review Checklist
- [ ] Code follows style guidelines
- [ ] Tests are included and passing
- [ ] Documentation is updated
- [ ] No hardcoded values
- [ ] Error handling is present
- [ ] Performance considered
- [ ] Platform-specific code is documented

---

## Project Statistics

- **Total Files:** 40+
- **Lines of Dart Code:** 2000+
- **Test Files:** 10+
- **Dependencies:** 15+
- **Supported Platforms:** iOS (primary), Android, Web, macOS, Windows, Linux
- **Minimum Flutter Version:** 3.9.2
- **Minimum Dart Version:** 3.0

---

## Contacts & Support

For questions or issues:
1. Check the `plan.md` for development roadmap
2. Review existing code in `lib/` for examples
3. Run tests to understand current state
4. Check Flutter/Riverpod documentation
5. Create issues in project repository

---

## Notes

This document describes the NoteProm pt Flutter application architecture and serves as a technical reference for all developers working on the project. It should be kept up-to-date as features are added or architectural decisions change.

**Last Updated:** 2024
**Version:** 1.0
**Phase:** Phase 3 Complete - Phase 4 (Note Editor) In Progress

---

*This project demonstrates best practices in Flutter development including clean architecture, state management with Riverpod, SQLite integration, and comprehensive testing.*
