import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static String formatFull(DateTime date) {
    return DateFormat('dd MMMM yyyy, hh:mm a').format(date);
  }

  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      final count = difference.inMinutes;
      return '$count minute${count == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      final count = difference.inHours;
      return '$count hour${count == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      final count = difference.inDays;
      return '$count day${count == 1 ? '' : 's'} ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }
}
