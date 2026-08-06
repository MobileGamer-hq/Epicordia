import 'dart:convert';

class TaskSubitem {
  final String id;
  final String title;
  final bool isDone;

  const TaskSubitem({
    required this.id,
    required this.title,
    this.isDone = false,
  });

  TaskSubitem copyWith({
    String? id,
    String? title,
    bool? isDone,
  }) {
    return TaskSubitem(
      id: id ?? this.id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isDone': isDone,
    };
  }

  factory TaskSubitem.fromJson(Map<String, dynamic> json) {
    return TaskSubitem(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] as String? ?? '',
      isDone: json['isDone'] as bool? ?? false,
    );
  }

  /// Encodes a list of [TaskSubitem] along with optional markdown notes into a raw string for `task.notes`.
  static String encodeNotes({String? userNotes, List<TaskSubitem>? subitems}) {
    final Map<String, dynamic> data = {};
    if (userNotes != null && userNotes.trim().isNotEmpty) {
      data['userNotes'] = userNotes.trim();
    }
    if (subitems != null && subitems.isNotEmpty) {
      data['subitems'] = subitems.map((e) => e.toJson()).toList();
    }
    if (data.isEmpty) return '';
    return jsonEncode(data);
  }

  /// Decodes raw string `task.notes` into structured data (user notes and list of [TaskSubitem]).
  static TaskNotesPayload decodeNotes(String? rawNotes) {
    if (rawNotes == null || rawNotes.trim().isEmpty) {
      return const TaskNotesPayload(userNotes: null, subitems: []);
    }

    final trimmed = rawNotes.trim();
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      try {
        final decoded = jsonDecode(trimmed) as Map<String, dynamic>;
        final userNotes = decoded['userNotes'] as String?;
        final subitemsJson = decoded['subitems'] as List<dynamic>?;
        final subitems = subitemsJson != null
            ? subitemsJson.map((item) => TaskSubitem.fromJson(item as Map<String, dynamic>)).toList()
            : <TaskSubitem>[];
        return TaskNotesPayload(userNotes: userNotes, subitems: subitems);
      } catch (_) {
        // Fallback for legacy plain text notes
      }
    }

    // Legacy plain text notes: return as user notes with no subitems
    return TaskNotesPayload(userNotes: trimmed, subitems: const []);
  }
}

class TaskNotesPayload {
  final String? userNotes;
  final List<TaskSubitem> subitems;

  const TaskNotesPayload({
    required this.userNotes,
    required this.subitems,
  });

  bool get hasSubitems => subitems.isNotEmpty;
  int get completedCount => subitems.where((s) => s.isDone).length;
  int get totalCount => subitems.length;
  double get progress => totalCount == 0 ? 0.0 : completedCount / totalCount;
  bool get allCompleted => totalCount > 0 && completedCount == totalCount;
}
