class TaskDateFormatter {
  /// Formats a time to a 12-hour AM/PM string, e.g. "2:30 PM".
  static String formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute $ampm';
  }

  /// Formats a task's due date with accurate relative intervals.
  ///
  /// Examples:
  /// - Today: "Due: Today, 3:00 PM"
  /// - Tomorrow: "Due: Tomorrow, 10:00 AM"
  /// - 1 day ago: "Due: Yesterday"
  /// - 3 days ago: "Due: 3 days ago"
  /// - 8 days ago: "Due: More than a week ago"
  /// - 14 days ago: "Due: 2 weeks ago"
  /// - 35 days ago: "Due: Last month"
  /// - 90 days ago: "Due: 3 months ago"
  /// - 400 days ago: "Due: Last year"
  /// - 800 days ago: "Due: 2 years ago"
  static String formatDueDate(DateTime? date, {DateTime? customNow}) {
    if (date == null) return 'No due date';

    final now = customNow ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(date.year, date.month, date.day);

    final daysDiff = today.difference(targetDay).inDays;

    if (daysDiff == 0) {
      return 'Due: Today, ${formatTime(date)}';
    } else if (daysDiff == -1) {
      return 'Due: Tomorrow, ${formatTime(date)}';
    } else if (daysDiff > 0) {
      // Overdue (in the past)
      if (daysDiff == 1) {
        return 'Due: Yesterday';
      } else if (daysDiff <= 6) {
        return 'Due: $daysDiff days ago';
      } else if (daysDiff <= 13) {
        return 'Due: More than a week ago';
      } else if (daysDiff < 30) {
        final weeks = daysDiff ~/ 7;
        return 'Due: $weeks weeks ago';
      } else if (daysDiff < 365) {
        final months = ((now.year - date.year) * 12) + (now.month - date.month);
        final effectiveMonths = months > 0 ? months : (daysDiff ~/ 30);
        if (effectiveMonths <= 1) {
          return 'Due: Last month';
        } else {
          return 'Due: $effectiveMonths months ago';
        }
      } else {
        final years = now.year - date.year;
        final effectiveYears = years > 0 ? years : (daysDiff ~/ 365);
        if (effectiveYears <= 1) {
          return 'Due: Last year';
        } else {
          return 'Due: $effectiveYears years ago';
        }
      }
    } else {
      // Future dates
      if (date.year == now.year) {
        return 'Due: ${date.month}/${date.day}';
      } else {
        return 'Due: ${date.month}/${date.day}/${date.year}';
      }
    }
  }

  /// Determines if a task is overdue given its dueDate and status.
  static bool isOverdue(DateTime? date, String? status, {DateTime? customNow}) {
    if (date == null) return false;
    if (status?.toLowerCase() == 'done') return false;
    final now = customNow ?? DateTime.now();
    return date.isBefore(now);
  }
}
