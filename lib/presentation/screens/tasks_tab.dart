import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/repository/task_repository.dart';
import '../../data/repository/board_repository.dart';
import '../../data/database/database.dart';
import '../../domain/models/task_subitem.dart';
import '../../core/utils/task_date_formatter.dart';
import '../widgets/layout/responsive_scaffold.dart';
import '../widgets/core/interactive_task_card.dart';
import '../../core/theme.dart';

enum TaskSortCriterion {
  priority,
  dueDate,
  completion,
  createdAt,
}

enum SortDirection {
  ascending,
  descending,
}

class TasksTab extends ConsumerStatefulWidget {
  const TasksTab({super.key});

  @override
  ConsumerState<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends ConsumerState<TasksTab> {
  String _selectedFilter = 'All';
  TaskSortCriterion _selectedSort = TaskSortCriterion.priority;
  SortDirection _sortDirection = SortDirection.descending;
  final _searchController = TextEditingController();

  final List<String> _filters = ['All', 'In Progress', 'Due Today', 'Overdue', 'Boards'];

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

  String _getSortCriterionLabel(TaskSortCriterion criterion) {
    switch (criterion) {
      case TaskSortCriterion.priority:
        return 'Priority';
      case TaskSortCriterion.dueDate:
        return 'Due Date';
      case TaskSortCriterion.completion:
        return 'Completion Level';
      case TaskSortCriterion.createdAt:
        return 'Date Created';
    }
  }

  String _getSortDirectionLabel(TaskSortCriterion criterion, SortDirection direction) {
    final isAsc = direction == SortDirection.ascending;
    switch (criterion) {
      case TaskSortCriterion.priority:
        return isAsc ? 'Low → High' : 'High → Low';
      case TaskSortCriterion.dueDate:
        return isAsc ? 'Earliest First' : 'Latest First';
      case TaskSortCriterion.completion:
        return isAsc ? 'Least Complete First' : 'Most Complete First';
      case TaskSortCriterion.createdAt:
        return isAsc ? 'Oldest First' : 'Newest First';
    }
  }

  IconData _getSortCriterionIcon(TaskSortCriterion criterion) {
    switch (criterion) {
      case TaskSortCriterion.priority:
        return Icons.flag_outlined;
      case TaskSortCriterion.dueDate:
        return Icons.event_outlined;
      case TaskSortCriterion.completion:
        return Icons.check_circle_outline_rounded;
      case TaskSortCriterion.createdAt:
        return Icons.access_time_outlined;
    }
  }

  double _calculateTaskCompletion(TaskEntity task) {
    if (task.status.toLowerCase() == 'done') return 1.0;
    final payload = TaskSubitem.decodeNotes(task.notes);
    if (payload.subitems.isNotEmpty) {
      final completed = payload.subitems.where((s) => s.isDone).length;
      return completed / payload.subitems.length;
    }
    if (task.status.toLowerCase() == 'in_progress') return 0.5;
    return 0.0;
  }

  List<TaskEntity> _applySorting(List<TaskEntity> list) {
    final sorted = List<TaskEntity>.from(list);
    final isAsc = _sortDirection == SortDirection.ascending;

    sorted.sort((a, b) {
      int cmp = 0;
      switch (_selectedSort) {
        case TaskSortCriterion.priority:
          cmp = a.priority.compareTo(b.priority);
          if (!isAsc) cmp = -cmp;
          if (cmp == 0) {
            final dueA = a.dueDate ?? DateTime(9999);
            final dueB = b.dueDate ?? DateTime(9999);
            cmp = dueA.compareTo(dueB);
          }
          break;

        case TaskSortCriterion.dueDate:
          if (a.dueDate == null && b.dueDate == null) {
            cmp = b.createdAt.compareTo(a.createdAt);
          } else if (a.dueDate == null) {
            cmp = 1; // Unscheduled tasks go to the bottom
          } else if (b.dueDate == null) {
            cmp = -1;
          } else {
            cmp = a.dueDate!.compareTo(b.dueDate!);
            if (!isAsc) cmp = -cmp;
          }
          break;

        case TaskSortCriterion.completion:
          final compA = _calculateTaskCompletion(a);
          final compB = _calculateTaskCompletion(b);
          cmp = compA.compareTo(compB);
          if (!isAsc) cmp = -cmp;
          if (cmp == 0) {
            cmp = b.priority.compareTo(a.priority);
          }
          break;

        case TaskSortCriterion.createdAt:
          cmp = a.createdAt.compareTo(b.createdAt);
          if (!isAsc) cmp = -cmp;
          break;
      }
      return cmp;
    });

    return sorted;
  }

  void _showSortBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final activeBlue = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600;
    final cardBg = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
    final borderClr = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sort Tasks',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, size: 20, color: textSecondary),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...TaskSortCriterion.values.map((criterion) {
                      final isSelected = _selectedSort == criterion;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? activeBlue.withValues(alpha: isDark ? 0.2 : 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? activeBlue : borderClr,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: ListTile(
                          dense: true,
                          leading: Icon(
                            _getSortCriterionIcon(criterion),
                            color: isSelected ? activeBlue : textSecondary,
                          ),
                          title: Text(
                            _getSortCriterionLabel(criterion),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? activeBlue : textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            _getSortDirectionLabel(criterion, _sortDirection),
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                            ),
                          ),
                          trailing: isSelected
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        _sortDirection == SortDirection.ascending
                                            ? Icons.arrow_upward_rounded
                                            : Icons.arrow_downward_rounded,
                                        color: activeBlue,
                                        size: 20,
                                      ),
                                      tooltip: 'Toggle sort direction',
                                      onPressed: () {
                                        setState(() {
                                          _sortDirection = _sortDirection == SortDirection.ascending
                                              ? SortDirection.descending
                                              : SortDirection.ascending;
                                        });
                                        setSheetState(() {});
                                      },
                                    ),
                                    Icon(Icons.check, color: activeBlue, size: 20),
                                  ],
                                )
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedSort = criterion;
                              // Sensible defaults when switching criteria
                              if (criterion == TaskSortCriterion.dueDate) {
                                _sortDirection = SortDirection.ascending;
                              } else if (criterion == TaskSortCriterion.priority) {
                                _sortDirection = SortDirection.descending;
                              } else if (criterion == TaskSortCriterion.completion) {
                                _sortDirection = SortDirection.ascending;
                              } else {
                                _sortDirection = SortDirection.descending;
                              }
                            });
                            Navigator.of(ctx).pop();
                          },
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(allTasksProvider);
    final boardsAsync = ref.watch(allBoardsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgApp = Theme.of(context).scaffoldBackgroundColor;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;
    final borderStrong = isDark ? EpicordiaColors.borderStrongDark : EpicordiaColors.borderStrongLight;
    final activeBlue = isDark ? EpicordiaColors.blue600 : EpicordiaColors.blue700;

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
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tasks',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Track your action items, to-dos & deadlines',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          // Search + filters + Sort
          Container(
            color: bgApp,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Column(
              children: [
                // Search bar & Sort trigger
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(color: textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Filter tasks by name, tag, or board...',
                          prefixIcon: Icon(
                            Icons.search,
                            size: 18,
                            color: textTertiary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _showSortBottomSheet(context),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? EpicordiaColors.surfaceSunkenDark : EpicordiaColors.surfaceSunkenLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderStrong),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getSortCriterionIcon(_selectedSort),
                              size: 16,
                              color: activeBlue,
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              _sortDirection == SortDirection.ascending
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                              size: 14,
                              color: activeBlue,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                // Filter chips & Active Sort Indicator
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
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
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? activeBlue
                                        : (isDark ? EpicordiaColors.surfaceSunkenDark : EpicordiaColors.surfaceSunkenLight),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: selected ? activeBlue : borderStrong,
                                    ),
                                  ),
                                  child: Text(
                                    f,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                      color: selected ? Colors.white : textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Active Sort label & quick direction toggle bar
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _showSortBottomSheet(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: borderStrong, width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Sorted by: ',
                              style: TextStyle(
                                fontSize: 11,
                                color: textTertiary,
                              ),
                            ),
                            Text(
                              '${_getSortCriterionLabel(_selectedSort)} (${_getSortDirectionLabel(_selectedSort, _sortDirection)})',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.unfold_more, size: 12, color: textTertiary),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _sortDirection = _sortDirection == SortDirection.ascending
                              ? SortDirection.descending
                              : SortDirection.ascending;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _sortDirection == SortDirection.ascending
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                              size: 13,
                              color: textSecondary,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              _sortDirection == SortDirection.ascending ? 'Asc' : 'Desc',
                              style: TextStyle(fontSize: 11, color: textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
                  if (_selectedFilter == 'In Progress') {
                    filtered = filtered.where((t) => t.status == 'in_progress').toList();
                  } else if (_selectedFilter == 'Due Today') {
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
                    filtered.sort((a, b) {
                      final titleA = boardsMap[a.boardId]?.title ?? '';
                      final titleB = boardsMap[b.boardId]?.title ?? '';
                      return titleA.compareTo(titleB);
                    });
                  }

                  // 3. Apply Selected Sorting Criterion & Direction
                  final sortedTasks = _applySorting(filtered);

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    itemCount: sortedTasks.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      if (index == sortedTasks.length) {
                        return _CreateTaskButton(
                          onTap: () => context.push('/create/task'),
                        );
                      }
                      final task = sortedTasks[index];
                      final boardTitle = boardsMap[task.boardId]?.title ?? 'Inbox';
                      final boardColor = _getBoardColor(task.boardId);
                      final isOverdue = TaskDateFormatter.isOverdue(task.dueDate, task.status);

                      return InteractiveTaskCard(
                        task: task,
                        boardTitle: boardTitle,
                        boardColor: boardColor,
                        isOverdue: isOverdue,
                        dueFormatted: TaskDateFormatter.formatDueDate(task.dueDate),
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

class _CreateTaskButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CreateTaskButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final borderStrong = isDark ? EpicordiaColors.borderStrongDark : EpicordiaColors.borderStrongLight;

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderStrong,
              style: BorderStyle.solid,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add,
                size: 18,
                color: textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                'Create New Task',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
