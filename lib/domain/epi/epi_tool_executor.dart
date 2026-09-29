import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../data/database/database.dart';
import '../../data/providers.dart';
import '../../data/repository/task_repository.dart';
import '../../data/repository/pin_repository.dart';
import '../../domain/models/note_model.dart';
import '../../domain/models/task_subitem.dart';
import '../../domain/cycle_detector.dart';
import '../../domain/models/in_app_alarm_model.dart';
import '../../presentation/notifiers/alarm_timer_provider.dart';
import 'epi_models.dart';
import 'epi_action_log.dart';

final epiToolExecutorProvider = Provider<EpiToolExecutor>((ref) {
  return EpiToolExecutor(ref);
});

class EpiToolExecutor {
  final Ref ref;

  EpiToolExecutor(this.ref);

  /// Executes an action emitted by Epi according to its permission tier.
  Future<EpiActionExecutionRecord> executeAction({
    required BuildContext context,
    required EpiActionCall action,
    bool forceConfirmed = false,
  }) async {
    final now = DateTime.now();

    // ── Tier 3: Destructive or Sensitive (Gate with confirmation dialog) ──
    if (action.tier == 'destructive_or_sensitive' && !forceConfirmed) {
      final confirmed = await _showConfirmationDialog(context, action);
      if (!confirmed) {
        return EpiActionExecutionRecord(
          action: action,
          status: ActionExecutionStatus.cancelled,
          message: 'Cancelled by user',
          timestamp: now,
        );
      }
    }

    try {
      switch (action.tool) {
        case 'create_task':
          return await _executeCreateTask(action);

        case 'update_task':
          return await _executeUpdateTask(action);

        case 'set_task_status':
          return await _executeSetTaskStatus(action);

        case 'delete_task':
          return await _executeDeleteTask(action);

        case 'create_note':
          return await _executeCreateNote(action);

        case 'delete_note':
          return await _executeDeleteNote(action);

        case 'query_tasks':
          return await _executeQueryTasks(action);

        case 'query_notes':
          return await _executeQueryNotes(action);

        case 'get_today_overview':
          return await _executeGetTodayOverview(action);

        case 'add_subtasks':
        case 'break_down_task':
          return await _executeAddSubtasks(action);

        case 'link_tasks':
          return await _executeLinkTasks(action);

        case 'triage_unsorted':
          return await _executeTriageUnsorted(action);

        case 'set_alarm':
          return await _executeSetAlarm(action);

        case 'set_timer':
          return await _executeSetTimer(action);

        case 'query_timetable':
          return await _executeQueryTimetable(action);

        default:
          return EpiActionExecutionRecord(
            action: action,
            status: ActionExecutionStatus.failed,
            message: 'Unknown tool: ${action.tool}',
            timestamp: now,
          );
      }
    } catch (e) {
      return EpiActionExecutionRecord(
        action: action,
        status: ActionExecutionStatus.failed,
        message: 'Execution error: $e',
        timestamp: now,
      );
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TOOL IMPLEMENTATIONS
  // ──────────────────────────────────────────────────────────────────────────

  String _stripDashes(String s) => s.replaceAll('—', ' - ').replaceAll('–', '-');

  Future<EpiActionExecutionRecord> _executeCreateTask(EpiActionCall action) async {
    final rawTitle = action.parameters['title']?.toString() ?? 'Untitled Task';
    final title = _stripDashes(rawTitle);
    final rawNotes = action.parameters['notes']?.toString();
    final notes = rawNotes != null ? _stripDashes(rawNotes) : null;
    final boardId = action.parameters['board_id']?.toString();
    final priority = (action.parameters['priority'] as num?)?.toInt() ?? 0;

    DateTime? dueDate;
    if (action.parameters['due_date'] != null) {
      dueDate = DateTime.tryParse(action.parameters['due_date'].toString());
    }

    DateTime? scheduledDate;
    if (action.parameters['scheduled_date'] != null) {
      scheduledDate = DateTime.tryParse(action.parameters['scheduled_date'].toString());
    }

    final newTaskId = DateTime.now().millisecondsSinceEpoch.toString();
    final taskRepo = ref.read(taskRepositoryProvider);

    final companion = TasksCompanion.insert(
      id: newTaskId,
      title: title,
      notes: notes != null && notes.isNotEmpty ? drift.Value(notes) : const drift.Value.absent(),
      boardId: boardId != null && boardId.isNotEmpty ? drift.Value(boardId) : const drift.Value.absent(),
      dueDate: dueDate != null ? drift.Value(dueDate) : const drift.Value.absent(),
      scheduledDate: scheduledDate != null ? drift.Value(scheduledDate) : const drift.Value.absent(),
      priority: drift.Value(priority),
      status: const drift.Value('todo'),
    );

    await taskRepo.createTask(companion);

    // Record in Action Log for undo
    ref.read(epiActionLogProvider.notifier).recordAction(EpiLogEntry(
      id: action.id,
      tool: action.tool,
      tier: action.tier,
      parameters: action.parameters,
      entityId: newTaskId,
      summary: 'Created task "$title"',
      timestamp: DateTime.now(),
      undoAction: () async {
        await taskRepo.deleteTask(newTaskId);
      },
    ));

    return EpiActionExecutionRecord(
      action: action,
      status: ActionExecutionStatus.success,
      message: 'Created task "$title"',
      createdEntityId: newTaskId,
      entityIds: [newTaskId],
      timestamp: DateTime.now(),
    );
  }

  Future<EpiActionExecutionRecord> _executeUpdateTask(EpiActionCall action) async {
    final taskId = action.parameters['task_id']?.toString();
    if (taskId == null) throw Exception('task_id is required for update_task');

    final taskDao = ref.read(taskDaoProvider);
    final taskRepo = ref.read(taskRepositoryProvider);
    final existing = await taskDao.getTask(taskId);
    if (existing == null) throw Exception('Task $taskId not found');

    final prevTask = existing;

    final updated = existing.copyWith(
      title: action.parameters['title'] != null
          ? _stripDashes(action.parameters['title']!.toString())
          : existing.title,
      notes: action.parameters['notes'] != null
          ? drift.Value(_stripDashes(action.parameters['notes']!.toString()))
          : drift.Value(existing.notes),
      priority: (action.parameters['priority'] as num?)?.toInt() ?? existing.priority,
      boardId: action.parameters['board_id'] != null
          ? drift.Value(action.parameters['board_id']?.toString())
          : drift.Value(existing.boardId),
      dueDate: action.parameters['due_date'] != null
          ? drift.Value(DateTime.tryParse(action.parameters['due_date'].toString()))
          : drift.Value(existing.dueDate),
      scheduledDate: action.parameters['scheduled_date'] != null
          ? drift.Value(DateTime.tryParse(action.parameters['scheduled_date'].toString()))
          : drift.Value(existing.scheduledDate),
      modifiedAt: DateTime.now(),
    );

    await taskRepo.updateTask(updated);

    // Record in Action Log for undo
    ref.read(epiActionLogProvider.notifier).recordAction(EpiLogEntry(
      id: action.id,
      tool: action.tool,
      tier: action.tier,
      parameters: action.parameters,
      entityId: taskId,
      summary: 'Updated task "${updated.title}"',
      timestamp: DateTime.now(),
      undoAction: () async {
        await taskRepo.updateTask(prevTask);
      },
    ));

    return EpiActionExecutionRecord(
      action: action,
      status: ActionExecutionStatus.success,
      message: 'Updated task "${updated.title}"',
      createdEntityId: taskId,
      entityIds: [taskId],
      timestamp: DateTime.now(),
    );
  }

  Future<EpiActionExecutionRecord> _executeSetTaskStatus(EpiActionCall action) async {
    final taskId = action.parameters['task_id']?.toString();
    final status = action.parameters['status']?.toString() ?? 'todo';
    if (taskId == null) throw Exception('task_id is required');

    final taskDao = ref.read(taskDaoProvider);
    final taskRepo = ref.read(taskRepositoryProvider);
    final existing = await taskDao.getTask(taskId);
    if (existing == null) throw Exception('Task $taskId not found');

    final prevStatus = existing.status;
    final updated = existing.copyWith(status: status, modifiedAt: DateTime.now());
    await taskRepo.updateTask(updated);

    // Record in Action Log for undo
    ref.read(epiActionLogProvider.notifier).recordAction(EpiLogEntry(
      id: action.id,
      tool: action.tool,
      tier: action.tier,
      parameters: action.parameters,
      entityId: taskId,
      summary: 'Changed status of "${existing.title}" to $status',
      timestamp: DateTime.now(),
      undoAction: () async {
        await taskRepo.updateTask(existing.copyWith(status: prevStatus, modifiedAt: DateTime.now()));
      },
    ));

    return EpiActionExecutionRecord(
      action: action,
      status: ActionExecutionStatus.success,
      message: 'Marked "${existing.title}" as $status',
      createdEntityId: taskId,
      entityIds: [taskId],
      timestamp: DateTime.now(),
    );
  }

  Future<EpiActionExecutionRecord> _executeDeleteTask(EpiActionCall action) async {
    final taskId = action.parameters['task_id']?.toString();
    if (taskId == null) throw Exception('task_id is required');

    final taskDao = ref.read(taskDaoProvider);
    final taskRepo = ref.read(taskRepositoryProvider);
    final existing = await taskDao.getTask(taskId);
    if (existing == null) throw Exception('Task $taskId not found');

    await taskRepo.deleteTask(taskId);

    // Record in Action Log for undo
    ref.read(epiActionLogProvider.notifier).recordAction(EpiLogEntry(
      id: action.id,
      tool: action.tool,
      tier: action.tier,
      parameters: action.parameters,
      entityId: taskId,
      summary: 'Deleted task "${existing.title}"',
      timestamp: DateTime.now(),
      undoAction: () async {
        await taskRepo.createTask(TasksCompanion.insert(
          id: existing.id,
          title: existing.title,
          notes: drift.Value(existing.notes),
          boardId: drift.Value(existing.boardId),
          dueDate: drift.Value(existing.dueDate),
          scheduledDate: drift.Value(existing.scheduledDate),
          priority: drift.Value(existing.priority),
          status: drift.Value(existing.status),
        ));
      },
    ));

    return EpiActionExecutionRecord(
      action: action,
      status: ActionExecutionStatus.success,
      message: 'Deleted task "${existing.title}"',
      timestamp: DateTime.now(),
    );
  }

  Future<EpiActionExecutionRecord> _executeCreateNote(EpiActionCall action) async {
    final rawTitle = action.parameters['title']?.toString() ?? 'Untitled Note';
    final title = _stripDashes(rawTitle);
    final rawMarkdown = action.parameters['markdown']?.toString() ?? '';
    final markdown = _stripDashes(rawMarkdown);
    final tag = action.parameters['tag']?.toString() ?? 'General';
    final boardId = action.parameters['board_id']?.toString();

    final allBlocks = <NoteBlock>[];
    if (title.isNotEmpty) {
      allBlocks.add(NoteBlock(type: BlockType.heading, text: title));
    }
    if (markdown.isNotEmpty) {
      allBlocks.addAll(NoteDocument.parseLegacyMarkdown(markdown));
    }

    final payload = NoteDocumentPayload(blocks: allBlocks);
    final contentJson = NoteDocument.encode(payload);

    final newNoteId = DateTime.now().millisecondsSinceEpoch.toString();
    final pinRepo = ref.read(pinRepositoryProvider);

    final companion = PinsCompanion.insert(
      id: newNoteId,
      type: 'note',
      boardId: boardId != null && boardId.isNotEmpty ? drift.Value(boardId) : const drift.Value.absent(),
      content: drift.Value(contentJson),
      tags: drift.Value(tag),
      isLocked: const drift.Value(false), // STRICT RULE: never locked
    );

    await pinRepo.createPin(companion);

    // Record in Action Log for undo
    ref.read(epiActionLogProvider.notifier).recordAction(EpiLogEntry(
      id: action.id,
      tool: action.tool,
      tier: action.tier,
      parameters: action.parameters,
      entityId: newNoteId,
      summary: 'Created note "$title"',
      timestamp: DateTime.now(),
      undoAction: () async {
        await pinRepo.deletePin(newNoteId);
      },
    ));

    return EpiActionExecutionRecord(
      action: action,
      status: ActionExecutionStatus.success,
      message: 'Created note "$title"',
      createdEntityId: newNoteId,
      entityIds: [newNoteId],
      timestamp: DateTime.now(),
    );
  }

  Future<EpiActionExecutionRecord> _executeDeleteNote(EpiActionCall action) async {
    final noteId = action.parameters['note_id']?.toString();
    if (noteId == null) throw Exception('note_id is required');

    final pinDao = ref.read(pinDaoProvider);
    final pinRepo = ref.read(pinRepositoryProvider);
    final existing = await pinDao.getPin(noteId);
    if (existing == null) throw Exception('Note $noteId not found');

    await pinRepo.deletePin(noteId);

    // Record in Action Log for undo
    ref.read(epiActionLogProvider.notifier).recordAction(EpiLogEntry(
      id: action.id,
      tool: action.tool,
      tier: action.tier,
      parameters: action.parameters,
      entityId: noteId,
      summary: 'Deleted note',
      timestamp: DateTime.now(),
      undoAction: () async {
        await pinRepo.createPin(PinsCompanion.insert(
          id: existing.id,
          type: existing.type,
          boardId: drift.Value(existing.boardId),
          content: drift.Value(existing.content),
          tags: drift.Value(existing.tags),
          isLocked: drift.Value(existing.isLocked),
        ));
      },
    ));

    return EpiActionExecutionRecord(
      action: action,
      status: ActionExecutionStatus.success,
      message: 'Deleted note',
      timestamp: DateTime.now(),
    );
  }

  Future<EpiActionExecutionRecord> _executeQueryTasks(EpiActionCall action) async {
    final taskDao = ref.read(taskDaoProvider);
    final allTasks = await taskDao.getAllTasks();
    final filter = action.parameters['filter']?.toString();
    final now = DateTime.now();

    var results = allTasks;
    if (filter == 'due_today') {
      final start = DateTime(now.year, now.month, now.day);
      final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
      results = results.where((t) => t.dueDate != null && t.dueDate!.isAfter(start) && t.dueDate!.isBefore(end)).toList();
    } else if (filter == 'overdue') {
      results = results.where((t) => t.status != 'done' && t.dueDate != null && t.dueDate!.isBefore(now)).toList();
    } else if (filter == 'unsorted') {
      results = results.where((t) => t.boardId == null).toList();
    }

    final matchingIds = results.map((t) => t.id).take(5).toList();

    return EpiActionExecutionRecord(
      action: action,
      status: ActionExecutionStatus.success,
      message: results.isEmpty
          ? 'No tasks found'
          : results.length == 1
              ? 'Found 1 task'
              : 'Found ${results.length} tasks',
      entityIds: matchingIds,
      timestamp: DateTime.now(),
    );
  }

  Future<EpiActionExecutionRecord> _executeQueryNotes(EpiActionCall action) async {
    final pinDao = ref.read(pinDaoProvider);
    // STRICT PRIVACY: Query only non-locked notes
    final allNotes = await pinDao.getAllNotes();
    final notes = allNotes.where((p) => !p.isLocked).toList();

    final term = action.parameters['search_term']?.toString().toLowerCase();
    var results = notes;
    if (term != null && term.isNotEmpty) {
      results = results.where((n) {
        final content = (n.content ?? '').toLowerCase();
        return content.contains(term);
      }).toList();
    }

    final matchingIds = results.map((n) => n.id).take(5).toList();

    return EpiActionExecutionRecord(
      action: action,
      status: ActionExecutionStatus.success,
      message: results.isEmpty
          ? 'No notes found'
          : results.length == 1
              ? 'Found 1 note'
              : 'Found ${results.length} notes',
      entityIds: matchingIds,
      timestamp: DateTime.now(),
    );
  }

  Future<EpiActionExecutionRecord> _executeGetTodayOverview(EpiActionCall action) async {
    final taskDao = ref.read(taskDaoProvider);
    final allTasks = await taskDao.getAllTasks();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final dueToday = allTasks.where((t) => t.dueDate != null && t.dueDate!.isAfter(start) && t.dueDate!.isBefore(end)).toList();
    final overdue = allTasks.where((t) => t.status != 'done' && t.dueDate != null && t.dueDate!.isBefore(now)).toList();
    final relatedIds = <String>{...dueToday.map((t) => t.id), ...overdue.map((t) => t.id)}.take(5).toList();

    return EpiActionExecutionRecord(
      action: action,
      status: ActionExecutionStatus.success,
      message: '${dueToday.length} due today, ${overdue.length} overdue',
      entityIds: relatedIds,
      timestamp: DateTime.now(),
    );
  }

  Future<EpiActionExecutionRecord> _executeAddSubtasks(EpiActionCall action) async {
    final taskId = action.parameters['task_id']?.toString();
    if (taskId == null) throw Exception('task_id is required for add_subtasks');

    final rawSubtasks = action.parameters['subtasks'];
    final subtaskList = <String>[];
    if (rawSubtasks is List) {
      for (final s in rawSubtasks) {
        if (s != null && s.toString().trim().isNotEmpty) {
          subtaskList.add(_stripDashes(s.toString().trim()));
        }
      }
    } else if (rawSubtasks is String && rawSubtasks.isNotEmpty) {
      subtaskList.add(_stripDashes(rawSubtasks.trim()));
    }

    if (subtaskList.isEmpty) {
      throw Exception('At least one subtask title is required');
    }

    final taskDao = ref.read(taskDaoProvider);
    final taskRepo = ref.read(taskRepositoryProvider);
    final existing = await taskDao.getTask(taskId);
    if (existing == null) throw Exception('Task $taskId not found');

    final payload = TaskSubitem.decodeNotes(existing.notes);
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final newSubitems = <TaskSubitem>[];
    for (var i = 0; i < subtaskList.length; i++) {
      newSubitems.add(TaskSubitem(
        id: '${nowMs}_$i',
        title: subtaskList[i],
        isDone: false,
      ));
    }

    final updatedSubitems = [...payload.subitems, ...newSubitems];
    final updatedNotes = TaskSubitem.encodeNotes(
      userNotes: payload.userNotes,
      subitems: updatedSubitems,
    );

    final updated = existing.copyWith(
      notes: drift.Value(updatedNotes),
      modifiedAt: DateTime.now(),
    );

    await taskRepo.updateTask(updated);

    // Record in Action Log for undo
    final prevNotes = existing.notes;
    ref.read(epiActionLogProvider.notifier).recordAction(EpiLogEntry(
      id: action.id,
      tool: action.tool,
      tier: action.tier,
      parameters: action.parameters,
      entityId: taskId,
      summary: 'Added ${newSubitems.length} ${newSubitems.length == 1 ? 'subtask' : 'subtasks'} to "${existing.title}"',
      timestamp: DateTime.now(),
      undoAction: () async {
        final cur = await taskDao.getTask(taskId);
        if (cur != null) {
          await taskRepo.updateTask(cur.copyWith(
            notes: drift.Value(prevNotes),
            modifiedAt: DateTime.now(),
          ));
        }
      },
    ));

    return EpiActionExecutionRecord(
      action: action,
      status: ActionExecutionStatus.success,
      message: 'Added ${newSubitems.length} ${newSubitems.length == 1 ? 'subtask' : 'subtasks'} to "${existing.title}"',
      createdEntityId: taskId,
      entityIds: [taskId],
      timestamp: DateTime.now(),
    );
  }

  Future<EpiActionExecutionRecord> _executeLinkTasks(EpiActionCall action) async {
    final taskId = action.parameters['task_id']?.toString();
    final dependsOnTaskId = action.parameters['depends_on_task_id']?.toString();
    if (taskId == null || dependsOnTaskId == null) {
      throw Exception('task_id and depends_on_task_id are both required');
    }

    final taskDao = ref.read(taskDaoProvider);
    final taskA = await taskDao.getTask(taskId);
    final taskB = await taskDao.getTask(dependsOnTaskId);
    if (taskA == null) throw Exception('Task $taskId not found');
    if (taskB == null) throw Exception('Prerequisite task $dependsOnTaskId not found');

    // Cycle detection check
    final allDeps = await taskDao.getAllTaskDependencies();
    if (createsCycle(taskId, dependsOnTaskId, allDeps)) {
      return EpiActionExecutionRecord(
        action: action,
        status: ActionExecutionStatus.failed,
        message: 'Could not link "${taskA.title}" to "${taskB.title}": this creates a circular dependency loop.',
        entityIds: [taskId, dependsOnTaskId],
        timestamp: DateTime.now(),
      );
    }

    await taskDao.addTaskDependency(taskId, dependsOnTaskId);

    // Record in Action Log for undo
    ref.read(epiActionLogProvider.notifier).recordAction(EpiLogEntry(
      id: action.id,
      tool: action.tool,
      tier: action.tier,
      parameters: action.parameters,
      entityId: taskId,
      summary: 'Linked "${taskA.title}" to depend on "${taskB.title}"',
      timestamp: DateTime.now(),
      undoAction: () async {
        await taskDao.removeTaskDependency(taskId, dependsOnTaskId);
      },
    ));

    return EpiActionExecutionRecord(
      action: action,
      status: ActionExecutionStatus.success,
      message: 'Linked "${taskA.title}" to depend on "${taskB.title}"',
      entityIds: [taskId, dependsOnTaskId],
      timestamp: DateTime.now(),
    );
  }

  Future<EpiActionExecutionRecord> _executeTriageUnsorted(EpiActionCall action) async {
    final rawAssignments = action.parameters['assignments'];
    if (rawAssignments is! List || rawAssignments.isEmpty) {
      throw Exception('assignments list is required for triage_unsorted');
    }

    final taskDao = ref.read(taskDaoProvider);
    final taskRepo = ref.read(taskRepositoryProvider);

    final affectedIds = <String>[];
    final undoSnapshots = <TaskEntity>[];

    for (final item in rawAssignments) {
      if (item is! Map) continue;
      final itemId = item['item_id']?.toString() ?? item['task_id']?.toString();
      final boardId = item['board_id']?.toString();
      final dueDateStr = item['due_date']?.toString();

      if (itemId == null || boardId == null) continue;

      final existing = await taskDao.getTask(itemId);
      if (existing != null) {
        undoSnapshots.add(existing);
        DateTime? newDueDate = existing.dueDate;
        if (dueDateStr != null && dueDateStr.isNotEmpty) {
          newDueDate = DateTime.tryParse(dueDateStr);
        }

        final updated = existing.copyWith(
          boardId: drift.Value(boardId),
          dueDate: drift.Value(newDueDate),
          modifiedAt: DateTime.now(),
        );
        await taskRepo.updateTask(updated);
        affectedIds.add(itemId);
      }
    }

    // Record in Action Log for undo
    ref.read(epiActionLogProvider.notifier).recordAction(EpiLogEntry(
      id: action.id,
      tool: action.tool,
      tier: action.tier,
      parameters: action.parameters,
      summary: 'Triaged ${affectedIds.length} ${affectedIds.length == 1 ? 'item' : 'items'} to boards',
      timestamp: DateTime.now(),
      undoAction: () async {
        for (final snap in undoSnapshots) {
          await taskRepo.updateTask(snap);
        }
      },
    ));

    return EpiActionExecutionRecord(
      action: action,
      status: ActionExecutionStatus.success,
      message: 'Triaged ${affectedIds.length} ${affectedIds.length == 1 ? 'item' : 'items'} to respective boards',
      entityIds: affectedIds,
      timestamp: DateTime.now(),
    );
  }

  Future<EpiActionExecutionRecord> _executeSetAlarm(EpiActionCall action) async {
    final rawTitle = action.parameters['title']?.toString() ?? 'Alarm';
    final title = _stripDashes(rawTitle);
    final timeStr = action.parameters['time']?.toString() ?? '08:00';
    final taskId = action.parameters['task_id']?.toString();
    final repeatDaysRaw = action.parameters['repeat_days'];

    List<int> repeatDays = [];
    if (repeatDaysRaw is List) {
      repeatDays = repeatDaysRaw.map((e) => (e as num).toInt()).toList();
    }

    final parts = timeStr.split(':');
    final hour = int.tryParse(parts[0]) ?? 8;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

    final alarmId = DateTime.now().millisecondsSinceEpoch.toString();
    final newAlarm = InAppAlarm(
      id: alarmId,
      title: title,
      hour: hour,
      minute: minute,
      repeatDays: repeatDays,
      taskId: taskId,
    );

    final alarmNotifier = ref.read(alarmTimerProvider.notifier);
    await alarmNotifier.addAlarm(newAlarm);

    // Record in Action Log for undo
    ref.read(epiActionLogProvider.notifier).recordAction(EpiLogEntry(
      id: action.id,
      tool: action.tool,
      tier: action.tier,
      parameters: action.parameters,
      entityId: alarmId,
      summary: 'Set alarm "$title" for ${newAlarm.formattedTime}',
      timestamp: DateTime.now(),
      undoAction: () async {
        await alarmNotifier.deleteAlarm(alarmId);
      },
    ));

    return EpiActionExecutionRecord(
      action: action,
      status: ActionExecutionStatus.success,
      message: 'Set alarm "$title" for ${newAlarm.formattedTime}',
      createdEntityId: alarmId,
      entityIds: [alarmId],
      timestamp: DateTime.now(),
    );
  }

  Future<EpiActionExecutionRecord> _executeSetTimer(EpiActionCall action) async {
    final durationNum = (action.parameters['duration_minutes'] as num?)?.toInt() ?? 25;
    final rawLabel = action.parameters['label']?.toString() ?? 'Focus Session';
    final label = _stripDashes(rawLabel);
    final taskId = action.parameters['task_id']?.toString();

    final alarmNotifier = ref.read(alarmTimerProvider.notifier);
    alarmNotifier.startTimer(
      duration: Duration(minutes: durationNum),
      label: label,
      taskId: taskId,
    );

    return EpiActionExecutionRecord(
      action: action,
      status: ActionExecutionStatus.success,
      message: 'Started $durationNum-minute timer for "$label"',
      timestamp: DateTime.now(),
    );
  }

  Future<EpiActionExecutionRecord> _executeQueryTimetable(EpiActionCall action) async {
    final timetableDao = ref.read(timetableDaoProvider);
    final dayOfWeek = (action.parameters['day_of_week'] as num?)?.toInt();

    final List<TimetableSlotEntity> slots;
    if (dayOfWeek != null) {
      slots = await (timetableDao.select(timetableDao.timetableSlots)
            ..where((t) => t.dayOfWeek.equals(dayOfWeek))
            ..orderBy([(t) => drift.OrderingTerm(expression: t.startTime)]))
          .get();
    } else {
      slots = await timetableDao.getAllSlots();
    }

    final ids = slots.map((s) => s.id).take(5).toList();

    return EpiActionExecutionRecord(
      action: action,
      status: ActionExecutionStatus.success,
      message: slots.isEmpty
          ? 'No schedule slots found'
          : slots.length == 1
              ? 'Found 1 schedule slot'
              : 'Found ${slots.length} schedule slots',
      entityIds: ids,
      timestamp: DateTime.now(),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // DIALOG FOR DESTRUCTIVE ACTIONS
  // ──────────────────────────────────────────────────────────────────────────

  Future<bool> _showConfirmationDialog(BuildContext context, EpiActionCall action) async {
    final title = action.parameters['title']?.toString() ?? 'this item';
    final tool = action.tool.replaceAll('_', ' ');

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 24),
              const SizedBox(width: 8),
              const Text('Confirm Action', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'Epi is asking to $tool: "$title". Do you want to proceed?',
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Proceed'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }
}
