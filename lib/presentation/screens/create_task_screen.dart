import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import '../../data/database/database.dart';
import '../../data/repository/task_repository.dart';
import '../../data/repository/board_repository.dart';
import '../../core/theme.dart';
import '../../domain/services/notification_service.dart';
import '../../domain/services/device_timer_alarm_service.dart';

class CreateTaskScreen extends ConsumerStatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen> {
  final _titleController = TextEditingController();
  final List<String> _items = [''];
  DateTime? _dueDate;
  String? _selectedBoardId;
  Timer? _debounceTimer;
  String _saveStatus = 'Saved';
  bool _isAutoSaved = false;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (mounted && _saveStatus != 'Saving...') {
      setState(() => _saveStatus = 'Saving...');
    }
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), _autoSave);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _autoSave() async {
    final title = _titleController.text.trim();
    final tasks = _items.where((i) => i.trim().isNotEmpty).toList();
    if (title.isEmpty && tasks.isEmpty) return;

    final repo = ref.read(taskRepositoryProvider);
    final notificationService = NotificationService();
    final timerAlarmService = DeviceTimerAlarmService();

    if (!_isAutoSaved) {
      _isAutoSaved = true;
      if (tasks.isEmpty && title.isNotEmpty) {
        final taskId = '${DateTime.now().millisecondsSinceEpoch}_0';
        await repo.createTask(
          TasksCompanion.insert(
            id: taskId,
            title: title,
            boardId: _selectedBoardId != null
                ? drift.Value(_selectedBoardId)
                : const drift.Value.absent(),
            dueDate: _dueDate != null
                ? drift.Value(_dueDate)
                : const drift.Value.absent(),
          ),
        );
        if (_dueDate != null) {
          await notificationService.scheduleTaskRemindersAndAlarm(
            baseId: taskId.hashCode,
            title: title,
            scheduledDate: _dueDate!,
          );
          timerAlarmService.createAlarm(
            hour: _dueDate!.hour,
            minute: _dueDate!.minute,
            title: title,
          );
        }
      } else {
        for (final item in tasks) {
          final taskId = '${DateTime.now().millisecondsSinceEpoch}_${tasks.indexOf(item)}';
          final itemTitle = item.trim();
          await repo.createTask(
            TasksCompanion.insert(
              id: taskId,
              title: itemTitle,
              boardId: _selectedBoardId != null
                  ? drift.Value(_selectedBoardId)
                  : const drift.Value.absent(),
              dueDate: _dueDate != null
                  ? drift.Value(_dueDate)
                  : const drift.Value.absent(),
              notes: title.isNotEmpty ? drift.Value(title) : const drift.Value.absent(),
            ),
          );
        }
      }
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
    final boards = boardsAsync.value ?? [];
    final boardsMap = {for (var b in boards) b.id: b};

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgApp = isDark ? EpicordiaColors.surfaceAppDark : EpicordiaColors.surfaceAppLight;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;
    final borderClr = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;
    final borderStrong = isDark ? EpicordiaColors.borderStrongDark : EpicordiaColors.borderStrongLight;
    final activeBlue = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600;

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
                'New To-do List',
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
        child: ListView(
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
                hintText: 'List title...',
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
            const SizedBox(height: 8),
            Divider(color: borderClr),
            const SizedBox(height: 12),
            // Task items
            ..._items.asMap().entries.map((entry) {
              final i = entry.key;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: borderStrong,
                          width: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        autofocus: i == 0,
                        onChanged: (v) => _items[i] = v,
                        onSubmitted: (_) => setState(() => _items.add('')),
                        style: TextStyle(color: textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Add a task...',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          hintStyle: TextStyle(
                            color: textTertiary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _items.add('')),
              child: Row(
                children: [
                  Icon(Icons.add, size: 18, color: activeBlue),
                  const SizedBox(width: 8),
                  Text(
                    'Add item',
                    style: TextStyle(
                      fontSize: 14,
                      color: activeBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Board Selection
            _OptionRow(
              icon: Icons.space_dashboard_outlined,
              label: _selectedBoardId == null
                  ? 'Assign to Board'
                  : 'Board: ${boardsMap[_selectedBoardId]?.title ?? 'Inbox'}',
              onTap: () => _showBoardSelectionBottomSheet(context, boards),
            ),
            const SizedBox(height: 12),
            // Due date
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
