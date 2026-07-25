import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/layout/responsive_scaffold.dart';
import '../widgets/core/epicordia_brand.dart';
import '../widgets/core/epicordia_card.dart';
import '../../data/repository/task_repository.dart';
import '../../data/repository/pin_repository.dart';

import '../../core/theme.dart';
import 'search_screen.dart';

class TodayDashboard extends ConsumerStatefulWidget {
  const TodayDashboard({super.key});

  @override
  ConsumerState<TodayDashboard> createState() => _TodayDashboardState();
}

class _TodayDashboardState extends ConsumerState<TodayDashboard> {
  String _userName = 'Somto';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name');
    if (name != null && name.isNotEmpty) {
      setState(() {
        _userName = name;
      });
    }
  }

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


  void _showSearchScreen(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const EpicordiaSearchScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final tween = Tween(begin: const Offset(0.0, -1.0), end: Offset.zero)
              .chain(CurveTween(curve: Curves.fastOutSlowIn));
          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unsortedNotesAsync = ref.watch(unsortedNotesProvider);
    final todayTasksAsync = ref.watch(tasksDueTodayProvider);
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good morning'
        : now.hour < 17
        ? 'Good afternoon'
        : 'Good evening';

    return ResponsiveScaffold(
      appBar: EpicordiaAppBar(
        onSearch: () => _showSearchScreen(context),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting, $_userName',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: EpicordiaColors.textPrimaryLight,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Here's your workspace overview for today.",
                      style: TextStyle(
                        fontSize: 14,
                        color: EpicordiaColors.textTertiaryLight,
                      ),
                    ),
                  ],
                ),
              ),

              // Activity Heatmap
              Hero(
                tag: 'heatmap-hero',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => context.push('/calendar'),
                    borderRadius: BorderRadius.circular(12),
                    child: const ActivityHeatmap(),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Unsorted Tray
              _SectionHeader(title: 'Recent Notes', actionLabel: 'View All', onAction: () => context.push('/notes')),
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

              // const SizedBox(height: 28),
              //
              // // ── Recent Boards ────────────────────────────────────
              // _SectionHeader(title: 'Recent Boards', actionLabel: 'View All', onAction: () => context.push('/boards')),
              // const SizedBox(height: 12),
              // recentBoardsAsync.when(
              //   loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
              //   error: (err, stack) => Text('Error: $err'),
              //   data: (boards) {
              //     if (boards.isEmpty) {
              //       return _SectionEmptyState(
              //         icon: Icons.space_dashboard_outlined,
              //         title: 'No recent boards to put there',
              //         subtitle: 'You can get started creating with the button below.',
              //         createLabel: 'Create Board',
              //         onCreate: () => context.push('/create/board'),
              //       );
              //     }
              //
              //     // Take most recent 3 boards
              //     final recent = boards.toList()..sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
              //     final top3 = recent.take(3).toList();
              //
              //     return Column(
              //       children: top3.map((board) {
              //         return Padding(
              //           padding: const EdgeInsets.only(bottom: 12),
              //           child: GestureDetector(
              //             onTap: () => context.push('/board/${board.id}'),
              //             child: _BoardCard(
              //               title: board.title,
              //               meta: 'Modified ${_formatModified(board.modifiedAt)}',
              //               color: _getBoardColor(board.id),
              //             ),
              //           ),
              //         );
              //       }).toList(),
              //     );
              //   },
              // ),
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
class ActivityHeatmap extends StatefulWidget {
  final Function(DateTime)? onTapDate;
  final DateTime? selectedMonth;
  final DateTime? selectedDate;
  const ActivityHeatmap({
    super.key,
    this.onTapDate,
    this.selectedMonth,
    this.selectedDate,
  });

  @override
  State<ActivityHeatmap> createState() => _ActivityHeatmapState();
}

class _ActivityHeatmapState extends State<ActivityHeatmap> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = widget.selectedMonth ?? DateTime.now();
  }

  @override
  void didUpdateWidget(covariant ActivityHeatmap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedMonth != null && widget.selectedMonth != oldWidget.selectedMonth) {
      _selectedMonth = widget.selectedMonth!;
    }
  }

  /// Example activity data.
  ///
  /// The key is the date and the value is the activity level.
  /// Replace this with your actual activity data.
  final Map<DateTime, int> _activityData = {
    DateTime(2026, 7, 1): 1,
    DateTime(2026, 7, 2): 2,
    DateTime(2026, 7, 3): 3,
    DateTime(2026, 7, 5): 4,
    DateTime(2026, 7, 8): 2,
    DateTime(2026, 7, 10): 3,
    DateTime(2026, 7, 15): 4,
    DateTime(2026, 7, 18): 2,
  };

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  Color _cellColor(int level, bool isDark) {
    if (isDark) {
      switch (level) {
        case 1:
          return const Color(0xFF1B3A60);
        case 2:
          return const Color(0xFF1D5A94);
        case 3:
          return const Color(0xFF0096C7);
        case 4:
          return EpicordiaColors.darkPrimary;
        default:
          return EpicordiaColors.surfaceSunkenDark;
      }
    } else {
      switch (level) {
        case 1:
          return EpicordiaColors.blue200;
        case 2:
          return EpicordiaColors.blue300;
        case 3:
          return EpicordiaColors.blue400;
        case 4:
          return EpicordiaColors.blue500;
        default:
          return EpicordiaColors.borderSubtleLight;
      }
    }
  }

  String _monthName(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[date.month - 1];
  }

  /// Returns the activity level for a specific day.
  int _getActivityLevel(DateTime date) {
    final normalizedDate = DateTime(
      date.year,
      date.month,
      date.day,
    );

    return _activityData[normalizedDate] ?? 0;
  }

  /// Generates all the days required to display the selected month.
  ///
  /// Monday is the first day of the week.
  List<List<DateTime?>> _generateCalendar() {
    final firstDayOfMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month,
      1,
    );

    final lastDayOfMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    );

    // DateTime.weekday:
    // Monday = 1
    // Sunday = 7
    final firstDayOffset = firstDayOfMonth.weekday - 1;

    final totalDays = lastDayOfMonth.day;

    final totalCells = firstDayOffset + totalDays;

    final numberOfWeeks = (totalCells / 7).ceil();

    final calendar = <List<DateTime?>>[];

    for (int week = 0; week < numberOfWeeks; week++) {
      final weekDays = <DateTime?>[];

      for (int day = 0; day < 7; day++) {
        final dayIndex = week * 7 + day;

        if (dayIndex < firstDayOffset ||
            dayIndex >= firstDayOffset + totalDays) {
          weekDays.add(null);
        } else {
          final dayNumber = dayIndex - firstDayOffset + 1;

          weekDays.add(
            DateTime(
              _selectedMonth.year,
              _selectedMonth.month,
              dayNumber,
            ),
          );
        }
      }

      calendar.add(weekDays);
    }

    return calendar;
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month - 1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final calendar = _generateCalendar();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;
    final activeBorderColor = isDark ? EpicordiaColors.darkPrimary : EpicordiaColors.blue700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Text(
              'Activity',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),

            const Spacer(),

            const _HeatmapLegend(),
          ],
        ),

        const SizedBox(height: 10),

        // Month navigation
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: _previousMonth,
              icon: Icon(
                Icons.chevron_left,
                size: 18,
                color: textSecondary,
              ),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),

            Text(
              '${_monthName(_selectedMonth)} ${_selectedMonth.year}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),

            IconButton(
              onPressed: _nextMonth,
              icon: Icon(
                Icons.chevron_right,
                size: 18,
                color: textSecondary,
              ),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Heatmap
        LayoutBuilder(
          builder: (context, constraints) {
            final numberOfWeeks = calendar.length;
            const columnSpacing = 4.0;
            const dayLabelsWidth = 12.0;
            const labelSpacing = 6.0;

            final availableWidth = constraints.maxWidth - dayLabelsWidth - labelSpacing;
            final cellWidth = (availableWidth - ((numberOfWeeks - 1) * columnSpacing)) / numberOfWeeks;
            final cellHeight = cellWidth / 3;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Day labels
                SizedBox(
                  width: dayLabelsWidth,
                  child: Column(
                    children: _dayLabels.map((day) {
                      return SizedBox(
                        height: cellHeight,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              day,
                              style: TextStyle(
                                fontSize: 9,
                                color: textTertiary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: labelSpacing),
                // Calendar columns
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: calendar.map((week) {
                      return SizedBox(
                        width: cellWidth,
                        child: Column(
                          children: week.map((date) {
                            if (date == null) {
                              return SizedBox(
                                height: cellHeight,
                              );
                            }

                            final now = DateTime.now();
                            final today = DateTime(now.year, now.month, now.day);
                            final currentDate = DateTime(date.year, date.month, date.day);
                            final isFuture = currentDate.isAfter(today);
                            final activityLevel = isFuture ? 0 : _getActivityLevel(date);

                            final isSelected = widget.selectedDate != null &&
                                date.year == widget.selectedDate!.year &&
                                date.month == widget.selectedDate!.month &&
                                date.day == widget.selectedDate!.day;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Tooltip(
                                message: '${date.day} ${_monthName(date)}: '
                                    '${activityLevel == 0 ? 'No activity' : 'Activity level $activityLevel'}',
                                child: GestureDetector(
                                  onTap: widget.onTapDate != null ? () => widget.onTapDate!(date) : null,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: cellWidth,
                                    height: cellHeight - 2,
                                    decoration: BoxDecoration(
                                      color: _cellColor(activityLevel, isDark),
                                      borderRadius: BorderRadius.circular(3),
                                      border: isSelected
                                          ? Border.all(color: activeBorderColor, width: 2.0)
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _HeatmapLegend extends StatelessWidget {
  const _HeatmapLegend();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTertiary = isDark
        ? EpicordiaColors.textTertiaryDark
        : EpicordiaColors.textTertiaryLight;

    final colors = isDark
        ? [
            EpicordiaColors.surfaceSunkenDark,
            const Color(0xFF1B3A60),
            const Color(0xFF1D5A94),
            const Color(0xFF0096C7),
            EpicordiaColors.darkPrimary,
          ]
        : [
            EpicordiaColors.borderSubtleLight,
            EpicordiaColors.blue200,
            EpicordiaColors.blue300,
            EpicordiaColors.blue400,
            EpicordiaColors.blue500,
          ];

    return Row(
      children: [
        Text('Less', style: TextStyle(fontSize: 9, color: textTertiary)),
        const SizedBox(width: 4),
        ...colors.map((c) =>
            Padding(
              padding: const EdgeInsets.only(left: 3),
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(2),
                  border: isDark
                      ? Border.all(color: EpicordiaColors.borderSubtleDark, width: 0.5)
                      : null,
                ),
              ),
            ),
        ),
        const SizedBox(width: 4),
        Text('More', style: TextStyle(fontSize: 9, color: textTertiary)),
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
