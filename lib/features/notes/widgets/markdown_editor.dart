import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/editor_provider.dart';

// Track the last known cursor position for detecting double Enter
int _lastEnterPosition = -1;

/// Custom markdown editor widget
/// Supports dual-view mode: formatted view and raw markdown view
class MarkdownEditor extends ConsumerWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback? onChanged;

  const MarkdownEditor({
    super.key,
    required this.controller,
    required this.focusNode,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorStateProvider);
    final theme = Theme.of(context);

    return editorState.isMarkdownView
        ? _buildMarkdownView(context, theme)
        : _buildFormattedView(context, theme);
  }

  /// Build raw markdown view (editable TextField)
  Widget _buildMarkdownView(BuildContext context, ThemeData theme) {
    return Container(
      color: theme.colorScheme.surface,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.enter): () =>
              _handleEnterKey(),
        },
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontFamily: 'monospace',
            height: 1.5,
          ),
          decoration: InputDecoration(
            hintText: 'Type your markdown here...',
            hintStyle: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
              fontFamily: 'monospace',
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(16),
          ),
          onChanged: (_) => onChanged?.call(),
        ),
      ),
    );
  }

  /// Build formatted view (rendered markdown)
  /// Shows rendered markdown with editing via toolbar or tap to switch to raw mode
  Widget _buildFormattedView(BuildContext context, ThemeData theme) {
    final isEmpty = controller.text.isEmpty;

    // Always use the same widget structure to prevent focus loss
    return Container(
      color: theme.colorScheme.surface,
      child: Stack(
        children: [
          // Conditionally show either the empty state TextField or rendered markdown
          if (isEmpty)
            // Empty state: show editable TextField with hint
            CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.enter): () =>
                    _handleEnterKey(),
              },
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                decoration: InputDecoration(
                  hintText: 'Start typing your note...',
                  hintStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
                onChanged: (_) => onChanged?.call(),
              ),
            )
          else
            // Has content: show rendered markdown
            GestureDetector(
              onLongPress: () => _copyMarkdownToClipboard(context),
              child: Markdown(
                data: controller.text,
                selectable: true,
                padding: const EdgeInsets.all(16),
                styleSheet: _buildMarkdownStyleSheet(context),
                onTapLink: (text, url, title) => _handleLinkTap(context, url),
              ),
            ),

          // When not empty, keep a hidden TextField for toolbar editing
          // This maintains focus and allows toolbar operations
          if (!isEmpty)
            Positioned(
              left: -10000,
              top: -10000,
              child: SizedBox(
                width: 100,
                height: 100,
                child: CallbackShortcuts(
                  bindings: {
                    const SingleActivator(LogicalKeyboardKey.enter): () =>
                        _handleEnterKey(),
                  },
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    maxLines: null,
                    onChanged: (_) => onChanged?.call(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Handle Enter key press for list continuation
  void _handleEnterKey() {
    final text = controller.text;
    final selection = controller.selection;

    if (!selection.isValid || selection.start != selection.end) {
      // If there's a selection or invalid cursor, insert normal newline
      _insertNewline();
      return;
    }

    final cursorPosition = selection.start;

    // Find the current line
    final beforeCursor = text.substring(0, cursorPosition);
    final lineStart = beforeCursor.lastIndexOf('\n') + 1;
    final lineEndIndex = text.indexOf('\n', cursorPosition);
    final lineEnd = lineEndIndex == -1 ? text.length : lineEndIndex;
    final currentLine = text.substring(lineStart, lineEnd);
    final lineContent = text.substring(lineStart, cursorPosition);

    // Check for unordered list (bullet points)
    final bulletMatch = RegExp(r'^(\s*)-\s').firstMatch(currentLine);
    if (bulletMatch != null) {
      final indent = bulletMatch.group(1) ?? '';
      final prefix = '$indent- ';

      // Check if this is an empty list item (just the marker)
      if (currentLine.trim() == '-') {
        // Double enter - remove the bullet and exit list mode
        _removeCurrentLineMarkerAndExitList(lineStart, lineEnd, prefix.length);
      } else {
        // Continue the list
        _insertNewline(prefix: prefix);
      }
      return;
    }

    // Check for ordered list (numbered)
    final numberedMatch = RegExp(r'^(\s*)(\d+)\.\s').firstMatch(currentLine);
    if (numberedMatch != null) {
      final indent = numberedMatch.group(1) ?? '';
      final currentNumber = int.parse(numberedMatch.group(2)!);
      final nextNumber = currentNumber + 1;
      final prefix = '$indent$nextNumber. ';

      // Check if this is an empty list item (just the number)
      final numberPattern = RegExp(r'^\s*\d+\.\s*$');
      if (numberPattern.hasMatch(currentLine)) {
        // Double enter - remove the number and exit list mode
        final markerLength = numberedMatch.group(0)!.length;
        _removeCurrentLineMarkerAndExitList(lineStart, lineEnd, markerLength);
      } else {
        // Continue the list with next number
        _insertNewline(prefix: prefix);
      }
      return;
    }

    // No list detected, insert normal newline
    _insertNewline();
  }

  /// Insert a newline with optional prefix
  void _insertNewline({String prefix = ''}) {
    final text = controller.text;
    final selection = controller.selection;
    final cursorPosition = selection.start;

    final beforeCursor = text.substring(0, cursorPosition);
    final afterCursor = text.substring(cursorPosition);
    final newText = '$beforeCursor\n$prefix$afterCursor';
    final newCursorPosition = cursorPosition + 1 + prefix.length;

    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursorPosition),
    );

    onChanged?.call();
  }

  /// Remove the marker from the current line and exit list mode
  void _removeCurrentLineMarkerAndExitList(
      int lineStart, int lineEnd, int markerLength) {
    final text = controller.text;
    final beforeLine = text.substring(0, lineStart);
    final afterLine = text.substring(lineEnd);

    // Remove the current line entirely and add just a newline
    final newText = '$beforeLine\n$afterLine';
    final newCursorPosition = lineStart + 1;

    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursorPosition),
    );

    onChanged?.call();
  }

  /// Build custom markdown style sheet
  MarkdownStyleSheet _buildMarkdownStyleSheet(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return MarkdownStyleSheet(
      h1: textTheme.headlineLarge?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.bold,
      ),
      h2: textTheme.headlineMedium?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.bold,
      ),
      h3: textTheme.headlineSmall?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.bold,
      ),
      h4: textTheme.titleLarge?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.bold,
      ),
      h5: textTheme.titleMedium?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.bold,
      ),
      h6: textTheme.titleSmall?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.bold,
      ),
      p: textTheme.bodyLarge?.copyWith(
        color: colorScheme.onSurface,
        height: 1.5,
      ),
      code: textTheme.bodyMedium?.copyWith(
        backgroundColor: colorScheme.surfaceContainerHighest,
        fontFamily: 'monospace',
        color: colorScheme.onSurface,
      ),
      codeblockDecoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      blockquote: textTheme.bodyLarge?.copyWith(
        color: colorScheme.onSurface.withOpacity(0.7),
        fontStyle: FontStyle.italic,
      ),
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: colorScheme.primary,
            width: 4,
          ),
        ),
      ),
      listBullet: textTheme.bodyLarge?.copyWith(
        color: colorScheme.onSurface,
      ),
      a: textTheme.bodyLarge?.copyWith(
        color: colorScheme.primary,
        decoration: TextDecoration.underline,
      ),
      em: const TextStyle(fontStyle: FontStyle.italic),
      strong: const TextStyle(fontWeight: FontWeight.bold),
      del: const TextStyle(decoration: TextDecoration.lineThrough),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant,
            width: 2,
          ),
        ),
      ),
      img: textTheme.bodyLarge?.copyWith(
        color: colorScheme.primary,
      ),
    );
  }

  /// Copy raw markdown content to clipboard
  Future<void> _copyMarkdownToClipboard(BuildContext context) async {
    try {
      await Clipboard.setData(ClipboardData(text: controller.text));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Markdown copied to clipboard'),
            duration: const Duration(seconds: 2),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Failed to copy: $e');
      }
    }
  }

  /// Handle link taps - open URLs in browser
  Future<void> _handleLinkTap(BuildContext context, String? url) async {
    if (url == null || url.isEmpty) {
      return;
    }

    try {
      final uri = Uri.parse(url);

      // Check if URL can be launched
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (context.mounted) {
          _showError(context, 'Could not open link: $url');
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Error opening link: $e');
      }
    }
  }

  /// Show error message
  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
