import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../data/database/database.dart';
import '../../data/providers.dart';
import '../../data/repository/task_repository.dart';
import '../../data/repository/pin_repository.dart';
import '../../domain/models/note_model.dart';
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
      message: 'Found ${results.length} task(s)',
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
      message: 'Found ${results.length} note(s)',
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
