import 'package:intl/intl.dart';

class AppFormatters {
  static final _currencyFormat = NumberFormat.currency(
    symbol: '₹',
    decimalDigits: 2,
    locale: 'en_IN',
  );

  static final _dateFormat = DateFormat('dd MMM yyyy');
  static final _monthFormat = DateFormat('MMMM yyyy');
  static final _shortMonthFormat = DateFormat('MMM yyyy');

  /// Formats double amount to Indian Rupee currency string (e.g., ₹500.00)
  static String formatCurrency(double amount) {
    return _currencyFormat.format(amount);
  }

  /// Formats DateTime to readable string (e.g., 15 Jun 2026)
  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  /// Formats DateTime to full month and year (e.g., June 2026)
  static String formatMonth(DateTime date) {
    return _monthFormat.format(date);
  }

  /// Formats DateTime to short month and year (e.g., Jun 2026)
  static String formatShortMonth(DateTime date) {
    return _shortMonthFormat.format(date);
  }

  /// Returns a human-readable relative time string (e.g., "2 hours ago")
  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays >= 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays >= 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays >= 7) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else if (difference.inDays >= 1) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}
