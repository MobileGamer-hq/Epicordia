import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'today_dashboard.dart';

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
    final weekTasksStream = ref.watch(taskRepositoryProvider).watchTasksDueThisWeek();
    final unsortedTasksStream = ref.watch(taskRepositoryProvider).watchUnsortedTasks();
    final unsortedNotesStream = ref.watch(pinRepositoryProvider).watchUnsortedNotes();

    return ResponsiveScaffold(
      appBar: const EpicordiaAppBar(),
      child: StreamBuilder(
        stream: boardsStream,
        builder: (context, boardsSnapshot) {
          final boards = boardsSnapshot.data ?? [];

          return StreamBuilder(
            stream: weekTasksStream,
            builder: (context, tasksSnapshot) {
              final weekTasks = tasksSnapshot.data ?? [];

              return StreamBuilder(
                stream: unsortedTasksStream,
                builder: (context, unsortedTasksSnapshot) {
                  final unsortedTasks = unsortedTasksSnapshot.data ?? [];

                  return StreamBuilder(
                    stream: unsortedNotesStream,
                    builder: (context, unsortedNotesSnapshot) {
                      final unsortedNotes = unsortedNotesSnapshot.data ?? [];

                      // If there is absolutely no data in the database (no boards, no tasks, no unsorted items)
                      if (boards.isEmpty && weekTasks.isEmpty && unsortedTasks.isEmpty && unsortedNotes.isEmpty) {
                        return _EmptyDashboardState();
                      }

                      return ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        children: [
                          // ── Activity Heatmap ─────────────────────────────────
                          const ActivityHeatmap(),
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

                          // ── Tasks for the Week ──────────────────────────────
                          _SectionHeader(title: 'Tasks for the Week', actionLabel: 'View All', onAction: () => context.go('/tasks')),
                          const SizedBox(height: 12),
                          if (weekTasks.isEmpty)
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
                                    const Text('No tasks due this week!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: EpicordiaColors.textSecondaryLight)),
                                    const SizedBox(height: 4),
                                    GestureDetector(
                                      onTap: () => context.push('/create/task'),
                                      child: Text('Add a task for this week', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: EpicordiaColors.blue600)),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ...weekTasks.map((task) => Padding(
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
                                      onTap: () => context.push('/create/board'),
                                      child: Text('Create your first visual board', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: EpicordiaColors.blue600)),
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
                                onTap: () => context.push('/board/${board.id}'),
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
              onPressed: () => context.push('/create/board'),
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
              onPressed: () => context.push('/create/note'),
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
            child: Text(actionLabel!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: EpicordiaColors.blue600)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;

    return SizedBox(
      width: 150,
      child: EpicordiaCard(
        onTap: onTap,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(category, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: EpicordiaColors.blue600, letterSpacing: 0.6)),
            const SizedBox(height: 6),
            Expanded(
              child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary, height: 1.3), maxLines: 3, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.access_time, size: 10, color: textTertiary),
                const SizedBox(width: 4),
                Text(time, style: TextStyle(fontSize: 10, color: textTertiary)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;
    final borderStrong = isDark ? EpicordiaColors.borderStrongDark : EpicordiaColors.borderStrongLight;

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
                  color: isCompleted ? EpicordiaColors.blue600 : borderStrong,
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
                    color: textPrimary,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    decorationColor: textTertiary,
                  ),
                ),
                if (task.dueDate != null) ...[
                  const SizedBox(height: 2),
                  Text('Due ${task.dueDate!.month}/${task.dueDate!.day}', style: TextStyle(fontSize: 11, color: textTertiary)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;

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
                Text(board.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
                const SizedBox(height: 2),
                Text('View workspace', style: TextStyle(fontSize: 11, color: textTertiary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
