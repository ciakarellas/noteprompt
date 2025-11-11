import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/markdown_constants.dart';
import '../providers/editor_provider.dart';

/// Markdown formatting toolbar
/// Provides buttons for common markdown formatting operations
class MarkdownToolbar extends ConsumerWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback? onFormatApplied;

  const MarkdownToolbar({
    super.key,
    required this.controller,
    required this.focusNode,
    this.onFormatApplied,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorStateProvider);
    final theme = Theme.of(context);

    // Show toolbar only in formatted view
    // In markdown view, users can type the syntax directly
    if (editorState.isMarkdownView) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              _ToolbarButton(
                icon: Icons.format_bold,
                tooltip: 'Bold',
                onPressed: () => _applyFormat(
                  context,
                  prefix: MarkdownConstants.bold,
                  suffix: MarkdownConstants.bold,
                ),
              ),
              _ToolbarButton(
                icon: Icons.format_italic,
                tooltip: 'Italic',
                onPressed: () => _applyFormat(
                  context,
                  prefix: MarkdownConstants.italic,
                  suffix: MarkdownConstants.italic,
                ),
              ),
              _ToolbarButton(
                icon: Icons.strikethrough_s,
                tooltip: 'Strikethrough',
                onPressed: () => _applyFormat(
                  context,
                  prefix: MarkdownConstants.strikethrough,
                  suffix: MarkdownConstants.strikethrough,
                ),
              ),
              const SizedBox(width: 4),
              const _ToolbarDivider(),
              const SizedBox(width: 4),
              _ToolbarButton(
                icon: Icons.title,
                label: 'H1',
                tooltip: 'Heading 1',
                onPressed: () => _applyLineFormat(
                  context,
                  prefix: MarkdownConstants.h1,
                ),
              ),
              _ToolbarButton(
                icon: Icons.title,
                label: 'H2',
                tooltip: 'Heading 2',
                onPressed: () => _applyLineFormat(
                  context,
                  prefix: MarkdownConstants.h2,
                ),
              ),
              _ToolbarButton(
                icon: Icons.title,
                label: 'H3',
                tooltip: 'Heading 3',
                onPressed: () => _applyLineFormat(
                  context,
                  prefix: MarkdownConstants.h3,
                ),
              ),
              const SizedBox(width: 4),
              const _ToolbarDivider(),
              const SizedBox(width: 4),
              _ToolbarButton(
                icon: Icons.format_list_bulleted,
                tooltip: 'Unordered list',
                onPressed: () => _applyLineFormat(
                  context,
                  prefix: MarkdownConstants.unorderedList,
                ),
              ),
              _ToolbarButton(
                icon: Icons.format_list_numbered,
                tooltip: 'Ordered list',
                onPressed: () => _applyLineFormat(
                  context,
                  prefix: MarkdownConstants.orderedList,
                ),
              ),
              const SizedBox(width: 4),
              const _ToolbarDivider(),
              const SizedBox(width: 4),
              _ToolbarButton(
                icon: Icons.code,
                tooltip: 'Inline code',
                onPressed: () => _applyFormat(
                  context,
                  prefix: MarkdownConstants.inlineCode,
                  suffix: MarkdownConstants.inlineCode,
                ),
              ),
              _ToolbarButton(
                icon: Icons.code_outlined,
                tooltip: 'Code block',
                onPressed: () => _applyCodeBlock(context),
              ),
              _ToolbarButton(
                icon: Icons.format_quote,
                tooltip: 'Blockquote',
                onPressed: () => _applyLineFormat(
                  context,
                  prefix: MarkdownConstants.blockquote,
                ),
              ),
              const SizedBox(width: 4),
              const _ToolbarDivider(),
              const SizedBox(width: 4),
              _ToolbarButton(
                icon: Icons.link,
                tooltip: 'Insert link',
                onPressed: () => _showLinkDialog(context),
              ),
              _ToolbarButton(
                icon: Icons.horizontal_rule,
                tooltip: 'Horizontal rule',
                onPressed: () => _applyHorizontalRule(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Apply inline formatting (wraps selected text)
  void _applyFormat(
    BuildContext context, {
    required String prefix,
    required String suffix,
  }) {
    final text = controller.text;
    final selection = controller.selection;

    if (!selection.isValid) {
      return;
    }

    String newText;
    TextSelection newSelection;

    if (selection.start == selection.end) {
      // No selection - insert placeholder with formatting
      final placeholder = MarkdownConstants.placeholder;
      final beforeCursor = text.substring(0, selection.start);
      final afterCursor = text.substring(selection.start);
      newText = '$beforeCursor$prefix$placeholder$suffix$afterCursor';
      newSelection = TextSelection(
        baseOffset: selection.start + prefix.length,
        extentOffset: selection.start + prefix.length + placeholder.length,
      );
    } else {
      // Has selection - wrap it
      final selectedText = text.substring(selection.start, selection.end);
      final beforeSelection = text.substring(0, selection.start);
      final afterSelection = text.substring(selection.end);
      newText = '$beforeSelection$prefix$selectedText$suffix$afterSelection';
      newSelection = TextSelection(
        baseOffset: selection.start + prefix.length,
        extentOffset: selection.end + prefix.length,
      );
    }

    // Update controller
    controller.value = controller.value.copyWith(
      text: newText,
      selection: newSelection,
    );

    // Notify parent of change
    onFormatApplied?.call();

    // Return focus to editor
    focusNode.requestFocus();
  }

  /// Apply line-based formatting (adds prefix to current line)
  void _applyLineFormat(BuildContext context, {required String prefix}) {
    final text = controller.text;
    final selection = controller.selection;

    if (!selection.isValid) {
      return;
    }

    // Find the start of the current line
    final beforeCursor = text.substring(0, selection.start);
    final lineStart = beforeCursor.lastIndexOf('\n') + 1;

    // Check if the line already has the prefix
    final currentLine = text.substring(lineStart);
    final bool hasPrefix = currentLine.startsWith(prefix);

    String newText;
    TextSelection newSelection;

    if (hasPrefix) {
      // Remove the prefix
      final afterPrefix = text.substring(lineStart + prefix.length);
      final beforeLine = text.substring(0, lineStart);
      newText = '$beforeLine$afterPrefix';
      newSelection = TextSelection.collapsed(
        offset: selection.start - prefix.length,
      );
    } else {
      // Add the prefix
      final beforeLine = text.substring(0, lineStart);
      final afterLine = text.substring(lineStart);
      newText = '$beforeLine$prefix$afterLine';
      newSelection = TextSelection.collapsed(
        offset: selection.start + prefix.length,
      );
    }

    // Update controller
    controller.value = controller.value.copyWith(
      text: newText,
      selection: newSelection,
    );

    // Notify parent of change
    onFormatApplied?.call();

    // Return focus to editor
    focusNode.requestFocus();
  }

  /// Apply code block formatting
  void _applyCodeBlock(BuildContext context) {
    final text = controller.text;
    final selection = controller.selection;

    if (!selection.isValid) {
      return;
    }

    String newText;
    TextSelection newSelection;

    if (selection.start == selection.end) {
      // No selection - insert code block template
      final codeBlockTemplate =
          '\n${MarkdownConstants.codeBlock}\n${MarkdownConstants.placeholder}\n${MarkdownConstants.codeBlock}\n';
      final beforeCursor = text.substring(0, selection.start);
      final afterCursor = text.substring(selection.start);
      newText = '$beforeCursor$codeBlockTemplate$afterCursor';
      newSelection = TextSelection(
        baseOffset: selection.start + MarkdownConstants.codeBlock.length + 2,
        extentOffset: selection.start +
            MarkdownConstants.codeBlock.length +
            2 +
            MarkdownConstants.placeholder.length,
      );
    } else {
      // Has selection - wrap it in code block
      final selectedText = text.substring(selection.start, selection.end);
      final beforeSelection = text.substring(0, selection.start);
      final afterSelection = text.substring(selection.end);
      newText =
          '$beforeSelection\n${MarkdownConstants.codeBlock}\n$selectedText\n${MarkdownConstants.codeBlock}\n$afterSelection';
      newSelection = TextSelection(
        baseOffset: selection.start + MarkdownConstants.codeBlock.length + 2,
        extentOffset: selection.end + MarkdownConstants.codeBlock.length + 2,
      );
    }

    // Update controller
    controller.value = controller.value.copyWith(
      text: newText,
      selection: newSelection,
    );

    // Notify parent of change
    onFormatApplied?.call();

    // Return focus to editor
    focusNode.requestFocus();
  }

  /// Apply horizontal rule
  void _applyHorizontalRule(BuildContext context) {
    final text = controller.text;
    final selection = controller.selection;

    if (!selection.isValid) {
      return;
    }

    final horizontalRule = '\n${MarkdownConstants.horizontalRule}\n';
    final beforeCursor = text.substring(0, selection.start);
    final afterCursor = text.substring(selection.start);
    final newText = '$beforeCursor$horizontalRule$afterCursor';
    final newSelection = TextSelection.collapsed(
      offset: selection.start + horizontalRule.length,
    );

    // Update controller
    controller.value = controller.value.copyWith(
      text: newText,
      selection: newSelection,
    );

    // Notify parent of change
    onFormatApplied?.call();

    // Return focus to editor
    focusNode.requestFocus();
  }

  /// Show link insertion dialog
  Future<void> _showLinkDialog(BuildContext context) async {
    final textController = TextEditingController();
    final urlController = TextEditingController();

    // Get selected text if any
    final selection = controller.selection;
    if (selection.start != selection.end) {
      final selectedText =
          controller.text.substring(selection.start, selection.end);
      textController.text = selectedText;
    }

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _LinkDialog(
        textController: textController,
        urlController: urlController,
      ),
    );

    if (result != null) {
      final linkText = result['text'] ?? MarkdownConstants.linkTextPlaceholder;
      final linkUrl = result['url'] ?? MarkdownConstants.linkUrlPlaceholder;
      final linkMarkdown = '[$linkText]($linkUrl)';

      final text = controller.text;
      final currentSelection = controller.selection;

      // Replace selected text or insert at cursor
      final beforeSelection = text.substring(0, currentSelection.start);
      final afterSelection = text.substring(currentSelection.end);
      final newText = '$beforeSelection$linkMarkdown$afterSelection';
      final newSelection = TextSelection.collapsed(
        offset: currentSelection.start + linkMarkdown.length,
      );

      // Update controller
      controller.value = controller.value.copyWith(
        text: newText,
        selection: newSelection,
      );

      // Notify parent of change
      onFormatApplied?.call();

      // Return focus to editor
      focusNode.requestFocus();
    }
  }
}

/// Toolbar button widget
class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final String tooltip;
  final VoidCallback onPressed;

  const _ToolbarButton({
    required this.icon,
    this.label,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (label != null) {
      // Button with icon and label (for headers)
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: GestureDetector(
          onTap: onPressed,
          behavior: HitTestBehavior.opaque,
          child: Tooltip(
            message: tooltip,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: theme.colorScheme.onSurface,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    label!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Icon-only button
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: IconButton(
        icon: Icon(icon, size: 20),
        tooltip: tooltip,
        onPressed: onPressed,
        visualDensity: VisualDensity.compact,
        color: theme.colorScheme.onSurface,
      ),
    );
  }
}

/// Toolbar divider
class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}

/// Link insertion dialog
class _LinkDialog extends StatelessWidget {
  final TextEditingController textController;
  final TextEditingController urlController;

  const _LinkDialog({
    required this.textController,
    required this.urlController,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Insert Link'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: textController,
            decoration: const InputDecoration(
              labelText: 'Link Text',
              hintText: 'Enter link text',
              border: OutlineInputBorder(),
            ),
            autofocus: textController.text.isEmpty,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: urlController,
            decoration: const InputDecoration(
              labelText: 'URL',
              hintText: 'https://example.com',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
            autofocus: textController.text.isNotEmpty,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop({
              'text': textController.text,
              'url': urlController.text,
            });
          },
          child: const Text('Insert'),
        ),
      ],
    );
  }
}
