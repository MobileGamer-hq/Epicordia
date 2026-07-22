import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/repository/task_repository.dart';
import '../../data/repository/board_repository.dart';
import '../../data/database/database.dart';
import '../widgets/layout/responsive_scaffold.dart';
import '../widgets/core/epicordia_card.dart';
import '../../core/theme.dart';

class TasksTab extends ConsumerStatefulWidget {
  const TasksTab({super.key});

  @override
  ConsumerState<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends ConsumerState<TasksTab> {
  String _selectedFilter = 'All';
  final _searchController = TextEditingController();

  final List<String> _filters = ['All', 'Due Today', 'Overdue', 'Boards'];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  String _formatDue(DateTime? date) {
    if (date == null) return 'No due date';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(date.year, date.month, date.day);

    if (due == today) {
      return 'Due: Today, ${_formatTime(date)}';
    } else if (due.isBefore(today)) {
      return 'Due: Yesterday';
    } else {
      return 'Due: ${date.month}/${date.day}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(allTasksProvider);
    final boardsAsync = ref.watch(allBoardsProvider);

    final boardsMap = boardsAsync.value?.fold<Map<String, BoardEntity>>(
          {},
          (map, board) {
            map[board.id] = board;
            return map;
          },
        ) ??
        {};

    return ResponsiveScaffold(
      child: Column(
        children: [
          // Search + filters
          Container(
            color: EpicordiaColors.surfaceAppLight,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Filter tasks by name, tag, or board...',
                    prefixIcon: Icon(
                      Icons.search,
                      size: 18,
                      color: EpicordiaColors.textTertiaryLight,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((f) {
                      final selected = _selectedFilter == f;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedFilter = f),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? EpicordiaColors.blue700
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected
                                    ? EpicordiaColors.blue700
                                    : EpicordiaColors.borderStrongLight,
                              ),
                            ),
                            child: Text(
                              f,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: selected
                                    ? Colors.white
                                    : EpicordiaColors.textSecondaryLight,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          // Task list
          Expanded(
            child: SelectionArea(
              child: tasksAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
                data: (tasks) {
                  final now = DateTime.now();
                  final startOfToday = DateTime(now.year, now.month, now.day);
                  final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

                  // 1. Search Query
                  final query = _searchController.text.trim().toLowerCase();
                  var filtered = tasks.where((task) {
                    if (query.isEmpty) return true;
                    final matchesTitle = task.title.toLowerCase().contains(query);
                    final matchesNotes = (task.notes ?? '').toLowerCase().contains(query);
                    return matchesTitle || matchesNotes;
                  }).toList();

                  // 2. Chip Filter
                  if (_selectedFilter == 'Due Today') {
                    filtered = filtered.where((t) {
                      return t.dueDate != null &&
                          t.dueDate!.isAfter(startOfToday) &&
                          t.dueDate!.isBefore(endOfToday);
                    }).toList();
                  } else if (_selectedFilter == 'Overdue') {
                    filtered = filtered.where((t) {
                      return t.status != 'done' &&
                          t.dueDate != null &&
                          t.dueDate!.isBefore(startOfToday);
                    }).toList();
                  } else if (_selectedFilter == 'Boards') {
                    filtered = filtered.where((t) => t.boardId != null).toList();
                    // Sort by board title
                    filtered.sort((a, b) {
                      final titleA = boardsMap[a.boardId]?.title ?? '';
                      final titleB = boardsMap[b.boardId]?.title ?? '';
                      return titleA.compareTo(titleB);
                    });
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                    itemCount: filtered.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      if (index == filtered.length) {
                        return _CreateTaskButton(
                          onTap: () => context.push('/create/task'),
                        );
                      }
                      final task = filtered[index];
                      final boardTitle = boardsMap[task.boardId]?.title ?? 'Inbox';
                      final boardColor = _getBoardColor(task.boardId);
                      final isOverdue = task.status != 'done' &&
                          task.dueDate != null &&
                          task.dueDate!.isBefore(startOfToday);

                      return _TaskListItem(
                        task: task,
                        boardTitle: boardTitle,
                        boardColor: boardColor,
                        isOverdue: isOverdue,
                        dueFormatted: _formatDue(task.dueDate),
                        onTap: () => context.push('/task/${task.id}'),
                        onToggle: () {
                          final isCompleted = task.status == 'done';
                          final newStatus = isCompleted ? 'todo' : 'done';
                          ref.read(taskRepositoryProvider).updateTask(
                                task.copyWith(status: newStatus),
                              );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Task list item ────────────────────────────────────────────
class _TaskListItem extends StatelessWidget {
  final TaskEntity task;
  final String boardTitle;
  final Color boardColor;
  final bool isOverdue;
  final String dueFormatted;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const _TaskListItem({
    required this.task,
    required this.boardTitle,
    required this.boardColor,
    required this.isOverdue,
    required this.dueFormatted,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = task.status == 'done';

    return GestureDetector(
      onTap: onTap,
      child: EpicordiaCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: GestureDetector(
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
                      color: isOverdue
                          ? EpicordiaColors.errorLight.withValues(alpha: 0.6)
                          : isCompleted
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
                            color: EpicordiaColors.textPrimaryLight,
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: EpicordiaColors.textTertiaryLight,
                          ),
                        ),
                      ),
                      if (isOverdue) ...[
                        const SizedBox(width: 6),
                        const Text('⚠️', style: TextStyle(fontSize: 14)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        dueFormatted,
                        style: TextStyle(
                          fontSize: 12,
                          color: isOverdue
                              ? EpicordiaColors.errorLight
                              : EpicordiaColors.textTertiaryLight,
                        ),
                      ),
                      const Text(
                        ' • ',
                        style: TextStyle(
                          fontSize: 12,
                          color: EpicordiaColors.textTertiaryLight,
                        ),
                      ),
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

class _CreateTaskButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CreateTaskButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: EpicordiaColors.borderStrongLight,
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add,
              size: 18,
              color: EpicordiaColors.textSecondaryLight,
            ),
            SizedBox(width: 6),
            Text(
              'Create New Task',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: EpicordiaColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
