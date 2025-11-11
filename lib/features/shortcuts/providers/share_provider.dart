import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/share_service.dart';

/// Provider for ShareService
/// Provides access to platform-specific sharing functionality
final shareServiceProvider = Provider<ShareService>((ref) {
  return ShareService();
});
