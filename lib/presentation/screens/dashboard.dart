import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' show Value;
import '../widgets/layout/responsive_scaffold.dart';
import '../widgets/core/epicordia_brand.dart';
import '../widgets/core/epicordia_card.dart';
import '../../data/repository/board_repository.dart';
import '../../data/repository/task_repository.dart';
import '../../data/repository/pin_repository.dart';
import '../../data/database/database.dart';
import '../../core/theme.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final boardsStream = ref.watch(boardRepositoryProvider).watchAllBoards();
    final todayTasksStream = ref.watch(taskRepositoryProvider).watchTasksDueToday();
    final unsortedTasksStream = ref.watch(taskRepositoryProvider).watchUnsortedTasks();
    final unsortedNotesStream = ref.watch(pinRepositoryProvider).watchUnsortedNotes();

    return ResponsiveScaffold(
      appBar: const EpicordiaAppBar(),
      child: StreamBuilder(
        stream: boardsStream,
        builder: (context, boardsSnapshot) {
          final boards = boardsSnapshot.data ?? [];

          return StreamBuilder(
            stream: todayTasksStream,
            builder: (context, tasksSnapshot) {
              final todayTasks = tasksSnapshot.data ?? [];

              return StreamBuilder(
                stream: unsortedTasksStream,
                builder: (context, unsortedTasksSnapshot) {
                  final unsortedTasks = unsortedTasksSnapshot.data ?? [];

                  return StreamBuilder(
                    stream: unsortedNotesStream,
                    builder: (context, unsortedNotesSnapshot) {
                      final unsortedNotes = unsortedNotesSnapshot.data ?? [];

                      // If there is absolutely no data in the database (no boards, no tasks, no unsorted items)
                      if (boards.isEmpty && todayTasks.isEmpty && unsortedTasks.isEmpty && unsortedNotes.isEmpty) {
                        return _EmptyDashboardState();
                      }

                      return ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        children: [
                          // ── Activity Heatmap ─────────────────────────────────
                          const _ActivityHeatmap(),
                          const SizedBox(height: 28),

                          // ── Unsorted Tray ───────────────────────────────────
                          if (unsortedTasks.isNotEmpty || unsortedNotes.isNotEmpty) ...[
                            _SectionHeader(title: 'Unsorted Tray', actionLabel: 'View All', onAction: () => context.go('/notes')),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 130,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  ...unsortedNotes.map((note) => Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: _QuickCaptureCard(
                                      category: 'NOTE',
                                      title: note.content ?? 'Untitled Note',
                                      time: 'Unsorted',
                                      onTap: () => context.go('/notes'),
                                    ),
                                  )),
                                  ...unsortedTasks.map((task) => Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: _QuickCaptureCard(
                                      category: 'TASK',
                                      title: task.title,
                                      time: task.dueDate != null ? 'Due soon' : 'No date',
                                      onTap: () => context.go('/tasks'),
                                    ),
                                  )),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),
                          ],

                          // ── Today Tasks ─────────────────────────────────────
                          _SectionHeader(title: 'Today\'s Checklist', actionLabel: 'View All', onAction: () => context.go('/tasks')),
                          const SizedBox(height: 12),
                          if (todayTasks.isEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                              decoration: BoxDecoration(
                                color: EpicordiaColors.surfaceCardLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: EpicordiaColors.borderSubtleLight),
                              ),
                              child: Center(
                                child: Column(
                                  children: [
                                    const Icon(Icons.done_all_outlined, size: 24, color: EpicordiaColors.textTertiaryLight),
                                    const SizedBox(height: 8),
                                    const Text('All caught up for today!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: EpicordiaColors.textSecondaryLight)),
                                    const SizedBox(height: 4),
                                    GestureDetector(
                                      onTap: () => context.go('/create/task'),
                                      child: const Text('Add a task to schedule today', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: EpicordiaColors.blue600)),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ...todayTasks.map((task) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _TodayTaskItem(
                                task: task,
                                onToggle: () async {
                                  final newStatus = task.status == 'Done' ? 'To Do' : 'Done';
                                  await ref.read(taskRepositoryProvider).updateTask(
                                    task.copyWith(status: newStatus),
                                  );
                                },
                              ),
                            )),

                          const SizedBox(height: 28),

                          // ── Recent Boards ────────────────────────────────────
                          _SectionHeader(title: 'Your Boards', actionLabel: 'View All', onAction: () => context.go('/boards')),
                          const SizedBox(height: 12),
                          if (boards.isEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                              decoration: BoxDecoration(
                                color: EpicordiaColors.surfaceCardLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: EpicordiaColors.borderSubtleLight),
                              ),
                              child: Center(
                                child: Column(
                                  children: [
                                    const Icon(Icons.space_dashboard_outlined, size: 24, color: EpicordiaColors.textTertiaryLight),
                                    const SizedBox(height: 8),
                                    const Text('No boards created yet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: EpicordiaColors.textSecondaryLight)),
                                    const SizedBox(height: 4),
                                    GestureDetector(
                                      onTap: () => context.go('/create/board'),
                                      child: const Text('Create your first visual board', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: EpicordiaColors.blue600)),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ...boards.take(3).map((board) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _BoardCard(
                                board: board,
                                onTap: () => context.go('/board/${board.id}'),
                              ),
                            )),
                          const SizedBox(height: 32),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Friendly Empty Dashboard State
// ────────────────────────────────────────────────────────────
class _EmptyDashboardState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Big branding logo element
            Container(
              width: 80,
              height: 80,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: EpicordiaColors.blue100,
                shape: BoxShape.circle,
              ),
              child: Image.asset('assets/Logo.png', fit: BoxFit.contain),
            ),
            const SizedBox(height: 24),
            const Text(
              'Welcome to Epicordia',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: EpicordiaColors.textPrimaryLight),
            ),
            const SizedBox(height: 10),
            const Text(
              'Your digital zen workspace. Start by creating a visual board, capturing notes, or scheduling some to-do lists.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: EpicordiaColors.textSecondaryLight, height: 1.5),
            ),
            const SizedBox(height: 32),
            // CTA Button for Board
            ElevatedButton.icon(
              onPressed: () => context.go('/create/board'),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create a Board', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: EpicordiaColors.blue600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                elevation: 0,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.go('/create/note'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: EpicordiaColors.borderStrongLight),
                foregroundColor: EpicordiaColors.textPrimaryLight,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              ),
              child: const Text('Jot down a Note', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Activity Heatmap
// ────────────────────────────────────────────────────────────
class _ActivityHeatmap extends StatelessWidget {
  const _ActivityHeatmap();

  // 7 weeks × 7 days = 49 cells. 0=none, 1–4 = activity levels
  static final List<List<int>> _data = [
    [0, 1, 0, 2, 0, 1, 0],
    [1, 2, 3, 1, 0, 2, 1],
    [0, 1, 4, 3, 2, 1, 0],
    [2, 3, 2, 4, 3, 2, 1],
    [1, 0, 3, 2, 4, 3, 2],
    [0, 2, 1, 3, 2, 1, 0],
    [1, 1, 2, 1, 0, 2, 1],
  ];

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  Color _cellColor(int level) {
    switch (level) {
      case 1: return EpicordiaColors.blue200;
      case 2: return EpicordiaColors.blue300;
      case 3: return EpicordiaColors.blue400;
      case 4: return EpicordiaColors.blue500;
      default: return EpicordiaColors.borderSubtleLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Activity', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: EpicordiaColors.textPrimaryLight)),
            const Spacer(),
            _HeatmapLegend(),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: _dayLabels.map((d) => SizedBox(
                height: 14,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(d, style: const TextStyle(fontSize: 9, color: EpicordiaColors.textTertiaryLight)),
                ),
              )).toList(),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _data.map((week) {
                  return Column(
                    children: week.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200 + entry.key * 30),
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _cellColor(entry.value),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeatmapLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Less', style: TextStyle(fontSize: 9, color: EpicordiaColors.textTertiaryLight)),
        const SizedBox(width: 4),
        ...([EpicordiaColors.borderSubtleLight, EpicordiaColors.blue200, EpicordiaColors.blue300, EpicordiaColors.blue400, EpicordiaColors.blue500].map((c) =>
          Padding(
            padding: const EdgeInsets.only(left: 3),
            child: Container(width: 10, height: 10, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
          ),
        )),
        const SizedBox(width: 4),
        const Text('More', style: TextStyle(fontSize: 9, color: EpicordiaColors.textTertiaryLight)),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────
// Section header
// ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: EpicordiaColors.textPrimaryLight)),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(actionLabel!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: EpicordiaColors.blue600)),
          ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────
// Quick capture card
// ────────────────────────────────────────────────────────────
class _QuickCaptureCard extends StatelessWidget {
  final String category;
  final String title;
  final String time;
  final VoidCallback onTap;

  const _QuickCaptureCard({required this.category, required this.title, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: EpicordiaCard(
        onTap: onTap,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(category, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: EpicordiaColors.blue600, letterSpacing: 0.6)),
            const SizedBox(height: 6),
            Expanded(
              child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: EpicordiaColors.textPrimaryLight, height: 1.3), maxLines: 3, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.access_time, size: 10, color: EpicordiaColors.textTertiaryLight),
                const SizedBox(width: 4),
                Text(time, style: const TextStyle(fontSize: 10, color: EpicordiaColors.textTertiaryLight)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Today task item
// ────────────────────────────────────────────────────────────
class _TodayTaskItem extends StatelessWidget {
  final TaskEntity task;
  final VoidCallback onToggle;

  const _TodayTaskItem({required this.task, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final isCompleted = task.status == 'Done';

    return EpicordiaCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? EpicordiaColors.blue600 : Colors.transparent,
                border: Border.all(
                  color: isCompleted ? EpicordiaColors.blue600 : EpicordiaColors.borderStrongLight,
                  width: 1.5,
                ),
              ),
              child: isCompleted ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
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
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: EpicordiaColors.textPrimaryLight,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    decorationColor: EpicordiaColors.textTertiaryLight,
                  ),
                ),
                if (task.dueDate != null) ...[
                  const SizedBox(height: 2),
                  Text('Due ${task.dueDate!.month}/${task.dueDate!.day}', style: const TextStyle(fontSize: 11, color: EpicordiaColors.textTertiaryLight)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Board card
// ────────────────────────────────────────────────────────────
class _BoardCard extends StatelessWidget {
  final BoardEntity board;
  final VoidCallback onTap;

  const _BoardCard({required this.board, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return EpicordiaCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFF8B9DC3),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Center(
              child: Icon(Icons.dashboard_outlined, size: 28, color: Colors.white.withValues(alpha: 0.5)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(board.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: EpicordiaColors.textPrimaryLight)),
                const SizedBox(height: 2),
                const Text('View workspace', style: TextStyle(fontSize: 11, color: EpicordiaColors.textTertiaryLight)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
