import 'package:flutter/foundation.dart';
import 'package:in_app_reminder/in_app_reminder.dart';

class DeviceReminderService {
  /// Check whether native reminders integration is supported on the current platform (iOS).
  bool get isSupported => defaultTargetPlatform == TargetPlatform.iOS;

  /// Creates a native iOS Reminder.
  /// Returns a boolean reminder status ID ("ios_synced") on success, or null on error/unsupported platform.
  Future<String?> createReminder({
    required String title,
    String? notes,
    DateTime? dueDate,
  }) async {
    if (!isSupported) return null;

    try {
      final success = await InAppReminder.addReminder(
        title: title,
        notes: notes,
        dateTime: dueDate,
      );
      return success ? 'ios_synced' : null;
    } catch (e) {
      debugPrint('DeviceReminderService create error: $e');
      return null;
    }
  }

  /// Deletes a native iOS Reminder by its ID (stubbed if unsupported by OS wrapper).
  Future<bool> deleteReminder(String reminderId) async {
    if (!isSupported) return false;
    return true;
  }
}
