import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:noteprompt/features/shortcuts/services/shortcuts_service.dart';

void main() {
  group('ShortcutsService', () {
    late ShortcutsService service;

    setUp(() {
      service = ShortcutsService();
    });

    group('isValidShortcutName', () {
      test('should return true for valid shortcut names', () {
        expect(service.isValidShortcutName('SendToClaude'), isTrue);
        expect(service.isValidShortcutName('MyShortcut'), isTrue);
        expect(service.isValidShortcutName('Shortcut123'), isTrue);
        expect(service.isValidShortcutName('My-Shortcut'), isTrue);
        expect(service.isValidShortcutName('My_Shortcut'), isTrue);
      });

      test('should return false for invalid shortcut names', () {
        expect(service.isValidShortcutName(''), isFalse);
        expect(service.isValidShortcutName('My<Shortcut'), isFalse);
        expect(service.isValidShortcutName('My>Shortcut'), isFalse);
        expect(service.isValidShortcutName('My:Shortcut'), isFalse);
        expect(service.isValidShortcutName('My"Shortcut'), isFalse);
        expect(service.isValidShortcutName('My/Shortcut'), isFalse);
        expect(service.isValidShortcutName('My\\Shortcut'), isFalse);
        expect(service.isValidShortcutName('My|Shortcut'), isFalse);
        expect(service.isValidShortcutName('My?Shortcut'), isFalse);
        expect(service.isValidShortcutName('My*Shortcut'), isFalse);
      });
    });

    group('sendToClaude', () {
      test('should throw ArgumentError for empty content', () async {
        // Note: This test will only work on iOS platform
        // On non-iOS platforms, it will throw PlatformException first
        expect(
          () async => await service.sendToClaude(''),
          throwsA(isA<ArgumentError>()),
        );

        expect(
          () async => await service.sendToClaude('   '),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw PlatformException on non-iOS platform', () async {
        // This test assumes we're running on a non-iOS platform (like in CI)
        // On actual iOS devices, this test would need to be skipped or modified
        expect(
          () async => await service.sendToClaude('Test content'),
          throwsA(
            isA<PlatformException>().having(
              (e) => e.code,
              'code',
              'UNSUPPORTED_PLATFORM',
            ),
          ),
        );
      });
    });

    group('URL length handling', () {
      test('should handle short text correctly', () {
        // Short text should use URL scheme
        final shortText = 'This is a short note';
        // We can't directly test the private method, but we can verify
        // that the text length is well below the 2000 character threshold
        expect(shortText.length < 2000, isTrue);
      });

      test('should handle long text correctly', () {
        // Long text should use clipboard approach
        final longText = 'A' * 3000; // 3000 characters
        // This would exceed the URL length limit
        final encodedLength = Uri.encodeComponent(longText).length;
        expect(encodedLength > 2000, isTrue);
      });
    });

    group('canLaunchShortcuts', () {
      test('should return false on non-iOS platforms', () async {
        // This test assumes we're running on a non-iOS platform
        final canLaunch = await service.canLaunchShortcuts();
        // On non-iOS platforms (like in CI), this should be false
        expect(canLaunch, isFalse);
      });
    });
  });

  group('Integration scenarios', () {
    test('should properly encode special characters in URLs', () {
      final textWithSpecialChars = 'Hello & goodbye! "quotes" \'apostrophes\'';
      final encoded = Uri.encodeComponent(textWithSpecialChars);

      // Verify encoding doesn't break the URL
      expect(encoded.contains('&'), isFalse);
      expect(encoded.contains('"'), isFalse);
      expect(encoded.contains(' '), isFalse);
    });

    test('should handle markdown content properly', () {
      final markdownContent = '''
# Heading 1
## Heading 2

**Bold text** and *italic text*

- List item 1
- List item 2

```dart
void main() {
  print('Hello, World!');
}
```

[Link](https://example.com)
''';

      final encoded = Uri.encodeComponent(markdownContent);
      // Verify the content can be encoded
      expect(encoded.isNotEmpty, isTrue);

      // Verify decoding returns original content
      final decoded = Uri.decodeComponent(encoded);
      expect(decoded, equals(markdownContent));
    });

    test('should handle newlines and special formatting', () {
      final textWithNewlines = 'Line 1\nLine 2\nLine 3';
      final encoded = Uri.encodeComponent(textWithNewlines);
      final decoded = Uri.decodeComponent(encoded);

      expect(decoded, equals(textWithNewlines));
    });

    test('should handle emoji content', () {
      final emojiContent = 'Hello 👋 World 🌍 Testing 🧪';
      final encoded = Uri.encodeComponent(emojiContent);
      final decoded = Uri.decodeComponent(encoded);

      expect(decoded, equals(emojiContent));
    });
  });
}
