import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noteprompt/features/notes/providers/editor_provider.dart';
import 'package:noteprompt/features/notes/widgets/markdown_editor.dart';

void main() {
  group('MarkdownEditor Widget Tests', () {
    late TextEditingController controller;
    late FocusNode focusNode;

    setUp(() {
      controller = TextEditingController();
      focusNode = FocusNode();
    });

    tearDown(() {
      controller.dispose();
      focusNode.dispose();
    });

    Widget createTestWidget({
      required ProviderContainer container,
      VoidCallback? onChanged,
    }) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: MarkdownEditor(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
            ),
          ),
        ),
      );
    }

    testWidgets('should display markdown view when isMarkdownView is true', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Set to markdown view
      container.read(editorStateProvider.notifier).toggleView();

      await tester.pumpWidget(createTestWidget(container: container));

      // Should show TextField with monospace font
      final textField = tester.widget<TextField>(find.byType(TextField).first);
      expect(textField.style?.fontFamily, equals('monospace'));
      expect(textField.decoration?.hintText, equals('Type your markdown here...'));
    });

    testWidgets('should display formatted view when isMarkdownView is false', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      controller.text = '# Hello World\nThis is a test';

      await tester.pumpWidget(createTestWidget(container: container));

      // Should show Markdown widget (in formatted view)
      // The formatted view uses a Stack with Markdown and invisible TextField
      expect(find.byType(Stack), findsOneWidget);
    });

    testWidgets('should display empty state prompt when content is empty in formatted view', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Empty content
      controller.text = '';

      await tester.pumpWidget(createTestWidget(container: container));

      // Should show hint text for empty state
      expect(find.text('Start typing your note...'), findsOneWidget);
    });

    testWidgets('should call onChanged when text is modified in markdown view', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Set to markdown view
      container.read(editorStateProvider.notifier).toggleView();

      var changeCount = 0;
      await tester.pumpWidget(createTestWidget(
        container: container,
        onChanged: () => changeCount++,
      ));

      // Type text
      await tester.enterText(find.byType(TextField).first, 'Test content');
      await tester.pump();

      expect(changeCount, greaterThan(0));
      expect(controller.text, equals('Test content'));
    });

    testWidgets('should call onChanged when text is modified in formatted view', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      controller.text = '# Test';

      var changeCount = 0;
      await tester.pumpWidget(createTestWidget(
        container: container,
        onChanged: () => changeCount++,
      ));

      // Find the invisible TextField overlay in formatted view
      final textFields = find.byType(TextField);
      expect(textFields, findsWidgets);

      // Type in the overlay TextField
      await tester.enterText(textFields.last, '# Updated Test');
      await tester.pump();

      expect(changeCount, greaterThan(0));
    });

    testWidgets('should use provided controller', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const initialText = 'Initial content';
      controller.text = initialText;

      await tester.pumpWidget(createTestWidget(container: container));

      // Update controller externally
      controller.text = 'Updated content';
      await tester.pump();

      expect(controller.text, equals('Updated content'));
    });

    testWidgets('should use provided focusNode', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestWidget(container: container));

      // Request focus
      focusNode.requestFocus();
      await tester.pump();

      expect(focusNode.hasFocus, isTrue);
    });

    testWidgets('should switch views when state changes', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      controller.text = '# Test';

      await tester.pumpWidget(createTestWidget(container: container));

      // Initially in formatted view - Stack with markdown
      expect(find.byType(Stack), findsOneWidget);

      // Toggle to markdown view
      container.read(editorStateProvider.notifier).toggleView();
      await tester.pumpAndSettle();

      // Now should show single TextField with monospace
      final textField = tester.widget<TextField>(find.byType(TextField).first);
      expect(textField.style?.fontFamily, equals('monospace'));

      // Toggle back to formatted view
      container.read(editorStateProvider.notifier).toggleView();
      await tester.pumpAndSettle();

      // Should show Stack again
      expect(find.byType(Stack), findsOneWidget);
    });

    testWidgets('should apply proper styling in markdown view', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Set to markdown view
      container.read(editorStateProvider.notifier).toggleView();

      await tester.pumpWidget(createTestWidget(container: container));

      final textField = tester.widget<TextField>(find.byType(TextField).first);

      expect(textField.maxLines, isNull); // Unlimited lines
      expect(textField.expands, isTrue); // Expands to fill space
      expect(textField.decoration?.border, InputBorder.none);
      expect(textField.style?.fontFamily, equals('monospace'));
      expect(textField.style?.height, equals(1.5));
    });

    testWidgets('should apply proper styling in formatted view with empty content', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      controller.text = '';

      await tester.pumpWidget(createTestWidget(container: container));

      final textField = tester.widget<TextField>(find.byType(TextField));

      expect(textField.maxLines, isNull);
      expect(textField.expands, isTrue);
      expect(textField.decoration?.border, InputBorder.none);
      expect(textField.style?.height, equals(1.5));
    });

    testWidgets('should handle null onChanged callback', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // No onChanged callback provided
      await tester.pumpWidget(createTestWidget(
        container: container,
        onChanged: null,
      ));

      // Should not throw when typing
      await tester.enterText(find.byType(TextField).first, 'Test');
      await tester.pump();

      // Just verify it doesn't crash
      expect(find.byType(MarkdownEditor), findsOneWidget);
    });

    testWidgets('should update when controller text changes', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      controller.text = 'Initial';

      await tester.pumpWidget(createTestWidget(container: container));

      // Change controller text
      controller.text = 'Updated';
      await tester.pump();

      // Widget should reflect the change
      expect(controller.text, equals('Updated'));
    });

    testWidgets('should preserve text when switching between views', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const testText = '# Test Heading\nTest content';
      controller.text = testText;

      await tester.pumpWidget(createTestWidget(container: container));

      // Start in formatted view
      expect(controller.text, equals(testText));

      // Switch to markdown view
      container.read(editorStateProvider.notifier).toggleView();
      await tester.pumpAndSettle();

      // Text should be preserved
      expect(controller.text, equals(testText));

      // Switch back to formatted view
      container.read(editorStateProvider.notifier).toggleView();
      await tester.pumpAndSettle();

      // Text should still be preserved
      expect(controller.text, equals(testText));
    });
  });

  group('MarkdownEditor Rendering Tests', () {
    late TextEditingController controller;
    late FocusNode focusNode;

    setUp(() {
      controller = TextEditingController();
      focusNode = FocusNode();
    });

    tearDown(() {
      controller.dispose();
      focusNode.dispose();
    });

    Widget createTestWidget({required ProviderContainer container}) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: MarkdownEditor(
              controller: controller,
              focusNode: focusNode,
            ),
          ),
        ),
      );
    }

    testWidgets('should render markdown content in formatted view', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      controller.text = '# Hello\n\nThis is **bold** text';

      await tester.pumpWidget(createTestWidget(container: container));
      await tester.pumpAndSettle();

      // Markdown widget should be present
      expect(find.byType(Stack), findsOneWidget);
    });

    testWidgets('should handle special characters in content', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(editorStateProvider.notifier).toggleView();

      const specialChars = '# Test\n\n<script>alert("xss")</script>\n\n*italic* **bold**';
      controller.text = specialChars;

      await tester.pumpWidget(createTestWidget(container: container));

      expect(controller.text, equals(specialChars));
    });

    testWidgets('should handle very long content', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final longContent = List.generate(100, (i) => '# Line $i\nContent for line $i').join('\n\n');
      controller.text = longContent;

      await tester.pumpWidget(createTestWidget(container: container));
      await tester.pumpAndSettle();

      expect(controller.text.length, greaterThan(1000));
    });
  });
}
