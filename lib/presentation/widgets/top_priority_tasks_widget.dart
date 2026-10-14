import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/feedback_service.dart';
import '../../core/utils/task_date_formatter.dart';
import '../../data/database/database.dart';
import '../../data/repository/task_repository.dart';
import '../../data/repository/board_repository.dart';
import '../../domain/models/task_subitem.dart';
import 'core/epicordia_card.dart';

/// A reactive, self-syncing widget that displays the user's top priority tasks.
/// Whenever tasks are created, updated, completed, or deleted anywhere in the app,
/// this widget automatically refreshes in real-time via Drift reactive streams.
/// Clicking it navigates directly to the Tasks Tab screen.
class TopPriorityTasksWidget extends ConsumerWidget {
  final int maxTasks;
  final VoidCallback? onHeaderTap;

  const TopPriorityTasksWidget({
    super.key,
    this.maxTasks = 4,
    this.onHeaderTap,
  });

  Color _getBoardColor(String? boardId) {
    if (boardId == null) return const Color(0xFF8B9DC3);
    const colors = [
      Color(0xFF8B9DC3),
      Color(0xFFA8B4C8),
      Color(0xFF6B7FA0),
      Color(0xFF9EAAC4),
      Color(0xFF6366F1),
      Color(0xFF3B82F6),
    ];
    return colors[boardId.hashCode.abs() % colors.length];
  }

