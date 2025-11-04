import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

/// Utility class for formatting dates
class DateFormatter {
  // Private constructor to prevent instantiation
  DateFormatter._();

  /// Format date for display in note list (e.g., "Jan 15, 2024")
  static String formatForDisplay(DateTime date) {
    return DateFormat(AppConstants.dateFormatDisplay).format(date);
  }

  /// Format date with full details (e.g., "January 15, 2024 3:45 PM")
  static String formatFull(DateTime date) {
    return DateFormat(AppConstants.dateFormatFull).format(date);
  }

  /// Format relative time (e.g., "2 hours ago", "Yesterday")
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
      }
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return formatForDisplay(date);
    }
  }

  /// Format time only (e.g., "3:45 PM")
  static String formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }
}
