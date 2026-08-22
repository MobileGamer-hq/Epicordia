import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import '../../data/database/database.dart';
import '../../data/repository/task_repository.dart';
import '../../data/repository/board_repository.dart';
import '../../data/providers.dart';
import '../../core/theme.dart';
import '../../domain/models/task_subitem.dart';
import '../../domain/services/device_reminder_service.dart';
import '../../domain/services/notification_service.dart';
import '../widgets/timer_picker_popover.dart';
import '../widgets/core/custom_circular_checkbox.dart';

class EditTaskScreen extends ConsumerStatefulWidget {
  final String taskId;
  const EditTaskScreen({super.key, required this.taskId});

  @override
  ConsumerState<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends ConsumerState<EditTaskScreen> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final List<TextEditingController> _subitemControllers = [];
  final List<bool> _subitemDoneStates = [];
  final List<String> _subitemIds = [];

  TaskEntity? _task;
  DateTime? _dueDate;
  String? _selectedBoardId;
  String _selectedStatus = 'todo';
  int _selectedPriority = 0;
  String? _recurrenceRule;
  bool _alsoAddToReminders = false;
  String? _osReminderId;
  Timer? _debounceTimer;
  String _saveStatus = 'Saved';
  bool _isLoadingTask = false;

  final _reminderService = DeviceReminderService();
  final _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onTextChanged);
    _notesController.addListener(_onTextChanged);
    _loadTask();
  }

  void _onTextChanged() {
    if (_isLoadingTask) return;
    if (mounted && _saveStatus != 'Saving...') {
      setState(() => _saveStatus = 'Saving...');
    }
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), _autoSave);
  }

  Future<void> _loadTask() async {
    _isLoadingTask = true;
    final task = await ref.read(taskDaoProvider).getTask(widget.taskId);
    if (task != null && mounted) {
      final decoded = TaskSubitem.decodeNotes(task.notes);

      _subitemControllers.clear();
      _subitemDoneStates.clear();
      _subitemIds.clear();

      for (var sub in decoded.subitems) {
        final ctrl = TextEditingController(text: sub.title);
        ctrl.addListener(_onTextChanged);
        _subitemControllers.add(ctrl);
        _subitemDoneStates.add(sub.isDone);
        _subitemIds.add(sub.id);
      }

      setState(() {
        _task = task;
        _titleController.text = task.title;
        _notesController.text = decoded.userNotes ?? '';
        _dueDate = task.dueDate;
        _selectedBoardId = task.boardId;
        _selectedStatus = task.status;
        _selectedPriority = task.priority;
        _recurrenceRule = task.recurrenceRule;
        _osReminderId = task.osReminderId;
        _alsoAddToReminders = task.osReminderId != null;
        _saveStatus = 'Saved';
      });
    }
    _isLoadingTask = false;
  }

  void _addSubitem() {
    setState(() {
      final ctrl = TextEditingController();
      ctrl.addListener(_onTextChanged);
      _subitemControllers.add(ctrl);
      _subitemDoneStates.add(false);
      _subitemIds.add('${DateTime.now().millisecondsSinceEpoch}_${_subitemControllers.length}');
      _saveStatus = 'Saving...';
    });
    _onTextChanged();
  }

  void _removeSubitem(int index) {
    setState(() {
      final removed = _subitemControllers.removeAt(index);
      removed.dispose();
      _subitemDoneStates.removeAt(index);
      _subitemIds.removeAt(index);
      _saveStatus = 'Saving...';
    });
    _onTextChanged();
  }

  void _toggleSubitem(int index) {
    setState(() {
      _subitemDoneStates[index] = !_subitemDoneStates[index];
      _saveStatus = 'Saving...';
    });
    _onTextChanged();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _titleController.dispose();
    _notesController.dispose();
    for (var ctrl in _subitemControllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: EpicordiaColors.errorLight)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      if (_osReminderId != null) {
        await _reminderService.deleteReminder(_osReminderId!);
      }
      await ref.read(taskRepositoryProvider).deleteTask(widget.taskId);
      if (mounted) context.go('/tasks');
    }
  }

  Future<void> _autoSave() async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _task == null) return;

    List<TaskSubitem> subitems = [];
    for (int i = 0; i < _subitemControllers.length; i++) {
      final text = _subitemControllers[i].text.trim();
      if (text.isNotEmpty) {
        subitems.add(TaskSubitem(
          id: _subitemIds[i],
          title: text,
          isDone: _subitemDoneStates[i],
        ));
      }
    }

    final encodedNotes = TaskSubitem.encodeNotes(
      userNotes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      subitems: subitems,
    );

    // Auto update status if all subitems are finished
    String updatedStatus = _selectedStatus;
    if (subitems.isNotEmpty && subitems.every((s) => s.isDone)) {
      updatedStatus = 'done';
    }

    final updatedTask = _task!.copyWith(
      title: title,
      notes: drift.Value(encodedNotes.isNotEmpty ? encodedNotes : null),
      dueDate: drift.Value(_dueDate),
      boardId: drift.Value(_selectedBoardId),
      status: updatedStatus,
      priority: _selectedPriority,
      recurrenceRule: drift.Value(_recurrenceRule),
      osReminderId: drift.Value(_osReminderId),
    );

    await ref.read(taskRepositoryProvider).updateTask(updatedTask);
    _task = updatedTask;

    if (_dueDate != null) {
      await _notificationService.scheduleTaskRemindersAndAlarm(
        baseId: _task!.id.hashCode,
        title: title,
        body: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        scheduledDate: _dueDate!,
        osReminderId: _osReminderId,
      );
    }
    if (mounted) setState(() => _saveStatus = 'Saved');
  }

  Future<void> _save() async {
    await _autoSave();
    if (mounted) context.go('/tasks');
  }

  @override
  Widget build(BuildContext context) {
    final boardsAsync = ref.watch(allBoardsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgApp = isDark ? EpicordiaColors.surfaceAppDark : EpicordiaColors.surfaceAppLight;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;
    final borderClr = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;
    final cardBg = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
    final activeBlue = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600;
    final successClr = isDark ? EpicordiaColors.successDark : EpicordiaColors.successLight;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        await _autoSave();
      },
      child: Scaffold(
        backgroundColor: bgApp,
        appBar: AppBar(
          backgroundColor: bgApp,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: textPrimary,
            ),
            onPressed: () async {
              await _autoSave();
              if (context.mounted) context.go('/tasks');
            },
          ),
          title: Row(
            children: [
              Text(
                'Edit Task',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _saveStatus == 'Saving...'
                      ? EpicordiaColors.blue100
                      : (isDark ? const Color(0xFF2B2E34) : const Color(0xFFF3F4F6)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _saveStatus,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _saveStatus == 'Saving...'
                        ? EpicordiaColors.blue600
                        : EpicordiaColors.textSecondaryLight,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.delete_outline, color: isDark ? EpicordiaColors.errorDark : EpicordiaColors.errorLight),
              onPressed: _delete,
            ),
            TextButton(
              onPressed: _save,
              child: Text(
                'Save',
                style: TextStyle(
                  color: activeBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: _task == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Title field
                    TextField(
                      controller: _titleController,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Task title...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        hintStyle: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: textTertiary,
                        ),
                      ),
                    ),
                    Divider(color: borderClr),
                    const SizedBox(height: 8),

                    // Description / notes
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: 14,
                        color: textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Notes',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        hintStyle: TextStyle(
                          color: textTertiary,
                        ),
                      ),
                    ),
                    Divider(color: borderClr),
                    const SizedBox(height: 16),

                    // Subtasks Checklist Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Checklist / Subtasks',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textSecondary),
                        ),
                        TextButton.icon(
                          onPressed: _addSubitem,
                          icon: Icon(Icons.add, size: 16, color: activeBlue),
                          label: Text('Add Item', style: TextStyle(color: activeBlue, fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (_subitemControllers.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'No subtasks. Tap "Add Item" above to create a checklist.',
                          style: TextStyle(fontSize: 13, color: textTertiary, fontStyle: FontStyle.italic),
                        ),
                      )
                    else
                      ..._subitemControllers.asMap().entries.map((entry) {
                        final i = entry.key;
                        final ctrl = entry.value;
                        final isDone = _subitemDoneStates[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              CustomCircularCheckbox(
                                isChecked: isDone,
                                onTap: () => _toggleSubitem(i),
                                size: 20,
                                activeColor: successClr,
                                borderColor: textTertiary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: ctrl,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDone ? textTertiary : textPrimary,
                                    decoration: isDone ? TextDecoration.lineThrough : null,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Item ${i + 1}',
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: borderClr),
                                    ),
                                    filled: true,
                                    fillColor: cardBg,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.close, size: 18, color: textTertiary),
                                onPressed: () => _removeSubitem(i),
                              ),
                            ],
                          ),
                        );
                      }),

                    const SizedBox(height: 20),
                    Divider(color: borderClr),
                    const SizedBox(height: 16),

                    // Status Selector
                    Text(
                      'Status',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textSecondary),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ('todo', 'Todo', Icons.radio_button_unchecked, isDark ? EpicordiaColors.blue600 : EpicordiaColors.blue600),
                        ('in_progress', 'In Progress', Icons.pending_outlined, const Color(0xFFF59E0B)),
                        ('done', 'Done', Icons.check_circle_outline, const Color(0xFF10B981)),
                      ].map((item) {
                        final (status, label, icon, activeColor) = item;
                        final isSelected = _selectedStatus == status;
                        final unselectedBg = isDark ? EpicordiaColors.surfaceSunkenDark : EpicordiaColors.surfaceSunkenLight;
                        final chipBorder = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;

                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedStatus = status);
                            _onTextChanged();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? activeColor : unselectedBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? activeColor : chipBorder,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  icon,
                                  size: 15,
                                  color: isSelected ? Colors.white : textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? Colors.white : textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Priority Selector
                    Text(
                      'Priority',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textSecondary),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        (0, 'Low', Icons.arrow_downward, const Color(0xFF10B981)),
                        (1, 'Medium', Icons.remove, const Color(0xFFF59E0B)),
                        (2, 'High', Icons.arrow_upward, const Color(0xFFEF4444)),
                      ].map((item) {
                        final (priority, label, icon, activeColor) = item;
                        final isSelected = _selectedPriority == priority;
                        final unselectedBg = isDark ? EpicordiaColors.surfaceSunkenDark : EpicordiaColors.surfaceSunkenLight;
                        final chipBorder = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;

                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedPriority = priority);
                            _onTextChanged();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? activeColor : unselectedBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? activeColor : chipBorder,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  icon,
                                  size: 14,
                                  color: isSelected ? Colors.white : activeColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? Colors.white : textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Board Selection
                    Text(
                      'Board',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textSecondary),
                    ),
                    const SizedBox(height: 8),
                    boardsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Text('Error loading boards: $err'),
                      data: (boards) {
                        final selectedBoard = boards.cast<BoardEntity?>().firstWhere(
                              (b) => b?.id == _selectedBoardId,
                              orElse: () => null,
                            );
                        return GestureDetector(
                          onTap: () => _showBoardSelectionBottomSheet(context, boards),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: borderClr),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.space_dashboard_outlined, size: 18, color: textSecondary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _selectedBoardId == null ? 'None (Inbox)' : (selectedBoard?.title ?? 'None (Inbox)'),
                                    style: TextStyle(fontSize: 14, color: textPrimary),
                                  ),
                                ),
                                Icon(Icons.keyboard_arrow_down, size: 18, color: textSecondary),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Due Date Selection
                    _OptionRow(
                      icon: Icons.calendar_today_outlined,
                      label: _formatDateTime(_dueDate),
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _dueDate ?? DateTime.now(),
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (pickedDate != null) {
                          if (!mounted) return;
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(_dueDate ?? DateTime.now()),
                          );
                          if (pickedTime != null) {
                            setState(() {
                              _dueDate = DateTime(
                                pickedDate.year,
                                pickedDate.month,
                                pickedDate.day,
                                pickedTime.hour,
                                pickedTime.minute,
                              );
                            });
                          } else {
                            setState(() {
                              _dueDate = DateTime(
                                pickedDate.year,
                                pickedDate.month,
                                pickedDate.day,
                              );
                            });
                          }
                          _onTextChanged();
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Recurrence Schedule
                    _OptionRow(
                      icon: Icons.update_rounded,
                      label: _recurrenceRule == null
                          ? 'Set Recurrence Frequency'
                          : 'Repeats: ${_recurrenceRule!.toUpperCase()}',
                      onTap: () {
                        _showRecurrenceDialog(context);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Timer / Alarm option row
                    _OptionRow(
                      icon: Icons.timer_outlined,
                      label: 'Start Timer / Set Alarm',
                      onTap: () {
                        TimerPickerPopover.show(
                          context,
                          taskTitle: _titleController.text.trim().isEmpty ? 'Task' : _titleController.text.trim(),
                        );
                      },
                    ),

                    if (defaultTargetPlatform == TargetPlatform.iOS) ...[
                      const SizedBox(height: 12),
                      SwitchListTile(
                        value: _alsoAddToReminders,
                        onChanged: (val) {
                          setState(() {
                            _alsoAddToReminders = val;
                          });
                          _onTextChanged();
                        },
                        title: Text(
                          'Also add to Reminders',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
                        ),
                        subtitle: Text(
                          'Syncs task directly with native iOS Reminders app',
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return 'Add due date';
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return 'Due: ${date.month}/${date.day}/${date.year} $hour:$minute $ampm';
  }

  void _showRecurrenceDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Set Task Frequency',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              ListTile(
                title: const Text('Does not repeat'),
                onTap: () {
                  setState(() => _recurrenceRule = null);
                  _onTextChanged();
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text('Daily'),
                onTap: () {
                  setState(() => _recurrenceRule = 'daily');
                  _onTextChanged();
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text('Weekly'),
                onTap: () {
                  setState(() => _recurrenceRule = 'weekly');
                  _onTextChanged();
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text('Monthly'),
                onTap: () {
                  setState(() => _recurrenceRule = 'monthly');
                  _onTextChanged();
                  Navigator.pop(ctx);
                },
              ),
            ],
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
        return Container(
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
                  _onTextChanged();
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
                    _onTextChanged();
                    Navigator.of(bottomSheetContext).pop();
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _OptionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _OptionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: textSecondary),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
