import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;

import '../../core/theme.dart';
import '../../data/database/database.dart';
import '../../data/repository/task_repository.dart';
import '../../data/repository/board_repository.dart';
import '../../data/providers.dart';
import '../../domain/models/task_subitem.dart';
import '../widgets/core/custom_circular_checkbox.dart';
import '../widgets/timer_picker_popover.dart';

class TaskFocusScreen extends ConsumerStatefulWidget {
  final String taskId;
  const TaskFocusScreen({super.key, required this.taskId});

  @override
  ConsumerState<TaskFocusScreen> createState() => _TaskFocusScreenState();
}

class _TaskFocusScreenState extends ConsumerState<TaskFocusScreen> {
  final _newSubtaskController = TextEditingController();
  final FocusNode _newSubtaskFocusNode = FocusNode();

  TaskEntity? _task;
  TaskNotesPayload? _notesPayload;
  List<TaskSubitem> _subitems = [];
  bool _isLoading = true;
  bool? _isGridView;
  int? _hoveredDropTargetIndex;

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  @override
  void dispose() {
    _newSubtaskController.dispose();
    _newSubtaskFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadTask() async {
    setState(() => _isLoading = true);
    final task = await ref.read(taskDaoProvider).getTask(widget.taskId);
    if (task != null && mounted) {
      final decoded = TaskSubitem.decodeNotes(task.notes);
      setState(() {
        _task = task;
        _notesPayload = decoded;
        _subitems = List.from(decoded.subitems);
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _persistSubitems(List<TaskSubitem> updatedList) async {
    if (_task == null) return;
    final userNotes = _notesPayload?.userNotes;
    final encoded = TaskSubitem.encodeNotes(
      userNotes: userNotes,
      subitems: updatedList,
    );

    final allDone = updatedList.isNotEmpty && updatedList.every((s) => s.isDone);
    final anyDone = updatedList.any((s) => s.isDone);
    final newStatus = allDone
        ? 'done'
        : (anyDone ? 'in_progress' : (_task!.status == 'done' ? 'todo' : _task!.status));

    final updatedTask = _task!.copyWith(
      notes: encoded.isNotEmpty ? drift.Value(encoded) : const drift.Value.absent(),
      status: newStatus,
    );

    setState(() {
      _task = updatedTask;
      _subitems = List.from(updatedList);
      _notesPayload = TaskNotesPayload(userNotes: userNotes, subitems: updatedList);
    });

    await ref.read(taskRepositoryProvider).updateTask(updatedTask);
  }

  void _toggleSubitem(int index) {
    if (index < 0 || index >= _subitems.length) return;
    HapticFeedback.selectionClick();
    final updated = List<TaskSubitem>.from(_subitems);
    final current = updated[index];
    updated[index] = current.copyWith(isDone: !current.isDone);
    _persistSubitems(updated);
  }

  void _reorderSubitems(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _subitems.length) return;
    if (newIndex < 0 || newIndex >= _subitems.length) return;
    if (oldIndex == newIndex) return;

    HapticFeedback.mediumImpact();
    final updated = List<TaskSubitem>.from(_subitems);
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    _persistSubitems(updated);
  }

  void _deleteSubitem(int index) {
    if (index < 0 || index >= _subitems.length) return;
    HapticFeedback.lightImpact();
    final updated = List<TaskSubitem>.from(_subitems);
    updated.removeAt(index);
    _persistSubitems(updated);
  }

  Future<void> _editSubitemDialog(int index) async {
    if (index < 0 || index >= _subitems.length) return;
    final item = _subitems[index];
    final controller = TextEditingController(text: item.title);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final activeBlue = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600;

    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit Subtask', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: textPrimary),
          decoration: const InputDecoration(
            hintText: 'Subtask title...',
            isDense: true,
          ),
          onSubmitted: (val) => Navigator.of(ctx).pop(val.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: activeBlue, foregroundColor: Colors.white),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newTitle != null && newTitle.isNotEmpty && newTitle != item.title) {
      final updated = List<TaskSubitem>.from(_subitems);
      updated[index] = item.copyWith(title: newTitle);
      _persistSubitems(updated);
    }
  }

  void _addNewSubtask() {
    final text = _newSubtaskController.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();
    final newId = '${DateTime.now().millisecondsSinceEpoch}_${_subitems.length}';
    final newItem = TaskSubitem(id: newId, title: text, isDone: false);
    final updated = List<TaskSubitem>.from(_subitems)..add(newItem);

    _newSubtaskController.clear();
    _persistSubitems(updated);
    _newSubtaskFocusNode.requestFocus();
  }

  Future<void> _updateStatus(String status) async {
    if (_task == null) return;
    HapticFeedback.selectionClick();
    final updated = _task!.copyWith(status: status);
    setState(() => _task = updated);
    await ref.read(taskRepositoryProvider).updateTask(updated);
  }

  String _formatDueDate(DateTime? date) {
    if (date == null) return 'No due date';
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.month}/${date.day}/${date.year} $hour:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgApp = isDark ? EpicordiaColors.surfaceAppDark : EpicordiaColors.surfaceAppLight;
    final cardBg = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;
    final borderClr = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;
    final activeBlue = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600;
    final successClr = isDark ? EpicordiaColors.successDark : EpicordiaColors.successLight;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgApp,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_task == null) {
      return Scaffold(
        backgroundColor: bgApp,
        appBar: AppBar(
          backgroundColor: bgApp,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textPrimary),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: textTertiary),
              const SizedBox(height: 12),
              Text('Task not found', style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: () => context.pop(), child: const Text('Go Back')),
            ],
          ),
        ),
      );
    }

    final boardsAsync = ref.watch(allBoardsProvider);
    final boards = boardsAsync.value ?? [];
    final board = boards.cast<BoardEntity?>().firstWhere((b) => b?.id == _task!.boardId, orElse: () => null);
    final boardTitle = board?.title ?? 'Inbox';
    final boardColor = board != null
        ? const Color(0xFF6B7FA0)
        : EpicordiaColors.blue600;

    final completedCount = _subitems.where((s) => s.isDone).length;
    final totalCount = _subitems.length;
    final progress = totalCount == 0 ? 0.0 : completedCount / totalCount;
    final isCompleted = _task!.status == 'done';
    final isOverdue = _task!.status != 'done' && _task!.dueDate != null && _task!.dueDate!.isBefore(DateTime.now());

    return Scaffold(
      backgroundColor: bgApp,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: AppBar(
          backgroundColor: bgApp,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: textPrimary, size: 22),
            tooltip: 'Back',
            onPressed: () => context.pop(),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: activeBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.center_focus_strong_rounded, size: 14, color: activeBlue),
                    const SizedBox(width: 5),
                    Text(
                      'FOCUS MODE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: activeBlue,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  _task!.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.timer_outlined, color: activeBlue, size: 20),
              tooltip: 'Start Focus Timer / Alarm',
              onPressed: () {
                TimerPickerPopover.show(context, taskTitle: _task!.title);
              },
            ),
            IconButton(
              icon: Icon(Icons.edit_outlined, color: textSecondary, size: 20),
              tooltip: 'Edit Task',
              onPressed: () => context.push('/task/${_task!.id}'),
            ),
            const SizedBox(width: 6),
          ],
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
            final showGrid = _isGridView ?? isWide;

            return Column(
              children: [
                // ── Task Header & Progress Card ──────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 16, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderClr),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Progress Ring
                            SizedBox(
                              width: 52,
                              height: 52,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: progress,
                                    strokeWidth: 4.5,
                                    backgroundColor: isDark ? borderClr : borderClr.withValues(alpha: 0.5),
                                    valueColor: AlwaysStoppedAnimation<Color>(progress == 1.0 ? successClr : activeBlue),
                                  ),
                                  Text(
                                    '${(progress * 100).toInt()}%',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _task!.title,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: textPrimary,
                                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                                      decorationColor: textTertiary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: boardColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          boardTitle,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: boardColor,
                                          ),
                                        ),
                                      ),
                                      if (_task!.dueDate != null) ...[
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.access_time_rounded,
                                              size: 13,
                                              color: isOverdue ? EpicordiaColors.errorLight : textTertiary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _formatDueDate(_task!.dueDate),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isOverdue ? EpicordiaColors.errorLight : textTertiary,
                                                fontWeight: isOverdue ? FontWeight.w700 : FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      Text(
                                        '$completedCount / $totalCount subtasks done',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Optional Notes text
                        if (_notesPayload?.userNotes != null && _notesPayload!.userNotes!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? EpicordiaColors.surfaceSunkenDark : EpicordiaColors.surfaceSunkenLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _notesPayload!.userNotes!,
                              style: TextStyle(fontSize: 12, color: textSecondary, height: 1.3),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],

                        const SizedBox(height: 12),
                        Divider(height: 1, color: borderClr),
                        const SizedBox(height: 10),

                        // Status Selection Chips
                        Row(
                          children: [
                            Text(
                              'Status:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary),
                            ),
                            const SizedBox(width: 8),
                            Wrap(
                              spacing: 6,
                              children: [
                                ('todo', 'To Do', Icons.radio_button_unchecked, activeBlue),
                                ('in_progress', 'In Progress', Icons.pending_outlined, const Color(0xFFF59E0B)),
                                ('done', 'Done', Icons.check_circle_outline, successClr),
                              ].map((item) {
                                final (sKey, sLabel, sIcon, sColor) = item;
                                final isSel = _task!.status == sKey;
                                return InkWell(
                                  onTap: () => _updateStatus(sKey),
                                  borderRadius: BorderRadius.circular(14),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 160),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isSel ? sColor : Colors.transparent,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSel ? sColor : borderClr,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(sIcon, size: 12, color: isSel ? Colors.white : textSecondary),
                                        const SizedBox(width: 4),
                                        Text(
                                          sLabel,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                            color: isSel ? Colors.white : textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Subtask List / Grid Header & Layout Switcher ────
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 16, vertical: 6),
                  child: Row(
                    children: [
                      Text(
                        'Subtasks & Checklist',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? EpicordiaColors.surfaceSunkenDark : EpicordiaColors.surfaceSunkenLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_subitems.length}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textSecondary),
                        ),
                      ),
                      const Spacer(),

                      // List / Grid View Toggle Switcher
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isDark ? EpicordiaColors.surfaceSunkenDark : EpicordiaColors.surfaceSunkenLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderClr),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () => setState(() => _isGridView = false),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: !showGrid ? activeBlue : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.view_list_rounded,
                                      size: 15,
                                      color: !showGrid ? Colors.white : textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'List',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: !showGrid ? FontWeight.w700 : FontWeight.w500,
                                        color: !showGrid ? Colors.white : textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => setState(() => _isGridView = true),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: showGrid ? activeBlue : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.grid_view_rounded,
                                      size: 14,
                                      color: showGrid ? Colors.white : textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Grid',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: showGrid ? FontWeight.w700 : FontWeight.w500,
                                        color: showGrid ? Colors.white : textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Main Content: List or Grid (both reorderable) ────
                Expanded(
                  child: _subitems.isEmpty
                      ? _buildEmptyState(textPrimary, textSecondary, textTertiary, activeBlue)
                      : showGrid
                          ? _buildWideGridView(isDark, cardBg, textPrimary, textSecondary, textTertiary, borderClr, activeBlue, successClr)
                          : _buildNarrowListView(isDark, cardBg, textPrimary, textSecondary, textTertiary, borderClr, activeBlue, successClr, isWide),
                ),

                // ── Quick Add Subtask Bar ────────────────────────────
                Container(
                  padding: EdgeInsets.fromLTRB(isWide ? 24 : 16, 10, isWide ? 24 : 16, 16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border(top: BorderSide(color: borderClr)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _newSubtaskController,
                          focusNode: _newSubtaskFocusNode,
                          style: TextStyle(color: textPrimary, fontSize: 14),
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _addNewSubtask(),
                          decoration: InputDecoration(
                            hintText: 'Add a subtask to focus on...',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderClr),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderClr),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: activeBlue, width: 1.5),
                            ),
                            filled: true,
                            fillColor: isDark ? EpicordiaColors.surfaceSunkenDark : EpicordiaColors.surfaceSunkenLight,
                            hintStyle: TextStyle(color: textTertiary, fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _addNewSubtask,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: activeBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, size: 18),
                            SizedBox(width: 4),
                            Text('Add', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Reorderable Ordered List View ──────────────────────────────
  Widget _buildNarrowListView(
    bool isDark,
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
    Color textTertiary,
    Color borderClr,
    Color activeBlue,
    Color successClr,
    bool isWide,
  ) {
    return ReorderableListView.builder(
      padding: EdgeInsets.fromLTRB(isWide ? 24 : 16, 4, isWide ? 24 : 16, 16),
      itemCount: _subitems.length,
      buildDefaultDragHandles: false,
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex -= 1;
        _reorderSubitems(oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final item = _subitems[index];
        final isDone = item.isDone;

        return Container(
          key: ValueKey(item.id),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDone
                ? (isDark ? EpicordiaColors.surfaceSunkenDark.withValues(alpha: 0.5) : EpicordiaColors.surfaceSunkenLight)
                : cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDone ? borderClr.withValues(alpha: 0.5) : borderClr,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Order Number Badge
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isDone
                      ? successClr.withValues(alpha: 0.15)
                      : activeBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isDone ? successClr : activeBlue,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Circular Checkbox
              CustomCircularCheckbox(
                isChecked: isDone,
                onTap: () => _toggleSubitem(index),
                size: 20,
                activeColor: successClr,
                borderColor: textTertiary,
              ),
              const SizedBox(width: 12),

              // Title (Editable on tap)
              Expanded(
                child: InkWell(
                  onTap: () => _editSubitemDialog(index),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDone ? textTertiary : textPrimary,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        decorationColor: textTertiary,
                        fontWeight: isDone ? FontWeight.normal : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

              // Edit icon
              IconButton(
                icon: Icon(Icons.edit_outlined, size: 16, color: textTertiary),
                onPressed: () => _editSubitemDialog(index),
                visualDensity: VisualDensity.compact,
                tooltip: 'Edit text',
              ),

              // Delete cross button
              IconButton(
                icon: Icon(Icons.close, size: 18, color: textTertiary),
                onPressed: () => _deleteSubitem(index),
                visualDensity: VisualDensity.compact,
                tooltip: 'Remove',
              ),

              // Drag Handle
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Icon(Icons.drag_indicator_rounded, size: 20, color: textTertiary),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Reorderable Grid View ──────────────────────────────────────
  Widget _buildWideGridView(
    bool isDark,
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
    Color textTertiary,
    Color borderClr,
    Color activeBlue,
    Color successClr,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900
            ? 3
            : (constraints.maxWidth > 500 ? 2 : 1);
        final ratio = constraints.maxWidth < 500 ? 2.8 : 2.3;

        return GridView.builder(
          padding: EdgeInsets.fromLTRB(
            constraints.maxWidth >= 600 ? 24 : 16,
            8,
            constraints.maxWidth >= 600 ? 24 : 16,
            24,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: ratio,
          ),
          itemCount: _subitems.length,
          itemBuilder: (context, index) {
            final item = _subitems[index];
            final isDone = item.isDone;

            return DragTarget<int>(
              onWillAcceptWithDetails: (details) {
                setState(() => _hoveredDropTargetIndex = index);
                return details.data != index;
              },
              onLeave: (data) {
                if (_hoveredDropTargetIndex == index) {
                  setState(() => _hoveredDropTargetIndex = null);
                }
              },
              onAcceptWithDetails: (details) {
                setState(() => _hoveredDropTargetIndex = null);
                _reorderSubitems(details.data, index);
              },
              builder: (context, candidateData, rejectedData) {
                final isTarget = _hoveredDropTargetIndex == index && candidateData.isNotEmpty;

                return LongPressDraggable<int>(
                  data: index,
                  feedback: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.transparent,
                    child: Container(
                      width: (constraints.maxWidth - 48 - (crossAxisCount - 1) * 14) / crossAxisCount,
                      height: 100,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: activeBlue, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: activeBlue.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                '#${index + 1}',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: activeBlue),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.3,
                    child: _buildGridItemCard(
                      index: index,
                      item: item,
                      isDone: isDone,
                      isDark: isDark,
                      cardBg: cardBg,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      textTertiary: textTertiary,
                      borderClr: borderClr,
                      activeBlue: activeBlue,
                      successClr: successClr,
                      isTarget: false,
                    ),
                  ),
                  child: _buildGridItemCard(
                    index: index,
                    item: item,
                    isDone: isDone,
                    isDark: isDark,
                    cardBg: cardBg,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    textTertiary: textTertiary,
                    borderClr: borderClr,
                    activeBlue: activeBlue,
                    successClr: successClr,
                    isTarget: isTarget,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildGridItemCard({
    required int index,
    required TaskSubitem item,
    required bool isDone,
    required bool isDark,
    required Color cardBg,
    required Color textPrimary,
    required Color textSecondary,
    required Color textTertiary,
    required Color borderClr,
    required Color activeBlue,
    required Color successClr,
    required bool isTarget,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDone
            ? (isDark ? EpicordiaColors.surfaceSunkenDark.withValues(alpha: 0.5) : EpicordiaColors.surfaceSunkenLight)
            : cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isTarget
              ? activeBlue
              : (isDone ? borderClr.withValues(alpha: 0.5) : borderClr),
          width: isTarget ? 2 : 1,
        ),
        boxShadow: isTarget
            ? [
                BoxShadow(
                  color: activeBlue.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Number Badge, Drag hint icon, Edit and Delete
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDone
                      ? successClr.withValues(alpha: 0.15)
                      : activeBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '#${index + 1}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isDone ? successClr : activeBlue,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.drag_indicator_rounded, size: 16, color: textTertiary),
              const Spacer(),
              InkWell(
                onTap: () => _editSubitemDialog(index),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Icon(Icons.edit_outlined, size: 15, color: textTertiary),
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: () => _deleteSubitem(index),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Icon(Icons.close, size: 16, color: textTertiary),
                ),
              ),
            ],
          ),
          const Spacer(),

          // Middle Row: Circular Checkbox + Title
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CustomCircularCheckbox(
                isChecked: isDone,
                onTap: () => _toggleSubitem(index),
                size: 20,
                activeColor: successClr,
                borderColor: textTertiary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () => _editSubitemDialog(index),
                  borderRadius: BorderRadius.circular(4),
                  child: Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDone ? textTertiary : textPrimary,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      decorationColor: textTertiary,
                      fontWeight: isDone ? FontWeight.normal : FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color textPrimary, Color textSecondary, Color textTertiary, Color activeBlue) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: activeBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.playlist_add_check_rounded, size: 36, color: activeBlue),
            ),
            const SizedBox(height: 16),
            Text(
              'No subtasks yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Break this task down into bite-sized actionable steps below.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
