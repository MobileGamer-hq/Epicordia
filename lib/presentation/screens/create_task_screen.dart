import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import '../../data/database/database.dart';
import '../../data/providers.dart';
import '../../data/repository/task_repository.dart';
import '../../data/repository/board_repository.dart';
import '../../core/theme.dart';
import '../../core/feedback_service.dart';
import '../../domain/models/task_subitem.dart';
import '../../domain/services/notification_service.dart';
import '../../domain/services/device_timer_alarm_service.dart';
import '../widgets/core/custom_circular_checkbox.dart';
import '../../domain/epi/epi_models.dart';

class CreateTaskScreen extends ConsumerStatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  // Subtasks checklist items
  final List<TextEditingController> _subtaskControllers = [];
  final List<FocusNode> _subtaskFocusNodes = [];

  // Metadata
  DateTime? _dueDate;
  String? _selectedBoardId;
  int _selectedPriority = 0; // 0: Low, 1: Medium, 2: High

  // Recurrence & Schedule state
  String? _recurrenceRule; // null (does not repeat), 'daily', 'weekdays', 'weekends', 'weekly', 'monthly'
  bool get _isRepeating => _recurrenceRule != null;
  Set<int> _selectedDays = {DateTime.now().weekday}; // 1 = Mon, 7 = Sun
  TimeOfDay _scheduleStartTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _scheduleEndTime = const TimeOfDay(hour: 10, minute: 0);
  bool _addToTimetable = true;

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    for (var c in _subtaskControllers) {
      c.dispose();
    }
    for (var f in _subtaskFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _addSubtask({String text = '', bool autoFocus = true}) {
    final controller = TextEditingController(text: text);
    final focusNode = FocusNode();
    setState(() {
      _subtaskControllers.add(controller);
      _subtaskFocusNodes.add(focusNode);
    });
    if (autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && focusNode.canRequestFocus) {
          focusNode.requestFocus();
        }
      });
    }
  }

  void _removeSubtask(int index) {
    if (index >= 0 && index < _subtaskControllers.length) {
      setState(() {
        final ctrl = _subtaskControllers.removeAt(index);
        final fn = _subtaskFocusNodes.removeAt(index);
        ctrl.dispose();
        fn.dispose();
      });
    }
  }

  String _formatDuration(TimeOfDay start, TimeOfDay end) {
    final startMinutes = start.hour * 60 + start.minute;
    var endMinutes = end.hour * 60 + end.minute;
    if (endMinutes < startMinutes) endMinutes += 24 * 60;
    final diff = endMinutes - startMinutes;
    final hours = diff ~/ 60;
    final mins = diff % 60;
    if (hours > 0 && mins > 0) return '${hours}h ${mins}m';
    if (hours > 0) return '${hours}h';
    return '${mins}m';
  }

  String _getRecurrenceDescription() {
    if (_recurrenceRule == null) return 'Does not repeat';
    switch (_recurrenceRule) {
      case 'daily':
        return 'Repeats every day';
      case 'weekdays':
        return 'Repeats Monday to Friday';
      case 'weekends':
        return 'Repeats Saturday & Sunday';
      case 'weekly':
        if (_selectedDays.length == 7) return 'Repeats every day';
        final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final days = (_selectedDays.toList()..sort()).map((d) => dayNames[d - 1]).join(', ');
        return 'Repeats on $days';
      case 'monthly':
        return 'Repeats every month';
      default:
        return 'Repeats custom';
    }
  }

  String _formatDueDate(DateTime? date) {
    if (date == null) return 'No due date';
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    final isTomorrow = date.year == now.year && date.month == now.month && date.day == now.day + 1;
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute $ampm';

    if (isToday) return 'Today, $timeStr';
    if (isTomorrow) return 'Tomorrow, $timeStr';
    return '${date.month}/${date.day}/${date.year}, $timeStr';
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 3)),
    );

    if (pickedDate != null && mounted) {
      final initialTime = _dueDate != null
          ? TimeOfDay.fromDateTime(_dueDate!)
          : const TimeOfDay(hour: 17, minute: 0);
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: initialTime,
      );

      setState(() {
        if (pickedTime != null) {
          _dueDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        } else {
          _dueDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            17,
            0,
          );
        }
      });
    }
  }

  void _showRecurrenceBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final activeBlue = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600;

    showModalBottomSheet(
      context: context,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Repeat Schedule',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.close_rounded),
                  title: Text('Does not repeat', style: TextStyle(color: textPrimary)),
                  trailing: _recurrenceRule == null ? Icon(Icons.check, color: activeBlue) : null,
                  onTap: () {
                    setState(() => _recurrenceRule = null);
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.today_rounded),
                  title: Text('Daily (Every day)', style: TextStyle(color: textPrimary)),
                  trailing: _recurrenceRule == 'daily' ? Icon(Icons.check, color: activeBlue) : null,
                  onTap: () {
                    setState(() {
                      _recurrenceRule = 'daily';
                      _selectedDays = {1, 2, 3, 4, 5, 6, 7};
                    });
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.business_center_outlined),
                  title: Text('Weekdays (Mon - Fri)', style: TextStyle(color: textPrimary)),
                  trailing: _recurrenceRule == 'weekdays' ? Icon(Icons.check, color: activeBlue) : null,
                  onTap: () {
                    setState(() {
                      _recurrenceRule = 'weekdays';
                      _selectedDays = {1, 2, 3, 4, 5};
                    });
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.weekend_outlined),
                  title: Text('Weekends (Sat - Sun)', style: TextStyle(color: textPrimary)),
                  trailing: _recurrenceRule == 'weekends' ? Icon(Icons.check, color: activeBlue) : null,
                  onTap: () {
                    setState(() {
                      _recurrenceRule = 'weekends';
                      _selectedDays = {6, 7};
                    });
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_view_week_rounded),
                  title: Text('Weekly (Custom days)', style: TextStyle(color: textPrimary)),
                  trailing: _recurrenceRule == 'weekly' ? Icon(Icons.check, color: activeBlue) : null,
                  onTap: () {
                    setState(() {
                      _recurrenceRule = 'weekly';
                      if (_selectedDays.isEmpty) {
                        _selectedDays = {DateTime.now().weekday};
                      }
                    });
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_month_outlined),
                  title: Text('Monthly', style: TextStyle(color: textPrimary)),
                  trailing: _recurrenceRule == 'monthly' ? Icon(Icons.check, color: activeBlue) : null,
                  onTap: () {
                    setState(() => _recurrenceRule = 'monthly');
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showBoardSelectionBottomSheet(BuildContext context, List<BoardEntity> boards) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final activeBlue = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600;

    showModalBottomSheet(
      context: context,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text(
                    'Select Board',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.inbox_outlined, color: textPrimary),
                  title: Text('None (Inbox)', style: TextStyle(color: textPrimary)),
                  trailing: _selectedBoardId == null ? Icon(Icons.check, color: activeBlue) : null,
                  onTap: () {
                    setState(() => _selectedBoardId = null);
                    Navigator.of(bottomSheetContext).pop();
                  },
                ),
                ...boards.map((board) {
                  final isSelected = _selectedBoardId == board.id;
                  return ListTile(
                    leading: Icon(Icons.dashboard_outlined, color: activeBlue),
                    title: Text(board.title, style: TextStyle(color: textPrimary)),
                    trailing: isSelected ? Icon(Icons.check, color: activeBlue) : null,
                    onTap: () {
                      setState(() => _selectedBoardId = board.id);
                      Navigator.of(bottomSheetContext).pop();
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final validSubtasks = _subtaskControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    // Validation
    if (title.isEmpty && validSubtasks.isEmpty) {
      FeedbackService.showError('Please enter a task title or add subtasks.');
      return;
    }

    final finalTitle = title.isNotEmpty ? title : validSubtasks.first;
    final userNotes = _notesController.text.trim();

    // Auto-detect Single Task vs Checklist Task:
    // If validSubtasks is empty -> Single Task (no subitems encoded)
    // If validSubtasks is not empty -> Checklist Task (subitems encoded)
    final List<TaskSubitem> subitems = [];
    if (validSubtasks.isNotEmpty) {
      for (int i = 0; i < validSubtasks.length; i++) {
        subitems.add(TaskSubitem(
          id: '${DateTime.now().millisecondsSinceEpoch}_$i',
          title: validSubtasks[i],
          isDone: false,
        ));
      }
    }

    final encodedNotes = TaskSubitem.encodeNotes(
      userNotes: userNotes.isNotEmpty ? userNotes : null,
      subitems: subitems.isNotEmpty ? subitems : null,
    );

    final taskId = DateTime.now().millisecondsSinceEpoch.toString();
    final repo = ref.read(taskRepositoryProvider);
    final notificationService = NotificationService();
    final timerAlarmService = DeviceTimerAlarmService();

    String? finalRecurrence = _recurrenceRule;
    DateTime? finalDueDate = _dueDate;

    // If repeating with timetable integration, create slots in TimetableDao
    if (_isRepeating && _addToTimetable && _selectedDays.isNotEmpty) {
      final timetableDao = ref.read(timetableDaoProvider);
      final startStr =
          '${_scheduleStartTime.hour.toString().padLeft(2, '0')}:${_scheduleStartTime.minute.toString().padLeft(2, '0')}';
      final endStr =
          '${_scheduleEndTime.hour.toString().padLeft(2, '0')}:${_scheduleEndTime.minute.toString().padLeft(2, '0')}';

      for (final day in _selectedDays) {
        await timetableDao.insertSlot(
          TimetableSlotsCompanion.insert(
            id: '${taskId}_day_$day',
            title: finalTitle,
            dayOfWeek: day,
            startTime: startStr,
            endTime: endStr,
            boardId: _selectedBoardId != null ? drift.Value(_selectedBoardId) : const drift.Value.absent(),
            notes: userNotes.isNotEmpty ? drift.Value(userNotes) : const drift.Value.absent(),
          ),
        );
      }

      if (finalDueDate == null) {
        final now = DateTime.now();
        finalDueDate = DateTime(
          now.year,
          now.month,
          now.day,
          _scheduleStartTime.hour,
          _scheduleStartTime.minute,
        );
      }
    }

    await repo.createTask(
      TasksCompanion.insert(
        id: taskId,
        title: finalTitle,
        notes: encodedNotes.isNotEmpty ? drift.Value(encodedNotes) : const drift.Value.absent(),
        boardId: _selectedBoardId != null ? drift.Value(_selectedBoardId) : const drift.Value.absent(),
        dueDate: finalDueDate != null ? drift.Value(finalDueDate) : const drift.Value.absent(),
        scheduledDate: finalDueDate != null ? drift.Value(finalDueDate) : const drift.Value.absent(),
        priority: drift.Value(_selectedPriority),
        recurrenceRule: finalRecurrence != null ? drift.Value(finalRecurrence) : const drift.Value.absent(),
      ),
    );

    if (finalDueDate != null) {
      await notificationService.scheduleTaskRemindersAndAlarm(
        baseId: taskId.hashCode,
        title: finalTitle,
        scheduledDate: finalDueDate,
      );
      timerAlarmService.createAlarm(
        hour: finalDueDate.hour,
        minute: finalDueDate.minute,
        title: finalTitle,
      );
    }

    if (mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/tasks');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final boardsAsync = ref.watch(allBoardsProvider);
    final boards = boardsAsync.value ?? [];
    final boardsMap = {for (var b in boards) b.id: b};

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgApp = isDark ? EpicordiaColors.surfaceAppDark : EpicordiaColors.surfaceAppLight;
    final cardBg = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
    final sunkenBg = isDark ? EpicordiaColors.surfaceSunkenDark : EpicordiaColors.surfaceSunkenLight;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;
    final borderClr = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;
    final activeBlue = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600;

    return Scaffold(
      backgroundColor: bgApp,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: AppBar(
          backgroundColor: bgApp,
          elevation: 0,
          toolbarHeight: 52,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, size: 22, color: textPrimary),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/tasks');
              }
            },
          ),
          title: Text(
            'Create Task',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: activeBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // Title Input
            TextField(
              controller: _titleController,
              autofocus: true,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'What needs to be done?',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
                hintStyle: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: textTertiary,
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Description / Notes Input
            TextField(
              controller: _notesController,
              maxLines: null,
              minLines: 2,
              style: TextStyle(fontSize: 14, color: textPrimary, height: 1.4),
              decoration: InputDecoration(
                hintText: 'Add notes or description...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
                hintStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: textTertiary,
                ),
              ),
            ),

            Divider(color: borderClr, height: 24),

            // Subtasks / Checklist Section (Progressive Disclosure)
            if (_subtaskControllers.isEmpty) ...[
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _addSubtask(),
                    icon: Icon(Icons.add_task_rounded, size: 16, color: activeBlue),
                    label: Text(
                      'Add subtasks',
                      style: TextStyle(color: activeBlue, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: activeBlue.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                  ),
                  const SizedBox(width: 10),
                  TextButton.icon(
                    onPressed: () {
                      final title = _titleController.text.trim();
                      final attached = EpiAttachedItem(
                        id: 'temp_new_task',
                        type: EpiAttachedItemType.task,
                        title: title.isNotEmpty ? title : 'New Task',
                        preview: _notesController.text.trim().isNotEmpty
                            ? _notesController.text.trim()
                            : null,
                      );
                      context.push('/epi', extra: {
                        'attachedItems': [attached],
                      });
                    },
                    icon: Icon(Icons.auto_awesome, size: 15, color: activeBlue),
                    label: Text(
                      'Ask Epi',
                      style: TextStyle(color: activeBlue, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.checklist_rounded, size: 18, color: textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        'Subtasks (${_subtaskControllers.length})',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () {
                      final title = _titleController.text.trim();
                      final attached = EpiAttachedItem(
                        id: 'temp_new_task',
                        type: EpiAttachedItemType.task,
                        title: title.isNotEmpty ? title : 'New Task',
                        preview: _notesController.text.trim().isNotEmpty
                            ? _notesController.text.trim()
                            : null,
                      );
                      context.push('/epi', extra: {
                        'attachedItems': [attached],
                      });
                    },
                    icon: Icon(Icons.auto_awesome, size: 14, color: activeBlue),
                    label: Text('Ask Epi', style: TextStyle(color: activeBlue, fontSize: 12)),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Subtask TextFields
              ..._subtaskControllers.asMap().entries.map((entry) {
                final i = entry.key;
                final ctrl = entry.value;
                final focusNode = _subtaskFocusNodes[i];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      CustomCircularCheckbox(
                        isChecked: false,
                        onTap: null,
                        size: 20,
                        borderColor: textTertiary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: ctrl,
                          focusNode: focusNode,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => _addSubtask(),
                          style: TextStyle(fontSize: 14, color: textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Subtask ${i + 1}',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: borderClr),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: borderClr),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: activeBlue),
                            ),
                            filled: true,
                            fillColor: cardBg,
                            hintStyle: TextStyle(color: textTertiary, fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(Icons.close_rounded, size: 18, color: textTertiary),
                        onPressed: () => _removeSubtask(i),
                      ),
                    ],
                  ),
                );
              }),

              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _addSubtask(),
                  icon: Icon(Icons.add, size: 16, color: activeBlue),
                  label: Text('Add another subtask', style: TextStyle(color: activeBlue, fontSize: 13)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ),
            ],

            Divider(color: borderClr, height: 28),

            // Task Properties & Metadata Container
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderClr),
              ),
              child: Column(
                children: [
                  // Board Selection
                  _SettingTile(
                    icon: Icons.space_dashboard_outlined,
                    label: 'Board',
                    value: _selectedBoardId == null
                        ? 'Inbox'
                        : (boardsMap[_selectedBoardId]?.title ?? 'Inbox'),
                    onTap: () => _showBoardSelectionBottomSheet(context, boards),
                  ),
                  Divider(color: borderClr, height: 1),

                  // Due Date & Time
                  _SettingTile(
                    icon: Icons.event_outlined,
                    label: 'Due Date',
                    value: _formatDueDate(_dueDate),
                    trailing: _dueDate != null
                        ? IconButton(
                            icon: Icon(Icons.close_rounded, size: 18, color: textTertiary),
                            onPressed: () => setState(() => _dueDate = null),
                          )
                        : null,
                    onTap: _pickDueDate,
                  ),
                  Divider(color: borderClr, height: 1),

                  // Priority Selector
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.flag_outlined, size: 20, color: textSecondary),
                        const SizedBox(width: 14),
                        Text(
                          'Priority',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Wrap(
                          spacing: 6,
                          children: [
                            (0, 'Low', const Color(0xFF10B981)),
                            (1, 'Med', const Color(0xFFF59E0B)),
                            (2, 'High', const Color(0xFFEF4444)),
                          ].map((item) {
                            final (priority, label, color) = item;
                            final isSelected = _selectedPriority == priority;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedPriority = priority),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isSelected ? color : sunkenBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? color : borderClr,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? Colors.white : textSecondary,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Schedule & Recurrence Card (Progressive Disclosure)
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isRepeating ? activeBlue.withValues(alpha: 0.4) : borderClr,
                  width: _isRepeating ? 1.5 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recurrence Header / Toggle Tile
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.repeat_rounded,
                          size: 20,
                          color: _isRepeating ? activeBlue : textSecondary,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: InkWell(
                            onTap: () => _showRecurrenceBottomSheet(context),
                            borderRadius: BorderRadius.circular(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Recurring Schedule',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _getRecurrenceDescription(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _isRepeating ? activeBlue : textTertiary,
                                    fontWeight: _isRepeating ? FontWeight.w600 : FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Switch.adaptive(
                          value: _isRepeating,
                          activeColor: activeBlue,
                          onChanged: (val) {
                            setState(() {
                              if (val) {
                                _recurrenceRule = 'daily';
                                _selectedDays = {1, 2, 3, 4, 5, 6, 7};
                              } else {
                                _recurrenceRule = null;
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  // Progressive Disclosure: Schedule Options appear ONLY when repeat is enabled!
                  if (_isRepeating) ...[
                    Divider(color: borderClr, height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Quick Frequency Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ('daily', 'Daily', {1, 2, 3, 4, 5, 6, 7}),
                              ('weekdays', 'Weekdays', {1, 2, 3, 4, 5}),
                              ('weekends', 'Weekends', {6, 7}),
                              ('weekly', 'Weekly', {DateTime.now().weekday}),
                              ('monthly', 'Monthly', <int>{}),
                            ].map((preset) {
                              final (rule, label, days) = preset;
                              final isSelected = _recurrenceRule == rule;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  label: Text(label, style: const TextStyle(fontSize: 12)),
                                  selected: isSelected,
                                  selectedColor: activeBlue,
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : textPrimary,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                  backgroundColor: sunkenBg,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        _recurrenceRule = rule;
                                        if (days.isNotEmpty) {
                                          _selectedDays = Set.from(days);
                                        }
                                      });
                                    }
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Day of week selector chips (M T W T F S S)
                        if (_recurrenceRule != 'monthly') ...[
                          Text(
                            'Active Days',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(7, (idx) {
                              final dayNum = idx + 1; // 1 = Mon ... 7 = Sun
                              final dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                              final isSelected = _selectedDays.contains(dayNum);

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      if (_selectedDays.length > 1) {
                                        _selectedDays.remove(dayNum);
                                      }
                                    } else {
                                      _selectedDays.add(dayNum);
                                    }
                                    if (_selectedDays.length == 7) {
                                      _recurrenceRule = 'daily';
                                    } else if (_selectedDays.length == 5 &&
                                        !_selectedDays.contains(6) &&
                                        !_selectedDays.contains(7)) {
                                      _recurrenceRule = 'weekdays';
                                    } else {
                                      _recurrenceRule = 'weekly';
                                    }
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: isSelected ? activeBlue : sunkenBg,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? activeBlue : borderClr,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      dayLetters[idx],
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white : textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Timetable Schedule Integration
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: sunkenBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderClr),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.calendar_view_week_rounded, size: 18, color: activeBlue),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Add to Timetable Schedule',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: textPrimary,
                                          ),
                                        ),
                                        Text(
                                          'Syncs weekly slots into Timetable & Calendar',
                                          style: TextStyle(fontSize: 11, color: textTertiary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch.adaptive(
                                    value: _addToTimetable,
                                    activeColor: activeBlue,
                                    onChanged: (val) => setState(() => _addToTimetable = val),
                                  ),
                                ],
                              ),
                              if (_addToTimetable) ...[
                                const Divider(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: () async {
                                          final picked = await showTimePicker(
                                            context: context,
                                            initialTime: _scheduleStartTime,
                                          );
                                          if (picked != null) {
                                            setState(() => _scheduleStartTime = picked);
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: cardBg,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: borderClr),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Start Time',
                                                  style: TextStyle(fontSize: 11, color: textTertiary)),
                                              const SizedBox(height: 2),
                                              Text(
                                                _scheduleStartTime.format(context),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: activeBlue,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: activeBlue.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _formatDuration(_scheduleStartTime, _scheduleEndTime),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: activeBlue,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: InkWell(
                                        onTap: () async {
                                          final picked = await showTimePicker(
                                            context: context,
                                            initialTime: _scheduleEndTime,
                                          );
                                          if (picked != null) {
                                            setState(() => _scheduleEndTime = picked);
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: cardBg,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: borderClr),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('End Time',
                                                  style: TextStyle(fontSize: 11, color: textTertiary)),
                                              const SizedBox(height: 2),
                                              Text(
                                                _scheduleEndTime.format(context),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: textPrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final Widget? trailing;

  const _SettingTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: EpicordiaColors.textSecondaryLight),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: textTertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (trailing != null)
              trailing!
            else ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, size: 18, color: textTertiary),
            ],
          ],
        ),
      ),
    );
  }
}
