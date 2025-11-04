import '../constants/app_constants.dart';
import '../constants/markdown_constants.dart';

/// Utility class for markdown operations
class MarkdownUtils {
  // Private constructor to prevent instantiation
  MarkdownUtils._();

  /// Extract title from content (first line, cleaned of markdown syntax)
  static String extractTitle(String content) {
    if (content.isEmpty) return AppConstants.defaultNoteTitle;

    final firstLine = content.split('\n').first.trim();

    // Remove markdown heading syntax (# ## ### etc.)
    final cleanTitle = firstLine.replaceAll(RegExp(r'^#+\s*'), '');

    // Remove other markdown syntax
    final title = cleanTitle
        .replaceAll(MarkdownConstants.bold, '')
        .replaceAll(MarkdownConstants.italic, '')
        .replaceAll(MarkdownConstants.strikethrough, '')
        .replaceAll(MarkdownConstants.inlineCode, '')
        .trim();

    return title.isEmpty ? AppConstants.defaultNoteTitle : title;
  }

  /// Generate preview text from content
  static String generatePreview(String content) {
    if (content.isEmpty) return '';

    // Remove markdown syntax
    String preview = content
        .replaceAll(RegExp(r'^#+\s*', multiLine: true), '') // Headers
        .replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1') // Bold
        .replaceAll(RegExp(r'\*(.+?)\*'), r'$1') // Italic
        .replaceAll(RegExp(r'~~(.+?)~~'), r'$1') // Strikethrough
        .replaceAll(RegExp(r'`(.+?)`'), r'$1') // Inline code
        .replaceAll(RegExp(r'```[\s\S]*?```'), '') // Code blocks
        .replaceAll(RegExp(r'\[(.+?)\]\(.+?\)'), r'$1') // Links
        .replaceAll(RegExp(r'!\[.+?\]\(.+?\)'), '') // Images
        .replaceAll(RegExp(r'^[-*+]\s+', multiLine: true), '') // Unordered lists
        .replaceAll(RegExp(r'^\d+\.\s+', multiLine: true), '') // Ordered lists
        .replaceAll(RegExp(r'^>\s+', multiLine: true), '') // Blockquotes
        .replaceAll(RegExp(r'^---+$', multiLine: true), '') // Horizontal rules
        .trim();

    // Replace multiple newlines with single space
    preview = preview.replaceAll(RegExp(r'\n+'), ' ').trim();

    // Truncate if too long
    if (preview.length > AppConstants.previewMaxLength) {
      preview = '${preview.substring(0, AppConstants.previewMaxLength)}...';
    }

    return preview;
  }

  /// Count words in text
  static int countWords(String text) {
    if (text.isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  /// Count characters in text
  static int countCharacters(String text) {
    return text.length;
  }

  /// Wrap selected text with markdown syntax
  static TextSelection wrapText({
    required String text,
    required TextSelection selection,
    required String prefix,
    String? suffix,
  }) {
    final actualSuffix = suffix ?? prefix;

    if (selection.start == selection.end) {
      // No selection - insert placeholder
      final placeholder = MarkdownConstants.placeholder;
      final beforeCursor = text.substring(0, selection.start);
      final afterCursor = text.substring(selection.start);
      final newText = '$beforeCursor$prefix$placeholder$actualSuffix$afterCursor';

      return TextSelection(
        baseOffset: selection.start + prefix.length,
        extentOffset: selection.start + prefix.length + placeholder.length,
      );
    } else {
      // Has selection - wrap it
      return TextSelection(
        baseOffset: selection.start + prefix.length,
        extentOffset: selection.end + prefix.length,
      );
    }
  }

  /// Check if text contains unsaved markdown
  static bool hasContent(String text) {
    return text.trim().isNotEmpty;
  }
}
