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
import '../../domain/models/in_app_timer_model.dart';
import '../../presentation/notifiers/alarm_timer_provider.dart';
import 'epi_models.dart';
import 'epi_action_log.dart';
import '../../data/repository/board_repository.dart';
import 'epi_chat_controller.dart';

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

        case 'update_note':
          return await _executeUpdateNote(action);

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

        case 'update_about_me':
          return await _executeUpdateAboutMe(action);

        case 'create_schedule_slot':
          return await _executeCreateScheduleSlot(action);

        case 'update_schedule_slot':
          return await _executeUpdateScheduleSlot(action);

        case 'delete_schedule_slot':
          return await _executeDeleteScheduleSlot(action);

        case 'query_boards':
          return await _executeQueryBoards(action);

        case 'create_board':
          return await _executeCreateBoard(action);

        case 'delete_board':
          return await _executeDeleteBoard(action);

        case 'set_recurrence':
          return await _executeSetRecurrence(action);

        case 'get_productivity_report':
          return await _executeGetProductivityReport(action);

        case 'wipe_thread':
        case 'clear_chat_history':
          return await _executeWipeThread(action);

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

    final taskDao = ref.read(taskDaoProvider);
    final allTasks = await taskDao.getAllTasks();
    final existingDup = allTasks.where((t) {
      if (t.title.toLowerCase().trim() != title.toLowerCase().trim()) return false;
      final diff = DateTime.now().difference(t.createdAt);
      return diff.inSeconds.abs() < 15;
    }).firstOrNull;

    if (existingDup != null) {
      return EpiActionExecutionRecord(
        action: action,
        status: ActionExecutionStatus.success,
        message: 'Task "$title" already exists',
        createdEntityId: existingDup.id,
        entityIds: [existingDup.id],
        wasNoOp: true,
        timestamp: DateTime.now(),
      );
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
      outputData: {
        'id': newTaskId,
        'title': title,
        'status': 'todo',
        'dueDate': dueDate?.toIso8601String(),
        'priority': priority,
        'type': 'task',
      },
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
      outputData: {
        'id': taskId,
        'title': updated.title,
        'status': updated.status,
        'dueDate': updated.dueDate?.toIso8601String(),
        'priority': updated.priority,
        'type': 'task',
      },
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
    if (prevStatus == status) {
      return EpiActionExecutionRecord(
        action: action,
        status: ActionExecutionStatus.success,
        message: 'Task "${existing.title}" is already marked as $status',
        createdEntityId: taskId,
        entityIds: [taskId],
        wasNoOp: true,
        timestamp: DateTime.now(),
      );
    }
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
      outputData: {
        'id': taskId,
        'title': existing.title,
        'status': status,
        'dueDate': existing.dueDate?.toIso8601String(),
        'priority': existing.priority,
        'type': 'task',
      },
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
      outputData: {
        'id': newNoteId,
        'title': title,
        'tags': tag,
        'type': 'note',
      },
      timestamp: DateTime.now(),
    );
  }

  Future<EpiActionExecutionRecord> _executeUpdateNote(EpiActionCall action) async {
    final noteId = action.parameters['note_id']?.toString();
    if (noteId == null) throw Exception('note_id is required for update_note');

    final pinDao = ref.read(pinDaoProvider);
    final pinRepo = ref.read(pinRepositoryProvider);
    final existing = await pinDao.getPin(noteId);
    if (existing == null) throw Exception('Note $noteId not found');
    if (existing.isLocked) throw Exception('Cannot modify locked note');

    final prevPin = existing;
    final currentPayload = NoteDocument.decode(existing.content ?? '');
    var blocks = List<NoteBlock>.from(currentPayload.blocks);

    final rawTitle = action.parameters['title']?.toString();
    final title = rawTitle != null ? _stripDashes(rawTitle) : null;

    final rawMarkdown = action.parameters['markdown']?.toString();
    final markdown = rawMarkdown != null ? _stripDashes(rawMarkdown) : null;

    final rawAppend = action.parameters['append_markdown']?.toString();
    final appendMarkdown = rawAppend != null ? _stripDashes(rawAppend) : null;

    final rawTags = action.parameters['tags'] ?? action.parameters['tag'];
    final tags = rawTags is List ? rawTags.map((t) => t.toString()).join(', ') : rawTags?.toString();

    final boardId = action.parameters['board_id']?.toString();

    final updatedFields = <String>[];

    if (markdown != null) {
      final newBlocks = <NoteBlock>[];
      final effectiveTitle = title ?? NoteDocument.extractTitle(existing.content ?? '');
      if (effectiveTitle.isNotEmpty && effectiveTitle != 'Untitled Note') {
        newBlocks.add(NoteBlock(type: BlockType.heading, text: effectiveTitle));
      }
      newBlocks.addAll(NoteDocument.parseLegacyMarkdown(markdown));
      blocks = newBlocks;
      updatedFields.add('markdown');
      if (title != null) updatedFields.add('title');
    } else {
      if (title != null) {
        if (blocks.isNotEmpty && blocks.first.type == BlockType.heading) {
          blocks[0] = blocks.first.copyWith(text: title);
        } else {
          blocks.insert(0, NoteBlock(type: BlockType.heading, text: title));
        }
        updatedFields.add('title');
      }
      if (appendMarkdown != null && appendMarkdown.isNotEmpty) {
        blocks.addAll(NoteDocument.parseLegacyMarkdown(appendMarkdown));
        updatedFields.add('append_markdown');
      }
    }

    final newContentJson = NoteDocument.encode(NoteDocumentPayload(
      blocks: blocks,
      drawing: currentPayload.drawing,
    ));

    var updated = existing.copyWith(
      content: drift.Value(newContentJson),
      modifiedAt: DateTime.now(),
    );

    if (tags != null) {
      updated = updated.copyWith(tags: drift.Value(tags));
      updatedFields.add('tags');
    }

    if (boardId != null) {
      updated = updated.copyWith(boardId: drift.Value(boardId.isEmpty ? null : boardId));
      updatedFields.add('board_id');
    }

    final wasNoOp = updatedFields.isEmpty ||
        (existing.content == updated.content &&
         existing.tags == updated.tags &&
         existing.boardId == updated.boardId);

    await pinRepo.updatePin(updated);

    final finalTitle = NoteDocument.extractTitle(updated.content ?? '');

    // Record in Action Log for undo
    ref.read(epiActionLogProvider.notifier).recordAction(EpiLogEntry(
      id: action.id,
      tool: action.tool,
      tier: action.tier,
      parameters: action.parameters,
      entityId: noteId,
      summary: 'Updated note "$finalTitle"',
      timestamp: DateTime.now(),
      undoAction: () async {
        await pinRepo.updatePin(prevPin);
      },
    ));

    return EpiActionExecutionRecord(
      action: action,
      status: ActionExecutionStatus.success,
      message: 'Updated note "$finalTitle"',
      createdEntityId: noteId,
      entityIds: [noteId],
      wasNoOp: wasNoOp,
      outputData: {
        'id': noteId,
        'title': finalTitle,
        'updatedFields': updatedFields,
      },
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
    final query = action.parameters['query']?.toString().toLowerCase().trim();
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

    if (query != null && query.isNotEmpty) {
      results = results.where((t) {
        final titleMatch = t.title.toLowerCase().contains(query);
        final notesMatch = t.notes?.toLowerCase().contains(query) ?? false;
        return titleMatch || notesMatch;
      }).toList();
    }

    final matchingIds = results.map((t) => t.id).take(5).toList();
    final tasksData = results.take(10).map((t) => {
      'id': t.id,
      'title': t.title,
      'status': t.status,
      'dueDate': t.dueDate?.toIso8601String(),
      'priority': t.priority,
      'notes': t.notes,
      'type': 'task',
    }).toList();

    String message;
    if (results.isEmpty) {
      message = query != null ? 'No tasks found matching "$query"' : 'No tasks found';
    } else if (results.length == 1) {
      message = 'Found task "${results.first.title}"';
    } else {
      message = 'Found ${results.length} tasks matching query';
    }

    return EpiActionExecutionRecord(
      action: action,
      status: ActionExecutionStatus.success,
      message: message,
      entityIds: matchingIds,
      outputData: tasksData,
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
    final notesData = results.take(10).map((n) {
      final payload = NoteDocument.decode(n.content ?? '');
      final title = NoteDocument.extractTitle(n.content ?? '');
      final markdown = NoteDocument.exportToMarkdown(payload.blocks);
      return {
        'id': n.id,
        'title': title,
        'tags': n.tags,
        'content': markdown,
        'type': 'note',
      };
    }).toList();

    return EpiActionExecutionRecord(
      action: action,
      status: ActionExecutionStatus.success,
      message: results.isEmpty
          ? 'No notes found'
          : results.length == 1
              ? 'Found 1 note'
              : 'Found ${results.length} notes',
      entityIds: matchingIds,
      outputData: notesData,
      timestamp: DateTime.now(),
    );
  }

  Future<EpiActionExecutionRecord> _executeQueryBoards(EpiActionCall action) async {
    final boardDao = ref.read(boardDaoProvider);
    final allBoards = await boardDao.getAllBoards();
    final query = action.parameters['query']?.toString().toLowerCase().trim();

    var results = allBoards;
    if (query != null && query.isNotEmpty) {
      results = results.where((b) => b.title.toLowerCase().contains(query)).toList();
    }

    final matchingIds = results.map((b) => b.id).take(5).toList();
    final boardsData = results.map((b) => {
      'id': b.id,
      'title': b.title,
      'viewMode': b.defaultViewMode,
    }).toList();

    String message;
    if (results.isEmpty) {
      message = query != null ? 'No projects or boards found matching "$query"' : 'No boards found';
    } else if (results.length == 1) {
      message = 'Found project "${results.first.title}"';
    } else {
      message = 'Found ${results.length} projects: ${results.map((b) => '"${b.title}"').join(', ')}';
    }

    return EpiActionExecutionRecord(
      action: action,
      status: ActionExecutionStatus.success,
      message: message,
      entityIds: matchingIds,
      outputData: boardsData,
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
    final existingAlarm = ref.read(alarmTimerProvider).alarms.where((a) =>
      a.title.toLowerCase().trim() == title.toLowerCase().trim() &&
      a.hour == hour &&
      a.minute == minute
    ).firstOrNull;
    if (existingAlarm != null) {
      return EpiActionExecutionRecord(
        action: action,
        status: ActionExecutionStatus.success,
        message: 'Alarm "$title" for ${existingAlarm.formattedTime} is already set',
        createdEntityId: existingAlarm.id,
        entityIds: [existingAlarm.id],
        wasNoOp: true,
        timestamp: DateTime.now(),
      );
    }
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
    final activeTimer = ref.read(alarmTimerProvider).activeTimer;
    if (activeTimer.state == TimerState.running &&
        activeTimer.label != null &&
        activeTimer.label!.toLowerCase().trim() == label.toLowerCase().trim()) {
      return EpiActionExecutionRecord(
        action: action,
        status: ActionExecutionStatus.success,
        message: 'Timer for "$label" is already running',
        wasNoOp: true,
        timestamp: DateTime.now(),
      );
    }

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
    final timetableData = slots.take(10).map((s) => {
      'id': s.id,
      'title': s.title,
      'dayOfWeek': s.dayOfWeek,
      'startTime': s.startTime,
      'endTime': s.endTime,
      'location': s.location,
      'type': 'schedule',
    }).toList();

    return EpiActionExecutionRecord(
      action: action,
      status: ActionExecutionStatus.success,
      message: slots.isEmpty
          ? 'No schedule slots found'
          : slots.length == 1
              ? 'Found 1 schedule slot'
              : 'Found ${slots.length} schedule slots',
      entityIds: ids,
      outputData: timetableData,
      timestamp: DateTime.now(),
    );
  }

  Future<EpiActionExecutionRecord> _executeUpdateAboutMe(EpiActionCall action) async {
    final rawContent = action.parameters['content']?.toString() ?? '';
    final content = _stripDashes(rawContent);

    final pinDao = ref.read(pinDaoProvider);
    final allNotes = await pinDao.getAllNotes();

    PinEntity? aboutMePin;
    for (final note in allNotes) {
      if (note.isLocked) continue;
      final blocks = NoteDocument.decodeBlocks(note.content ?? '');
      if (blocks.isNotEmpty) {
        final title = blocks.first.text.trim().toLowerCase();
        if (title == 'about me' || title == '# about me') {
          aboutMePin = note;
          break;
        }
      }
    }

    final allBlocks = <NoteBlock>[
      NoteBlock(type: BlockType.heading, text: 'About Me'),
      ...NoteDocument.parseLegacyMarkdown(content),
    ];
    final contentJson = NoteDocument.encode(NoteDocumentPayload(blocks: allBlocks));

    if (aboutMePin != null) {
      final prevPin = aboutMePin;
      final updated = aboutMePin.copyWith(
        content: drift.Value(contentJson),
        modifiedAt: DateTime.now(),
      );
      await pinDao.updatePin(updated);

      ref.read(epiActionLogProvider.notifier).recordAction(EpiLogEntry(
        id: action.id,
        tool: action.tool,
        tier: action.tier,
        parameters: action.parameters,
        entityId: aboutMePin.id,
        summary: 'Updated "About Me" profile',
        timestamp: DateTime.now(),
        undoAction: () async {
          await pinDao.updatePin(prevPin);
        },
      ));

      return EpiActionExecutionRecord(
        action: action,
        status: ActionExecutionStatus.success,
        message: 'Updated "About Me" profile',
        createdEntityId: aboutMePin.id,
        entityIds: [aboutMePin.id],
        outputData: {
          'id': aboutMePin.id,
          'title': 'About Me',
          'type': 'note',
          'tags': aboutMePin.tags ?? 'Profile',
        },
        timestamp: DateTime.now(),
      );
    } else {
      final newId = DateTime.now().millisecondsSinceEpoch.toString();
      await pinDao.insertPin(PinsCompanion.insert(
        id: newId,
        type: 'note',
        content: drift.Value(contentJson),
        tags: const drift.Value('Profile'),
      ));

      ref.read(epiActionLogProvider.notifier).recordAction(EpiLogEntry(
        id: action.id,
        tool: action.tool,
        tier: action.tier,
        parameters: action.parameters,
        entityId: newId,
        summary: 'Created "About Me" profile',
        timestamp: DateTime.now(),
        undoAction: () async {
          await pinDao.deletePin(newId);
        },
      ));

      return EpiActionExecutionRecord(
        action: action,
        status: ActionExecutionStatus.success,
        message: 'Saved "About Me" profile',
        createdEntityId: newId,
        entityIds: [newId],
        outputData: {
          'id': newId,
          'title': 'About Me',
          'type': 'note',
          'tags': 'Profile',
        },
        timestamp: DateTime.now(),
      );
    }
  }

  Future<EpiActionExecutionRecord> _executeCreateScheduleSlot(EpiActionCall action) async {
    final rawTitle = action.parameters['title']?.toString() ?? 'Scheduled Block';
    final title = _stripDashes(rawTitle);
    final dayOfWeek = (action.parameters['day_of_week'] as num?)?.toInt() ?? 1;
    final startTime = action.parameters['start_time']?.toString() ?? '09:00';
    final endTime = action.parameters['end_time']?.toString() ?? '10:00';
    final location = action.parameters['location']?.toString();
    final rawNotes = action.parameters['notes']?.toString();
    final notes = rawNotes != null ? _stripDashes(rawNotes) : null;

    final newSlotId = DateTime.now().millisecondsSinceEpoch.toString();
    final timetableDao = ref.read(timetableDaoProvider);

    final existingSlots = await timetableDao.getAllSlots();
    final existingSlot = existingSlots.where((s) =>
      s.title.toLowerCase().trim() == title.toLowerCase().trim() &&
      s.dayOfWeek == dayOfWeek &&
      s.startTime == startTime
    ).firstOrNull;
    if (existingSlot != null) {
      return EpiActionExecutionRecord(
        action: action,
        status: ActionExecutionStatus.success,
        message: 'Schedule slot "$title" ($startTime - $endTime) already exists',
        createdEntityId: existingSlot.id,
        entityIds: [existingSlot.id],
        wasNoOp: true,
        timestamp: DateTime.now(),
      );
    }

    await timetableDao.insertSlot(TimetableSlotsCompanion.insert(
      id: newSlotId,
      title: title,
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
      location: location != null ? drift.Value(location) : const drift.Value.absent(),
      notes: notes != null ? drift.Value(notes) : const drift.Value.absent(),
    ));

    ref.read(epiActionLogProvider.notifier).recordAction(EpiLogEntry(
      id: action.id,
      tool: action.tool,
      tier: action.tier,
      parameters: action.parameters,
      entityId: newSlotId,
      summary: 'Scheduled "$title" ($startTime - $endTime)',
      timestamp: DateTime.now(),
      undoAction: () async {
        await timetableDao.deleteSlot(newSlotId);
      },
    ));

    return EpiActionExecutionRecord(
      action: action,
      status: ActionExecutionStatus.success,
      message: 'Scheduled "$title" ($startTime - $endTime)',
      createdEntityId: newSlotId,
      entityIds: [newSlotId],
      outputData: {
        'id': newSlotId,
        'title': title,
        'dayOfWeek': dayOfWeek,
        'startTime': startTime,
        'endTime': endTime,
        'location': location,
        'type': 'schedule',
      },
      timestamp: DateTime.now(),
    );
  }

  Future<EpiActionExecutionRecord> _executeUpdateScheduleSlot(EpiActionCall action) async {
    final slotId = action.parameters['slot_id']?.toString();
    if (slotId == null) throw Exception('slot_id is required for update_schedule_slot');

    final timetableDao = ref.read(timetableDaoProvider);
    final allSlots = await timetableDao.getAllSlots();
    final existing = allSlots.where((s) => s.id == slotId).firstOrNull;
    if (existing == null) throw Exception('Schedule slot $slotId not found');

    final prevSlot = existing;

    final rawTitle = action.parameters['title']?.toString();
    final title = rawTitle != null ? _stripDashes(rawTitle) : existing.title;

    final dayOfWeek = (action.parameters['day_of_week'] as num?)?.toInt() ?? existing.dayOfWeek;
    final startTime = action.parameters['start_time']?.toString() ?? existing.startTime;
    final endTime = action.parameters['end_time']?.toString() ?? existing.endTime;

    final rawLoc = action.parameters['location'];
    final location = rawLoc != null ? rawLoc.toString() : existing.location;

    final rawNotes = action.parameters['notes'];
    final notes = rawNotes != null ? _stripDashes(rawNotes.toString()) : existing.notes;

    final updatedFields = <String>[];
    if (rawTitle != null && rawTitle != existing.title) updatedFields.add('title');
    if (action.parameters['day_of_week'] != null && dayOfWeek != existing.dayOfWeek) updatedFields.add('day_of_week');
    if (action.parameters['start_time'] != null && startTime != existing.startTime) updatedFields.add('start_time');
    if (action.parameters['end_time'] != null && endTime != existing.endTime) updatedFields.add('end_time');
    if (rawLoc != null && location != existing.location) updatedFields.add('location');
    if (rawNotes != null && notes != existing.notes) updatedFields.add('notes');

    // Overlap conflict detection against other slots on target day
    TimetableSlotEntity? conflictSlot;
    for (final other in allSlots) {
      if (other.id == slotId) continue;
      if (other.dayOfWeek != dayOfWeek) continue;
      if (startTime.compareTo(other.endTime) < 0 && endTime.compareTo(other.startTime) > 0) {
        conflictSlot = other;
        break;
      }
    }

    final updatedSlot = existing.copyWith(
      title: title,
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
      location: drift.Value(location),
      notes: drift.Value(notes),
    );

    final wasNoOp = updatedFields.isEmpty;

    await timetableDao.updateSlot(updatedSlot);

    ref.read(epiActionLogProvider.notifier).recordAction(EpiLogEntry(
      id: action.id,
      tool: action.tool,
      tier: action.tier,
      parameters: action.parameters,
      entityId: slotId,
      summary: 'Updated schedule slot "$title"',
      timestamp: DateTime.now(),
      undoAction: () async {
        await timetableDao.updateSlot(prevSlot);
      },
    ));

    var msg = 'Updated schedule slot "$title" ($startTime - $endTime)';
    if (conflictSlot != null) {
      msg += ' (Notice: overlaps with "${conflictSlot.title}" ${conflictSlot.startTime}-${conflictSlot.endTime})';
    }

    return EpiActionExecutionRecord(
      action: action,
      status: ActionExecutionStatus.success,
      message: msg,
      createdEntityId: slotId,
      entityIds: [slotId],
      wasNoOp: wasNoOp,
      outputData: {
        'id': slotId,
        'title': title,
        'dayOfWeek': dayOfWeek,
        'startTime': startTime,
        'endTime': endTime,
        'location': location,
        'type': 'schedule',
        'updatedFields': updatedFields,
        if (conflictSlot != null)
          'conflict': {
            'title': conflictSlot.title,
            'dayOfWeek': conflictSlot.dayOfWeek,
            'startTime': conflictSlot.startTime,
            'endTime': conflictSlot.endTime,
          },
      },
      timestamp: DateTime.now(),
    );
  }

  Future<EpiActionExecutionRecord> _executeDeleteScheduleSlot(EpiActionCall action) async {
    final slotId = action.parameters['slot_id']?.toString();
    if (slotId == null) throw Exception('slot_id is required');

    final timetableDao = ref.read(timetableDaoProvider);
    final allSlots = await timetableDao.getAllSlots();
    final existing = allSlots.where((s) => s.id == slotId).firstOrNull;
    if (existing == null) throw Exception('Schedule slot $slotId not found');

    await timetableDao.deleteSlot(slotId);

    ref.read(epiActionLogProvider.notifier).recordAction(EpiLogEntry(
      id: action.id,
      tool: action.tool,
      tier: action.tier,
      parameters: action.parameters,
      entityId: slotId,
      summary: 'Deleted schedule slot "${existing.title}"',
      timestamp: DateTime.now(),
      undoAction: () async {
        await timetableDao.insertSlot(TimetableSlotsCompanion.insert(
          id: existing.id,
          title: existing.title,
          dayOfWeek: existing.dayOfWeek,
          startTime: existing.startTime,
          endTime: existing.endTime,
          location: drift.Value(existing.location),
          notes: drift.Value(existing.notes),
        ));
      },
    ));

    return EpiActionExecutionRecord(
      action: action,
      status: ActionExecutionStatus.success,
      message: 'Deleted schedule slot "${existing.title}"',
      entityIds: [slotId],
      timestamp: DateTime.now(),
    );
  }

  Future<EpiActionExecutionRecord> _executeCreateBoard(EpiActionCall action) async {
    final rawTitle = action.parameters['title']?.toString() ?? 'New Project';
    final title = _stripDashes(rawTitle);
    final viewMode = action.parameters['view_mode']?.toString() ?? 'canvas';

    final boardRepo = ref.read(boardRepositoryProvider);
    final allBoards = await boardRepo.getAllBoards();
    final existing = allBoards.where((b) => b.title.toLowerCase().trim() == title.toLowerCase().trim()).firstOrNull;
    if (existing != null) {
      return EpiActionExecutionRecord(
        action: action,
        status: ActionExecutionStatus.success,
        message: 'Project "$title" already exists',
        createdEntityId: existing.id,
        entityIds: [existing.id],
        wasNoOp: true,
        timestamp: DateTime.now(),
      );
    }

    final newBoardId = DateTime.now().millisecondsSinceEpoch.toString();
    await boardRepo.createBoard(BoardsCompanion.insert(
      id: newBoardId,
      title: title,
      defaultViewMode: drift.Value(viewMode),
    ));

    ref.read(epiActionLogProvider.notifier).recordAction(EpiLogEntry(
      id: action.id,
      tool: action.tool,
      tier: action.tier,
      parameters: action.parameters,
      entityId: newBoardId,
      summary: 'Created project "$title"',
      timestamp: DateTime.now(),
      undoAction: () async {
        await boardRepo.deleteBoard(newBoardId);
      },
    ));

    return EpiActionExecutionRecord(
      action: action,
      status: ActionExecutionStatus.success,
      message: 'Created project "$title"',
      createdEntityId: newBoardId,
      entityIds: [newBoardId],
      timestamp: DateTime.now(),
    );
  }

  Future<EpiActionExecutionRecord> _executeDeleteBoard(EpiActionCall action) async {
    final boardId = action.parameters['board_id']?.toString();
    if (boardId == null) throw Exception('board_id is required');

    final boardRepo = ref.read(boardRepositoryProvider);
    final existing = await boardRepo.getBoard(boardId);
    final title = existing?.title ?? 'Project';

    await boardRepo.deleteBoard(boardId);

    ref.read(epiActionLogProvider.notifier).recordAction(EpiLogEntry(
      id: action.id,
      tool: action.tool,
      tier: action.tier,
      parameters: action.parameters,
      entityId: boardId,
      summary: 'Deleted project "$title"',
      timestamp: DateTime.now(),
      undoAction: () async {
        if (existing != null) {
          await boardRepo.createBoard(BoardsCompanion.insert(
            id: existing.id,
            title: existing.title,
            defaultViewMode: drift.Value(existing.defaultViewMode),
          ));
        }
      },
    ));

    return EpiActionExecutionRecord(
      action: action,
      status: ActionExecutionStatus.success,
      message: 'Deleted project "$title"',
      entityIds: [boardId],
      timestamp: DateTime.now(),
    );
  }

  Future<EpiActionExecutionRecord> _executeSetRecurrence(EpiActionCall action) async {
    final taskId = action.parameters['task_id']?.toString();
    if (taskId == null) throw Exception('task_id is required');
    final rule = action.parameters['rule']?.toString() ?? 'weekly';

    final taskDao = ref.read(taskDaoProvider);
    final taskRepo = ref.read(taskRepositoryProvider);
    final existing = await taskDao.getTask(taskId);
    if (existing == null) throw Exception('Task $taskId not found');

    if (existing.recurrenceRule == rule) {
      return EpiActionExecutionRecord(
        action: action,
        status: ActionExecutionStatus.success,
        message: 'Task "${existing.title}" is already set to repeat $rule',
        createdEntityId: taskId,
        entityIds: [taskId],
        wasNoOp: true,
        timestamp: DateTime.now(),
      );
    }

    final prevRule = existing.recurrenceRule;
    final updated = existing.copyWith(
      recurrenceRule: drift.Value(rule == 'none' ? null : rule),
      modifiedAt: DateTime.now(),
    );
    await taskRepo.updateTask(updated);

    ref.read(epiActionLogProvider.notifier).recordAction(EpiLogEntry(
      id: action.id,
      tool: action.tool,
      tier: action.tier,
      parameters: action.parameters,
      entityId: taskId,
      summary: 'Set recurrence to $rule on "${existing.title}"',
      timestamp: DateTime.now(),
      undoAction: () async {
        await taskRepo.updateTask(existing.copyWith(recurrenceRule: drift.Value(prevRule)));
      },
    ));

    return EpiActionExecutionRecord(
      action: action,
      status: ActionExecutionStatus.success,
      message: 'Set recurrence to $rule for "${existing.title}"',
      createdEntityId: taskId,
      entityIds: [taskId],
      timestamp: DateTime.now(),
    );
  }

  Future<EpiActionExecutionRecord> _executeGetProductivityReport(EpiActionCall action) async {
    final taskDao = ref.read(taskDaoProvider);
    final allTasks = await taskDao.getAllTasks();
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    final completedThisWeek = allTasks.where((t) =>
      t.status == 'done' && t.modifiedAt.isAfter(sevenDaysAgo)
    ).toList();
    final activeTasks = allTasks.where((t) => t.status != 'done').toList();
    final overdueTasks = activeTasks.where((t) => t.dueDate != null && t.dueDate!.isBefore(now)).toList();
    final total = allTasks.length;
    final completionPct = total > 0 ? ((completedThisWeek.length / total) * 100).round() : 0;

    final reportData = {
      'completedPast7Days': completedThisWeek.length,
      'completedTitles': completedThisWeek.map((t) => t.title).take(5).toList(),
      'activeTasks': activeTasks.length,
      'overdueTasks': overdueTasks.length,
      'completionRate': '$completionPct%',
    };

    return EpiActionExecutionRecord(
      action: action,
      status: ActionExecutionStatus.success,
      message: '${completedThisWeek.length} completed this week, ${activeTasks.length} active, ${overdueTasks.length} overdue',
      entityIds: completedThisWeek.map((t) => t.id).take(5).toList(),
      outputData: reportData,
      timestamp: DateTime.now(),
    );
  }

  Future<EpiActionExecutionRecord> _executeWipeThread(EpiActionCall action) async {
    ref.read(epiChatProvider.notifier).clearChat();
    return EpiActionExecutionRecord(
      action: action,
      status: ActionExecutionStatus.success,
      message: 'Wiped chat thread for a fresh start',
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
