import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/database/database.dart';
import '../../data/repository/board_repository.dart';
import '../../data/repository/pin_repository.dart';
import '../../data/repository/task_repository.dart';
import '../../core/board_settings_provider.dart';
import '../widgets/features/board_canvas.dart';
import '../widgets/features/pin_editor_panel.dart';


class BoardScreen extends ConsumerStatefulWidget {
  final String boardId;
  const BoardScreen({super.key, required this.boardId});

  @override
  ConsumerState<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends ConsumerState<BoardScreen> {
  String _viewMode = 'Canvas';
  final GlobalKey<BoardCanvasState> _canvasKey = GlobalKey<BoardCanvasState>();

  bool _isEditingPin = false;

  Future<void> _addNote() async => _addPin('note', width: 220, height: 160, content: '');
  Future<void> _addTask() async {
    final repo = ref.read(pinRepositoryProvider);
    final taskRepo = ref.read(taskRepositoryProvider);
    final pins = await repo.watchPinsForBoard(widget.boardId).first;
    final offset = 80.0 + (pins.length % 8) * 28.0;
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    await repo.createPin(
      PinsCompanion.insert(
        id: id,
        boardId: Value(widget.boardId),
        type: 'task',
        x: Value(offset),
        y: Value(offset),
        width: const Value(240),
        height: const Value(110),
        content: const Value('New Task'),
      ),
    );

    final taskId = '${id}_task';
    await taskRepo.createTask(
      TasksCompanion.insert(
        id: taskId,
        pinId: Value(id),
        boardId: Value(widget.boardId),
        title: 'New Task',
        status: const Value('todo'),
        priority: const Value(0),
      ),
    );
  }

  Future<void> _addChecklist() async => _addPin('checklist', width: 220, height: 180, content: '{"items":[]}');
  Future<void> _addDrawing() async => _addPin('drawing', width: 240, height: 200, content: '{"strokes":[]}');
  Future<void> _addLink() async => _addPin('link', width: 240, height: 100, content: '{"url":""}');
  Future<void> _addImage() async => _addPin('image', width: 240, height: 200);
  Future<void> _addColorSwatch() async => _addPin('colorSwatch', width: 160, height: 160, content: '{"hex":"#3D68EE","label":"Royal Blue"}');
  Future<void> _addAudio() async => _addPin('audio', width: 240, height: 110, content: '{"title":"Voice Memo","durationSeconds":42}');
  Future<void> _addFile() async => _addPin('file', width: 240, height: 100, content: '{"displayName":"Document.pdf","fileSize":1258291}');
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgApp = isDark ? EpicordiaColors.surfaceAppDark : EpicordiaColors.surfaceSunkenLight;

    return Scaffold(
      backgroundColor: bgApp,
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
                  options: const ['Canvas', 'List', 'Focus', 'Kanban'],
                  onSelect: (v) => setState(() => _viewMode = v),
                ),
              ],
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
                    onEditStateChanged: (editing) => setState(() => _isEditingPin = editing),
                  )
                else if (_viewMode == 'Kanban')
                  _BoardKanbanView(boardId: widget.boardId)
                else
                  _BoardListView(
                    boardId: widget.boardId,
                    tasksOnly: _viewMode == 'Focus',
                  ),
                if (_viewMode == 'Canvas' && !_isEditingPin)
                  Consumer(
                    builder: (context, ref, _) {
                      final toolbarPos = ref.watch(toolbarPositionProvider);
                      final toolbarWidget = _CanvasToolbar(
                        onAddNote: _addNote,
                        onAddTask: _addTask,
                        onAddChecklist: _addChecklist,
                        onAddDrawing: _addDrawing,
                        onAddLink: _addLink,
                        onAddImage: _addImage,
                        onAddColorSwatch: _addColorSwatch,
                        onAddAudio: _addAudio,
                        onAddFile: _addFile,
                        onAddHeading: _addHeading,
                        onAddFrame: _addFrame,
                        onAddConnector: () => _canvasKey.currentState?.toggleConnectorMode(),
                        onDelete: _deleteSelection,
                      );

                      switch (toolbarPos) {
                        case ToolbarPosition.left:
                          return Positioned(
                            left: 12,
                            top: 20,
                            child: toolbarWidget,
                          );
                        case ToolbarPosition.right:
                          return Positioned(
                            right: 12,
                            top: 20,
                            child: toolbarWidget,
                          );
                        case ToolbarPosition.bottom:
                          return Positioned(
                            left: 12,
                            right: 12,
                            bottom: 16,
                            child: Center(child: toolbarWidget),
                          );
                      }
                    },
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? EpicordiaColors.surfaceAppDark : EpicordiaColors.surfaceAppLight;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final activeBlue = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue700;

    return Material(
      color: bg,
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
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: textSecondary,
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
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: activeBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Settings',
                      onPressed: () => context.push('/settings'),
                      icon: Icon(
                        Icons.settings_outlined,
                        color: textPrimary,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;

    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          color: textSecondary,
        ),
      ),
    );
  }
}

