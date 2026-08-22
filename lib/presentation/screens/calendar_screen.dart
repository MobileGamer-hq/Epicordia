import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/repository/task_repository.dart';
import '../../data/repository/pin_repository.dart';
import '../../data/repository/board_repository.dart';
import '../../data/database/database.dart';
import '../../core/theme.dart';
import '../../domain/services/data_export_service.dart';
import '../../data/providers.dart';
import '../widgets/permission_explanation_dialog.dart';
import '../widgets/timetable_kanban_view.dart';
import '../widgets/core/interactive_task_card.dart';
import '../widgets/core/interactive_note_card.dart';
import 'today_dashboard.dart';

import '../widgets/device_sync_review_sheet.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  int _activeViewIndex = 0; // 0 = Calendar, 1 = Timetable (Kanban)

  Future<void> _handleExport(String type) async {
    final db = ref.read(databaseProvider);
    final tasks = ref.read(allTasksProvider).value ?? [];
    final boards = ref.read(allBoardsProvider).value ?? [];
    final timetableSlots = ref.read(allTimetableSlotsProvider).value ?? [];

    final boardsMap = {for (final b in boards) b.id: b};

    String fileContent = '';
    String fileName = '';

    if (type == 'json') {
      fileContent = await DataExportService.generateWorkspaceJson(db);
      fileName = 'epicordia_workspace_export.json';
    } else if (type == 'csv_tasks') {
      fileContent = DataExportService.exportTasksToCsv(tasks, boardsMap);
      fileName = 'epicordia_tasks_export.csv';
    } else if (type == 'csv_timetable') {
      fileContent = DataExportService.exportTimetableToCsv(timetableSlots);
      fileName = 'epicordia_timetable_export.csv';
    }

    final path = await DataExportService.saveExportToFile(
      fileName: fileName,
      content: fileContent,
    );

    if (mounted && path != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export saved: $fileName'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

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
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Interactive Calendar',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync Device Calendar & Alarms',
            onPressed: () async {
              final proceed = await PermissionExplanationDialog.show(
                context: context,
                title: 'Sync Device Calendar & Alarms',
                description:
                    'Epicordia will fetch device calendar events and alarms so you can review and select items to import.',
                icon: Icons.calendar_month_outlined,
              );
              if (!proceed || !context.mounted) return;
              DeviceSyncReviewSheet.show(context);
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export Data',
            onSelected: _handleExport,
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'json',
                child: Row(
                  children: [
                    Icon(Icons.code, size: 18),
                    SizedBox(width: 8),
                    Text('Export Schedule (JSON)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'csv_timetable',
                child: Row(
                  children: [
                    Icon(Icons.table_chart, size: 18),
                    SizedBox(width: 8),
                    Text('Export Weekly Schedule (CSV)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'csv_tasks',
                child: Row(
                  children: [
                    Icon(Icons.list_alt, size: 18),
                    SizedBox(width: 8),
                    Text('Export Tasks (CSV)'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            // View Mode Switcher: Calendar vs Weekly Schedule (Kanban)
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTabItem(
                      index: 0,
                      label: 'Calendar',
                      icon: Icons.calendar_month_outlined,
                      isDark: isDark,
                    ),
                    _buildTabItem(
                      index: 1,
                      label: 'Schedule',
                      icon: Icons.view_week_outlined,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _activeViewIndex == 1
                  ? const TimetableKanbanView()
                  : SelectionArea(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 600;

                          if (isWide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left Column (55%): Heatmap Calendar
                                Expanded(
                                  flex: 55,
                                  child: ListView(
                                    padding: const EdgeInsets.only(
                                      left: 20,
                                      right: 12,
                                      top: 8,
                                      bottom: 40,
                                    ),
                                    children: [
                                      _buildHeatmapHero(cardBg: cardBg, borderClr: borderClr),
                                    ],
                                  ),
                                ),
                                // Right Column (45%): Tasks & Notes for Selected Day
                                Expanded(
                                  flex: 45,
                                  child: ListView(
                                    padding: const EdgeInsets.only(
                                      left: 12,
                                      right: 20,
                                      top: 8,
                                      bottom: 40,
                                    ),
                                    children: [
                                      Text(
                                        _formatDateHeader(_selectedDate),
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      ..._buildDayContent(
                                        dayTasks: dayTasks,
                                        dayNotes: dayNotes,
                                        boardsMap: boardsMap,
                                        textPrimary: textPrimary,
                                        textSecondary: textSecondary,
                                        textTertiary: textTertiary,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }

                          // Compact Mobile Layout (< 600px)
                          return ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            children: [
                              // Heatmap inside Hero (scrolls with list)
                              _buildHeatmapHero(cardBg: cardBg, borderClr: borderClr),
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
                              ..._buildDayContent(
                                dayTasks: dayTasks,
                                dayNotes: dayNotes,
                                boardsMap: boardsMap,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                                textTertiary: textTertiary,
                              ),
                              const SizedBox(height: 40),
                            ],
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmapHero({
    required Color cardBg,
    required Color borderClr,
  }) {
    return Hero(
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
    );
  }

  List<Widget> _buildDayContent({
    required List<TaskEntity> dayTasks,
    required List<PinEntity> dayNotes,
    required Map<String, BoardEntity> boardsMap,
    required Color textPrimary,
    required Color textSecondary,
    required Color textTertiary,
  }) {
    if (dayTasks.isEmpty && dayNotes.isEmpty) {
      return [
        const SizedBox(height: 32),
        Center(
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
        ),
      ];
    }

    final widgets = <Widget>[];

    if (dayTasks.isNotEmpty) {
      widgets.add(
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
      );
      widgets.addAll(dayTasks.map((task) {
        final boardTitle = boardsMap[task.boardId]?.title ?? 'Inbox';
        final boardColor = _getBoardColor(task.boardId);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InteractiveTaskCard(
            task: task,
            boardTitle: boardTitle,
            boardColor: boardColor,
          ),
        );
      }));
      widgets.add(const SizedBox(height: 12));
    }

    if (dayNotes.isNotEmpty) {
      widgets.add(
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
      );
      widgets.addAll(dayNotes.map((note) {
        final boardTitle = boardsMap[note.boardId]?.title ?? 'Inbox';
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InteractiveNoteCard(
            note: note,
            boardTitle: boardTitle,
          ),
        );
      }));
    }

    return widgets;
  }

  Widget _buildTabItem({
    required int index,
    required String label,
    required IconData icon,
    required bool isDark,
  }) {
    final isActive = _activeViewIndex == index;
    final activeBlue = EpicordiaColors.blue500;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;

    return GestureDetector(
      onTap: () => setState(() => _activeViewIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Simple wrappers for lists to avoid layout differences

