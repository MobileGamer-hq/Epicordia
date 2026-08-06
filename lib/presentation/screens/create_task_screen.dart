import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import '../../data/database/database.dart';
import '../../data/repository/task_repository.dart';
import '../../data/repository/board_repository.dart';
import '../../core/theme.dart';
import '../../domain/models/task_subitem.dart';
import '../../domain/services/notification_service.dart';
import '../../domain/services/device_timer_alarm_service.dart';

enum TaskTypeMode { single, checklist }

class CreateTaskScreen extends ConsumerStatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen> {
  TaskTypeMode _mode = TaskTypeMode.checklist;
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  final List<TextEditingController> _itemControllers = [
    TextEditingController(),
  ];

  DateTime? _dueDate;
  String? _selectedBoardId;
  String? _recurrenceRule; // null, 'daily', 'weekly', 'monthly'

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    for (var c in _itemControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addItemField() {
    setState(() {
      _itemControllers.add(TextEditingController());
    });
  }

  void _removeItemField(int index) {
    if (_itemControllers.length <= 1) return;
    setState(() {
      final removed = _itemControllers.removeAt(index);
      removed.dispose();
    });
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();

    List<TaskSubitem> subitems = [];
    if (_mode == TaskTypeMode.checklist) {
      subitems = _itemControllers
          .map((c) => c.text.trim())
          .where((text) => text.isNotEmpty)
          .map((text) => TaskSubitem(
                id: '${DateTime.now().millisecondsSinceEpoch}_${subitems.length}',
                title: text,
                isDone: false,
              ))
          .toList();
    }

    final userNotes = _notesController.text.trim();

    // Validation
    if (title.isEmpty && subitems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title or checklist items.')),
      );
      return;
    }

    final finalTitle = title.isNotEmpty
        ? title
        : (subitems.isNotEmpty ? subitems.first.title : 'Untitled Task');

    final encodedNotes = TaskSubitem.encodeNotes(
      userNotes: userNotes.isNotEmpty ? userNotes : null,
      subitems: subitems,
    );

    final taskId = DateTime.now().millisecondsSinceEpoch.toString();
    final repo = ref.read(taskRepositoryProvider);
    final notificationService = NotificationService();
    final timerAlarmService = DeviceTimerAlarmService();

    await repo.createTask(
      TasksCompanion.insert(
        id: taskId,
        title: finalTitle,
        notes: encodedNotes.isNotEmpty ? drift.Value(encodedNotes) : const drift.Value.absent(),
        boardId: _selectedBoardId != null ? drift.Value(_selectedBoardId) : const drift.Value.absent(),
        dueDate: _dueDate != null ? drift.Value(_dueDate) : const drift.Value.absent(),
        recurrenceRule: _recurrenceRule != null ? drift.Value(_recurrenceRule) : const drift.Value.absent(),
      ),
    );

    if (_dueDate != null) {
      await notificationService.scheduleTaskRemindersAndAlarm(
        baseId: taskId.hashCode,
        title: finalTitle,
        scheduledDate: _dueDate!,
      );
      timerAlarmService.createAlarm(
        hour: _dueDate!.hour,
        minute: _dueDate!.minute,
        title: finalTitle,
      );
    }

    if (mounted) context.go('/tasks');
  }

