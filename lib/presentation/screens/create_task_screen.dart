import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import '../../data/database/database.dart';
import '../../data/repository/task_repository.dart';
import '../../data/repository/board_repository.dart';
import '../../core/theme.dart';

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

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final tasks = _items.where((i) => i.trim().isNotEmpty).toList();
    if (title.isEmpty && tasks.isEmpty) return;

    final repo = ref.read(taskRepositoryProvider);
    if (tasks.isEmpty && title.isNotEmpty) {
      await repo.createTask(
        TasksCompanion.insert(
          id: '${DateTime.now().millisecondsSinceEpoch}_0',
          title: title,
          boardId: _selectedBoardId != null
              ? drift.Value(_selectedBoardId)
              : const drift.Value.absent(),
          dueDate: _dueDate != null
              ? drift.Value(_dueDate)
              : const drift.Value.absent(),
        ),
      );
    } else {
      for (final item in tasks) {
        await repo.createTask(
          TasksCompanion.insert(
            id: '${DateTime.now().millisecondsSinceEpoch}_${tasks.indexOf(item)}',
            title: item.trim(),
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
          'New To-do List',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'Save',
              style: TextStyle(
                color: EpicordiaColors.blue600,
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
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: EpicordiaColors.textPrimaryLight,
              ),
              decoration: const InputDecoration(
                hintText: 'List title...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                hintStyle: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: EpicordiaColors.textTertiaryLight,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(color: EpicordiaColors.borderSubtleLight),
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
                          color: EpicordiaColors.borderStrongLight,
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
                        decoration: const InputDecoration(
                          hintText: 'Add a task...',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          hintStyle: TextStyle(
                            color: EpicordiaColors.textTertiaryLight,
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
              child: const Row(
                children: [
                  Icon(Icons.add, size: 18, color: EpicordiaColors.blue600),
                  SizedBox(width: 8),
                  Text(
                    'Add item',
                    style: TextStyle(
                      fontSize: 14,
                      color: EpicordiaColors.blue600,
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
    showModalBottomSheet(
      context: context,
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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text(
                  'Select Board',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.inbox_outlined),
                title: const Text('None (Inbox)'),
                trailing: _selectedBoardId == null ? const Icon(Icons.check, color: EpicordiaColors.blue600) : null,
                onTap: () {
                  setState(() => _selectedBoardId = null);
                  Navigator.of(context).pop();
                },
              ),
              ...boards.map((board) {
                final isSelected = _selectedBoardId == board.id;
                return ListTile(
                  leading: const Icon(Icons.dashboard_outlined, color: EpicordiaColors.blue600),
                  title: Text(board.title),
                  trailing: isSelected ? const Icon(Icons.check, color: EpicordiaColors.blue600) : null,
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: EpicordiaColors.textSecondaryLight),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: EpicordiaColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
