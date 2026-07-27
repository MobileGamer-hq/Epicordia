import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/database/database.dart';

class DataExportService {
  /// Converts all database entities (Boards, Pins, Tasks, Connectors, Attachments, TimetableSlots)
  /// into a structured JSON string payload.
  static Future<String> generateWorkspaceJson(AppDatabase db) async {
    final boards = await db.select(db.boards).get();
    final pins = await db.select(db.pins).get();
    final tasks = await db.select(db.tasks).get();
    final connectors = await db.select(db.connectors).get();
    final attachments = await db.select(db.attachments).get();
    final timetableSlots = await db.select(db.timetableSlots).get();

    final exportData = {
      'app': 'Epicordia',
      'version': '1.0.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'boards': boards.map((b) => b.toJson()).toList(),
      'pins': pins.map((p) => p.toJson()).toList(),
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'connectors': connectors.map((c) => c.toJson()).toList(),
      'attachments': attachments.map((a) => a.toJson()).toList(),
      'timetableSlots': timetableSlots.map((s) => s.toJson()).toList(),
    };

    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(exportData);
  }

  /// Converts a list of TaskEntity objects to a clean CSV string.
  static String exportTasksToCsv(List<TaskEntity> tasks, Map<String, BoardEntity> boardsMap) {
    final buffer = StringBuffer();
    // CSV Header
    buffer.writeln('"ID","Title","Status","Priority","Due Date","Scheduled Date","Board","Notes","Recurrence"');

    for (final task in tasks) {
      final boardTitle = boardsMap[task.boardId]?.title ?? 'Inbox';
      final title = _escapeCsv(task.title);
      final status = _escapeCsv(task.status);
      final priority = task.priority.toString();
      final dueDate = task.dueDate?.toIso8601String() ?? '';
      final scheduledDate = task.scheduledDate?.toIso8601String() ?? '';
      final board = _escapeCsv(boardTitle);
      final notes = _escapeCsv(task.notes ?? '');
      final recurrence = _escapeCsv(task.recurrenceRule ?? '');

      buffer.writeln('"${task.id}",$title,$status,$priority,"$dueDate","$scheduledDate",$board,$notes,$recurrence');
    }

    return buffer.toString();
  }

  /// Converts a list of TimetableSlotEntity objects to a clean CSV string.
  static String exportTimetableToCsv(List<TimetableSlotEntity> slots) {
    final buffer = StringBuffer();
    // CSV Header
    buffer.writeln('"ID","Day Of Week","Start Time","End Time","Title","Location","Color Tag","Notes"');

    const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    for (final slot in slots) {
      final dayName = (slot.dayOfWeek >= 1 && slot.dayOfWeek <= 7)
          ? dayNames[slot.dayOfWeek - 1]
          : 'Day ${slot.dayOfWeek}';
      final title = _escapeCsv(slot.title);
      final location = _escapeCsv(slot.location ?? '');
      final color = _escapeCsv(slot.colorTag ?? '');
      final notes = _escapeCsv(slot.notes ?? '');

      buffer.writeln('"${slot.id}","$dayName","${slot.startTime}","${slot.endTime}",$title,$location,$color,$notes');
    }

    return buffer.toString();
  }

  /// Helper to escape string values for CSV format.
  static String _escapeCsv(String input) {
    final escaped = input.replaceAll('"', '""');
    return '"$escaped"';
  }

  /// Prompts user to save or write content to local file storage.
  static Future<String?> saveExportToFile({
    required String fileName,
    required String content,
  }) async {
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isWindows || Platform.isMacOS)) {
        final outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Export File',
          fileName: fileName,
        );

        if (outputFile != null) {
          final file = File(outputFile);
          await file.writeAsString(content);
          return outputFile;
        }
      }

      // Fallback to Documents directory if saveFile picker is unavailable or cancelled
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(content);
      return file.path;
    } catch (e) {
      debugPrint('DataExportService save error: $e');
      return null;
    }
  }
}
