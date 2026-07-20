import 'package:flutter/material.dart';
import '../widgets/layout/responsive_scaffold.dart';
import '../widgets/core/epicordia_brand.dart';
import '../widgets/core/epicordia_card.dart';
import '../../core/theme.dart';

class TasksTab extends StatefulWidget {
  const TasksTab({super.key});

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  String _selectedFilter = 'All';
  final _searchController = TextEditingController();

  final List<String> _filters = ['All', 'Due Today', 'Overdue', 'Boards'];

  final List<_TaskData> _tasks = const [
    // _TaskData(
    //   title: 'Update Infrastructure API keys',
    //   due: 'Due: Yesterday',
    //   board: 'DEVOPS BOARD',
    //   boardColor: Color(0xFFC6362E),
    //   isOverdue: true,
    //   isCompleted: false,
    // ),
    // _TaskData(
    //   title: 'Review Q3 Design Language System',
    //   due: 'Due: Today, 5:00 PM',
    //   board: 'DESIGN',
    //   boardColor: Color(0xFF0077B6),
    //   isOverdue: false,
    //   isCompleted: false,
    // ),
    // _TaskData(
    //   title: 'Setup Weekly Sync with Stakeholders',
    //   due: 'Completed 2h ago',
    //   board: 'MANAGEMENT',
    //   boardColor: Color(0xFF1A9A5B),
    //   isOverdue: false,
    //   isCompleted: true,
    // ),
    // _TaskData(
    //   title: 'Draft product requirement document for V2',
    //   due: 'Due: Oct 12',
    //   board: 'PRODUCT',
    //   boardColor: Color(0xFF0077B6),
    //   isOverdue: false,
    //   isCompleted: false,
    // ),
    // _TaskData(
    //   title: 'Prepare client presentation deck',
    //   due: 'Due: Oct 14',
    //   board: 'SALES',
    //   boardColor: Color(0xFF0077B6),
    //   isOverdue: false,
    //   isCompleted: false,
    // ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      appBar: const EpicordiaSimpleAppBar(),
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
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                itemCount: _tasks.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  if (index == _tasks.length) {
                    return _CreateTaskButton(onTap: () {});
                  }
                  return _TaskListItem(task: _tasks[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data model ───────────────────────────────────────────────
class _TaskData {
  final String title;
  final String due;
  final String board;
  final Color boardColor;
  final bool isOverdue;
  final bool isCompleted;
  const _TaskData({
    required this.title,
    required this.due,
    required this.board,
    required this.boardColor,
    required this.isOverdue,
    required this.isCompleted,
  });
}

// ── Task list item ────────────────────────────────────────────
class _TaskListItem extends StatelessWidget {
  final _TaskData task;
  const _TaskListItem({required this.task});

  @override
  Widget build(BuildContext context) {
    return EpicordiaCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: task.isCompleted
                    ? EpicordiaColors.successLight
                    : Colors.transparent,
                border: Border.all(
                  color: task.isOverdue
                      ? EpicordiaColors.errorLight.withValues(alpha: 0.6)
                      : task.isCompleted
                      ? EpicordiaColors.successLight
                      : EpicordiaColors.borderStrongLight,
                  width: 1.5,
                ),
              ),
              child: task.isCompleted
                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                  : null,
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
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: EpicordiaColors.textTertiaryLight,
                        ),
                      ),
                    ),
                    if (task.isOverdue) ...[
                      const SizedBox(width: 6),
                      const Text('⚠️', style: TextStyle(fontSize: 14)),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      task.due,
                      style: TextStyle(
                        fontSize: 12,
                        color: task.isOverdue
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
                      task.board,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: task.boardColor,
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