  void _navigateToTasks(BuildContext context) {
    HapticFeedback.lightImpact();
    if (onHeaderTap != null) {
      onHeaderTap!();
    } else {
      context.push('/tasks');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderClr = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;
    final activeBlue = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600;
    final successClr = const Color(0xFF10B981);
    final errorClr = const Color(0xFFEF4444);

    // Reactive streams that auto-sync whenever the database changes
    final topTasksAsync = ref.watch(topPriorityTasksProvider);
    final boardsAsync = ref.watch(allBoardsProvider);

    final boardsMap = boardsAsync.value?.fold<Map<String, BoardEntity>>(
          {},
          (map, board) {
            map[board.id] = board;
            return map;
          },
        ) ??
        {};

    return EpicordiaCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header (Tapping takes user to Tasks Tab) ────────────────────────
          InkWell(
            onTap: () => _navigateToTasks(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          errorClr.withValues(alpha: 0.2),
                          const Color(0xFFF59E0B).withValues(alpha: 0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: errorClr.withValues(alpha: 0.3)),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.priority_high_rounded,
                        size: 18,
                        color: errorClr,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Top Priority Tasks',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Real-time Auto-Sync pulse badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: successClr.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: successClr.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: successClr,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'AUTO-SYNC',
                                    style: TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                      color: successClr,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Your highest impact focus items',
                          style: TextStyle(fontSize: 11.5, color: textTertiary),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: textTertiary,
                  ),
                ],
              ),
            ),
          ),

          Divider(height: 1, color: borderClr),

          // ── Tasks Body (Auto-synced Stream) ─────────────────────────────────
          topTasksAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Unable to load priority tasks: $err',
                style: TextStyle(fontSize: 12, color: errorClr),
              ),
            ),
            data: (tasks) {
              if (tasks.isEmpty) {
                return InkWell(
                  onTap: () => _navigateToTasks(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: successClr.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.check_circle_outline, color: successClr, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'All priority tasks complete!',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tap to explore all tasks in Tasks Tab.',
                                style: TextStyle(fontSize: 12, color: textTertiary),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: textTertiary),
                      ],
                    ),
                  ),
                );
              }

              final displayTasks = tasks.take(maxTasks).toList();

              return Column(
                children: [
                  ...displayTasks.asMap().entries.map((entry) {
                    final index = entry.key;
                    final task = entry.value;
                    final isLast = index == displayTasks.length - 1;

                    final boardTitle = boardsMap[task.boardId]?.title ?? 'Inbox';
                    final boardColor = _getBoardColor(task.boardId);
                    final isOverdue = TaskDateFormatter.isOverdue(task.dueDate, task.status);
                    final formattedDate = TaskDateFormatter.formatDueDate(task.dueDate);
                    final notesPayload = TaskSubitem.decodeNotes(task.notes);

                    // Priority color & badge
                    final (priorityLabel, priorityColor, priorityIcon) = switch (task.priority) {
                      >= 2 => ('HIGH', const Color(0xFFEF4444), Icons.arrow_upward_rounded),
                      1 => ('MED', const Color(0xFFF59E0B), Icons.remove_rounded),
                      _ => ('LOW', const Color(0xFF10B981), Icons.arrow_downward_rounded),
                    };

                    final isInProgress = task.status == 'in_progress';
                    final isDone = task.status == 'done';

                    return InkWell(
                      onTap: () => _navigateToTasks(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: isLast ? null : Border(bottom: BorderSide(color: borderClr, width: 0.8)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Interactive status checkbox (updating here immediately resyncs stream)
                            Padding(
                              padding: const EdgeInsets.only(top: 2, right: 12),
                              child: GestureDetector(
                                onTap: () async {
                                  HapticFeedback.lightImpact();
                                  String nextStatus = task.status == 'todo'
                                      ? 'in_progress'
                                      : (task.status == 'in_progress' ? 'done' : 'todo');

                                  await ref.read(taskRepositoryProvider).updateTask(
                                        task.copyWith(status: nextStatus),
                                      );

                                  if (nextStatus == 'done') {
                                    FeedbackService.showSuccess('Task marked complete!');
                                  }
                                },
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDone
                                        ? successClr
                                        : isInProgress
                                            ? activeBlue.withValues(alpha: 0.15)
                                            : Colors.transparent,
                                    border: Border.all(
                                      color: isDone
                                          ? successClr
                                          : isInProgress
                                              ? activeBlue
                                              : (isOverdue ? errorClr.withValues(alpha: 0.6) : borderClr),
                                      width: isInProgress ? 2 : 1.5,
                                    ),
                                  ),
                                  child: isDone
                                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                                      : isInProgress
                                          ? Icon(Icons.play_arrow_rounded, size: 11, color: activeBlue)
                                          : null,
                                ),
                              ),
                            ),

                            // Task Title & Metadata
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      // Priority badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: priorityColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(priorityIcon, size: 10, color: priorityColor),
                                            const SizedBox(width: 3),
                                            Text(
                                              priorityLabel,
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                                color: priorityColor,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isInProgress) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: activeBlue.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'IN PROGRESS',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: activeBlue,
                                              letterSpacing: 0.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                      const Spacer(),
                                      // Board Pill
                                      Text(
                                        boardTitle,
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: boardColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),

                                  // Title
                                  Text(
                                    task.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary,
                                      decoration: task.status == 'done' ? TextDecoration.lineThrough : null,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),

                                  const SizedBox(height: 4),

                                  // Subtask count & Due Date
                                  Row(
                                    children: [
                                      if (task.dueDate != null) ...[
                                        Icon(
                                          isOverdue ? Icons.error_outline_rounded : Icons.access_time_rounded,
                                          size: 12,
                                          color: isOverdue ? errorClr : textTertiary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          formattedDate,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: isOverdue ? FontWeight.w700 : FontWeight.w400,
                                            color: isOverdue ? errorClr : textTertiary,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                      ],
                                      if (notesPayload.hasSubitems) ...[
                                        Icon(Icons.checklist_rounded, size: 12, color: textTertiary),
                                        const SizedBox(width: 3),
                                        Text(
                                          '${notesPayload.completedCount}/${notesPayload.totalCount} subtasks',
                                          style: TextStyle(fontSize: 11, color: textTertiary),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),

          // ── Footer Action Button (Navigates to Tasks Tab) ────────────────────
          Divider(height: 1, color: borderClr),
          InkWell(
            onTap: () => _navigateToTasks(context),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Open Tasks Tab',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: activeBlue,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 14, color: activeBlue),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