class _BreadcrumbSeparator extends StatelessWidget {
  const _BreadcrumbSeparator();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Icon(
        Icons.chevron_right_rounded,
        size: 16,
        color: textTertiary,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
    final borderClr = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;
    final activeBlue = isDark ? EpicordiaColors.blue600 : EpicordiaColors.blue700;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderClr),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
          final isActive = opt == selected;
          return GestureDetector(
            onTap: () => onSelect(opt),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? activeBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                opt,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : textSecondary,
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

  IconData _iconForType(String type) {
    switch (type) {
      case 'task':
        return Icons.check_circle_outline;
      case 'checklist':
        return Icons.checklist_rounded;
      case 'drawing':
        return Icons.draw_outlined;
      case 'link':
        return Icons.link_rounded;
      case 'image':
        return Icons.image_outlined;
      case 'heading':
        return Icons.title_rounded;
      case 'frame':
        return Icons.grid_view_rounded;
      default:
        return Icons.sticky_note_2_outlined;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
    final borderClr = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
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
              style: TextStyle(color: textSecondary),
            ),
          );
        }

        final sorted = List<PinEntity>.from(filtered)..sort((a, b) => a.y.compareTo(b.y));

        return ReorderableListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          itemCount: sorted.length,
          onReorder: (oldIndex, newIndex) async {
            if (oldIndex < newIndex) newIndex -= 1;
            final movedItem = sorted.removeAt(oldIndex);
            sorted.insert(newIndex, movedItem);

            final repo = ref.read(pinRepositoryProvider);
            for (int i = 0; i < sorted.length; i++) {
              final item = sorted[i];
              final targetY = 80.0 + i * 90.0;
              if ((item.y - targetY).abs() > 0.5) {
                await repo.updatePinPosition(item.id, x: item.x, y: targetY);
              }
            }
          },
          itemBuilder: (context, index) {
            final pin = sorted[index];
            final preview = _getPreviewText(pin);

            return Container(
              key: ValueKey(pin.id),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderClr),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                onTap: () => showPinEditorPanel(context, pinId: pin.id, boardId: boardId),
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: (isDark ? EpicordiaColors.blue400 : EpicordiaColors.blue600).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _iconForType(pin.type),
                    size: 20,
                    color: isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue700,
                  ),
                ),
                title: Text(
                  preview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? EpicordiaColors.surfaceAppDark : EpicordiaColors.surfaceSunkenLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          pin.type.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: textSecondary,
                          ),
                        ),
                      ),
                      if (pin.colorTag != null && pin.colorTag!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorFromTag(pin.colorTag),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                trailing: ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.drag_handle_rounded,
                      color: textSecondary,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getPreviewText(PinEntity pin) {
    if (pin.content == null || pin.content!.trim().isEmpty) {
      return _fallbackTypeTitle(pin.type);
    }
    final raw = pin.content!.trim();
    if (raw.startsWith('{')) {
      try {
        final Map<String, dynamic> data = jsonDecode(raw);
        switch (pin.type) {
          case 'file':
            final path = data['filePath'] as String? ?? data['path'] as String? ?? '';
            final name = data['fileName'] as String? ?? (path.isNotEmpty ? path.split(RegExp(r'[/\\]')).last : '');
            return name.isNotEmpty ? name : 'Document File';
          case 'link':
            final title = data['title'] as String? ?? '';
            final url = data['url'] as String? ?? '';
            return title.isNotEmpty ? title : (url.isNotEmpty ? url : 'Web Link');
          case 'image':
            final caption = data['caption'] as String? ?? '';
            final path = data['filePath'] as String? ?? '';
            final name = path.isNotEmpty ? path.split(RegExp(r'[/\\]')).last : 'Image';
            return caption.isNotEmpty ? caption : name;
          case 'colorSwatch':
            final label = data['label'] as String? ?? '';
            final hex = data['hex'] as String? ?? '';
            return label.isNotEmpty ? 'Color: $label' : (hex.isNotEmpty ? 'Swatch: ${hex.toUpperCase()}' : 'Color Swatch');
          case 'task':
          case 'tasklist':
          case 'checklist':
            final title = data['title'] as String? ?? data['text'] as String? ?? '';
            return title.isNotEmpty ? title : _fallbackTypeTitle(pin.type);
          default:
            final title = data['title'] as String? ?? data['name'] as String? ?? '';
            return title.isNotEmpty ? title : _fallbackTypeTitle(pin.type);
        }
      } catch (_) {
        return _fallbackTypeTitle(pin.type);
      }
    }

    final firstLine = raw.split('\n').first.replaceAll(RegExp(r'^#+\s*'), '').trim();
    return firstLine.isNotEmpty ? firstLine : _fallbackTypeTitle(pin.type);
  }

  String _fallbackTypeTitle(String type) {
    switch (type) {
      case 'note': return 'Note';
      case 'task': return 'Task';
      case 'file': return 'Document File';
      case 'link': return 'Link';
      case 'image': return 'Image';
      case 'colorSwatch': return 'Color Swatch';
      case 'drawing': return 'Drawing';
      case 'heading': return 'Heading';
      case 'checklist': return 'Checklist';
      case 'tasklist': return 'Task List';
      case 'frame': return 'Frame';
      default: return type.toUpperCase();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KANBAN VIEW IMPLEMENTATION
// ─────────────────────────────────────────────────────────────────────────────
class _BoardKanbanView extends ConsumerWidget {
  final String boardId;
  const _BoardKanbanView({required this.boardId});

  static const List<(String, String, Color)> _columns = [
    ('todo', 'To Do', Color(0xFFB9BCC2)),
    ('in_progress', 'In Progress', Color(0xFF5FA8F5)),
    ('done', 'Done', Color(0xFF5FC7A3)),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinsStream = ref.watch(pinRepositoryProvider).watchPinsForBoard(boardId);
    final tasksStream = ref.watch(taskRepositoryProvider).watchTasksForBoard(boardId);

    return StreamBuilder<List<PinEntity>>(
      stream: pinsStream,
      builder: (context, pinSnapshot) {
        final pins = pinSnapshot.data ?? const <PinEntity>[];
        final taskPins = pins.where((p) => p.type == 'task').toList();

        return StreamBuilder<List<TaskEntity>>(
          stream: tasksStream,
          builder: (context, taskSnapshot) {
            final tasks = taskSnapshot.data ?? const <TaskEntity>[];
            final taskMap = {for (var t in tasks) if (t.pinId != null) t.pinId!: t};

            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 768;

                if (isWide) {
                  final colWidth = (constraints.maxWidth - 48) / 3;
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _columns.map((col) {
                        final (statusKey, title, color) = col;
                        final colPins = taskPins.where((p) {
                          final t = taskMap[p.id];
                          final status = t?.status ?? 'todo';
                          return status == statusKey || (statusKey == 'todo' && status != 'in_progress' && status != 'done');
                        }).toList();

                        return Container(
                          width: colWidth,
                          margin: const EdgeInsets.only(right: 12),
                          child: _KanbanColumn(
                            boardId: boardId,
                            statusKey: statusKey,
                            title: title,
                            color: color,
                            pins: colPins,
                            taskMap: taskMap,
                          ),
                        );
                      }).toList(),
                    ),
                  );
                } else {
                  // Phone / Narrow screen -> Stack To Do, In Progress, and Done vertically in a Column
                  return SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _columns.map((col) {
                        final (statusKey, title, color) = col;
                        final colPins = taskPins.where((p) {
                          final t = taskMap[p.id];
                          final status = t?.status ?? 'todo';
                          return status == statusKey || (statusKey == 'todo' && status != 'in_progress' && status != 'done');
                        }).toList();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: _KanbanColumn(
                            boardId: boardId,
                            statusKey: statusKey,
                            title: title,
                            color: color,
                            pins: colPins,
                            taskMap: taskMap,
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}

class _KanbanColumn extends ConsumerWidget {
  final String boardId;
  final String statusKey;
  final String title;
  final Color color;
  final List<PinEntity> pins;
  final Map<String, TaskEntity> taskMap;

  const _KanbanColumn({
    required this.boardId,
    required this.statusKey,
    required this.title,
    required this.color,
    required this.pins,
    required this.taskMap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCol = isDark ? EpicordiaColors.surfaceAppDark : EpicordiaColors.surfaceSunkenLight;
    final cardBg = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
    final borderClr = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;

    return DragTarget<PinEntity>(
      onAcceptWithDetails: (details) async {
        final pin = details.data;
        final existingTask = taskMap[pin.id];
        final taskRepo = ref.read(taskRepositoryProvider);

        if (existingTask != null) {
          await taskRepo.updateTask(existingTask.copyWith(status: statusKey));
        } else {
          final taskId = DateTime.now().millisecondsSinceEpoch.toString();
          final previewTitle = pin.content?.split('\n').first ?? 'Task';
          await taskRepo.createTask(
            TasksCompanion.insert(
              id: taskId,
              pinId: Value(pin.id),
              boardId: Value(boardId),
              title: previewTitle,
              status: Value(statusKey),
            ),
          );
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return Container(
          decoration: BoxDecoration(
            color: isHovered ? color.withValues(alpha: 0.08) : bgCol,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovered ? color : borderClr,
              width: isHovered ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Column header
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${pins.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (pins.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    'Drop tasks here',
                    style: TextStyle(fontSize: 13, color: textSecondary),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: pins.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final pin = pins[index];
                      final preview = pin.content?.split('\n').first ?? 'Task';

                      return LongPressDraggable<PinEntity>(
                        data: pin,
                        feedback: Material(
                          elevation: 12,
                          borderRadius: BorderRadius.circular(14),
                          color: cardBg,
                          child: Container(
                            width: 260,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: color, width: 1.5),
                            ),
                            child: Text(
                              preview,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
                            ),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.3,
                          child: _KanbanCard(
                            pin: pin,
                            preview: preview,
                            boardId: boardId,
                            color: color,
                          ),
                        ),
                        child: _KanbanCard(
                          pin: pin,
                          preview: preview,
                          boardId: boardId,
                          color: color,
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _KanbanCard extends StatelessWidget {
  final PinEntity pin;
  final String preview;
  final String boardId;
  final Color color;

  const _KanbanCard({
    required this.pin,
    required this.preview,
    required this.boardId,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
    final borderClr = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showPinEditorPanel(context, pinId: pin.id, boardId: boardId),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderClr),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CanvasToolbar extends ConsumerWidget {
  final VoidCallback onAddNote;
  final VoidCallback onAddTask;
  final VoidCallback onAddChecklist;
  final VoidCallback onAddDrawing;
  final VoidCallback onAddLink;
  final VoidCallback onAddImage;
  final VoidCallback onAddColorSwatch;
  final VoidCallback onAddAudio;
  final VoidCallback onAddFile;
  final VoidCallback onAddHeading;
  final VoidCallback onAddFrame;
  final VoidCallback onAddConnector;
  final VoidCallback onDelete;

  const _CanvasToolbar({
    required this.onAddNote,
    required this.onAddTask,
    required this.onAddChecklist,
    required this.onAddDrawing,
    required this.onAddLink,
    required this.onAddImage,
    required this.onAddColorSwatch,
    required this.onAddAudio,
    required this.onAddFile,
    required this.onAddHeading,
    required this.onAddFrame,
    required this.onAddConnector,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(toolbarPositionProvider);
    final activeMode = ref.watch(canvasToolModeProvider);
    final isHorizontal = position == ToolbarPosition.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
    final borderClr = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;

    final modeTools = [
      (CanvasToolMode.select, Icons.near_me_rounded, 'Select Tool'),
      (CanvasToolMode.pan, Icons.pan_tool_outlined, 'Pan Tool (Hand)'),
      (CanvasToolMode.zoom, Icons.search_rounded, 'Zoom Tool'),
    ];

    final addTools = [
      (Icons.sticky_note_2_outlined, 'Note', onAddNote),
      (Icons.check_circle_outline, 'Task', onAddTask),
      (Icons.checklist_rounded, 'Checklist', onAddChecklist),
      (Icons.draw_outlined, 'Drawing', onAddDrawing),
      (Icons.link_rounded, 'Link', onAddLink),
      (Icons.image_outlined, 'Image', onAddImage),
      (Icons.palette_outlined, 'Color Swatch', onAddColorSwatch),
      (Icons.mic_none_rounded, 'Audio Memo', onAddAudio),
      (Icons.attach_file_rounded, 'Document / File', onAddFile),
      (Icons.title_rounded, 'Heading', onAddHeading),
      (Icons.crop_free_rounded, 'Frame', onAddFrame),
      (Icons.timeline_rounded, 'Connector Mode', onAddConnector),
    ];

    Widget buildDivider() {
      return isHorizontal
          ? Container(
              width: 1,
              height: 24,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              color: borderClr,
            )
          : Container(
              height: 1,
              width: 24,
              margin: const EdgeInsets.symmetric(vertical: 6),
              color: borderClr,
            );
    }

    final children = <Widget>[
      // Grip Handle (Cycle Position)
      _ToolButton(
        icon: isHorizontal ? Icons.drag_handle_rounded : Icons.drag_indicator_rounded,
        tooltip: 'Change toolbar position (Left / Right / Bottom)',
        onTap: () => ref.read(toolbarPositionProvider.notifier).cyclePosition(),
      ),
      buildDivider(),

      // Mutually Exclusive Mode Buttons
      ...modeTools.map((m) {
        final (mode, icon, label) = m;
        final isActive = activeMode == mode;
        return _ToolButton(
          icon: icon,
          tooltip: label,
          isActive: isActive,
          onTap: () => ref.read(canvasToolModeProvider.notifier).setMode(mode),
        );
      }),
      buildDivider(),

      // Pin Creation Tools
      ...addTools.map((t) {
        final (icon, label, action) = t;
        return _ToolButton(icon: icon, tooltip: label, onTap: action);
      }),
      buildDivider(),

      // Delete Selection
      _ToolButton(
        icon: Icons.delete_outline_rounded,
        tooltip: 'Delete selected pin(s)',
        onTap: onDelete,
        isDanger: true,
      ),
    ];

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      color: bg,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderClr, width: 0.8),
        ),
        child: isHorizontal
            ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: children,
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: children,
              ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isActive;
  final bool isDanger;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.tooltip,
    this.isActive = false,
    this.isDanger = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeBg = isDark ? EpicordiaColors.blue600.withValues(alpha: 0.25) : EpicordiaColors.blue100;
    final activeIconClr = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue700;
    final defaultIconClr = isDanger
        ? (isDark ? EpicordiaColors.errorDark : EpicordiaColors.errorLight)
        : (isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight);

    return Tooltip(
      message: tooltip,
      preferBelow: false,
      waitDuration: const Duration(milliseconds: 300),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: isActive ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isActive ? activeIconClr : defaultIconClr,
          ),
        ),
      ),
    );
  }
}
