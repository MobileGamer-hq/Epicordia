import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../data/database/database.dart';
import '../../../data/repository/task_repository.dart';
import 'epicordia_card.dart';
import 'item_interaction_dialogs.dart';

class InteractiveTaskCard extends ConsumerWidget {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompleted = task.status == 'done';
    final isInProgress = task.status == 'in_progress';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;
    final borderStrong = isDark ? EpicordiaColors.borderStrongDark : EpicordiaColors.borderStrongLight;
    final successClr = isDark ? EpicordiaColors.successDark : EpicordiaColors.successLight;
    final errorClr = isDark ? EpicordiaColors.errorDark : EpicordiaColors.errorLight;
    final inProgressClr = const Color(0xFFF59E0B);

    final formattedDueDate = dueFormatted ?? _formatDue(task.dueDate);
    final computedOverdue = isOverdue || (task.status != 'done' && task.dueDate != null && task.dueDate!.isBefore(DateTime.now()));

    return GestureDetector(
      onTap: onTap ?? () => context.push('/task/${task.id}'),
      onLongPress: onLongPress ??
          () => ItemInteractionDialogs.showTaskDetailDialog(
                context: context,
                ref: ref,
                task: task,
                boardTitle: boardTitle,
                boardColor: boardColor,
              ),
      onDoubleTap: onDoubleTap ??
          () => ItemInteractionDialogs.showDoubleTapMenu(
                context: context,
                title: task.title,
                subtitle: 'Task in $boardTitle',
                items: [
                  DoubleTapMenuItem(
                    icon: isCompleted ? Icons.undo_rounded : Icons.check_circle_outline,
                    label: isCompleted ? 'Mark as To Do' : 'Mark as Complete',
                    onTap: () {
                      final next = isCompleted ? 'todo' : 'done';
                      ref.read(taskRepositoryProvider).updateTask(task.copyWith(status: next));
                    },
                  ),
                  DoubleTapMenuItem(
                    icon: Icons.copy_rounded,
                    label: 'Copy Task',
                    onTap: () {
                      final statusStr = isCompleted ? 'Completed' : (isInProgress ? 'In Progress' : 'To Do');
                      ItemInteractionDialogs.copyToClipboard(
                        context,
                        'Task: ${task.title}\nStatus: $statusStr\nBoard: $boardTitle\nNotes: ${task.notes ?? ''}',
                      );
                    },
                  ),
                  DoubleTapMenuItem(
                    icon: Icons.share_outlined,
                    label: 'Share Task',
                    onTap: () {
                      final statusStr = isCompleted ? 'Completed' : (isInProgress ? 'In Progress' : 'To Do');
                      ItemInteractionDialogs.shareContent(
                        context,
                        'Task: ${task.title}\nStatus: $statusStr\nBoard: $boardTitle\nNotes: ${task.notes ?? ''}',
                      );
                    },
                  ),
                  DoubleTapMenuItem(
                    icon: Icons.edit_outlined,
                    label: 'Edit Task',
                    onTap: () => context.push('/task/${task.id}'),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: GestureDetector(
                onTap: onToggle ??
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
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
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
                  Row(
                    children: [
                      Text(
                        formattedDueDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: computedOverdue ? errorClr : textTertiary,
                          fontWeight: computedOverdue ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        boardTitle,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: boardColor,
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
      ),
    );
  }
}
