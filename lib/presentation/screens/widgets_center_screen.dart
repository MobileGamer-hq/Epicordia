import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../data/repository/pin_repository.dart';
import '../../data/repository/task_repository.dart';
import '../../data/repository/board_repository.dart';
import '../../data/database/database.dart';
import '../../core/widgets/widget_service.dart';
import '../../domain/models/task_subitem.dart';
import '../notifiers/alarm_timer_provider.dart';

class WidgetsCenterScreen extends ConsumerStatefulWidget {
  const WidgetsCenterScreen({super.key});

  @override
  ConsumerState<WidgetsCenterScreen> createState() => _WidgetsCenterScreenState();
}

class _WidgetsCenterScreenState extends ConsumerState<WidgetsCenterScreen> {
  PinEntity? _selectedNote;
  TaskEntity? _selectedTask;
  TaskEntity? _selectedSubtaskTask;

  void _showNotePickerDialog(List<PinEntity> notes, Map<String, BoardEntity> boardsMap) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Pinned Note'),
        content: SizedBox(
          width: double.maxFinite,
          height: 350,
          child: notes.isEmpty
              ? const Center(child: Text('No notes available'))
              : ListView.separated(
                  itemCount: notes.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final note = notes[idx];
                    final lines = (note.content ?? '').split('\n');
                    final title = lines.isNotEmpty && lines[0].trim().isNotEmpty ? lines[0] : 'Untitled Note';
                    final boardTitle = boardsMap[note.boardId]?.title ?? 'Inbox';

                    return ListTile(
                      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text('In $boardTitle', style: const TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.push_pin_outlined, size: 18),
                      onTap: () {
                        setState(() => _selectedNote = note);
                        Navigator.of(ctx).pop();
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showTaskPickerDialog(List<TaskEntity> tasks, Map<String, BoardEntity> boardsMap, {bool isForSubtasks = false}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isForSubtasks ? 'Select Task with Subtasks' : 'Select Pinned Task'),
        content: SizedBox(
          width: double.maxFinite,
          height: 350,
          child: tasks.isEmpty
              ? const Center(child: Text('No tasks available'))
              : ListView.separated(
                  itemCount: tasks.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final task = tasks[idx];
                    final boardTitle = boardsMap[task.boardId]?.title ?? 'Inbox';
                    final subitemsCount = TaskSubitem.decodeNotes(task.notes).subitems.length;

                    return ListTile(
                      title: Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text('In $boardTitle • $subitemsCount subtasks', style: const TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.check_circle_outline, size: 18),
                      onTap: () {
                        setState(() {
                          if (isForSubtasks) {
                            _selectedSubtaskTask = task;
                          } else {
                            _selectedTask = task;
                          }
                        });
                        Navigator.of(ctx).pop();
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgApp = isDark ? EpicordiaColors.surfaceAppDark : EpicordiaColors.surfaceAppLight;
    final cardBg = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final borderClr = isDark ? EpicordiaColors.borderStrongDark : EpicordiaColors.borderSubtleLight;

    final notesAsync = ref.watch(allNotesProvider);
    final tasksAsync = ref.watch(allTasksProvider);
    final boardsAsync = ref.watch(allBoardsProvider);
    final timetableAsync = ref.watch(allTimetableSlotsProvider);
    final alarmsState = ref.watch(alarmTimerProvider);

    final boardsMap = boardsAsync.value?.fold<Map<String, BoardEntity>>(
          {},
          (map, b) {
            map[b.id] = b;
            return map;
          },
        ) ??
        {};

    final notesList = notesAsync.value ?? [];
    final tasksList = tasksAsync.value ?? [];
    final timetableSlots = timetableAsync.value ?? [];

    final note = _selectedNote ?? (notesList.isNotEmpty ? notesList.first : null);
    final task = _selectedTask ?? (tasksList.isNotEmpty ? tasksList.first : null);
    final subtaskTask = _selectedSubtaskTask ?? (tasksList.isNotEmpty ? tasksList.first : null);
    final subitemsPayload = subtaskTask != null ? TaskSubitem.decodeNotes(subtaskTask.notes) : null;

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
          'Home Screen Widgets',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customize widgets to display specific notes, featured tasks, task subtasks, focus heatmaps, daily schedule, and session countdowns on your device home screen.',
              style: TextStyle(fontSize: 13, color: textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),

            // 1. Quick Capture Widget Preview & Action
            _buildWidgetPreviewCard(
              context: context,
              title: 'Create Widget',
              icon: Icons.add_circle_outline,
              cardBg: cardBg,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              borderClr: borderClr,
              previewWidget: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF23262D) : const Color(0xFFF8F9FB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderClr),
                ),
                child: Center(
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: EpicordiaColors.blue600,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Icon(Icons.add, color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ),
              onSync: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Create Widget takes you directly to the Create Hub screen!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // 2. Focus Heatmap Widget Preview
            _buildWidgetPreviewCard(
              context: context,
              title: 'Focus Heatmap Widget',
              icon: Icons.grid_view_rounded,
              cardBg: cardBg,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              borderClr: borderClr,
              previewWidget: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF23262D) : const Color(0xFFF8F9FB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderClr),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('82% Focus Rate', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: EpicordiaColors.blue600)),
                    const SizedBox(height: 2),
                    Text('Visual Workflow • August 2026', style: TextStyle(fontSize: 11, color: textSecondary)),
                    const SizedBox(height: 10),
                    // 28 day activity grid preview
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 4,
                        crossAxisSpacing: 4,
                        childAspectRatio: 1.5,
                      ),
                      itemCount: 28,
                      itemBuilder: (ctx, idx) {
                        final level = (idx % 3 == 0) ? (idx % 4) : 0;
                        final clr = level == 3
                            ? const Color(0xFF1D4ED8)
                            : level == 2
                                ? const Color(0xFF3B82F6)
                                : level == 1
                                    ? const Color(0xFF93C5FD)
                                    : (isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0));
                        return Container(
                          decoration: BoxDecoration(
                            color: clr,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              onSync: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Focus Heatmap Widget synced!'), behavior: SnackBarBehavior.floating),
                );
              },
            ),

            const SizedBox(height: 20),

            // 3. Task & Subtasks Widget Preview & Control
            _buildWidgetPreviewCard(
              context: context,
              title: 'Task & Subtasks Widget',
              icon: Icons.checklist_rtl_rounded,
              cardBg: cardBg,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              borderClr: borderClr,
              previewWidget: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF23262D) : const Color(0xFFF8F9FB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderClr),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: EpicordiaColors.blue600.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        boardsMap[subtaskTask?.boardId]?.title ?? 'INBOX',
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: EpicordiaColors.blue600),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtaskTask?.title ?? 'No Task Selected',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subitemsPayload != null && subitemsPayload.subitems.isNotEmpty
                          ? '${subitemsPayload.subitems.where((s) => s.isDone).length}/${subitemsPayload.subitems.length} subtasks completed'
                          : 'No subtasks attached to task',
                      style: TextStyle(fontSize: 11, color: textSecondary),
                    ),
                    if (subitemsPayload != null && subitemsPayload.subitems.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ...subitemsPayload.subitems.take(3).map((sub) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Icon(
                                sub.isDone ? Icons.check_box_outlined : Icons.check_box_outline_blank,
                                size: 14,
                                color: sub.isDone ? EpicordiaColors.blue600 : textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  sub.title,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textPrimary,
                                    decoration: sub.isDone ? TextDecoration.lineThrough : null,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
              onSelect: () => _showTaskPickerDialog(tasksList, boardsMap, isForSubtasks: true),
              onSync: subtaskTask != null
                  ? () async {
                      final boardTitle = boardsMap[subtaskTask.boardId]?.title ?? 'Inbox';
                      await ref.read(widgetServiceProvider).syncTaskWithSubtasks(subtaskTask, boardTitle);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Task & Subtasks Widget synced!'), behavior: SnackBarBehavior.floating),
                        );
                      }
                    }
                  : null,
            ),

            const SizedBox(height: 20),

            // 4. Pinned Note Widget Preview & Control
            _buildWidgetPreviewCard(
              context: context,
              title: 'Pinned Note Widget',
              icon: Icons.sticky_note_2_outlined,
              cardBg: cardBg,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              borderClr: borderClr,
              previewWidget: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF23262D) : const Color(0xFFF8F9FB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderClr),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: EpicordiaColors.blue600.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            boardsMap[note?.boardId]?.title ?? 'INBOX',
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: EpicordiaColors.blue600),
                          ),
                        ),
                        Text(
                          note != null ? '${note.modifiedAt.month}/${note.modifiedAt.day}' : 'Today',
                          style: TextStyle(fontSize: 10, color: textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      note != null
                          ? ((note.content ?? '').split('\n').first.isNotEmpty
                              ? (note.content ?? '').split('\n').first
                              : 'Untitled Note')
                          : 'No Note Selected',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      note != null && (note.content ?? '').split('\n').length > 1
                          ? (note.content ?? '').split('\n').sublist(1).join('\n')
                          : 'Tap below to select a note to pin on your home screen.',
                      style: TextStyle(fontSize: 11, color: textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              onSelect: () => _showNotePickerDialog(notesList, boardsMap),
              onSync: note != null
                  ? () async {
                      final boardTitle = boardsMap[note.boardId]?.title ?? 'Inbox';
                      await ref.read(widgetServiceProvider).syncPinnedNoteWidget(note, boardTitle);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Pinned Note Widget synced!'), behavior: SnackBarBehavior.floating),
                        );
                      }
                    }
                  : null,
            ),

