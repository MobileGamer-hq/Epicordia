import 'package:flutter/foundation.dart';
import 'package:in_app_reminder/in_app_reminder.dart';

class DeviceReminderService {
  final InAppReminder _plugin;

  DeviceReminderService({InAppReminder? plugin})
      : _plugin = plugin ?? InAppReminder();

  /// Check whether native reminders integration is supported on the current platform (iOS).
  bool get isSupported => defaultTargetPlatform == TargetPlatform.iOS;

  /// Creates a native iOS Reminder.
  /// Returns the created reminder ID string on success, or null on error/unsupported platform.
  Future<String?> createReminder({
    required String title,
    String? notes,
    DateTime? dueDate,
  }) async {
    if (!isSupported) return null;

    try {
      final reminderId = await _plugin.addReminder(
        title: title,
        notes: notes,
        dueDate: dueDate,
      );
      return reminderId;
    } catch (e) {
      debugPrint('DeviceReminderService create error: $e');
      return null;
    }
  }

  /// Deletes a native iOS Reminder by its ID.
  Future<bool> deleteReminder(String reminderId) async {
    if (!isSupported) return false;

    try {
      final success = await _plugin.deleteReminder(reminderId);
      return success ?? false;
    } catch (e) {
      debugPrint('DeviceReminderService delete error: $e');
      return false;
    }
  }
}
