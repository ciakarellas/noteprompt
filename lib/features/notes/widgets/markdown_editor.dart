import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/editor_provider.dart';

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
    );
  }

  /// Build formatted view (rendered markdown)
  /// Shows rendered markdown with editing via toolbar or tap to switch to raw mode
  Widget _buildFormattedView(BuildContext context, ThemeData theme) {
    // If content is empty, show the editable text field with a hint
    if (controller.text.isEmpty) {
      return Container(
        color: theme.colorScheme.surface,
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
      );
    }

    // For formatted view with content: show rendered markdown only
    // TextField is hidden but active for toolbar editing
    return Stack(
      children: [
        // Rendered markdown (visible) with long-press to copy raw markdown
        GestureDetector(
          onLongPress: () => _copyMarkdownToClipboard(context),
          child: Container(
            color: theme.colorScheme.surface,
            child: Markdown(
              data: controller.text,
              selectable: true,
              padding: const EdgeInsets.all(16),
              styleSheet: _buildMarkdownStyleSheet(context),
              onTapLink: (text, url, title) => _handleLinkTap(context, url),
            ),
          ),
        ),
        // Hidden TextField for toolbar editing
        // Positioned offscreen but still functional
        Positioned(
          left: -10000,
          top: -10000,
          child: SizedBox(
            width: 100,
            height: 100,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              maxLines: null,
              onChanged: (_) => onChanged?.call(),
            ),
          ),
        ),
      ],
    );
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