            const SizedBox(height: 20),

            // 5. Featured Pinned Task Widget
            _buildWidgetPreviewCard(
              context: context,
              title: 'Featured Task Widget',
              icon: Icons.task_alt,
              cardBg: cardBg,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              borderClr: borderClr,
              previewWidget: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF23262D) : const Color(0xFFF8F9FB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderClr),
                ),
                child: Row(
                  children: [
                    Icon(
                      task?.status == 'Done' ? Icons.check_circle : Icons.circle_outlined,
                      color: EpicordiaColors.blue600,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task?.title ?? 'No Task Selected',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            task?.dueDate != null ? 'Due ${task!.dueDate!.month}/${task.dueDate!.day}' : 'No due date set',
                            style: TextStyle(fontSize: 11, color: textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              onSelect: () => _showTaskPickerDialog(tasksList, boardsMap),
              onSync: task != null
                  ? () async {
                      final boardTitle = boardsMap[task.boardId]?.title ?? 'Inbox';
                      await ref.read(widgetServiceProvider).syncPinnedTaskWidget(task, boardTitle);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Featured Task Widget synced!'), behavior: SnackBarBehavior.floating),
                        );
                      }
                    }
                  : null,
            ),

            const SizedBox(height: 20),

            // 6. Daily Schedule Widget
            _buildWidgetPreviewCard(
              context: context,
              title: 'Daily Schedule Widget',
              icon: Icons.calendar_month,
              cardBg: cardBg,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              borderClr: borderClr,
              previewWidget: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF23262D) : const Color(0xFFF8F9FB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderClr),
                ),
                child: timetableSlots.isEmpty
                    ? Text('No schedule events set for today', style: TextStyle(fontSize: 12, color: textSecondary))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: timetableSlots.take(2).map((slot) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                const Icon(Icons.schedule, size: 12, color: EpicordiaColors.blue600),
                                const SizedBox(width: 6),
                                Text('${slot.startTime} - ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textPrimary)),
                                Expanded(
                                  child: Text(slot.title, style: TextStyle(fontSize: 11, color: textSecondary), overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),
              onSync: () async {
                await ref.read(widgetServiceProvider).syncDailyScheduleWidget(timetableSlots);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Daily Schedule Widget synced!'), behavior: SnackBarBehavior.floating),
                  );
                }
              },
            ),

            const SizedBox(height: 20),

            // 7. Sessions & Alarms Widget
            _buildWidgetPreviewCard(
              context: context,
              title: 'Sessions & Alarms Widget',
              icon: Icons.timer_outlined,
              cardBg: cardBg,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              borderClr: borderClr,
              previewWidget: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF23262D) : const Color(0xFFF8F9FB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderClr),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.alarm, color: EpicordiaColors.blue600, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alarmsState.alarms.isNotEmpty ? alarmsState.alarms.first.title : 'Focus Session Alarm',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                          ),
                          Text(
                            alarmsState.alarms.isNotEmpty
                                ? '${alarmsState.alarms.first.hour}:${alarmsState.alarms.first.minute.toString().padLeft(2, '0')}'
                                : '07:30 AM',
                            style: TextStyle(fontSize: 11, color: textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              onSync: () async {
                if (alarmsState.alarms.isNotEmpty) {
                  await ref.read(widgetServiceProvider).syncSessionWidget(alarmsState.alarms.first);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Session Widget synced!'), behavior: SnackBarBehavior.floating),
                    );
                  }
                }
              },
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildWidgetPreviewCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color cardBg,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderClr,
    required Widget previewWidget,
    VoidCallback? onSelect,
    VoidCallback? onSync,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderClr),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: EpicordiaColors.blue600, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          previewWidget,
          const SizedBox(height: 14),
          Row(
            children: [
              if (onSelect != null)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textPrimary,
                    side: BorderSide(color: borderClr),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.touch_app_outlined, size: 16),
                  label: const Text('Change Selection'),
                  onPressed: onSelect,
                ),
              const Spacer(),
              if (onSync != null)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: EpicordiaColors.blue600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.sync, size: 16),
                  label: const Text('Sync Widget'),
                  onPressed: onSync,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
