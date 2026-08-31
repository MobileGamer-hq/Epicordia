import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/theme.dart';
import '../../../data/database/database.dart';
import '../../../data/repository/task_repository.dart';
import '../../../domain/models/task_subitem.dart';
import 'epicordia_card.dart';
import 'item_interaction_dialogs.dart';
import 'custom_circular_checkbox.dart';

class InteractiveTaskCard extends ConsumerStatefulWidget {
  final TaskEntity task;
  final String boardTitle;
  final Color boardColor;
  final String? dueFormatted;
  final bool isOverdue;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;
  final VoidCallback? onLongPress;
  final VoidCallback? onDoubleTap;

  const InteractiveTaskCard({
    super.key,
    required this.task,
    required this.boardTitle,
    required this.boardColor,
    this.dueFormatted,
    this.isOverdue = false,
    this.onTap,
    this.onToggle,
    this.onLongPress,
    this.onDoubleTap,
  });

  @override
  ConsumerState<InteractiveTaskCard> createState() => _InteractiveTaskCardState();
}

class _InteractiveTaskCardState extends ConsumerState<InteractiveTaskCard> {
  bool _isExpanded = false;

  String _formatDue(DateTime? date) {
    if (date == null) return 'No due date';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(date.year, date.month, date.day);

    if (due == today) {
      final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
      final ampm = date.hour >= 12 ? 'PM' : 'AM';
      final minute = date.minute.toString().padLeft(2, '0');
      return 'Due: Today, $hour:$minute $ampm';
    } else if (due.isBefore(today)) {
      return 'Due: Overdue (${date.month}/${date.day})';
    } else {
      return 'Due: ${date.month}/${date.day}';
    }
  }

