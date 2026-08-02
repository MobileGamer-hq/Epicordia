import 'dart:convert';

class InAppAlarm {
  final String id;
  final String title;
  final int hour; // 0..23
  final int minute; // 0..59
  final List<int> repeatDays; // 1 = Mon, 7 = Sun. Empty = One-time alarm
  final bool isEnabled;
  final String? taskId;
  final String? ringtone;

  const InAppAlarm({
    required this.id,
    required this.title,
    required this.hour,
    required this.minute,
    this.repeatDays = const [],
    this.isEnabled = true,
    this.taskId,
    this.ringtone,
  });

  String get formattedTime {
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final m = minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    return '${h.toString().padLeft(2, '0')}:$m $period';
  }

  String get repeatDaysSummary {
    if (repeatDays.isEmpty) return 'Once';
    if (repeatDays.length == 7) return 'Everyday';
    if (repeatDays.length == 5 && repeatDays.every((d) => d >= 1 && d <= 5)) {
      return 'Weekdays';
    }
    if (repeatDays.length == 2 && repeatDays.contains(6) && repeatDays.contains(7)) {
      return 'Weekends';
    }
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return repeatDays.map((d) => days[d - 1]).join(', ');
  }

  /// Calculates duration remaining until next ring time
  Duration get timeUntilNextRing {
    final now = DateTime.now();
    DateTime target = DateTime(now.year, now.month, now.day, hour, minute);

    if (repeatDays.isEmpty) {
      if (target.isBefore(now)) {
        target = target.add(const Duration(days: 1));
      }
      return target.difference(now);
    }

    // Find next day in repeatDays
    int currentWeekday = now.weekday; // 1 = Mon, 7 = Sun
    for (int offset = 0; offset < 7; offset++) {
      int checkWeekday = ((currentWeekday - 1 + offset) % 7) + 1;
      if (repeatDays.contains(checkWeekday)) {
        DateTime checkTarget = DateTime(now.year, now.month, now.day, hour, minute)
            .add(Duration(days: offset));
        if (checkTarget.isAfter(now)) {
          return checkTarget.difference(now);
        }
      }
    }

    // Fallback tomorrow
    if (target.isBefore(now)) {
      target = target.add(const Duration(days: 1));
    }
    return target.difference(now);
  }

  InAppAlarm copyWith({
    String? id,
    String? title,
    int? hour,
    int? minute,
    List<int>? repeatDays,
    bool? isEnabled,
    String? taskId,
    String? ringtone,
  }) {
    return InAppAlarm(
      id: id ?? this.id,
      title: title ?? this.title,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      repeatDays: repeatDays ?? this.repeatDays,
      isEnabled: isEnabled ?? this.isEnabled,
      taskId: taskId ?? this.taskId,
      ringtone: ringtone ?? this.ringtone,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'hour': hour,
      'minute': minute,
      'repeatDays': repeatDays,
      'isEnabled': isEnabled,
      'taskId': taskId,
      'ringtone': ringtone,
    };
  }

  factory InAppAlarm.fromMap(Map<String, dynamic> map) {
    return InAppAlarm(
      id: map['id'] as String,
      title: map['title'] as String? ?? 'Alarm',
      hour: (map['hour'] as num).toInt(),
      minute: (map['minute'] as num).toInt(),
      repeatDays: List<int>.from(map['repeatDays'] ?? []),
      isEnabled: map['isEnabled'] as bool? ?? true,
      taskId: map['taskId'] as String?,
      ringtone: map['ringtone'] as String?,
    );
  }

  String toJson() => json.encode(toMap());
  factory InAppAlarm.fromJson(String source) =>
      InAppAlarm.fromMap(json.decode(source) as Map<String, dynamic>);
}
