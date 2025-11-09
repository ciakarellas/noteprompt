# Markdown Notes App - Development Plan

## Project Overview

A Flutter mobile application for creating and managing markdown notes with dual-mode editing (formatted/raw markdown), formatting toolbar, and iOS Shortcuts integration for Claude AI.

**Target Platforms:** iOS (primary), Android (secondary)
**State Management:** Riverpod
**Database:** SQLite (sqflite)
**Primary Features:** Markdown editing, dual-view mode, formatting toolbar, iOS Shortcuts integration

---

## Technical Stack

### Core Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.5.1

  # Database
  sqflite: ^2.3.2
  path: ^1.8.3

  # Markdown
  flutter_markdown: ^0.6.18
  markdown: ^7.1.1

  # UI Components
  flutter_markdown_editor: ^0.1.6  # Optional: markdown toolbar helpers

  # Platform Integration
  url_launcher: ^6.2.2

  # Utilities
  intl: ^0.18.1
  uuid: ^4.2.2
  shared_preferences: ^2.2.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
  mockito: ^5.4.4
  build_runner: ^2.4.7
```

---

## Project Structure

```
lib/
├── main.dart                       # App entry point, Riverpod setup
├── core/
│   ├── database/
│   │   ├── database_helper.dart    # SQLite database initialization
│   │   └── tables.dart             # Table schemas
│   ├── constants/
│   │   ├── app_constants.dart      # App-wide constants
│   │   └── markdown_constants.dart # Markdown syntax templates
│   └── utils/
│       ├── date_formatter.dart     # Date formatting utilities
│       └── markdown_utils.dart     # Markdown helper functions
├── features/
│   ├── notes/
│   │   ├── models/
│   │   │   └── note_model.dart     # Note data model
│   │   ├── repositories/
│   │   │   └── notes_repository.dart # Database operations
│   │   ├── providers/
│   │   │   ├── notes_provider.dart   # Notes list provider
│   │   │   ├── note_detail_provider.dart # Single note provider
│   │   │   └── editor_provider.dart  # Editor state provider
│   │   ├── screens/
│   │   │   ├── notes_list_screen.dart  # Home screen
│   │   │   └── note_editor_screen.dart # Editor screen
│   │   └── widgets/
│   │       ├── note_card.dart         # Note list item
│   │       ├── markdown_toolbar.dart  # Formatting toolbar
│   │       ├── markdown_editor.dart   # Custom markdown editor
│   │       └── view_mode_toggle.dart  # View switcher
│   └── shortcuts/
│       ├── providers/
│       │   └── shortcuts_provider.dart
│       └── services/
│           └── shortcuts_service.dart  # iOS Shortcuts integration
└── shared/
    ├── theme/
    │   └── app_theme.dart          # App theming
    └── widgets/
        ├── custom_app_bar.dart     # Reusable app bar
        └── empty_state.dart        # Empty state widget
```

---

## Database Design

### Notes Table Schema

```sql
CREATE TABLE notes (
  id TEXT PRIMARY KEY,
  title TEXT,
  content TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
)
```

### Note Model

```dart
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

  // Auto-generate title from first line of content
  factory Note.create(String content) {
    final now = DateTime.now();
    final title = _extractTitle(content);

    return Note(
      id: Uuid().v4(),
      title: title,
      content: content,
      createdAt: now,
      updatedAt: now,
    );
  }

  static String _extractTitle(String content) {
    if (content.isEmpty) return 'Untitled Note';
    final firstLine = content.split('\n').first.trim();
    // Remove markdown heading syntax
    final cleanTitle = firstLine.replaceAll(RegExp(r'^#+\s*'), '');
    return cleanTitle.isEmpty ? 'Untitled Note' : cleanTitle;
  }

  // Conversion methods
  Map<String, dynamic> toMap();
  factory Note.fromMap(Map<String, dynamic> map);
  Note copyWith({...});
}
```

---

## State Management Architecture (Riverpod)

### Provider Structure

```dart
// 1. Database Provider (singleton)
final databaseProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

// 2. Notes Repository Provider
final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return NotesRepository(database);
});

