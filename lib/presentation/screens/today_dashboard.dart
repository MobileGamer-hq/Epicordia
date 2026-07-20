import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/layout/responsive_scaffold.dart';
import '../widgets/core/epicordia_brand.dart';
import '../widgets/core/epicordia_card.dart';
import '../../data/repository/task_repository.dart';
import '../../data/repository/board_repository.dart';
import '../../data/repository/pin_repository.dart';
import '../../data/database/database.dart';
import '../../core/theme.dart';

class TodayDashboard extends ConsumerWidget {
  const TodayDashboard({super.key});

  String _formatModified(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inMinutes < 60) {
      return 'Modified ${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return 'Modified ${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Modified Yesterday';
    } else {
      return 'Modified ${date.month}/${date.day}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute $ampm';
  }

  Color _getBoardColor(String? boardId) {
    if (boardId == null) return Colors.grey;
    final colors = [const Color(0xFF8B9DC3), const Color(0xFFA8B4C8), const Color(0xFF6B7FA0), const Color(0xFF9EAAC4)];
    return colors[boardId.hashCode % colors.length];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unsortedNotesAsync = ref.watch(unsortedNotesProvider);
    final todayTasksAsync = ref.watch(tasksDueTodayProvider);
    final recentBoardsAsync = ref.watch(allBoardsProvider);

    return ResponsiveScaffold(
      appBar: const EpicordiaAppBar(),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            children: [
              // Activity Heatmap
              const _ActivityHeatmap(),
              const SizedBox(height: 28),
          
              // Unsorted Tray
              _SectionHeader(title: 'Unsorted Tray', actionLabel: 'View All', onAction: () => context.push('/notes')),
              const SizedBox(height: 12),
              unsortedNotesAsync.when(
                loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
                error: (err, stack) => Text('Error: $err'),
                data: (notes) {
                  if (notes.isEmpty) {
                    return _SectionEmptyState(
                      icon: Icons.sticky_note_2_outlined,
                      title: 'No unsorted items to put there',
                      subtitle: 'You can get started creating with the button below.',
                      createLabel: 'Capture Note',
                      onCreate: () => context.push('/create/note'),
                    );
                  }
                  return SizedBox(
                    height: 160,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: notes.length,
                      itemBuilder: (context, index) {
                        final note = notes[index];
                        final lines = (note.content ?? '').split('\n');
                        final title = lines.isNotEmpty && lines[0].trim().isNotEmpty ? lines[0] : 'Untitled Note';
                        final preview = lines.length > 1 ? lines.sublist(1).join('\n').trim() : null;

                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: _QuickCaptureCard(
                            category: 'QUICK CAPTURE',
                            title: title,
                            preview: preview,
                            time: _formatModified(note.modifiedAt),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
          
              const SizedBox(height: 28),
          
              // Today Tasks
              _SectionHeader(title: 'Today', actionLabel: 'View All', onAction: () => context.push('/tasks')),
              const SizedBox(height: 12),
              todayTasksAsync.when(
                loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
                error: (err, stack) => Text('Error: $err'),
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return _SectionEmptyState(
                      icon: Icons.check_box_outlined,
                      title: 'No tasks for today',
                      subtitle: 'There are no tasks to put there. You can get started creating with the button below.',
                      createLabel: 'Add Task',
                      onCreate: () => context.push('/create/task'),
                    );
                  }
                  return Column(
                    children: tasks.map((task) {
                      final isCompleted = task.status == 'done';
                      final meta = task.dueDate != null ? 'Due ${_formatTime(task.dueDate!)}' : 'No due date';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _TodayTaskItem(
                          title: task.title,
                          meta: isCompleted ? 'Completed' : meta,
                          isCompleted: isCompleted,
                          isInProgress: task.status == 'in_progress',
                          onToggle: () {
                            final newStatus = isCompleted ? 'todo' : 'done';
                            ref.read(taskRepositoryProvider).updateTask(task.copyWith(status: newStatus));
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
          
              const SizedBox(height: 28),
          
              // ── Recent Boards ────────────────────────────────────
              _SectionHeader(title: 'Recent Boards', actionLabel: 'View All', onAction: () => context.push('/boards')),
              const SizedBox(height: 12),
              recentBoardsAsync.when(
                loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
                error: (err, stack) => Text('Error: $err'),
                data: (boards) {
                  if (boards.isEmpty) {
                    return _SectionEmptyState(
                      icon: Icons.space_dashboard_outlined,
                      title: 'No recent boards to put there',
                      subtitle: 'You can get started creating with the button below.',
                      createLabel: 'Create Board',
                      onCreate: () => context.push('/create/board'),
                    );
                  }

                  // Take most recent 3 boards
                  final recent = boards.toList()..sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
                  final top3 = recent.take(3).toList();

                  return Column(
                    children: top3.map((board) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () => context.push('/board/${board.id}'),
                          child: _BoardCard(
                            title: board.title,
                            meta: 'Modified ${_formatModified(board.modifiedAt)}',
                            color: _getBoardColor(board.id),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section empty state component ──────────────────────────────
class _SectionEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onCreate;
  final String createLabel;

  const _SectionEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onCreate,
    required this.createLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: EpicordiaColors.surfaceCardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EpicordiaColors.borderSubtleLight),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: EpicordiaColors.surfaceSunkenLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: EpicordiaColors.textTertiaryLight),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: EpicordiaColors.textPrimaryLight),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: EpicordiaColors.textTertiaryLight),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: EpicordiaColors.borderStrongLight),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            onPressed: onCreate,
            icon: const Icon(Icons.add, size: 14, color: EpicordiaColors.textSecondaryLight),
            label: Text(createLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: EpicordiaColors.textSecondaryLight)),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Activity Heatmap
// ────────────────────────────────────────────────────────────
class _ActivityHeatmap extends StatelessWidget {
  const _ActivityHeatmap();

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
            const SizedBox(width: 6),
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
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: EpicordiaColors.textPrimaryLight)),
        if (actionLabel != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Text(actionLabel!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: EpicordiaColors.blue600)),
          ),
      ],
    );
  }
}

class _QuickCaptureCard extends StatelessWidget {
  final String category;
  final String title;
  final String? preview;
  final String? time;

  const _QuickCaptureCard({required this.category, required this.title, this.preview, this.time});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: EpicordiaCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(category, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: EpicordiaColors.textTertiaryLight, letterSpacing: 0.8)),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: EpicordiaColors.textPrimaryLight, height: 1.3), maxLines: 3, overflow: TextOverflow.ellipsis),
            if (preview != null) ...[
              const SizedBox(height: 8),
              Text(preview!, style: const TextStyle(fontSize: 11, color: EpicordiaColors.textTertiaryLight, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            if (time != null) ...[
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 11, color: EpicordiaColors.textTertiaryLight),
                  const SizedBox(width: 4),
                  Text(time!, style: const TextStyle(fontSize: 10, color: EpicordiaColors.textTertiaryLight)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TodayTaskItem extends StatelessWidget {
  final String title;
  final String meta;
  final bool isCompleted;
  final bool isInProgress;
  final VoidCallback onToggle;

  const _TodayTaskItem({
    required this.title,
    required this.meta,
    required this.isCompleted,
    required this.isInProgress,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return EpicordiaCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isInProgress ? EpicordiaColors.blue600 : Colors.transparent,
                border: Border.all(
                  color: isCompleted ? EpicordiaColors.blue600 : EpicordiaColors.borderStrongLight,
                  width: 1.5,
                ),
              ),
              child: isCompleted ? const Icon(Icons.check, size: 13, color: Colors.white) : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: EpicordiaColors.textPrimaryLight,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    decorationColor: EpicordiaColors.textTertiaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(meta, style: const TextStyle(fontSize: 12, color: EpicordiaColors.textTertiaryLight)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BoardCard extends StatelessWidget {
  final String title;
  final String meta;
  final Color color;

  const _BoardCard({required this.title, required this.meta, required this.color});

  @override
  Widget build(BuildContext context) {
    return EpicordiaCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 110,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Center(
              child: Icon(Icons.dashboard_outlined, size: 36, color: Colors.white.withValues(alpha: 0.5)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: EpicordiaColors.textPrimaryLight)),
                const SizedBox(height: 2),
                Text(meta, style: const TextStyle(fontSize: 12, color: EpicordiaColors.textTertiaryLight)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