  void _toggleSubitem(TaskNotesPayload payload, int index) {
    final subitems = List<TaskSubitem>.from(payload.subitems);
    final current = subitems[index];
    subitems[index] = current.copyWith(isDone: !current.isDone);

    final updatedNotes = TaskSubitem.encodeNotes(
      userNotes: payload.userNotes,
      subitems: subitems,
    );

    // Auto-update overall task status if subitems are completed
    final allDone = subitems.isNotEmpty && subitems.every((s) => s.isDone);
    final anyDone = subitems.any((s) => s.isDone);
    final newStatus = allDone
        ? 'done'
        : (anyDone ? 'in_progress' : (widget.task.status == 'done' ? 'todo' : widget.task.status));

    ref.read(taskRepositoryProvider).updateTask(
          widget.task.copyWith(
            notes: updatedNotes.isNotEmpty ? drift.Value(updatedNotes) : const drift.Value.absent(),
            status: newStatus,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final isCompleted = task.status == 'done';
    final isInProgress = task.status == 'in_progress';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;
    final borderStrong = isDark ? EpicordiaColors.borderStrongDark : EpicordiaColors.borderStrongLight;
    final borderSubtle = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;
    final successClr = isDark ? EpicordiaColors.successDark : EpicordiaColors.successLight;
    final errorClr = isDark ? EpicordiaColors.errorDark : EpicordiaColors.errorLight;
    final activeBlue = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600;
    final inProgressClr = const Color(0xFFF59E0B);

    final formattedDueDate = widget.dueFormatted ?? _formatDue(task.dueDate);
    final computedOverdue = widget.isOverdue || (task.status != 'done' && task.dueDate != null && task.dueDate!.isBefore(DateTime.now()));

    final notesPayload = TaskSubitem.decodeNotes(task.notes);
    final subitems = notesPayload.subitems;

    // Filter items to display based on compact vs expanded state
    final visibleSubitems = _isExpanded ? subitems : subitems.take(3).toList();

    return GestureDetector(
      onTap: widget.onTap ?? () => context.push('/task/${task.id}'),
      onLongPress: widget.onLongPress ??
          () => ItemInteractionDialogs.showTaskDetailDialog(
                context: context,
                ref: ref,
                task: task,
                boardTitle: widget.boardTitle,
                boardColor: widget.boardColor,
              ),
      onDoubleTap: widget.onDoubleTap ??
          () => ItemInteractionDialogs.showDoubleTapMenu(
                context: context,
                title: task.title,
                subtitle: 'Task in ${widget.boardTitle}',
                items: [
                  DoubleTapMenuItem(
                    icon: Icons.center_focus_strong_rounded,
                    label: 'Focus Mode',
                    onTap: () => context.push('/task/${task.id}/focus'),
                  ),
                  DoubleTapMenuItem(
                    icon: isCompleted ? Icons.undo_rounded : Icons.check_circle_outline,
                    label: isCompleted ? 'Mark as To Do' : 'Mark as Complete',
                    onTap: () {
                      final next = isCompleted ? 'todo' : 'done';
                      ref.read(taskRepositoryProvider).updateTask(task.copyWith(status: next));
                    },
                  ),
                  DoubleTapMenuItem(
                    icon: Icons.edit_outlined,
                    label: 'Edit Task & Subtasks',
                    onTap: () => context.push('/task/${task.id}'),
                  ),
                  DoubleTapMenuItem(
                    icon: Icons.copy_rounded,
                    label: 'Copy Task',
                    onTap: () {
                      final statusStr = isCompleted ? 'Completed' : (isInProgress ? 'In Progress' : 'To Do');
                      ItemInteractionDialogs.copyToClipboard(
                        context,
                        'Task: ${task.title}\nStatus: $statusStr\nBoard: ${widget.boardTitle}\nNotes: ${notesPayload.userNotes ?? ''}',
                      );
                    },
                  ),
                  DoubleTapMenuItem(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete Task',
                    color: EpicordiaColors.errorLight,
                    onTap: () async {
                      await ref.read(taskRepositoryProvider).deleteTask(task.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Task deleted'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
      child: EpicordiaCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: GestureDetector(
                    onTap: widget.onToggle ??
                        () {
                          String nextStatus;
                          if (task.status == 'todo') {
                            nextStatus = 'in_progress';
                          } else if (task.status == 'in_progress') {
                            nextStatus = 'done';
                          } else {
                            nextStatus = 'todo';
                          }
                          ref.read(taskRepositoryProvider).updateTask(
                                task.copyWith(status: nextStatus),
                              );
                        },
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? successClr
                            : isInProgress
                                ? inProgressClr.withValues(alpha: 0.15)
                                : Colors.transparent,
                        border: Border.all(
                          color: isCompleted
                              ? successClr
                              : isInProgress
                                  ? inProgressClr
                                  : (computedOverdue ? errorClr.withValues(alpha: 0.6) : borderStrong),
                          width: isInProgress ? 2 : 1.5,
                        ),
                      ),
                      child: isCompleted
                          ? const Icon(Icons.check, size: 13, color: Colors.white)
                          : isInProgress
                              ? Icon(Icons.play_arrow_rounded, size: 12, color: inProgressClr)
                              : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                                decoration: isCompleted ? TextDecoration.lineThrough : null,
                                decorationColor: textTertiary,
                              ),
                            ),
                          ),
                          if (isInProgress) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: inProgressClr.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: inProgressClr.withValues(alpha: 0.4), width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.pending_outlined, size: 11, color: inProgressClr),
                                  const SizedBox(width: 4),
                                  Text(
                                    'IN PROGRESS',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: inProgressClr,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                computedOverdue ? Icons.error_outline_rounded : Icons.access_time_rounded,
                                size: 12,
                                color: computedOverdue ? errorClr : textTertiary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                formattedDueDate,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: computedOverdue ? errorClr : textTertiary,
                                  fontWeight: computedOverdue ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                          if (task.recurrenceRule != null) ...[
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.autorenew_rounded, size: 12, color: activeBlue),
                                const SizedBox(width: 3),
                                Text(
                                  task.recurrenceRule!.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: activeBlue,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          Text(
                            widget.boardTitle,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: widget.boardColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Optional User Notes
            if (notesPayload.userNotes != null && notesPayload.userNotes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 34),
                child: Text(
                  notesPayload.userNotes!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                    height: 1.3,
                  ),
                ),
              ),
            ],

            // Subitems Checklist Section
            if (notesPayload.hasSubitems) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 34),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subtask Progress Header & Bar
                    Row(
                      children: [
                        Text(
                          'Subtasks (${notesPayload.completedCount}/${notesPayload.totalCount})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOutCubic,
                              tween: Tween<double>(begin: 0.0, end: notesPayload.progress),
                              builder: (context, animValue, child) {
                                return LinearProgressIndicator(
                                  value: animValue,
                                  minHeight: 5,
                                  backgroundColor: borderSubtle,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    notesPayload.allCompleted ? successClr : activeBlue,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Subitem List
                    ...visibleSubitems.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final subitem = entry.value;
                      return InkWell(
                        onTap: () => _toggleSubitem(notesPayload, idx),
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              CustomCircularCheckbox(
                                isChecked: subitem.isDone,
                                size: 18,
                                activeColor: successClr,
                                borderColor: textTertiary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  subitem.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: subitem.isDone ? textTertiary : textPrimary,
                                    decoration: subitem.isDone ? TextDecoration.lineThrough : null,
                                    decorationColor: textTertiary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    // Expand / Collapse Chevron Toggle
                    if (subitems.length > 3) ...[
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => setState(() => _isExpanded = !_isExpanded),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Text(
                                _isExpanded ? 'Show less' : 'Show all (${subitems.length} items)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: activeBlue,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                size: 16,
                                color: activeBlue,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
