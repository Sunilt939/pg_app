/// Formats dates and times according to UI Design System Section 9:
/// - Date: "12 Nov 2026"
/// - Short date (same year): "12 Nov"
/// - Month: "November 2026"
/// - Time: "3:42 pm" (12-hour, lower-case am or pm)
/// - Relative time: under 1 min "Just now", under 1 hour "{n} min ago",
///   under 24 hours "{n} h ago", yesterday "Yesterday", older: short date
/// - Dates from database are in UTC and converted to Indian Standard Time (IST, UTC+5:30).
abstract final class DateFormat {
  static const istOffset = Duration(hours: 5, minutes: 30);

  static const List<String> shortMonths = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static const List<String> fullMonths = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  /// Converts a UTC [dateTime] to Indian Standard Time (UTC+5:30).
  static DateTime toIst(DateTime dateTime) {
    if (dateTime.isUtc) {
      return dateTime.add(istOffset);
    }
    return dateTime;
  }

  /// Full date format: "12 Nov 2026"
  static String formatDate(DateTime date, {bool convertToIst = false}) {
    final d = convertToIst ? toIst(date) : date;
    final month = shortMonths[d.month - 1];
    return '${d.day} $month ${d.year}';
  }

  /// Short date format (for same year): "12 Nov"
  static String formatShortDate(DateTime date, {bool convertToIst = false}) {
    final d = convertToIst ? toIst(date) : date;
    final month = shortMonths[d.month - 1];
    return '${d.day} $month';
  }

  /// Full month and year format: "November 2026"
  static String formatMonthYear(DateTime date, {bool convertToIst = false}) {
    final d = convertToIst ? toIst(date) : date;
    final month = fullMonths[d.month - 1];
    return '$month ${d.year}';
  }

  /// 12-hour time format with lowercase am/pm: "3:42 pm"
  static String formatTime(DateTime date, {bool convertToIst = false}) {
    final d = convertToIst ? toIst(date) : date;
    final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minutePadded = d.minute.toString().padLeft(2, '0');
    final period = d.hour >= 12 ? 'pm' : 'am';
    return '$hour12:$minutePadded $period';
  }

  /// Relative time format:
  /// - under 1 min: "Just now"
  /// - under 1 hour: "{n} min ago"
  /// - under 24 hours: "{n} h ago"
  /// - yesterday: "Yesterday"
  /// - older: short date (e.g. "12 Nov")
  static String formatRelativeTime(
    DateTime dateTime, {
    DateTime? now,
    bool convertToIst = false,
  }) {
    final target = convertToIst ? toIst(dateTime) : dateTime;
    final current = now != null
        ? (convertToIst ? toIst(now) : now)
        : (convertToIst ? toIst(DateTime.now().toUtc()) : DateTime.now());

    final difference = current.difference(target);

    if (difference.isNegative || difference.inSeconds < 60) {
      return 'Just now';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours} h ago';
    }

    // Check if target was yesterday by calendar day
    final startOfCurrentDay = DateTime(current.year, current.month, current.day);
    final startOfTargetDay = DateTime(target.year, target.month, target.day);
    final daysDiff = startOfCurrentDay.difference(startOfTargetDay).inDays;

    if (daysDiff == 1) {
      return 'Yesterday';
    }

    if (target.year == current.year) {
      return formatShortDate(target);
    }
    return formatDate(target);
  }

  /// Formats room and bed string according to section 9:
  /// e.g. "Room 101, bed A" or "Bed A"
  static String formatBedAndRoom({String? room, required String bed}) {
    if (room != null && room.isNotEmpty) {
      return 'Room $room, bed $bed';
    }
    return 'Bed $bed';
  }
}

String formatDate(DateTime date, {bool convertToIst = false}) =>
    DateFormat.formatDate(date, convertToIst: convertToIst);