  @override
  Widget build(BuildContext context) {
    final boardsAsync = ref.watch(allBoardsProvider);
    final boards = boardsAsync.value ?? [];
    final boardsMap = {for (var b in boards) b.id: b};

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgApp = isDark ? EpicordiaColors.surfaceAppDark : EpicordiaColors.surfaceAppLight;
    final cardBg = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;
    final borderClr = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;
    final borderStrong = isDark ? EpicordiaColors.borderStrongDark : EpicordiaColors.borderStrongLight;
    final activeBlue = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600;

    return Scaffold(
      backgroundColor: bgApp,
      appBar: AppBar(
        backgroundColor: bgApp,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => context.go('/tasks'),
        ),
        title: Text(
          'Create New Task',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: activeBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              ),
              child: const Text(
                'Save',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Mode Selector Segment
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderClr),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _ModeSegmentButton(
                      label: 'Single Action',
                      icon: Icons.check_circle_outline_rounded,
                      isSelected: _mode == TaskTypeMode.single,
                      onTap: () => setState(() => _mode = TaskTypeMode.single),
                    ),
                  ),
                  Expanded(
                    child: _ModeSegmentButton(
                      label: 'Checklist / Subtasks',
                      icon: Icons.checklist_rounded,
                      isSelected: _mode == TaskTypeMode.checklist,
                      onTap: () => setState(() => _mode = TaskTypeMode.checklist),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Mode helper description
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: activeBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 18, color: activeBlue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _mode == TaskTypeMode.single
                          ? 'Create a simple single-action task (e.g. "Upload app" or "Call John").'
                          : 'Create a task with multiple sub-items (e.g. "Grocery Shopping List").',
                      style: TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Main Title Input
            TextField(
              controller: _titleController,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
              decoration: InputDecoration(
                hintText: _mode == TaskTypeMode.single ? 'Task title (e.g. Upload App)' : 'List title (e.g. Shopping List)',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                hintStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: textTertiary,
                ),
              ),
            ),
            Divider(color: borderClr),
            const SizedBox(height: 12),

            // Mode Specific Inputs
            if (_mode == TaskTypeMode.single) ...[
              TextField(
                controller: _notesController,
                maxLines: 4,
                style: TextStyle(fontSize: 14, color: textPrimary),
                decoration: InputDecoration(
                  hintText: 'Add description or notes (optional)...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderClr),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderClr),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: activeBlue),
                  ),
                  filled: true,
                  fillColor: cardBg,
                  hintStyle: TextStyle(color: textTertiary, fontSize: 14),
                ),
              ),
            ] else ...[
              // Checklist Subitems
              Text(
                'Things to do in this task:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              ..._itemControllers.asMap().entries.map((entry) {
                final i = entry.key;
                final controller = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: borderStrong, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          autofocus: i == 0 && _titleController.text.isNotEmpty,
                          onSubmitted: (_) => _addItemField(),
                          style: TextStyle(color: textPrimary, fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'Add item ${i + 1}...',
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
                            hintStyle: TextStyle(color: textTertiary, fontSize: 14),
                          ),
                        ),
                      ),
                      if (_itemControllers.length > 1) ...[
                        const SizedBox(width: 6),
                        IconButton(
                          icon: Icon(Icons.remove_circle_outline, color: EpicordiaColors.errorLight, size: 20),
                          onPressed: () => _removeItemField(i),
                        ),
                      ],
                    ],
                  ),
                );
              }),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _addItemField,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  decoration: BoxDecoration(
                    color: activeBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 18, color: activeBlue),
                      const SizedBox(width: 6),
                      Text(
                        'Add another item',
                        style: TextStyle(
                          fontSize: 14,
                          color: activeBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                maxLines: 2,
                style: TextStyle(fontSize: 14, color: textPrimary),
                decoration: InputDecoration(
                  hintText: 'Additional notes or summary (optional)...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderClr),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderClr),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: activeBlue),
                  ),
                  filled: true,
                  fillColor: cardBg,
                  hintStyle: TextStyle(color: textTertiary, fontSize: 13),
                ),
              ),
            ],

            const SizedBox(height: 24),
            Divider(color: borderClr),
            const SizedBox(height: 12),

            // Options: Board, Due Date & Time, Recurrence Schedule
            _OptionRow(
              icon: Icons.space_dashboard_outlined,
              label: _selectedBoardId == null
                  ? 'Assign to Board'
                  : 'Board: ${boardsMap[_selectedBoardId]?.title ?? 'Inbox'}',
              onTap: () => _showBoardSelectionBottomSheet(context, boards),
            ),
            _OptionRow(
              icon: Icons.calendar_today_outlined,
              label: _formatDateTime(_dueDate),
              trailing: _dueDate != null
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _dueDate = null),
                    )
                  : null,
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
            _OptionRow(
              icon: Icons.update_rounded,
              label: _recurrenceRule == null
                  ? 'Schedule Frequency (Does not repeat)'
                  : 'Repeats: ${_recurrenceLabel(_recurrenceRule)}',
              trailing: _recurrenceRule != null
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _recurrenceRule = null),
                    )
                  : null,
              onTap: () => _showRecurrenceDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return 'Add Due Date & Time';
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return 'Due: ${date.month}/${date.day}/${date.year} $hour:$minute $ampm';
  }

  String _recurrenceLabel(String? rule) {
    switch (rule) {
      case 'daily':
        return 'Every Day';
      case 'weekly':
        return 'Every Week';
      case 'monthly':
        return 'Every Month';
      default:
        return 'Custom Schedule';
    }
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
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text('Daily'),
                onTap: () {
                  setState(() => _recurrenceRule = 'daily');
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text('Weekly'),
                onTap: () {
                  setState(() => _recurrenceRule = 'weekly');
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text('Monthly'),
                onTap: () {
                  setState(() => _recurrenceRule = 'monthly');
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
        );
      },
    );
  }
}

class _ModeSegmentButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeSegmentButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[700]),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  const _OptionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
