import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/repository/task_repository.dart';
import '../../data/repository/pin_repository.dart';
import '../../data/repository/board_repository.dart';
import '../../data/database/database.dart';
import '../../core/theme.dart';
import '../../domain/services/device_calendar_service.dart';
import '../widgets/permission_explanation_dialog.dart';
import 'today_dashboard.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();

  String _formatDateHeader(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Color _getBoardColor(String? boardId) {
    if (boardId == null) return Colors.grey;
    final colors = [
      const Color(0xFF8B9DC3),
      const Color(0xFFA8B4C8),
      const Color(0xFF6B7FA0),
      const Color(0xFF9EAAC4)
    ];
    return colors[boardId.hashCode % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(allTasksProvider);
    final notesAsync = ref.watch(allNotesProvider);
    final boardsAsync = ref.watch(allBoardsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgApp = isDark ? EpicordiaColors.surfaceAppDark : EpicordiaColors.surfaceAppLight;
    final cardBg = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
    final borderClr = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;

    final boardsMap = boardsAsync.value?.fold<Map<String, BoardEntity>>(
          {},
          (map, board) {
            map[board.id] = board;
            return map;
          },
        ) ??
        {};

    final selectedYear = _selectedDate.year;
    final selectedMonth = _selectedDate.month;
    final selectedDay = _selectedDate.day;

    // Filter tasks due on this day
    final dayTasks = tasksAsync.value?.where((t) {
          if (t.dueDate == null) return false;
          return t.dueDate!.year == selectedYear &&
              t.dueDate!.month == selectedMonth &&
              t.dueDate!.day == selectedDay;
        }).toList() ??
        [];

    // Filter notes modified on this day
    final dayNotes = notesAsync.value?.where((n) {
          return n.modifiedAt.year == selectedYear &&
              n.modifiedAt.month == selectedMonth &&
              n.modifiedAt.day == selectedDay;
        }).toList() ??
        [];

    return Scaffold(
      backgroundColor: bgApp,
      appBar: AppBar(
        backgroundColor: bgApp,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: textPrimary,
          ),
          onPressed: () => context.go('/'),
        ),
        title: Text(
          'Interactive Calendar',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync Device Calendar',
            onPressed: () async {
              final proceed = await PermissionExplanationDialog.show(
                context: context,
                title: 'Sync Device Calendar',
                description:
                    'Epicordia will sync your tasks with your native device calendar.',
                icon: Icons.calendar_month_outlined,
              );
              if (!proceed || !context.mounted) return;

              final calendarService = DeviceCalendarService();
              final calendars = await calendarService.getWritableCalendars();
              if (!context.mounted) return;

              if (calendars.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No writable device calendars found or permission denied.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              final primaryCalendar = calendars.first;
              int syncedCount = 0;
              final tasks = tasksAsync.value ?? [];

              for (final task in tasks) {
                if (task.dueDate != null) {
                  final eventId = await calendarService.syncTaskToCalendar(
                    calendarId: primaryCalendar.id!,
                    title: task.title,
                    notes: task.notes,
                    startDate: task.dueDate!,
                    existingEventId: task.calendarEventId,
                    rruleString: task.recurrenceRule,
                  );
                  if (eventId != null) syncedCount++;
                }
              }

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Synced $syncedCount tasks to calendar "${primaryCalendar.name}"'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // Heatmap inside Hero
              Hero(
                tag: 'heatmap-hero',
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderClr),
                    ),
                    child: ActivityHeatmap(
                      selectedDate: _selectedDate,
                      selectedMonth: _selectedDate,
                      onTapDate: (date) {
                        setState(() {
                          _selectedDate = date;
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Date header
              Text(
                _formatDateHeader(_selectedDate),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              // Items list
              Expanded(
                child: SelectionArea(
                  child: dayTasks.isEmpty && dayNotes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 48,
                                color: textTertiary.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No tasks or notes for this date',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.only(bottom: 40),
                          children: [
                            if (dayTasks.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'Tasks',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: textTertiary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              ...dayTasks.map((task) {
                                final boardTitle = boardsMap[task.boardId]?.title ?? 'Inbox';
                                final boardColor = _getBoardColor(task.boardId);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: CardTaskItem(
                                    task: task,
                                    boardTitle: boardTitle,
                                    boardColor: boardColor,
                                    onTap: () => context.push('/task/${task.id}'),
                                    onToggle: () {
                                      final isCompleted = task.status == 'done';
                                      final newStatus = isCompleted ? 'todo' : 'done';
                                      ref.read(taskRepositoryProvider).updateTask(
                                            task.copyWith(status: newStatus),
                                          );
                                    },
                                  ),
                                );
                              }),
                              const SizedBox(height: 12),
                            ],
                            if (dayNotes.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'Notes',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: textTertiary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              ...dayNotes.map((note) {
                                final boardTitle = boardsMap[note.boardId]?.title ?? 'Inbox';
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: CardNoteItem(
                                    note: note,
                                    boardTitle: boardTitle,
                                    onTap: () => context.push('/note/${note.id}'),
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Simple wrappers for lists to avoid layout differences
class CardTaskItem extends StatelessWidget {
  final TaskEntity task;
  final String boardTitle;
  final Color boardColor;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const CardTaskItem({
    super.key,
    required this.task,
    required this.boardTitle,
    required this.boardColor,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = task.status == 'done';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
    final borderClr = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderClr),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onToggle,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? (isDark ? EpicordiaColors.successDark : EpicordiaColors.successLight)
                      : Colors.transparent,
                  border: Border.all(
                    color: isCompleted
                        ? (isDark ? EpicordiaColors.successDark : EpicordiaColors.successLight)
                        : (isDark ? EpicordiaColors.borderStrongDark : EpicordiaColors.borderStrongLight),
                    width: 1.5,
                  ),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, size: 13, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
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
                      decorationColor: textTertiary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
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

class CardNoteItem extends StatelessWidget {
  final PinEntity note;
  final String boardTitle;
  final VoidCallback onTap;

  const CardNoteItem({
    super.key,
    required this.note,
    required this.boardTitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lines = (note.content ?? '').split('\n');
    final title = lines.isNotEmpty && lines[0].trim().isNotEmpty ? lines[0] : 'Untitled Note';
    final preview = lines.length > 1 ? lines.sublist(1).join('\n').trim() : 'No additional content';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
    final borderClr = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final accentBlue = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderClr),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              preview,
              style: TextStyle(
                fontSize: 12,
                color: textSecondary,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              'Board: $boardTitle',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: accentBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