// 3. Notes List Provider (StreamProvider for real-time updates)
final notesListProvider = StreamProvider<List<Note>>((ref) {
  final repository = ref.watch(notesRepositoryProvider);
  return repository.watchAllNotes();
});

// 4. Individual Note Provider (FutureProvider)
final noteProvider = FutureProvider.family<Note?, String>((ref, id) async {
  final repository = ref.watch(notesRepositoryProvider);
  return repository.getNoteById(id);
});

// 5. Editor State Provider (StateNotifier)
final editorStateProvider = StateNotifierProvider<EditorStateNotifier, EditorState>((ref) {
  return EditorStateNotifier();
});

class EditorState {
  final bool isMarkdownView;  // false = formatted, true = raw markdown
  final bool hasUnsavedChanges;
  final TextEditingController? controller;

  EditorState({
    this.isMarkdownView = false,
    this.hasUnsavedChanges = false,
    this.controller,
  });
}

class EditorStateNotifier extends StateNotifier<EditorState> {
  EditorStateNotifier() : super(EditorState());

  void toggleView() { /* ... */ }
  void markAsSaved() { /* ... */ }
  void markAsModified() { /* ... */ }
}

// 6. Shortcuts Provider (for iOS integration)
final shortcutsProvider = Provider<ShortcutsService>((ref) {
  return ShortcutsService();
});
```

---

## Development Phases

### Phase 1: Foundation Setup (Days 1-2)

**Goal:** Set up project structure and core infrastructure

#### Tasks:
- [x] Initialize Flutter project
- [ ] Add all required dependencies to `pubspec.yaml`
- [ ] Create folder structure as per project layout
- [ ] Set up Riverpod (wrap app with ProviderScope)
- [ ] Configure app theme (light/dark mode support)
- [ ] Set up platform-specific configurations (iOS/Android)

#### Deliverables:
- Project structure complete
- Dependencies installed and verified
- Basic app shell with theme

---

### Phase 2: Database Layer (Days 3-4)

**Goal:** Implement SQLite database and data models

#### Tasks:
- [ ] Create `DatabaseHelper` class with singleton pattern
- [ ] Define notes table schema and migration strategy
- [ ] Implement `Note` model with all conversion methods
- [ ] Create `NotesRepository` with CRUD operations:
  - `Future<List<Note>> getAllNotes()`
  - `Future<Note?> getNoteById(String id)`
  - `Future<String> insertNote(Note note)`
  - `Future<int> updateNote(Note note)`
  - `Future<int> deleteNote(String id)`
  - `Stream<List<Note>> watchAllNotes()` (for real-time updates)
- [ ] Write unit tests for database operations
- [ ] Test database migrations and data persistence

#### Deliverables:
- Working SQLite database
- Full CRUD functionality tested
- Repository pattern implemented

---

### Phase 3: Notes List Screen (Days 5-6)

**Goal:** Build the home screen showing all notes

#### Tasks:
- [x] Create `NotesListScreen` widget
- [x] Implement `NoteCard` widget to display:
  - Title (first line)
  - Content preview (first 2-3 lines)
  - Last modified date (formatted)
- [x] Connect to `notesListProvider` using Riverpod
- [x] Handle loading, error, and empty states
- [x] Add FloatingActionButton for "Create New Note"
- [x] Implement navigation to editor screen
- [x] Add swipe-to-delete functionality (dismissible)
- [x] Sort notes by `updatedAt` (most recent first)

#### UI Components:
```dart
class NotesListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesListProvider);

    return notesAsync.when(
      data: (notes) => notes.isEmpty
          ? EmptyStateWidget()
          : ListView.builder(...),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => ErrorWidget(error),
    );
  }
}
```

#### Deliverables:
- Functional notes list screen
- Create/delete notes working
- Navigation flow established

---

### Phase 4: Markdown Editor - Basic (Days 7-9)

**Goal:** Create a dual-mode markdown editor

#### Tasks:
- [x] Create `NoteEditorScreen` with AppBar actions
- [x] Implement `MarkdownEditor` widget with:
  - `TextField` for markdown view (raw text)
  - `Markdown` widget for formatted view (read-only initially)
  - `TextEditingController` management
- [x] Create `ViewModeToggle` button (Icon: eye/code)
- [x] Implement view switching logic:
  - Preserve cursor position when possible
  - Smooth transition between views
- [x] Add auto-save functionality (debounced after 2 seconds of inactivity)
- [x] Implement manual save button in AppBar
- [x] Handle back navigation with unsaved changes warning

#### View Mode Logic:
```dart
// In formatted view: Show rendered markdown
// In markdown view: Show raw text with TextField

