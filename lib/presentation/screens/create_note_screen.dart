import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import '../../data/database/database.dart';
import '../../data/repository/pin_repository.dart';
import '../../data/repository/board_repository.dart';
import '../../core/theme.dart';

class CreateNoteScreen extends ConsumerStatefulWidget {
  const CreateNoteScreen({super.key});

  @override
  ConsumerState<CreateNoteScreen> createState() => _CreateNoteScreenState();
}

class _CreateNoteScreenState extends ConsumerState<CreateNoteScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty && body.isEmpty) return;

    final content = title.isNotEmpty ? '$title\n\n$body' : body;
    await ref.read(pinRepositoryProvider).createPin(
      PinsCompanion.insert(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        boardId: const drift.Value(null),
        type: 'note',
        content: drift.Value(content),
      ),
    );
    if (mounted) context.go('/notes');
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
        title: const Text('New Note', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: EpicordiaColors.textPrimaryLight)),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save', style: TextStyle(color: EpicordiaColors.blue600, fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            children: [
              // Title
              TextField(
                controller: _titleController,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: EpicordiaColors.textPrimaryLight),
                decoration: const InputDecoration(
                  hintText: 'Note title...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  hintStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: EpicordiaColors.textTertiaryLight),
                ),
              ),
              const Divider(color: EpicordiaColors.borderSubtleLight),
              const SizedBox(height: 8),
              // Body
              Expanded(
                child: TextField(
                  controller: _bodyController,
                  autofocus: true,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(fontSize: 15, color: EpicordiaColors.textPrimaryLight, height: 1.6),
                  decoration: const InputDecoration(
                    hintText: 'Start writing...',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    hintStyle: TextStyle(color: EpicordiaColors.textTertiaryLight),
                  ),
                ),
              ),
              // Format toolbar
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: EpicordiaColors.borderSubtleLight)),
                ),
                child: const Row(
                  children: [
                    _FmtButton(icon: Icons.format_bold),
                    _FmtButton(icon: Icons.format_italic),
                    _FmtButton(icon: Icons.format_underline),
                    _FmtButton(icon: Icons.format_list_bulleted),
                    _FmtButton(icon: Icons.format_list_numbered),
                    _FmtButton(icon: Icons.link),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FmtButton extends StatelessWidget {
  final IconData icon;
  const _FmtButton({required this.icon});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 20, color: EpicordiaColors.textSecondaryLight),
      ),
    );
  }
}
