import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noteprompt/features/notes/providers/editor_provider.dart';
import 'package:noteprompt/features/notes/widgets/markdown_toolbar.dart';
import 'package:noteprompt/core/constants/markdown_constants.dart';

void main() {
  group('MarkdownToolbar', () {
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

    testWidgets('should not show toolbar in markdown view',
        (WidgetTester tester) async {
      // Set editor to markdown view
      final container = ProviderContainer(
        overrides: [
          editorStateProvider.overrideWith((ref) {
            final notifier = EditorStateNotifier();
            notifier.toggleView(); // Switch to markdown view
            return notifier;
          }),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: MarkdownToolbar(
                controller: controller,
                focusNode: focusNode,
              ),
            ),
          ),
        ),
      );

      // Toolbar should not be visible in markdown view
      expect(find.byType(MarkdownToolbar), findsOneWidget);
      expect(find.byIcon(Icons.format_bold), findsNothing);
    });

    testWidgets('should show toolbar in formatted view',
        (WidgetTester tester) async {
      final container = ProviderContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: MarkdownToolbar(
                controller: controller,
                focusNode: focusNode,
              ),
            ),
          ),
        ),
      );

      // Toolbar should be visible in formatted view
      expect(find.byIcon(Icons.format_bold), findsOneWidget);
      expect(find.byIcon(Icons.format_italic), findsOneWidget);
      expect(find.byIcon(Icons.strikethrough_s), findsOneWidget);
      expect(find.byIcon(Icons.format_list_bulleted), findsOneWidget);
      expect(find.byIcon(Icons.format_list_numbered), findsOneWidget);
      expect(find.byIcon(Icons.link), findsOneWidget);
      expect(find.byIcon(Icons.code), findsOneWidget);
    });

    testWidgets('bold button should wrap selected text with **',
        (WidgetTester tester) async {
      final container = ProviderContainer();
      controller.text = 'Hello world';
      controller.selection = const TextSelection(baseOffset: 0, extentOffset: 5);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: MarkdownToolbar(
                controller: controller,
                focusNode: focusNode,
              ),
            ),
          ),
        ),
      );

      // Tap bold button
      await tester.tap(find.byIcon(Icons.format_bold));
      await tester.pump();

      // Text should be wrapped with **
      expect(controller.text, equals('**Hello** world'));
      expect(controller.selection.start, equals(2));
      expect(controller.selection.end, equals(7));
    });

    testWidgets('bold button should insert placeholder when no selection',
        (WidgetTester tester) async {
      final container = ProviderContainer();
      controller.text = 'Hello world';
      controller.selection = const TextSelection.collapsed(offset: 6);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: MarkdownToolbar(
                controller: controller,
                focusNode: focusNode,
              ),
            ),
          ),
        ),
      );

      // Tap bold button
      await tester.tap(find.byIcon(Icons.format_bold));
      await tester.pump();

      // Placeholder should be inserted with **
      expect(controller.text, contains('**${MarkdownConstants.placeholder}**'));
    });

    testWidgets('italic button should wrap selected text with *',
        (WidgetTester tester) async {
      final container = ProviderContainer();
      controller.text = 'Hello world';
      controller.selection = const TextSelection(baseOffset: 6, extentOffset: 11);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: MarkdownToolbar(
                controller: controller,
                focusNode: focusNode,
              ),
            ),
          ),
        ),
      );

      // Tap italic button
      await tester.tap(find.byIcon(Icons.format_italic));
      await tester.pump();

      // Text should be wrapped with *
      expect(controller.text, equals('Hello *world*'));
    });

    testWidgets('H1 button should add # prefix to line',
        (WidgetTester tester) async {
      final container = ProviderContainer();
      controller.text = 'Hello world';
      controller.selection = const TextSelection.collapsed(offset: 3);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: MarkdownToolbar(
                controller: controller,
                focusNode: focusNode,
              ),
            ),
          ),
        ),
      );

      // Find and tap H1 button (looks for buttons with 'H1' label)
      final h1Button = find.widgetWithText(InkWell, 'H1');
      expect(h1Button, findsOneWidget);

      await tester.tap(h1Button);
      await tester.pump();

      // Line should start with #
      expect(controller.text, equals('# Hello world'));
    });

    testWidgets('H1 button should toggle prefix on/off',
        (WidgetTester tester) async {
      final container = ProviderContainer();
      controller.text = '# Hello world';
      controller.selection = const TextSelection.collapsed(offset: 5);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: MarkdownToolbar(
                controller: controller,
                focusNode: focusNode,
              ),
            ),
          ),
        ),
      );

      // Find and tap H1 button
      final h1Button = find.widgetWithText(InkWell, 'H1');
      await tester.tap(h1Button);
      await tester.pump();

      // Prefix should be removed
      expect(controller.text, equals('Hello world'));
    });

    testWidgets('unordered list button should add - prefix',
        (WidgetTester tester) async {
      final container = ProviderContainer();
      controller.text = 'Item 1';
      controller.selection = const TextSelection.collapsed(offset: 3);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: MarkdownToolbar(
                controller: controller,
                focusNode: focusNode,
              ),
            ),
          ),
        ),
      );

      // Tap unordered list button
      await tester.tap(find.byIcon(Icons.format_list_bulleted));
      await tester.pump();

      // Line should start with -
      expect(controller.text, equals('- Item 1'));
    });

    testWidgets('ordered list button should add 1. prefix',
        (WidgetTester tester) async {
      final container = ProviderContainer();
      controller.text = 'Item 1';
      controller.selection = const TextSelection.collapsed(offset: 3);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: MarkdownToolbar(
                controller: controller,
                focusNode: focusNode,
              ),
            ),
          ),
        ),
      );

      // Tap ordered list button
      await tester.tap(find.byIcon(Icons.format_list_numbered));
      await tester.pump();

      // Line should start with 1.
      expect(controller.text, equals('1. Item 1'));
    });

    testWidgets('code button should wrap text with backticks',
        (WidgetTester tester) async {
      final container = ProviderContainer();
      controller.text = 'var x = 10';
      controller.selection = const TextSelection(baseOffset: 0, extentOffset: 10);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: MarkdownToolbar(
                controller: controller,
                focusNode: focusNode,
              ),
            ),
          ),
        ),
      );

      // Tap inline code button
      await tester.tap(find.byIcon(Icons.code));
      await tester.pump();

      // Text should be wrapped with `
      expect(controller.text, equals('`var x = 10`'));
    });

    testWidgets('code block button should insert code block template',
        (WidgetTester tester) async {
      final container = ProviderContainer();
      controller.text = 'Some text';
      controller.selection = const TextSelection.collapsed(offset: 9);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: MarkdownToolbar(
                controller: controller,
                focusNode: focusNode,
              ),
            ),
          ),
        ),
      );

      // Tap code block button
      await tester.tap(find.byIcon(Icons.code_outlined));
      await tester.pump();

      // Should insert code block with placeholders
      expect(controller.text, contains('```'));
      expect(controller.text, contains(MarkdownConstants.placeholder));
    });

    testWidgets('link button should show dialog',
        (WidgetTester tester) async {
      final container = ProviderContainer();
      controller.text = 'Click here';
      controller.selection = const TextSelection(baseOffset: 6, extentOffset: 10);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: MarkdownToolbar(
                controller: controller,
                focusNode: focusNode,
              ),
            ),
          ),
        ),
      );

      // Tap link button
      await tester.tap(find.byIcon(Icons.link));
      await tester.pumpAndSettle();

      // Dialog should appear
      expect(find.text('Insert Link'), findsOneWidget);
      expect(find.text('Link Text'), findsOneWidget);
      expect(find.text('URL'), findsOneWidget);

      // Selected text should be pre-filled
      final linkTextField = find.widgetWithText(TextField, 'Link Text');
      expect(linkTextField, findsOneWidget);

      // Enter URL
      await tester.enterText(
        find.widgetWithText(TextField, 'URL'),
        'https://example.com',
      );

      // Tap insert
      await tester.tap(find.text('Insert'));
      await tester.pumpAndSettle();

      // Link should be inserted
      expect(controller.text, contains('[here](https://example.com)'));
    });

    testWidgets('horizontal rule button should insert ---',
        (WidgetTester tester) async {
      final container = ProviderContainer();
      controller.text = 'Some text';
      controller.selection = const TextSelection.collapsed(offset: 9);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: MarkdownToolbar(
                controller: controller,
                focusNode: focusNode,
              ),
            ),
          ),
        ),
      );

      // Tap horizontal rule button
      await tester.tap(find.byIcon(Icons.horizontal_rule));
      await tester.pump();

      // Should insert horizontal rule
      expect(controller.text, contains('---'));
    });

    testWidgets('onFormatApplied callback should be called',
        (WidgetTester tester) async {
      final container = ProviderContainer();
      controller.text = 'Hello';
      controller.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
      bool callbackCalled = false;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: MarkdownToolbar(
                controller: controller,
                focusNode: focusNode,
                onFormatApplied: () {
                  callbackCalled = true;
                },
              ),
            ),
          ),
        ),
      );

      // Tap bold button
      await tester.tap(find.byIcon(Icons.format_bold));
      await tester.pump();

      // Callback should be called
      expect(callbackCalled, isTrue);
    });

    testWidgets('blockquote button should add > prefix',
        (WidgetTester tester) async {
      final container = ProviderContainer();
      controller.text = 'A quote';
      controller.selection = const TextSelection.collapsed(offset: 3);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: MarkdownToolbar(
                controller: controller,
                focusNode: focusNode,
              ),
            ),
          ),
        ),
      );

      // Tap blockquote button
      await tester.tap(find.byIcon(Icons.format_quote));
      await tester.pump();

      // Line should start with >
      expect(controller.text, equals('> A quote'));
    });
  });
}