Widget build() {
  return state.isMarkdownView
    ? TextField(
        controller: _controller,
        decoration: InputDecoration.collapsed(hintText: 'Type markdown...'),
        maxLines: null,
      )
    : Markdown(
        data: _controller.text,
        selectable: true,
        // Challenge: How to make this editable?
        // Solution: Overlay invisible TextField or handle gestures
      );
}
```

#### Deliverables:
- Dual-mode editor working
- View toggle functional
- Auto-save implemented

---

### Phase 5: Formatting Toolbar (Days 10-12) ✅

**Goal:** Add markdown formatting helpers for non-technical users

#### Tasks:
- [x] Create `MarkdownToolbar` widget with buttons:
  - Bold (`**text**`)
  - Italic (`*text*`)
  - Strikethrough (`~~text~~`)
  - Headers (H1, H2, H3)
  - Unordered list (`- item`)
  - Ordered list (`1. item`)
  - Link (`[text](url)`)
  - Code block (` ``` `)
  - Inline code (`` `code` ``)
  - Blockquote (`> quote`)
  - Horizontal rule (`---`)
- [x] Implement text selection wrapping logic:
  - Get current selection from TextEditingController
  - Wrap selected text with markdown syntax
  - Update cursor position after insertion
- [x] Show/hide toolbar based on view mode:
  - Always visible in formatted view
  - Hidden in markdown view
- [x] Add link dialog for URL input
- [x] Write comprehensive tests for toolbar functionality

#### Toolbar Button Logic:
```dart
void applyMarkdownFormat(String prefix, String suffix) {
  final text = controller.text;
  final selection = controller.selection;

  if (selection.start == selection.end) {
    // No selection: insert placeholder
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      '$prefix placeholder $suffix',
    );
    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection(
        baseOffset: selection.start + prefix.length,
        extentOffset: selection.start + prefix.length + 11, // 'placeholder' length
      ),
    );
  } else {
    // Wrap selected text
    final selectedText = text.substring(selection.start, selection.end);
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      '$prefix$selectedText$suffix',
    );
    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection(
        baseOffset: selection.start,
        extentOffset: selection.end + prefix.length + suffix.length,
      ),
    );
  }
}
```

#### Deliverables:
- Fully functional formatting toolbar
- All markdown features accessible via buttons
- Text selection and cursor management working

---

### Phase 6: Advanced Markdown Support (Days 13-14)

**Goal:** Ensure comprehensive markdown rendering

#### Tasks:
- [ ] Configure `flutter_markdown` package for full syntax support:
  - Bold, italic, strikethrough
  - Headers (H1-H6)
  - Unordered and ordered lists
  - Links (clickable)
  - Code blocks with syntax highlighting (optional)
  - Blockquotes
  - Horizontal rules
  - Images (optional - if supporting image links)
- [ ] Customize markdown styling to match app theme
- [ ] Test rendering of complex markdown documents
- [ ] Handle edge cases (empty content, very long notes)
- [ ] Implement markdown preview mode (optional - separate screen)

#### Custom Markdown Style:
```dart
MarkdownStyleSheet buildMarkdownStyle(BuildContext context) {
  final theme = Theme.of(context);
  return MarkdownStyleSheet(
    h1: theme.textTheme.headlineLarge,
    h2: theme.textTheme.headlineMedium,
    p: theme.textTheme.bodyLarge,
    code: theme.textTheme.bodyMedium?.copyWith(
      backgroundColor: theme.colorScheme.surfaceVariant,
      fontFamily: 'monospace',
    ),
    // ... more customization
  );
}
```

#### Deliverables:
- All markdown syntax rendering correctly
- Custom styling applied
- Edge cases handled

---

