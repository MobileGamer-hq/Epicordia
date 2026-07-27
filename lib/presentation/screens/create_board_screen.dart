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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgApp = isDark ? EpicordiaColors.surfaceAppDark : EpicordiaColors.surfaceAppLight;
    final cardBg = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;
    final borderClr = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;
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
          onPressed: () => context.go('/boards'),
        ),
        title: Text(
          'New Board',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              'Create',
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
            // Title
            TextField(
              controller: _titleController,
              autofocus: true,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Board name...',
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
            const SizedBox(height: 24),

            // Default view mode
            Text(
              'Default view',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textSecondary,
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
                            ? activeBlue
                            : cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: active
                              ? activeBlue
                              : borderClr,
                        ),
                      ),
                      child: Text(
                        mode,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: active
                              ? (isDark ? Colors.black : Colors.white)
                              : textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Kanban toggle
            Text(
              'Options',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textSecondary,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderClr),
              ),
              child: SwitchListTile(
                title: Text(
                  'Enable Kanban stages',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
                subtitle: Text(
                  'Add To-do / In-progress / Done columns',
                  style: TextStyle(
                    fontSize: 12,
                    color: textTertiary,
                  ),
                ),
                value: _kanban,
                activeThumbColor: activeBlue,
                onChanged: (v) => setState(() => _kanban = v),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Color preview
            Text(
              'Cover color',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textSecondary,
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
