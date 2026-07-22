import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/repository/task_repository.dart';
import '../../data/repository/pin_repository.dart';
import '../../data/repository/board_repository.dart';
import '../../data/database/database.dart';
import '../../core/theme.dart';
import 'today_dashboard.dart';
import 'notes_tab.dart';
import 'tasks_tab.dart';

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
      backgroundColor: EpicordiaColors.surfaceAppLight,
      appBar: AppBar(
        backgroundColor: EpicordiaColors.surfaceAppLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: EpicordiaColors.textPrimaryLight,
          ),
          onPressed: () => context.go('/'),
        ),
        title: const Text(
          'Interactive Calendar',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: EpicordiaColors.textPrimaryLight,
          ),
        ),
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
                      color: EpicordiaColors.surfaceCardLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: EpicordiaColors.borderSubtleLight),
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
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: EpicordiaColors.textPrimaryLight,
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
                                color: EpicordiaColors.textTertiaryLight.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No tasks or notes for this date',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: EpicordiaColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.only(bottom: 40),
                          children: [
                            if (dayTasks.isNotEmpty) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'Tasks',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: EpicordiaColors.textTertiaryLight,
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
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'Notes',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: EpicordiaColors.textTertiaryLight,
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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: EpicordiaColors.surfaceCardLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: EpicordiaColors.borderSubtleLight),
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
                      ? EpicordiaColors.successLight
                      : Colors.transparent,
                  border: Border.all(
                    color: isCompleted
                        ? EpicordiaColors.successLight
                        : EpicordiaColors.borderStrongLight,
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
                      color: EpicordiaColors.textPrimaryLight,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                      decorationColor: EpicordiaColors.textTertiaryLight,
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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: EpicordiaColors.surfaceCardLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: EpicordiaColors.borderSubtleLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: EpicordiaColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              preview,
              style: const TextStyle(
                fontSize: 12,
                color: EpicordiaColors.textSecondaryLight,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              'Board: $boardTitle',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: EpicordiaColors.blue600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