### Phase 7: iOS Shortcuts Integration (Days 15-16)

**Goal:** Enable sending note content to Claude via iOS Shortcuts

#### Tasks:
- [ ] Create `ShortcutsService` class
- [ ] Implement URL scheme approach:
  - `shortcuts://run-shortcut?name=SendToClaude&input=text`
  - URL encode note content
  - Handle long text (URL length limitations)
- [ ] Add "Send to Claude" button in editor AppBar
- [ ] Platform check: only show on iOS
- [ ] Handle errors (Shortcuts app not installed, shortcut not found)
- [ ] (Optional) Implement native iOS Intents for better UX:
  - Create iOS plugin wrapper
  - Use platform channels
  - Handle callback from Shortcuts

#### Basic Implementation:
```dart
class ShortcutsService {
  Future<bool> sendToClaude(String noteContent) async {
    if (!Platform.isIOS) {
      throw PlatformException(code: 'UNSUPPORTED_PLATFORM');
    }

    final encodedText = Uri.encodeComponent(noteContent);
    final shortcutUrl = 'shortcuts://run-shortcut?name=SendToClaude&input=text&text=$encodedText';

    if (await canLaunchUrl(Uri.parse(shortcutUrl))) {
      return await launchUrl(Uri.parse(shortcutUrl));
    }
    return false;
  }
}
```

#### Deliverables:
- iOS Shortcuts integration working
- "Send to Claude" button functional
- Error handling for edge cases

---

### Phase 8: Android Alternative (Day 17)

**Goal:** Provide Android users with similar functionality

#### Options:
1. **Share Intent:** Use standard Android share to send text to any app
2. **Hide feature:** Simply don't show "Send to Claude" on Android
3. **Custom URL scheme:** If Claude supports Android intents

#### Tasks:
- [ ] Implement Android share functionality using `share_plus` package
- [ ] Platform-specific button rendering
- [ ] Test on Android device/emulator

```dart
// Android alternative
void shareToAndroid(String content) {
  Share.share(content, subject: 'Note from Markdown Notes App');
}
```

#### Deliverables:
- Android users can share notes
- Platform-specific behavior implemented

---

### Phase 9: Polish & UX Improvements (Days 18-19)

**Goal:** Refine user experience and add finishing touches

#### Tasks:
- [ ] Implement search/filter in notes list (optional)
- [ ] Add note sorting options (date, title, custom order)
- [ ] Create settings screen:
  - Default view mode (formatted/markdown)
  - Auto-save interval
  - Theme preference (light/dark/system)
  - Shortcut name configuration
- [ ] Add confirmation dialogs:
  - Delete note confirmation
  - Discard unsaved changes warning
- [ ] Implement undo/redo in editor (optional)
- [ ] Add haptic feedback for button presses
- [ ] Improve empty states with helpful messages
- [ ] Add app icon and splash screen
- [ ] Implement note duplication feature
- [ ] Add note statistics (character/word count)

#### Deliverables:
- Polished, production-ready UI
- All UX improvements implemented
- App ready for testing

---

### Phase 10: Testing & Deployment (Days 20-21)

**Goal:** Ensure app quality and prepare for release

#### Tasks:
- [ ] Write unit tests:
  - Database operations (100% coverage)
  - Note model methods
  - Markdown utilities
  - Repository methods
- [ ] Write widget tests:
  - Note card rendering
  - Editor screen interactions
  - Toolbar button actions
- [ ] Write integration tests:
  - Full user flows (create → edit → save → delete)
  - View mode switching
  - iOS Shortcuts trigger
- [ ] Manual testing on physical devices:
  - iPhone (iOS 14+)
  - Android device (Android 10+)
- [ ] Performance testing:
  - Large notes (10,000+ characters)
  - Many notes (100+ notes)
  - Memory usage
- [ ] Fix bugs and issues found during testing
- [ ] Prepare for deployment:
  - Update app version
  - Generate app icons (iOS/Android)
  - Configure signing (iOS: certificates, Android: keystore)
  - Build release APK/IPA

#### Deliverables:
- Test coverage > 80%
- All critical bugs fixed
- Release builds ready

---

## Key Technical Challenges & Solutions

