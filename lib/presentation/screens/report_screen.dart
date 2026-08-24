import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../data/database/database.dart';
import '../../data/repository/task_repository.dart';
import '../../data/repository/pin_repository.dart';
import '../../domain/state/journaling_provider.dart';
import '../widgets/layout/responsive_scaffold.dart';
import '../widgets/core/epicordia_card.dart';
import '../widgets/core/interactive_note_card.dart';
import '../widgets/core/interactive_task_card.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  String _selectedTimeframe = 'This Week'; // 'This Week', 'Last Week', 'This Month'

  DateTime _getStartDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_selectedTimeframe == 'This Week') {
      return today.subtract(Duration(days: today.weekday - 1)); // Monday of this week
    } else if (_selectedTimeframe == 'Last Week') {
      return today.subtract(Duration(days: today.weekday - 1 + 7)); // Monday of last week
    } else {
      return DateTime(today.year, today.month, 1); // 1st of this month
    }
  }

  int _getDaysCount() {
    if (_selectedTimeframe == 'This Month') {
      final now = DateTime.now();
      return DateTime(now.year, now.month + 1, 0).day;
    }
    return 7;
  }

  void _showDayInsightsModal(BuildContext context, DateTime date, List<TaskEntity> dayTasks, List<PinEntity> dayJournals) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;

    final missedTasks = dayTasks.where((t) {
      final isDone = t.status.toLowerCase() == 'done' || t.status.toLowerCase() == 'completed';
      final due = t.dueDate ?? t.scheduledDate;
      return !isDone && due != null && due.isBefore(DateTime.now());
    }).toList();

    final completedTasks = dayTasks.where((t) {
      return t.status.toLowerCase() == 'done' || t.status.toLowerCase() == 'completed';
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: EpicordiaColors.borderStrongLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Insights for ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Breakdown of tasks, missed items, and journal entries.',
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                  const SizedBox(height: 20),

                  // 1. Missed Tasks
                  if (missedTasks.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 18, color: EpicordiaColors.errorLight),
                        const SizedBox(width: 6),
                        Text(
                          'Missed Tasks (${missedTasks.length})',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: EpicordiaColors.errorLight),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...missedTasks.map((t) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InteractiveTaskCard(task: t, boardTitle: 'Inbox', boardColor: EpicordiaColors.blue600),
                        )),
                    const SizedBox(height: 16),
                  ],

                  // 2. Completed Tasks
                  Row(
                    children: [
                      Icon(Icons.check_circle_outline, size: 18, color: EpicordiaColors.blue600),
                      const SizedBox(width: 6),
                      Text(
                        'Completed Tasks (${completedTasks.length})',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (completedTasks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('No completed tasks on this date.', style: TextStyle(fontSize: 12, color: textSecondary)),
                    )
                  else
                    ...completedTasks.map((t) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InteractiveTaskCard(task: t, boardTitle: 'Inbox', boardColor: EpicordiaColors.blue600),
                        )),
                  const SizedBox(height: 16),

                  // 3. Journal Entries
                  Row(
                    children: [
                      Icon(Icons.edit_note_rounded, size: 18, color: EpicordiaColors.blue600),
                      const SizedBox(width: 6),
                      Text(
                        'Journal Entries (${dayJournals.length})',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (dayJournals.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('No journal entries logged for this date.', style: TextStyle(fontSize: 12, color: textSecondary)),
                    )
                  else
                    ...dayJournals.map((j) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InteractiveNoteCard(note: j, boardTitle: 'Inbox'),
                        )),
                ],
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
    final notesAsync = ref.watch(allNotesProvider);
    final journalingState = ref.watch(journalingPlanProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgApp = isDark ? EpicordiaColors.surfaceAppDark : EpicordiaColors.surfaceAppLight;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final activeBlue = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600;

    final tasks = tasksAsync.value ?? [];
    final notes = notesAsync.value ?? [];

    final startDate = _getStartDate();
    final totalDays = _getDaysCount();
    final endDate = startDate.add(Duration(days: totalDays));

    // Calculate metrics for timeframe
    int completedCount = 0;
    int missedCount = 0;
    int journalCount = 0;

    final dayStats = <DateTime, Map<String, int>>{};

    for (int i = 0; i < totalDays; i++) {
      final d = startDate.add(Duration(days: i));
      final dayKey = DateTime(d.year, d.month, d.day);
      dayStats[dayKey] = {'completed': 0, 'missed': 0, 'journals': 0};
    }

    for (final task in tasks) {
      final created = task.createdAt;
      final due = task.dueDate ?? task.scheduledDate ?? created;
      final taskDay = DateTime(due.year, due.month, due.day);

      final isDone = task.status.toLowerCase() == 'done' || task.status.toLowerCase() == 'completed';
      final isMissed = !isDone && due.isBefore(DateTime.now());

      if (taskDay.isAfter(startDate.subtract(const Duration(days: 1))) && taskDay.isBefore(endDate)) {
        if (dayStats.containsKey(taskDay)) {
          if (isDone) {
            dayStats[taskDay]!['completed'] = (dayStats[taskDay]!['completed'] ?? 0) + 1;
            completedCount++;
          } else if (isMissed) {
            dayStats[taskDay]!['missed'] = (dayStats[taskDay]!['missed'] ?? 0) + 1;
            missedCount++;
          }
        }
      }
    }

    final journalsList = notes.where((n) {
      final tagsStr = (n.tags ?? n.colorTag ?? '').toLowerCase();
      return tagsStr.contains('journal');
    }).toList();

    for (final note in journalsList) {
      final d = note.entryDate ?? note.createdAt;
      final noteDay = DateTime(d.year, d.month, d.day);
      if (noteDay.isAfter(startDate.subtract(const Duration(days: 1))) && noteDay.isBefore(endDate)) {
        if (dayStats.containsKey(noteDay)) {
          dayStats[noteDay]!['journals'] = (dayStats[noteDay]!['journals'] ?? 0) + 1;
          journalCount++;
        }
      }
    }

    final totalTasks = completedCount + missedCount;
    final completionRate = totalTasks > 0 ? ((completedCount / totalTasks) * 100).round() : 100;

    return ResponsiveScaffold(
      child: Scaffold(
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
            'Progress & Insights',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 48),
          children: [
            // Timeframe Selector Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['This Week', 'Last Week', 'This Month'].map((tf) {
                  final selected = _selectedTimeframe == tf;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(tf),
                      selected: selected,
                      selectedColor: activeBlue,
                      labelStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : textSecondary,
                      ),
                      onSelected: (_) => setState(() => _selectedTimeframe = tf),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // KPI Grid Cards
            Row(
              children: [
                Expanded(
                  child: EpicordiaCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.local_fire_department_outlined, size: 16, color: activeBlue),
                            const SizedBox(width: 6),
                            Text('Streak', style: TextStyle(fontSize: 13, color: textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${journalingState.currentStreak} Days',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Best: ${journalingState.longestStreak} Days',
                          style: TextStyle(fontSize: 11, color: activeBlue, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: EpicordiaCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.track_changes_outlined, size: 16, color: activeBlue),
                            const SizedBox(width: 6),
                            Text('Completion', style: TextStyle(fontSize: 13, color: textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$completionRate%',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$completedCount Done / $missedCount Missed',
                          style: TextStyle(
                            fontSize: 11,
                            color: missedCount > 0 ? EpicordiaColors.errorLight : EpicordiaColors.blue600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Interactive Progress Bar Chart Card
            EpicordiaCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Daily Breakdown',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                      Text(
                        'Tap a bar for details',
                        style: TextStyle(fontSize: 11, color: textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _LegendItem(color: EpicordiaColors.blue600, label: 'Completed'),
                      const SizedBox(width: 16),
                      _LegendItem(color: EpicordiaColors.errorLight, label: 'Missed'),
                      const SizedBox(width: 16),
                      _LegendItem(color: const Color(0xFF9C27B0), label: 'Journals'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Chart Bars
                  SizedBox(
                    height: 160,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: dayStats.length > 7 ? MainAxisAlignment.start : MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: dayStats.entries.map((entry) {
                          final date = entry.key;
                          final stats = entry.value;
                          final done = stats['completed'] ?? 0;
                          final missed = stats['missed'] ?? 0;
                          final j = stats['journals'] ?? 0;
                          final maxVal = (done + missed + j).clamp(1, 20);

                          final dayName = dayStats.length > 7
                              ? '${date.day}'
                              : ['M', 'T', 'W', 'T', 'F', 'S', 'S'][date.weekday - 1];

                          final dayTasks = tasks.where((t) {
                            final due = t.dueDate ?? t.scheduledDate ?? t.createdAt;
                            return due.year == date.year && due.month == date.month && due.day == date.day;
                          }).toList();

                          final dayJournals = journalsList.where((n) {
                            final d = n.entryDate ?? n.createdAt;
                            return d.year == date.year && d.month == date.month && d.day == date.day;
                          }).toList();

                          return Padding(
                            padding: EdgeInsets.symmetric(horizontal: dayStats.length > 7 ? 6.0 : 10.0),
                            child: GestureDetector(
                              onTap: () => _showDayInsightsModal(context, date, dayTasks, dayJournals),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  // Stacked / Segmented Bar
                                  Container(
                                    width: dayStats.length > 7 ? 16 : 22,
                                    height: (maxVal * 12.0).clamp(16.0, 120.0),
                                    decoration: BoxDecoration(
                                      color: isDark ? EpicordiaColors.surfaceSunkenDark : EpicordiaColors.surfaceSunkenLight,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (j > 0)
                                          Expanded(
                                            flex: j,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF9C27B0),
                                                borderRadius: BorderRadius.vertical(
                                                  top: const Radius.circular(6),
                                                  bottom: Radius.circular(done == 0 && missed == 0 ? 6 : 0),
                                                ),
                                              ),
                                            ),
                                          ),
                                        if (missed > 0)
                                          Expanded(
                                            flex: missed,
                                            child: Container(color: EpicordiaColors.errorLight),
                                          ),
                                        if (done > 0)
                                          Expanded(
                                            flex: done,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: EpicordiaColors.blue600,
                                                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(6)),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    dayName,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Journaling Goal Progress Summary Card
            EpicordiaCard(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isDark ? EpicordiaColors.blue900 : EpicordiaColors.blue100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.edit_calendar_rounded, color: activeBlue, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Journaling Goal Progress',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$journalCount journal entries logged this period.',
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                      ],
                    ),
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

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
