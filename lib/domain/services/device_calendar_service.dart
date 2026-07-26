import 'package:device_calendar_plus/device_calendar_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;

class DeviceCalendarService {
  final DeviceCalendarPlugin _plugin;

  DeviceCalendarService({DeviceCalendarPlugin? plugin})
      : _plugin = plugin ?? DeviceCalendarPlugin();

  /// Check and request calendar permissions from the OS.
  Future<bool> requestPermissions() async {
    final permissionsGranted = await _plugin.hasPermissions();
    if (permissionsGranted.isSuccess && (permissionsGranted.data ?? false)) {
      return true;
    }
    final result = await _plugin.requestPermissions();
    return result.isSuccess && (result.data ?? false);
  }

  /// Retrieve all available calendars on the user's device.
  Future<List<Calendar>> getWritableCalendars() async {
    final hasPerm = await requestPermissions();
    if (!hasPerm) return [];

    final result = await _plugin.retrieveCalendars();
    if (result.isSuccess && result.data != null) {
      return result.data!.where((cal) => cal.isReadOnly != true).toList();
    }
    return [];
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

    final location = tz.getLocation('UTC');
    final startTz = tz.TZDateTime.from(startDate.toUtc(), location);
    final endTz = tz.TZDateTime.from(
      (endDate ?? startDate.add(const Duration(hours: 1))).toUtc(),
      location,
    );

    RecurrenceRule? recurrenceRule;
    if (rruleString != null && rruleString.isNotEmpty) {
      recurrenceRule = _parseRRule(rruleString);
    }

    final event = Event(
      calendarId,
      eventId: existingEventId,
      title: title,
      description: notes,
      start: startTz,
      end: endTz,
      recurrenceRule: recurrenceRule,
    );

    final result = await _plugin.createOrUpdateEvent(event);
    if (result != null && result.isSuccess) {
      return result.data;
    } else if (result != null && result.errors.isNotEmpty) {
      debugPrint('DeviceCalendarService sync error: ${result.errors.first.errorMessage}');
    }
    return null;
  }

  /// Delete an event from the device calendar by ID.
  Future<bool> deleteEvent(String calendarId, String eventId) async {
    final hasPerm = await requestPermissions();
    if (!hasPerm) return false;

    final result = await _plugin.deleteEvent(calendarId, eventId);
    return result.isSuccess && (result.data ?? false);
  }

  /// Simple parser converting basic RRULE strings (FREQ=DAILY, WEEKLY, MONTHLY)
  /// into device_calendar_plus RecurrenceRule objects.
  RecurrenceRule? _parseRRule(String rruleStr) {
    try {
      final upperStr = rruleStr.toUpperCase();
      RecurrenceFrequency freq = RecurrenceFrequency.Daily;
      if (upperStr.contains('FREQ=WEEKLY')) {
        freq = RecurrenceFrequency.Weekly;
      } else if (upperStr.contains('FREQ=MONTHLY')) {
        freq = RecurrenceFrequency.Monthly;
      } else if (upperStr.contains('FREQ=YEARLY')) {
        freq = RecurrenceFrequency.Yearly;
      }
      return RecurrenceRule(freq);
    } catch (e) {
      debugPrint('Error parsing RRULE: $e');
      return null;
    }
  }
}
