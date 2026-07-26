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
import '../../domain/services/device_reminder_service.dart';
import '../../domain/services/device_calendar_service.dart';
import '../../domain/services/notification_service.dart';
import '../widgets/timer_picker_popover.dart';
import '../widgets/permission_explanation_dialog.dart';

class EditTaskScreen extends ConsumerStatefulWidget {
  final String taskId;
  const EditTaskScreen({super.key, required this.taskId});

  @override
  ConsumerState<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends ConsumerState<EditTaskScreen> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  TaskEntity? _task;
  DateTime? _dueDate;
  String? _selectedBoardId;
  String _selectedStatus = 'todo';
  int _selectedPriority = 0;
  bool _alsoAddToReminders = false;
  String? _osReminderId;

  final _reminderService = DeviceReminderService();
  final _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  Future<void> _loadTask() async {
    final task = await ref.read(taskDaoProvider).getTask(widget.taskId);
    if (task != null && mounted) {
      setState(() {
        _task = task;
        _titleController.text = task.title;
        _notesController.text = task.notes ?? '';
        _dueDate = task.dueDate;
        _selectedBoardId = task.boardId;
        _selectedStatus = task.status;
        _selectedPriority = task.priority;
        _osReminderId = task.osReminderId;
        _alsoAddToReminders = task.osReminderId != null;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
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

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    String? reminderId = _osReminderId;

    if (_alsoAddToReminders && defaultTargetPlatform == TargetPlatform.iOS) {
      if (reminderId == null) {
        final proceed = await PermissionExplanationDialog.show(
          context: context,
          title: 'Sync to iOS Reminders',
          description: 'Epicordia will add this task to your native Reminders app.',
          icon: Icons.notifications_active_outlined,
        );
        if (proceed) {
          reminderId = await _reminderService.createReminder(
            title: title,
            notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
            dueDate: _dueDate,
          );
        }
      }
    } else if (!_alsoAddToReminders && reminderId != null) {
      await _reminderService.deleteReminder(reminderId);
      reminderId = null;
    }

    if (_task != null) {
      await ref.read(taskRepositoryProvider).updateTask(
            _task!.copyWith(
              title: title,
              notes: drift.Value(_notesController.text.trim().isEmpty ? null : _notesController.text.trim()),
              dueDate: drift.Value(_dueDate),
              boardId: drift.Value(_selectedBoardId),
              status: _selectedStatus,
              priority: _selectedPriority,
              osReminderId: drift.Value(reminderId),
            ),
          );

      if (_dueDate != null) {
        await _notificationService.scheduleTaskNotification(
          id: _task!.id.hashCode,
          title: title,
          body: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          scheduledDate: _dueDate!,
          osReminderId: reminderId,
        );
      }
    }
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
          onPressed: () => context.go('/tasks'),
        ),
        title: Text(
          'Edit Task',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
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
                    maxLines: 3,
                    style: TextStyle(
                      fontSize: 14,
                      color: textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Add description / notes...',
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

                  // Status Selector
                  Text(
                    'Status',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: ['todo', 'in_progress', 'done'].map((status) {
                      final isSelected = _selectedStatus == status;
                      final label = status == 'todo' ? 'Todo' : status == 'in_progress' ? 'In Progress' : 'Done';
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(label),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedStatus = status);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Priority Selector
                  Text(
                    'Priority',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [0, 1, 2].map((priority) {
                      final isSelected = _selectedPriority == priority;
                      final label = priority == 0 ? 'Low' : priority == 1 ? 'Medium' : 'High';
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(label),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedPriority = priority);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

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
                      }
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
    );
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return 'Add due date';
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return 'Due: ${date.month}/${date.day}/${date.year} $hour:$minute $ampm';
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
      builder: (context) {
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
                  Navigator.of(context).pop();
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
                    Navigator.of(context).pop();
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
