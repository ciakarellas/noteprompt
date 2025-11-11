import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/shortcuts_service.dart';

/// Provider for ShortcutsService
/// Provides singleton instance of the shortcuts service for iOS integration
final shortcutsServiceProvider = Provider<ShortcutsService>((ref) {
  return ShortcutsService();
});
