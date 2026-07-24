import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:epicordia/data/database/database.dart';
import 'package:epicordia/data/repository/task_repository.dart';
import 'package:epicordia/data/repository/pin_repository.dart';
import '../core/epicordia_button.dart';

enum CaptureType { note, task }

class QuickCaptureModal extends ConsumerStatefulWidget {
  const QuickCaptureModal({super.key});

  @override
  ConsumerState<QuickCaptureModal> createState() => _QuickCaptureModalState();
}

class _QuickCaptureModalState extends ConsumerState<QuickCaptureModal> {
  final TextEditingController _controller = TextEditingController();
  CaptureType _type = CaptureType.note;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (_type == CaptureType.task) {
      await ref.read(taskRepositoryProvider).createTask(
        TasksCompanion.insert(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: text,
        ),
      );
    } else {
      await ref.read(pinRepositoryProvider).createPin(
        PinsCompanion.insert(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          boardId: const drift.Value(null),
          type: 'note',
          content: drift.Value(text),
        ),
      );
    }
    
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Zen Mode: Just a massive text field and a save button. No tags, no boards.
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ChoiceChip(
                label: const Text('Note'),
                selected: _type == CaptureType.note,
                onSelected: (selected) {
                  if (selected) setState(() => _type = CaptureType.note);
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Task'),
                selected: _type == CaptureType.task,
                onSelected: (selected) {
                  if (selected) setState(() => _type = CaptureType.task);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: 5,
            minLines: 1,
            style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w400),
            decoration: InputDecoration(
              hintText: _type == CaptureType.note ? 'Jot something down...' : 'What needs to be done?',
              hintStyle: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w400,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
              ),
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              EpicordiaButton(
                label: 'Save to Inbox',
                onPressed: _save,
                icon: Icons.inbox_outlined,
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// Helper to launch it
void showQuickCapture(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => const QuickCaptureModal(),
  );
}
