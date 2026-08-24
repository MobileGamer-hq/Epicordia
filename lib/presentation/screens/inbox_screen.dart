import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../data/repository/task_repository.dart';
import '../../data/repository/pin_repository.dart';
import '../../data/database/database.dart';
import '../../domain/models/note_model.dart';
import '../widgets/core/item_interaction_dialogs.dart';

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute $ampm';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    if (target == today) return 'Today at ${_formatTime(date)}';
    if (target == today.add(const Duration(days: 1))) return 'Tomorrow at ${_formatTime(date)}';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day} at ${_formatTime(date)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgApp = isDark ? EpicordiaColors.surfaceAppDark : EpicordiaColors.surfaceAppLight;
    final cardBg = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
    final borderClr = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;
    final activeBlue = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600;

    final tasksAsync = ref.watch(allTasksProvider);
    final notesAsync = ref.watch(allNotesProvider);

    final tasks = tasksAsync.value ?? [];
    final notes = notesAsync.value ?? [];

    final now = DateTime.now();
    final overdue = tasks.where((t) => t.status != 'done' && t.dueDate != null && t.dueDate!.isBefore(now)).toList();
    final upcoming = tasks.where((t) => t.status != 'done' && t.dueDate != null && t.dueDate!.isAfter(now)).toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

    return Scaffold(
      backgroundColor: bgApp,
      appBar: AppBar(
        backgroundColor: bgApp,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: Text(
          'Activity & Notifications',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // Status Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderClr),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: activeBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.notifications_active_outlined, color: activeBlue, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Task Reminders & Alarms Active',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Reminders set for task day, 1 hour before, 5 min before & exact due alarm.',
                          style: TextStyle(fontSize: 11, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Overdue Section
            if (overdue.isNotEmpty) ...[
              Text(
                'OVERDUE NOTIFICATIONS',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: EpicordiaColors.errorLight, letterSpacing: 0.8),
              ),
              const SizedBox(height: 8),
              ...overdue.map((t) => _ActivityTaskTile(
                task: t,
                isOverdue: true,
                formattedDate: _formatDate(t.dueDate!),
                onTap: () => context.push('/task/${t.id}'),
                onToggle: () {
                  ref.read(taskRepositoryProvider).updateTask(t.copyWith(status: 'done'));
                },
              )),
              const SizedBox(height: 20),
            ],

            // Scheduled Reminders Section
            Text(
              'UPCOMING TASK REMINDERS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: textTertiary, letterSpacing: 0.8),
            ),
            const SizedBox(height: 8),
            if (upcoming.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderClr),
                ),
                child: Text('No upcoming scheduled task reminders.', style: TextStyle(fontSize: 13, color: textSecondary)),
              )
            else
              ...upcoming.map((t) => _ActivityTaskTile(
                task: t,
                isOverdue: false,
                formattedDate: _formatDate(t.dueDate!),
                onTap: () => context.push('/task/${t.id}'),
                onToggle: () {
                  ref.read(taskRepositoryProvider).updateTask(t.copyWith(status: 'done'));
                },
              )),

            const SizedBox(height: 20),

            // Recent Workspace Activity
            Text(
              'RECENT WORKSPACE ACTIVITY',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: textTertiary, letterSpacing: 0.8),
            ),
            const SizedBox(height: 8),
            if (notes.isEmpty && tasks.isEmpty)
              Text('No activity yet.', style: TextStyle(color: textSecondary))
            else
              ...notes.take(5).map((n) {
                final title = NoteDocument.extractTitle(n.content ?? '');
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderClr),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit_note_rounded, size: 20, color: activeBlue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Note updated: $title',
                          style: TextStyle(fontSize: 13, color: textPrimary, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _ActivityTaskTile extends ConsumerWidget {
  final TaskEntity task;
  final bool isOverdue;
  final String formattedDate;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const _ActivityTaskTile({
    required this.task,
    required this.isOverdue,
    required this.formattedDate,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
    final borderClr = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final isCompleted = task.status == 'done';

    return GestureDetector(
      onTap: onTap,
      onLongPress: () => ItemInteractionDialogs.showTaskDetailDialog(
        context: context,
        ref: ref,
        task: task,
        boardTitle: 'Inbox',
        boardColor: Colors.grey,
      ),
      onDoubleTap: () => ItemInteractionDialogs.showDoubleTapMenu(
        context: context,
        title: task.title,
        subtitle: formattedDate,
        items: [
          DoubleTapMenuItem(
            icon: isCompleted ? Icons.undo_rounded : Icons.check_circle_outline,
            label: isCompleted ? 'Reopen Task' : 'Mark as Done',
            onTap: onToggle,
          ),
          DoubleTapMenuItem(
            icon: Icons.copy_rounded,
            label: 'Copy Task',
            onTap: () {
              ItemInteractionDialogs.copyToClipboard(context, 'Task: ${task.title}\nDue: $formattedDate');
            },
          ),
          DoubleTapMenuItem(
            icon: Icons.share_outlined,
            label: 'Share Task',
            onTap: () {
              ItemInteractionDialogs.shareContent(context, 'Task: ${task.title}\nDue: $formattedDate');
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isOverdue ? EpicordiaColors.errorLight.withValues(alpha: 0.5) : borderClr),
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                isCompleted ? Icons.check_circle : Icons.circle_outlined,
                color: isCompleted
                    ? (isDark ? EpicordiaColors.successDark : EpicordiaColors.successLight)
                    : (isOverdue ? EpicordiaColors.errorLight : textSecondary),
              ),
              onPressed: onToggle,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.alarm, size: 12, color: isOverdue ? EpicordiaColors.errorLight : textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        formattedDate,
                        style: TextStyle(fontSize: 11, color: isOverdue ? EpicordiaColors.errorLight : textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: textSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}