### Challenge 1: Editable Formatted Markdown View

**Problem:** `flutter_markdown` renders markdown as read-only widgets, but we need both formatted view and editing capability.

**Solution:**
- **Option A:** Use two separate widgets (TextField for markdown view, Markdown widget for formatted view) and sync content via TextEditingController
- **Option B:** Implement custom rich text editor using TextSpan with markdown styling
- **Option C:** Use package like `flutter_quill` with markdown conversion
- **Recommended:** Start with Option A for simplicity, evaluate Option B if UX is poor

### Challenge 2: Cursor Position on View Toggle

**Problem:** Switching between views loses cursor position.

**Solution:**
- Store cursor offset in editor state
- On view switch, restore cursor position in TextField
- For formatted view, scroll to approximate position (line-based calculation)

### Challenge 3: Auto-save Implementation

**Problem:** Need to save frequently but avoid excessive database writes.

**Solution:**
- Use debouncing (wait 2 seconds after last keystroke)
- Implement with `Timer` or `rxdart` debounce
- Show save indicator (e.g., "Saving...", "Saved")

```dart
Timer? _debounceTimer;

void onTextChanged(String text) {
  _debounceTimer?.cancel();
  _debounceTimer = Timer(Duration(seconds: 2), () {
    saveNote(text);
  });
}
```

### Challenge 4: Long Note Content in iOS Shortcuts

**Problem:** URL schemes have length limitations (~2000 characters).

**Solution:**
- For short notes: use URL scheme
- For long notes:
  - Option A: Copy to clipboard, launch Shortcuts (Shortcut reads from clipboard)
  - Option B: Use native iOS Intents framework (requires platform channel)
  - Option C: Save to shared container, pass file path

---

## Performance Considerations

### Database Optimization
- Use indexes on `updated_at` for fast sorting
- Implement pagination for notes list (if 100+ notes)
- Use transactions for batch operations

### UI Performance
- Use `ListView.builder` for lazy loading of notes
- Implement `AutomaticKeepAliveClientMixin` for editor state preservation
- Debounce markdown rendering on fast typing
- Use `const` constructors where possible

### Memory Management
- Dispose TextEditingControllers properly
- Cancel timers and streams in dispose methods
- Avoid keeping large strings in memory unnecessarily

---

## Testing Strategy

### Unit Tests
- Note model serialization/deserialization
- Database CRUD operations
- Markdown utility functions
- Title extraction logic

### Widget Tests
- Note card displays correct information
- Toolbar buttons apply correct markdown
- View toggle switches correctly
- Empty states show appropriately

### Integration Tests
- Complete user flow: Create → Edit → Save → View → Delete
- Auto-save functionality
- iOS Shortcuts integration
- Search and filter (if implemented)

### Manual Testing Checklist
- [ ] Create note with various markdown syntax
- [ ] Edit existing note
- [ ] Delete note with confirmation
- [ ] Toggle between formatted and markdown views
- [ ] Use all toolbar buttons
- [ ] Trigger iOS Shortcut
- [ ] Test on multiple devices and OS versions
- [ ] Test with empty content, very long content
- [ ] Test with poor network (if any network features)
- [ ] Test dark mode rendering

---

## Future Enhancements (Post-MVP)

### Phase 2 Features
- [ ] Note categories/tags
- [ ] Full-text search with highlighting
- [ ] Note export (PDF, plain text)
- [ ] Cloud sync (Firebase, iCloud)
- [ ] Markdown templates
- [ ] Image attachments
- [ ] Note sharing via link
- [ ] Collaboration features
- [ ] Voice-to-text integration
- [ ] Note locking/encryption
- [ ] Widget for home screen (quick note creation)
- [ ] Apple Watch companion app
- [ ] Siri Shortcuts integration

---

## Timeline Summary

| Phase | Duration | Deliverable |
|-------|----------|-------------|
| Foundation Setup | 2 days | Project structure, dependencies |
| Database Layer | 2 days | SQLite + Repository pattern |
| Notes List Screen | 2 days | Home screen with CRUD |
| Markdown Editor Basic | 3 days | Dual-mode editor |
| Formatting Toolbar | 3 days | UI controls for markdown |
| Advanced Markdown | 2 days | Full markdown support |
| iOS Shortcuts | 2 days | Claude integration |
| Android Alternative | 1 day | Share functionality |
| Polish & UX | 2 days | Refinements |
| Testing & Deployment | 2 days | Quality assurance |
| **TOTAL** | **21 days** | **Production-ready MVP** |

