import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database/database.dart';
import 'dao/board_dao.dart';
import 'dao/pin_dao.dart';
import 'dao/task_dao.dart';
import 'dao/connector_dao.dart';
import 'dao/timetable_dao.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final boardDaoProvider = Provider<BoardDao>((ref) {
  return ref.watch(databaseProvider).boardDao;
});

final pinDaoProvider = Provider<PinDao>((ref) {
  return ref.watch(databaseProvider).pinDao;
});

final taskDaoProvider = Provider<TaskDao>((ref) {
  return ref.watch(databaseProvider).taskDao;
});

final connectorDaoProvider = Provider<ConnectorDao>((ref) {
  return ref.watch(databaseProvider).connectorDao;
});

final timetableDaoProvider = Provider<TimetableDao>((ref) {
  return ref.watch(databaseProvider).timetableDao;
});

final allTimetableSlotsProvider = StreamProvider<List<TimetableSlotEntity>>((ref) {
  return ref.watch(timetableDaoProvider).watchAllSlots();
});

/// Watches the single Task row linked to a canvas pin (via Tasks.pinId).
final taskForPinProvider = StreamProvider.family<TaskEntity?, String>((ref, pinId) {
  return ref.watch(taskDaoProvider).watchTaskForPin(pinId);
});

/// Watches all Task rows belonging to a task-list card (via Tasks.groupPinId).
final tasksForGroupPinProvider = StreamProvider.family<List<TaskEntity>, String>((ref, groupPinId) {
  return ref.watch(taskDaoProvider).watchTasksForGroupPin(groupPinId);
});

/// Manages the saved user display name from onboarding and settings.
class UserNameNotifier extends Notifier<String> {
  @override
  String build() {
    _load();
    return 'Somto';
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name');
    if (name != null && name.isNotEmpty) {
      state = name;
    }
  }

  Future<void> updateName(String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    state = trimmed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', trimmed);
  }
}

final userNameProvider = NotifierProvider<UserNameNotifier, String>(UserNameNotifier.new);


