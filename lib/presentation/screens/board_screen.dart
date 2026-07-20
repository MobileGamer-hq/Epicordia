import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/database/database.dart';
import '../../data/repository/board_repository.dart';
import '../../data/repository/pin_repository.dart';
import '../widgets/features/board_canvas.dart';

class BoardScreen extends ConsumerStatefulWidget {
  final String boardId;
  const BoardScreen({super.key, required this.boardId});

  @override
  ConsumerState<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends ConsumerState<BoardScreen> {
  String _viewMode = 'Canvas';
  final GlobalKey<BoardCanvasState> _canvasKey = GlobalKey<BoardCanvasState>();

  Future<void> _addNote() async {
    final repo = ref.read(pinRepositoryProvider);
    final pins = await repo.watchPinsForBoard(widget.boardId).first;
    final offset = 80.0 + (pins.length % 6) * 32.0;
    await repo.createNoteOnBoard(widget.boardId, x: offset, y: offset);
  }

  Future<void> _addTask() async {
    final repo = ref.read(pinRepositoryProvider);
    final pins = await repo.watchPinsForBoard(widget.boardId).first;
    final offset = 120.0 + (pins.length % 6) * 32.0;
    await repo.createTaskOnBoard(widget.boardId, x: offset, y: offset);
  }

  Future<void> _deleteSelection() async {
    await _canvasKey.currentState?.deleteSelection();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EpicordiaColors.surfaceSunkenLight,
      appBar: _BoardAppBar(boardId: widget.boardId),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                _ViewToggle(
                  selected: _viewMode,
                  options: const ['Canvas', 'List', 'Focus'],
                  onSelect: (v) => setState(() => _viewMode = v),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5A030).withValues(alpha: 0.4)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined, size: 16, color: Color(0xFFB5730A)),
                  SizedBox(width: 8),
                  Text(
                    '4 items unsorted',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB5730A),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Stack(
              children: [
                if (_viewMode == 'Canvas')
                  BoardCanvas(
                    key: _canvasKey,
                    boardId: widget.boardId,
                    onAddNote: _addNote,
                    onAddTask: _addTask,
                  )
                else
                  _BoardListView(
                    boardId: widget.boardId,
                    tasksOnly: _viewMode == 'Focus',
                  ),
                if (_viewMode == 'Canvas')
                  Positioned(
                    left: 12,
                    top: 20,
                    child: _CanvasToolbar(
                      onAddNote: _addNote,
                      onAddTask: _addTask,
                      onDelete: _deleteSelection,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BoardAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String boardId;
  const _BoardAppBar({required this.boardId});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardRepo = ref.read(boardRepositoryProvider);

    return Material(
      color: EpicordiaColors.surfaceAppLight,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FutureBuilder<(BoardEntity?, BoardEntity?)>(
              future: _loadBoardChain(boardRepo, boardId),
              builder: (context, snapshot) {
                final board = snapshot.data?.$1;
                final parent = snapshot.data?.$2;
                final title = board?.title ?? 'Board';

                return Row(
                  children: [
                    IconButton(
                      tooltip: 'Back to boards',
                      onPressed: () => context.go('/boards'),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: EpicordiaColors.textSecondaryLight,
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          _BreadcrumbLink(
                            label: 'Home',
                            onTap: () => context.go('/'),
                          ),
                          if (parent != null) ...[
                            const _BreadcrumbSeparator(),
                            Flexible(
                              child: _BreadcrumbLink(
                                label: parent.title,
                                onTap: () => context.go('/board/${parent.id}'),
                              ),
                            ),
                          ],
                          const _BreadcrumbSeparator(),
                          Flexible(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: EpicordiaColors.blue700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Notifications',
                      onPressed: () {},
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: EpicordiaColors.textPrimaryLight,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Settings',
                      onPressed: () => context.go('/settings'),
                      icon: const Icon(
                        Icons.settings_outlined,
                        color: EpicordiaColors.textPrimaryLight,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<(BoardEntity?, BoardEntity?)> _loadBoardChain(
    BoardRepository repo,
    String id,
  ) async {
    final board = await repo.getBoard(id);
    if (board?.parentBoardId == null) return (board, null);
    final parent = await repo.getBoard(board!.parentBoardId!);
    return (board, parent);
  }
}

class _BreadcrumbLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _BreadcrumbLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 13,
          color: EpicordiaColors.textSecondaryLight,
        ),
      ),
    );
  }
}

class _BreadcrumbSeparator extends StatelessWidget {
  const _BreadcrumbSeparator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Icon(
        Icons.chevron_right_rounded,
        size: 16,
        color: EpicordiaColors.textTertiaryLight,
      ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  final String selected;
  final List<String> options;
  final ValueChanged<String> onSelect;
  const _ViewToggle({
    required this.selected,
    required this.options,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EpicordiaColors.surfaceCardLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: EpicordiaColors.borderSubtleLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
          final isActive = opt == selected;
          return GestureDetector(
            onTap: () => onSelect(opt),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? EpicordiaColors.blue700 : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                opt,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : EpicordiaColors.textSecondaryLight,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _BoardListView extends ConsumerWidget {
  final String boardId;
  final bool tasksOnly;

  const _BoardListView({required this.boardId, required this.tasksOnly});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinsStream = ref.watch(pinRepositoryProvider).watchPinsForBoard(boardId);

    return StreamBuilder<List<PinEntity>>(
      stream: pinsStream,
      builder: (context, snapshot) {
        final pins = snapshot.data ?? const <PinEntity>[];
        final filtered = tasksOnly ? pins.where((p) => p.type == 'task').toList() : pins;

        if (filtered.isEmpty) {
          return Center(
            child: Text(
              tasksOnly ? 'No tasks on this board' : 'No items on this board',
              style: const TextStyle(color: EpicordiaColors.textSecondaryLight),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final pin = filtered[index];
            final preview = pin.content?.split('\n').first ?? pin.type;
            return ListTile(
              tileColor: EpicordiaColors.surfaceCardLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: EpicordiaColors.borderSubtleLight),
              ),
              leading: Icon(
                pin.type == 'task' ? Icons.check_circle_outline : Icons.sticky_note_2_outlined,
                color: EpicordiaColors.textSecondaryLight,
              ),
              title: Text(preview),
            );
          },
        );
      },
    );
  }
}

class _CanvasToolbar extends StatelessWidget {
  final VoidCallback onAddNote;
  final VoidCallback onAddTask;
  final VoidCallback onDelete;

  const _CanvasToolbar({
    required this.onAddNote,
    required this.onAddTask,
    required this.onDelete,
  });

  static const _tools = [
    (Icons.sticky_note_2_outlined, _ToolAction.note),
    (Icons.check_circle_outline, _ToolAction.task),
    (Icons.link, _ToolAction.none),
    (Icons.image_outlined, _ToolAction.none),
    (Icons.draw_outlined, _ToolAction.none),
    (Icons.show_chart, _ToolAction.none),
    (Icons.crop_free, _ToolAction.none),
    (Icons.delete_outline, _ToolAction.delete),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EpicordiaColors.surfaceCardLight,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(_tools.length, (i) {
            final (icon, action) = _tools[i];
            final showDivider = i == 4;
            final isDanger = action == _ToolAction.delete;
            return Column(
              children: [
                if (showDivider)
                  const Divider(height: 1, thickness: 1, color: EpicordiaColors.borderSubtleLight),
                _ToolButton(
                  icon: icon,
                  isDanger: isDanger,
                  onTap: () {
                    switch (action) {
                      case _ToolAction.note:
                        onAddNote();
                      case _ToolAction.task:
                        onAddTask();
                      case _ToolAction.delete:
                        onDelete();
                      case _ToolAction.none:
                        break;
                    }
                  },
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

enum _ToolAction { note, task, delete, none }

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final bool isDanger;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    this.isDanger = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Icon(
          icon,
          size: 20,
          color: isDanger ? EpicordiaColors.errorLight : EpicordiaColors.textSecondaryLight,
        ),
      ),
    );
  }
}
