import 'dart:io';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service for sharing note content to external apps
/// Handles platform-specific sharing behavior:
/// - iOS: URL scheme to trigger Shortcuts app
/// - Android: Standard share intent
class ShareService {
  /// Default iOS Shortcut name for Claude integration
  static const String defaultShortcutName = 'SendToClaude';

  /// Share note content
  ///
  /// On iOS: Attempts to send to Claude via Shortcuts app
  /// On Android: Uses standard share dialog
  ///
  /// Returns true if share was initiated successfully
  Future<bool> shareNote({
    required String content,
    String? title,
    String? shortcutName,
  }) async {
    if (Platform.isIOS) {
      return _shareToIOSShortcuts(
        content: content,
        shortcutName: shortcutName ?? defaultShortcutName,
      );
    } else if (Platform.isAndroid) {
      return _shareToAndroid(
        content: content,
        title: title,
      );
    } else {
      // Fallback for other platforms (desktop, web)
      return _shareToAndroid(
        content: content,
        title: title,
      );
    }
  }

  /// Share note content to Claude via iOS Shortcuts
  ///
  /// Uses URL scheme: shortcuts://run-shortcut?name=ShortcutName&input=text&text=content
  /// Note: URL schemes have length limitations (~2000 characters)
  /// For longer notes, falls back to clipboard + shortcut launch
  Future<bool> _shareToIOSShortcuts({
    required String content,
    required String shortcutName,
  }) async {
    try {
      // URL scheme has length limitations, check content size
      const maxUrlLength = 2000;
      final encodedText = Uri.encodeComponent(content);

      if (encodedText.length > maxUrlLength) {
        // For long notes, copy to clipboard and launch shortcut
        // The shortcut can be configured to read from clipboard
        await Clipboard.setData(ClipboardData(text: content));

        final shortcutUrl = 'shortcuts://run-shortcut?name=$shortcutName';
        final uri = Uri.parse(shortcutUrl);

        if (await canLaunchUrl(uri)) {
          return await launchUrl(uri);
        } else {
          throw PlatformException(
            code: 'SHORTCUT_NOT_AVAILABLE',
            message: 'Shortcuts app is not available or shortcut "$shortcutName" not found',
          );
        }
      } else {
        // For short notes, pass content directly via URL
        final shortcutUrl = 'shortcuts://run-shortcut?name=$shortcutName&input=text&text=$encodedText';
        final uri = Uri.parse(shortcutUrl);

        if (await canLaunchUrl(uri)) {
          return await launchUrl(uri);
        } else {
          throw PlatformException(
            code: 'SHORTCUT_NOT_AVAILABLE',
            message: 'Shortcuts app is not available or shortcut "$shortcutName" not found',
          );
        }
      }
    } on PlatformException {
      rethrow;
    } catch (e) {
      throw PlatformException(
        code: 'SHARE_FAILED',
        message: 'Failed to share to iOS Shortcuts: $e',
      );
    }
  }

  /// Share note content via Android share intent
  ///
  /// Opens the standard Android share dialog allowing user to choose
  /// any app that can receive text (Claude, email, messaging, etc.)
  Future<bool> _shareToAndroid({
    required String content,
    String? title,
  }) async {
    try {
      final result = await Share.share(
        content,
        subject: title ?? 'Note from NotePrompt',
      );

      // ShareResult status indicates if share was successful
      return result.status == ShareResultStatus.success ||
             result.status == ShareResultStatus.unavailable; // unavailable means user dismissed, which is ok
    } catch (e) {
      throw PlatformException(
        code: 'SHARE_FAILED',
        message: 'Failed to share on Android: $e',
      );
    }
  }

  /// Copy note content to clipboard
  ///
  /// Fallback option or explicit copy action
  Future<void> copyToClipboard(String content) async {
    await Clipboard.setData(ClipboardData(text: content));
  }

  /// Check if platform supports sharing
  bool get isSharingSupported {
    return Platform.isIOS || Platform.isAndroid;
  }

  /// Get platform-specific share button label
  String get shareButtonLabel {
    if (Platform.isIOS) {
      return 'Send to Claude';
    } else if (Platform.isAndroid) {
      return 'Share Note';
    } else {
      return 'Copy Note';
    }
  }

  /// Get platform-specific share button icon
  /// Returns icon name as string for use with Icons class
  String get shareButtonIcon {
    if (Platform.isIOS) {
      return 'shortcuts'; // Icons.shortcuts
    } else if (Platform.isAndroid) {
      return 'share'; // Icons.share
    } else {
      return 'copy'; // Icons.copy
    }
  }
}
