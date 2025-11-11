import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service for iOS Shortcuts integration
/// Enables sending note content to Claude via iOS Shortcuts app
class ShortcutsService {
  // Maximum URL length for URL scheme approach (conservative estimate)
  static const int _maxUrlLength = 2000;

  // Default shortcut name
  static const String _defaultShortcutName = 'SendToClaude';

  /// Send note content to Claude via iOS Shortcuts
  ///
  /// For short text: uses URL scheme directly
  /// For long text: copies to clipboard and launches shortcut
  ///
  /// Returns true if successful, false otherwise
  Future<bool> sendToClaude(
    String noteContent, {
    String shortcutName = _defaultShortcutName,
  }) async {
    // Platform check
    if (!Platform.isIOS) {
      throw PlatformException(
        code: 'UNSUPPORTED_PLATFORM',
        message: 'iOS Shortcuts are only available on iOS devices',
      );
    }

    // Handle empty content
    if (noteContent.trim().isEmpty) {
      throw ArgumentError('Note content cannot be empty');
    }

    try {
      // Determine if we should use URL scheme or clipboard approach
      if (_shouldUseClipboard(noteContent, shortcutName)) {
        return await _sendViaClipboard(noteContent, shortcutName);
      } else {
        return await _sendViaUrlScheme(noteContent, shortcutName);
      }
    } catch (e) {
      debugPrint('Error sending to Claude: $e');
      rethrow;
    }
  }

  /// Check if content is too long for URL scheme
  bool _shouldUseClipboard(String content, String shortcutName) {
    final encodedText = Uri.encodeComponent(content);
    final shortcutUrl =
        'shortcuts://run-shortcut?name=$shortcutName&input=text&text=$encodedText';

    return shortcutUrl.length > _maxUrlLength;
  }

  /// Send content via URL scheme (for shorter text)
  Future<bool> _sendViaUrlScheme(String content, String shortcutName) async {
    final encodedText = Uri.encodeComponent(content);
    final shortcutUrl =
        'shortcuts://run-shortcut?name=$shortcutName&input=text&text=$encodedText';

    final uri = Uri.parse(shortcutUrl);

    // Check if URL can be launched
    if (await canLaunchUrl(uri)) {
      return await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      throw PlatformException(
        code: 'SHORTCUT_NOT_FOUND',
        message:
            'Could not launch shortcut "$shortcutName". Make sure the shortcut exists in the Shortcuts app.',
      );
    }
  }

  /// Send content via clipboard (for longer text)
  /// Copies content to clipboard then launches shortcut which reads from clipboard
  Future<bool> _sendViaClipboard(String content, String shortcutName) async {
    // Copy to clipboard
    await Clipboard.setData(ClipboardData(text: content));

    // Launch shortcut without text parameter
    // The shortcut should be configured to read from clipboard
    final shortcutUrl = 'shortcuts://run-shortcut?name=$shortcutName';
    final uri = Uri.parse(shortcutUrl);

    // Check if URL can be launched
    if (await canLaunchUrl(uri)) {
      return await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      throw PlatformException(
        code: 'SHORTCUT_NOT_FOUND',
        message:
            'Could not launch shortcut "$shortcutName". Make sure the shortcut exists in the Shortcuts app.',
      );
    }
  }

  /// Check if the Shortcuts app is available
  Future<bool> canLaunchShortcuts() async {
    if (!Platform.isIOS) {
      return false;
    }

    final uri = Uri.parse('shortcuts://');
    return await canLaunchUrl(uri);
  }

  /// Validate shortcut name (basic validation)
  bool isValidShortcutName(String name) {
    return name.isNotEmpty && !name.contains(RegExp(r'[<>:"/\\|?*]'));
  }
}
