import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TaskSettingsState {
  final bool autoDeleteCompleted;
  final int autoDeleteHours;

  const TaskSettingsState({
    this.autoDeleteCompleted = true,
    this.autoDeleteHours = 24,
  });

  TaskSettingsState copyWith({
    bool? autoDeleteCompleted,
    int? autoDeleteHours,
  }) {
    return TaskSettingsState(
      autoDeleteCompleted: autoDeleteCompleted ?? this.autoDeleteCompleted,
      autoDeleteHours: autoDeleteHours ?? this.autoDeleteHours,
    );
  }

  static const List<int> supportedRetentionHours = [
    1,
    12,
    24,
    48,
    72,
    168,
    336,
    720,
  ];

  static String retentionLabel(int hours) {
    switch (hours) {
      case 1:
        return '1 Hour';
      case 12:
        return '12 Hours';
      case 24:
        return '24 Hours (1 Day)';
      case 48:
        return '48 Hours (2 Days)';
      case 72:
        return '3 Days';
      case 168:
        return '1 Week (7 Days)';
      case 336:
        return '2 Weeks (14 Days)';
      case 720:
        return '1 Month (30 Days)';
      default:
        if (hours % 24 == 0) {
          return '${hours ~/ 24} Days';
        }
        return '$hours Hours';
    }
  }
}

class TaskSettingsNotifier extends Notifier<TaskSettingsState> {
  static const _keyAutoDelete = 'task_auto_delete_completed';
  static const _keyRetentionHours = 'task_auto_delete_hours';

  @override
  TaskSettingsState build() {
    _loadFromPrefs();
    return const TaskSettingsState();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final autoDelete = prefs.getBool(_keyAutoDelete) ?? true;
    final hours = prefs.getInt(_keyRetentionHours) ?? 24;
    state = TaskSettingsState(
      autoDeleteCompleted: autoDelete,
      autoDeleteHours: hours,
    );
  }

  Future<void> setAutoDeleteCompleted(bool enabled) async {
    state = state.copyWith(autoDeleteCompleted: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoDelete, enabled);
  }

  Future<void> setAutoDeleteHours(int hours) async {
    state = state.copyWith(autoDeleteHours: hours);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyRetentionHours, hours);
  }
}

final taskSettingsProvider =
    NotifierProvider<TaskSettingsNotifier, TaskSettingsState>(
  TaskSettingsNotifier.new,
);
