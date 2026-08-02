import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/database/database.dart';
import '../../data/providers.dart';
import '../services/notification_service.dart';

class JournalingPlanState {
  final bool isEnabled;
  final String frequency; // 'daily', 'fiveDays', 'threeDays', 'custom'
  final List<int> daysOfWeek; // 1=Mon ... 7=Sun
  final int reminderHour;
  final int reminderMinute;
  final int currentStreak;
  final int longestStreak;
  final bool hasJournaledToday;

  const JournalingPlanState({
    required this.isEnabled,
    required this.frequency,
    required this.daysOfWeek,
    required this.reminderHour,
    required this.reminderMinute,
    required this.currentStreak,
    required this.longestStreak,
    required this.hasJournaledToday,
  });

  int get targetDaysCount {
    if (frequency == 'daily') return 7;
    if (frequency == 'fiveDays') return 5;
    if (frequency == 'threeDays') return 3;
    return daysOfWeek.length;
  }

  String get formattedTime {
    final h = reminderHour % 12 == 0 ? 12 : reminderHour % 12;
    final m = reminderMinute.toString().padLeft(2, '0');
    final ampm = reminderHour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  JournalingPlanState copyWith({
    bool? isEnabled,
    String? frequency,
    List<int>? daysOfWeek,
    int? reminderHour,
    int? reminderMinute,
    int? currentStreak,
    int? longestStreak,
    bool? hasJournaledToday,
  }) {
    return JournalingPlanState(
      isEnabled: isEnabled ?? this.isEnabled,
      frequency: frequency ?? this.frequency,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      hasJournaledToday: hasJournaledToday ?? this.hasJournaledToday,
    );
  }
}

class JournalingPlanNotifier extends Notifier<JournalingPlanState> {
  static const _keyEnabled = 'journaling_plan_enabled';
  static const _keyFrequency = 'journaling_plan_frequency';
  static const _keyDaysOfWeek = 'journaling_plan_days_of_week';
  static const _keyReminderHour = 'journaling_plan_reminder_hour';
  static const _keyReminderMinute = 'journaling_plan_reminder_minute';

  @override
  JournalingPlanState build() {
    _loadState();
    return const JournalingPlanState(
      isEnabled: false,
      frequency: 'daily',
      daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
      reminderHour: 20,
      reminderMinute: 0,
      currentStreak: 0,
      longestStreak: 0,
      hasJournaledToday: false,
    );
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_keyEnabled) ?? false;
    final frequency = prefs.getString(_keyFrequency) ?? 'daily';
    final daysJson = prefs.getString(_keyDaysOfWeek);
    List<int> days = [1, 2, 3, 4, 5, 6, 7];
    if (daysJson != null && daysJson.isNotEmpty) {
      try {
        days = List<int>.from(jsonDecode(daysJson));
      } catch (_) {}
    } else if (frequency == 'fiveDays') {
      days = [1, 2, 3, 4, 5];
    } else if (frequency == 'threeDays') {
      days = [1, 3, 5];
    }

    final hour = prefs.getInt(_keyReminderHour) ?? 20;
    final minute = prefs.getInt(_keyReminderMinute) ?? 0;

    state = state.copyWith(
      isEnabled: enabled,
      frequency: frequency,
      daysOfWeek: days,
      reminderHour: hour,
      reminderMinute: minute,
    );

    _updateStreakMetrics();
  }

  Future<void> updatePlan({
    bool? isEnabled,
    String? frequency,
    List<int>? daysOfWeek,
    int? reminderHour,
    int? reminderMinute,
  }) async {
    final newEnabled = isEnabled ?? state.isEnabled;
    final newFreq = frequency ?? state.frequency;

    List<int> newDays = daysOfWeek ?? state.daysOfWeek;
    if (frequency != null) {
      if (newFreq == 'daily') {
        newDays = [1, 2, 3, 4, 5, 6, 7];
      } else if (newFreq == 'fiveDays') {
        newDays = [1, 2, 3, 4, 5];
      } else if (newFreq == 'threeDays') {
        newDays = [1, 3, 5];
      }
    }

    final newHour = reminderHour ?? state.reminderHour;
    final newMinute = reminderMinute ?? state.reminderMinute;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, newEnabled);
    await prefs.setString(_keyFrequency, newFreq);
    await prefs.setString(_keyDaysOfWeek, jsonEncode(newDays));
    await prefs.setInt(_keyReminderHour, newHour);
    await prefs.setInt(_keyReminderMinute, newMinute);

    state = state.copyWith(
      isEnabled: newEnabled,
      frequency: newFreq,
      daysOfWeek: newDays,
      reminderHour: newHour,
      reminderMinute: newMinute,
    );

    // Sync automatic notification schedules
    final notifService = NotificationService();
    await notifService.initialize();
    if (newEnabled) {
      await notifService.scheduleJournalingReminders(
        hour: newHour,
        minute: newMinute,
        daysOfWeek: newDays,
      );
    } else {
      await notifService.cancelJournalingReminders();
    }
  }

  /// Calculates current streak and longest streak based on journal entries
  void updateStreakFromNotes(List<PinEntity> notes) {
    final journalDates = <DateTime>{};

    for (final note in notes) {
      final tagsStr = note.tags ?? note.colorTag ?? '';
      final isJournal = tagsStr.toLowerCase().contains('journal') ||
          (note.content ?? '').toLowerCase().contains('journal');

      if (isJournal) {
        final d = note.entryDate ?? note.createdAt;
        journalDates.add(DateTime(d.year, d.month, d.day));
      }
    }

    if (journalDates.isEmpty) {
      state = state.copyWith(
        currentStreak: 0,
        longestStreak: 0,
        hasJournaledToday: false,
      );
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final hasToday = journalDates.contains(today);

    // Current streak calculation
    int currentStreak = 0;
    DateTime checkDate = hasToday ? today : yesterday;

    while (journalDates.contains(checkDate)) {
      currentStreak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    // Longest streak calculation
    final sortedDates = journalDates.toList()..sort();
    int maxStreak = 0;
    int tempStreak = 0;
    DateTime? prev;

    for (final d in sortedDates) {
      if (prev == null) {
        tempStreak = 1;
      } else {
        final diff = d.difference(prev).inDays;
        if (diff == 1) {
          tempStreak++;
        } else if (diff > 1) {
          tempStreak = 1;
        }
      }
      if (tempStreak > maxStreak) maxStreak = tempStreak;
      prev = d;
    }

    state = state.copyWith(
      currentStreak: currentStreak,
      longestStreak: maxStreak,
      hasJournaledToday: hasToday,
    );
  }

  void _updateStreakMetrics() {
    try {
      final db = ref.read(databaseProvider);
      db.pinDao.watchAllNotes().first.then((notes) {
        updateStreakFromNotes(notes);
      });
    } catch (_) {}
  }
}

final journalingPlanProvider =
    NotifierProvider<JournalingPlanNotifier, JournalingPlanState>(JournalingPlanNotifier.new);

class LockAllJournalsNotifier extends Notifier<bool> {
  static const _keyLockAllJournals = 'lock_all_journals_enabled';

  @override
  bool build() {
    _load();
    return false;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_keyLockAllJournals) ?? false;
  }

  Future<void> toggle(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLockAllJournals, value);
  }
}

final lockAllJournalsProvider =
    NotifierProvider<LockAllJournalsNotifier, bool>(LockAllJournalsNotifier.new);