---

## Risk Assessment

### High Risk
- **iOS Shortcuts reliability:** URL schemes may not work as expected, shortcut may not exist on user device
  - *Mitigation:* Provide clear user instructions, handle errors gracefully
- **Editable formatted view UX:** Technical challenge to make formatted markdown editable
  - *Mitigation:* Start with separate views, gather user feedback

### Medium Risk
- **Performance with large notes:** Markdown rendering may lag on very long documents
  - *Mitigation:* Implement chunked rendering, add performance tests
- **Database migrations:** Future schema changes could break existing data
  - *Mitigation:* Implement proper migration strategy from start

### Low Risk
- **Platform differences:** iOS vs Android behavior discrepancies
  - *Mitigation:* Use platform checks, test on both platforms

---

## Success Metrics

### MVP Success Criteria
- [ ] Users can create, edit, and delete notes
- [ ] Markdown rendering works for all supported syntax
- [ ] Dual-mode editing is intuitive and smooth
- [ ] iOS Shortcuts integration functions reliably
- [ ] App performs well with 50+ notes
- [ ] No critical bugs or crashes
- [ ] App passes App Store review (iOS)

### Performance Targets
- App launch time: < 2 seconds
- Note open time: < 500ms
- View toggle delay: < 200ms
- Auto-save latency: < 100ms after debounce

---

## Getting Started

### Development Environment Setup

1. **Install Flutter SDK**
   ```bash
   flutter --version  # Verify Flutter 3.9.2+
   ```

2. **Clone and setup project**
   ```bash
   cd noteprompt
   flutter pub get
   flutter doctor  # Ensure all checks pass
   ```

3. **IDE Setup**
   - Install Dart and Flutter plugins
   - Enable Flutter formatting on save
   - Configure analysis_options.yaml for linting

4. **Run the app**
   ```bash
   flutter run -d ios  # For iOS simulator
   flutter run -d android  # For Android emulator
   ```

### First Steps

1. **Phase 1:** Update `pubspec.yaml` with all dependencies
2. **Phase 1:** Create folder structure
3. **Phase 1:** Set up Riverpod in `main.dart`
4. **Phase 2:** Implement database layer
5. Continue following phases in order...

---

## Resources

### Documentation
- [Flutter Documentation](https://flutter.dev/docs)
- [Riverpod Documentation](https://riverpod.dev/)
- [sqflite Package](https://pub.dev/packages/sqflite)
- [flutter_markdown Package](https://pub.dev/packages/flutter_markdown)
- [iOS Shortcuts URL Scheme](https://support.apple.com/guide/shortcuts/run-shortcuts-from-a-url-apd624386f42/ios)

### Design Inspiration
- Apple Notes app (iOS)
- Bear (markdown notes app)
- Notion (editor UX)
- iA Writer (distraction-free writing)

---

## Questions for Product Owner

Before starting development, clarify:

1. **iOS Shortcut Name:** What should the default shortcut name be? (Currently assuming "SendToClaude")
2. **Markdown Syntax:** Are there any specific markdown extensions needed? (e.g., tables, footnotes)
3. **Android Priority:** Is Android share functionality sufficient, or should we invest in deeper integration?
4. **Theme:** Should we support custom themes or just light/dark mode?
5. **Cloud Sync:** Any plans for cloud backup in near future? (Affects architecture decisions)
6. **Target iOS Version:** Minimum supported iOS version? (iOS 13+, 14+, 15+?)

---

## Conclusion

This plan provides a structured approach to building the Markdown Notes App over a 21-day development cycle. The phased approach allows for iterative development, testing, and refinement. By following this plan, we'll deliver a production-ready MVP that meets all core requirements while maintaining code quality and performance standards.

**Next Step:** Review this plan, get approval, and begin Phase 1 - Foundation Setup.
