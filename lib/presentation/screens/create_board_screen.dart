import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/database/database.dart';
import '../../data/repository/board_repository.dart';
import '../../core/theme.dart';

class CreateBoardScreen extends ConsumerStatefulWidget {
  const CreateBoardScreen({super.key});

  @override
  ConsumerState<CreateBoardScreen> createState() => _CreateBoardScreenState();
}

class _CreateBoardScreenState extends ConsumerState<CreateBoardScreen> {
  final _titleController = TextEditingController();
  String _viewMode = 'Canvas';
  bool _kanban = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await ref
        .read(boardRepositoryProvider)
        .createBoard(BoardsCompanion.insert(id: id, title: title));
    if (mounted) context.push('/board/$id');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EpicordiaColors.surfaceAppLight,
      appBar: AppBar(
        backgroundColor: EpicordiaColors.surfaceAppLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: EpicordiaColors.textPrimaryLight,
          ),
          onPressed: () => context.go('/boards'),
        ),
        title: const Text(
          'New Board',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: EpicordiaColors.textPrimaryLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'Create',
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
            // Title
            TextField(
              controller: _titleController,
              autofocus: true,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: EpicordiaColors.textPrimaryLight,
              ),
              decoration: const InputDecoration(
                hintText: 'Board name...',
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
            const Divider(color: EpicordiaColors.borderSubtleLight),
            const SizedBox(height: 24),

            // Default view mode
            const Text(
              'Default view',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: EpicordiaColors.textSecondaryLight,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: ['Canvas', 'List', 'Focus'].map((mode) {
                final active = _viewMode == mode;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _viewMode = mode),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? EpicordiaColors.blue600
                            : EpicordiaColors.surfaceCardLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: active
                              ? EpicordiaColors.blue600
                              : EpicordiaColors.borderSubtleLight,
                        ),
                      ),
                      child: Text(
                        mode,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: active
                              ? Colors.white
                              : EpicordiaColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Kanban toggle
            const Text(
              'Options',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: EpicordiaColors.textSecondaryLight,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: EpicordiaColors.surfaceCardLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: EpicordiaColors.borderSubtleLight),
              ),
              child: SwitchListTile(
                title: const Text(
                  'Enable Kanban stages',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: EpicordiaColors.textPrimaryLight,
                  ),
                ),
                subtitle: const Text(
                  'Add To-do / In-progress / Done columns',
                  style: TextStyle(
                    fontSize: 12,
                    color: EpicordiaColors.textTertiaryLight,
                  ),
                ),
                value: _kanban,
                activeThumbColor: EpicordiaColors.blue600,
                onChanged: (v) => setState(() => _kanban = v),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Color preview
            const Text(
              'Cover color',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: EpicordiaColors.textSecondaryLight,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 12),
            _ColorPicker(),
          ],
        ),
      ),
    );
  }
}

class _ColorPicker extends StatefulWidget {
  @override
  State<_ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<_ColorPicker> {
  int _selected = 0;
  final List<Color> _colors = [
    const Color(0xFF8B9DC3),
    const Color(0xFFA8B4C8),
    const Color(0xFF6B7FA0),
    const Color(0xFF9EAAC4),
    const Color(0xFF5FC7A3),
    const Color(0xFFF4C453),
    const Color(0xFFF0806B),
    const Color(0xFF9C8CF0),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(_colors.length, (i) {
        return GestureDetector(
          onTap: () => setState(() => _selected = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _colors[i],
              shape: BoxShape.circle,
              border: Border.all(
                color: _selected == i
                    ? EpicordiaColors.blue600
                    : Colors.transparent,
                width: 2.5,
              ),
              boxShadow: _selected == i
                  ? [
                      BoxShadow(
                        color: _colors[i].withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
          ),
        );
      }),
    );
  }
}
