import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import '../../data/database/database.dart';
import '../../data/repository/task_repository.dart';
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

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty && _items.every((i) => i.trim().isEmpty)) return;

    // Save each non-empty item as a task
    final repo = ref.read(taskRepositoryProvider);
    final tasks = _items.where((i) => i.trim().isNotEmpty).toList();
    for (final item in tasks) {
      await repo.createTask(TasksCompanion.insert(
        id: '${DateTime.now().millisecondsSinceEpoch}_${tasks.indexOf(item)}',
        title: item.trim(),
        dueDate: _dueDate != null ? drift.Value(_dueDate) : const drift.Value.absent(),
      ));
    }
    if (mounted) context.go('/tasks');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EpicordiaColors.surfaceAppLight,
      appBar: AppBar(
        backgroundColor: EpicordiaColors.surfaceAppLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: EpicordiaColors.textPrimaryLight),
          onPressed: () => context.go('/create'),
        ),
        title: const Text('New To-do List', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: EpicordiaColors.textPrimaryLight)),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save', style: TextStyle(color: EpicordiaColors.blue600, fontWeight: FontWeight.w700, fontSize: 15)),
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
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: EpicordiaColors.textPrimaryLight),
              decoration: const InputDecoration(
                hintText: 'List title...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                hintStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: EpicordiaColors.textTertiaryLight),
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
                        border: Border.all(color: EpicordiaColors.borderStrongLight, width: 1.5),
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
                          hintStyle: TextStyle(color: EpicordiaColors.textTertiaryLight),
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
                  Text('Add item', style: TextStyle(fontSize: 14, color: EpicordiaColors.blue600, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Due date
            _OptionRow(
              icon: Icons.calendar_today_outlined,
              label: _dueDate == null ? 'Add due date' : 'Due: ${_dueDate!.month}/${_dueDate!.day}/${_dueDate!.year}',
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _dueDate = picked);
              },
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
  const _OptionRow({required this.icon, required this.label, required this.onTap});

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
            Text(label, style: const TextStyle(fontSize: 14, color: EpicordiaColors.textSecondaryLight)),
          ],
        ),
      ),
    );
  }
}
