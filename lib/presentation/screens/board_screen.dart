import 'package:drift/drift.dart' show Value;
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

  Future<void> _addNote() async => _addPin('note', width: 220, height: 160, content: '');
  Future<void> _addTask() async => _addPin('task', width: 240, height: 110);
  Future<void> _addChecklist() async => _addPin('checklist', width: 220, height: 180, content: '{"items":[]}');
  Future<void> _addDrawing() async => _addPin('drawing', width: 240, height: 200, content: '{"strokes":[]}');
  Future<void> _addLink() async => _addPin('link', width: 240, height: 100, content: '{"url":""}');
  Future<void> _addImage() async => _addPin('image', width: 240, height: 200);
  Future<void> _addHeading() async => _addPin('heading', width: 260, height: 48, content: '{"text":"New Heading","style":"heading"}');
  Future<void> _addFrame() async => _addPin('frame', width: 320, height: 280, content: '{"label":"Group"}');

  Future<void> _addPin(
    String type, {
    double width = 220,
    double height = 160,
    String? content,
  }) async {
    final repo = ref.read(pinRepositoryProvider);
    final pins = await repo.watchPinsForBoard(widget.boardId).first;
    final offset = 80.0 + (pins.length % 8) * 28.0;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await repo.createPin(
      PinsCompanion.insert(
        id: id,
        boardId: Value(widget.boardId),
        type: type,
        x: Value(offset),
        y: Value(offset),
        width: Value(width),
        height: Value(height),
        content: Value(content),
      ),
    );
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ViewToggle(
                  selected: _viewMode,
                  options: const ['Canvas', 'List', 'Focus'],
                  onSelect: (v) => setState(() => _viewMode = v),
                ),
              ],
            ),
          ),
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 20),
          //   child: Container(
          //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          //     decoration: BoxDecoration(
          //       color: const Color(0xFFFFF3CD),
          //       borderRadius: BorderRadius.circular(10),
          //       border: Border.all(color: const Color(0xFFE5A030).withValues(alpha: 0.4)),
          //     ),
          //     child: const Row(
          //       mainAxisSize: MainAxisSize.min,
          //       children: [
          //         Icon(Icons.inbox_outlined, size: 16, color: Color(0xFFB5730A)),
          //         SizedBox(width: 8),
          //         Text(
          //           '4 items unsorted',
          //           style: TextStyle(
          //             fontSize: 13,
          //             fontWeight: FontWeight.w600,
          //             color: Color(0xFFB5730A),
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
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
                      onAddChecklist: _addChecklist,
                      onAddDrawing: _addDrawing,
                      onAddLink: _addLink,
                      onAddImage: _addImage,
                      onAddHeading: _addHeading,
                      onAddFrame: _addFrame,
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
                            onTap: () => context.push('/'),
                          ),
                          if (parent != null) ...[
                            const _BreadcrumbSeparator(),
                            Flexible(
                              child: _BreadcrumbLink(
                                label: parent.title,
                                onTap: () => context.push('/board/${parent.id}'),
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
                      onPressed: () => context.push('/settings'),
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
          separatorBuilder: (_, _) => const SizedBox(height: 8),
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
  final VoidCallback onAddChecklist;
  final VoidCallback onAddDrawing;
  final VoidCallback onAddLink;
  final VoidCallback onAddImage;
  final VoidCallback onAddHeading;
  final VoidCallback onAddFrame;
  final VoidCallback onDelete;

  const _CanvasToolbar({
    required this.onAddNote,
    required this.onAddTask,
    required this.onAddChecklist,
    required this.onAddDrawing,
    required this.onAddLink,
    required this.onAddImage,
    required this.onAddHeading,
    required this.onAddFrame,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final addTools = [
      (Icons.sticky_note_2_outlined, 'Note', onAddNote),
      (Icons.check_circle_outline, 'Task', onAddTask),
      (Icons.checklist_rounded, 'Checklist', onAddChecklist),
      (Icons.draw_outlined, 'Drawing', onAddDrawing),
      (Icons.link_rounded, 'Link', onAddLink),
      (Icons.image_outlined, 'Image', onAddImage),
      (Icons.title_rounded, 'Heading', onAddHeading),
      (Icons.crop_free_rounded, 'Frame', onAddFrame),
    ];

    return Container(
      decoration: BoxDecoration(
        color: EpicordiaColors.surfaceCardLight,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(2, 4),
          ),
        ],
        border: Border.all(color: EpicordiaColors.borderSubtleLight, width: 0.8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 4),
          ...addTools.map((t) {
            final (icon, label, action) = t;
            return _ToolButton(icon: icon, tooltip: label, onTap: action);
          }),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Divider(height: 8, thickness: 1, color: EpicordiaColors.borderSubtleLight),
          ),
          _ToolButton(
            icon: Icons.delete_outline_rounded,
            tooltip: 'Delete selected',
            onTap: onDelete,
            isDanger: true,
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isDanger;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.tooltip,
    this.isDanger = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      waitDuration: const Duration(milliseconds: 400),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            size: 20,
            color: isDanger ? EpicordiaColors.errorLight : EpicordiaColors.textSecondaryLight,
          ),
        ),
      ),
    );
  }
}
