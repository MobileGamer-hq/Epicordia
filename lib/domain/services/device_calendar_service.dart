import 'package:device_calendar_plus/device_calendar_plus.dart';
import 'package:flutter/foundation.dart';

class DeviceCalendarService {
  final DeviceCalendar _plugin;

  DeviceCalendarService({DeviceCalendar? plugin})
      : _plugin = plugin ?? DeviceCalendar();

  /// Check and request calendar permissions from the OS.
  Future<bool> requestPermissions() async {
    final status = await _plugin.hasPermissions();
    if (status == CalendarPermissionStatus.granted) {
      return true;
    }
    final newStatus = await _plugin.requestPermissions();
    return newStatus == CalendarPermissionStatus.granted;
  }

  /// Retrieve all available calendars on the user's device.
  Future<List<Calendar>> getWritableCalendars() async {
    final hasPerm = await requestPermissions();
    if (!hasPerm) return [];

    try {
      final calendars = await _plugin.listCalendars();
      return calendars.where((cal) => cal.readOnly != true).toList();
    } catch (e) {
      debugPrint('DeviceCalendarService list error: $e');
      return [];
    }
  }

  /// Create or update an event on the device calendar.
  /// Returns the device [eventId] if successful, or null on error.
  Future<String?> syncTaskToCalendar({
    required String calendarId,
    required String title,
    String? notes,
    required DateTime startDate,
    DateTime? endDate,
    String? existingEventId,
    String? rruleString,
  }) async {
    final hasPerm = await requestPermissions();
    if (!hasPerm) return null;

    final start = startDate;
    final end = endDate ?? startDate.add(const Duration(hours: 1));

    try {
      if (existingEventId != null && existingEventId.isNotEmpty) {
        await _plugin.updateEvent(
          instanceId: existingEventId,
          title: title,
          description: notes,
          startDate: start,
          endDate: end,
        );
        return existingEventId;
      } else {
        final eventId = await _plugin.createEvent(
          calendarId: calendarId,
          title: title,
          description: notes,
          startDate: start,
          endDate: end,
        );
        return eventId;
      }
    } catch (e) {
      debugPrint('DeviceCalendarService sync error: $e');
      return null;
    }
  }

  /// Delete an event from the device calendar by ID.
  Future<bool> deleteEvent(String calendarId, String eventId) async {
    final hasPerm = await requestPermissions();
    if (!hasPerm) return false;

    try {
      await _plugin.deleteEvent(eventId);
      return true;
    } catch (e) {
      debugPrint('DeviceCalendarService delete error: $e');
      return false;
    }
  }
}
