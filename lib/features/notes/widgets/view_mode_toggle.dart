import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/editor_provider.dart';

/// View mode toggle button
/// Switches between formatted view (rendered markdown) and raw markdown view
class ViewModeToggle extends ConsumerWidget {
  const ViewModeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorStateProvider);
    final isMarkdownView = editorState.isMarkdownView;

    return IconButton(
      icon: Icon(
        isMarkdownView ? Icons.visibility : Icons.code,
        semanticLabel: isMarkdownView
            ? 'Switch to formatted view'
            : 'Switch to markdown view',
      ),
      tooltip: isMarkdownView ? 'Show formatted view' : 'Show raw markdown',
      onPressed: () {
        ref.read(editorStateProvider.notifier).toggleView();
      },
    );
  }
}
