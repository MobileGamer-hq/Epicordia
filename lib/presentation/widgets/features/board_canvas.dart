import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_canvas/infinite_canvas.dart';

import '../../../core/theme.dart';
import '../../../data/database/database.dart';
import '../../../data/repository/pin_repository.dart';
import 'board_pin_card.dart';
import 'connector_layer.dart';

class BoardCanvas extends ConsumerStatefulWidget {
  final String boardId;
  final VoidCallback? onAddNote;
  final VoidCallback? onAddTask;
  final VoidCallback? onDeleteSelection;

  const BoardCanvas({
    super.key,
    required this.boardId,
    this.onAddNote,
    this.onAddTask,
    this.onDeleteSelection,
  });

  @override
  ConsumerState<BoardCanvas> createState() => BoardCanvasState();
}

class BoardCanvasState extends ConsumerState<BoardCanvas> {
  late final InfiniteCanvasController _controller;
  bool _wasDragging = false;
  List<PinEntity> _latestPins = const [];

  @override
  void initState() {
    super.initState();
    _controller = InfiniteCanvasController();
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  InfiniteCanvasController get controller => _controller;

  void _onControllerChanged() {
    if (_controller.mouseDown) {
      _wasDragging = true;
      return;
    }

    if (_wasDragging) {
      _wasDragging = false;
      _persistNodePositions();
    }
  }

  Future<void> _persistNodePositions() async {
    final repo = ref.read(pinRepositoryProvider);
    for (final node in _controller.nodes) {
      final pinId = (node.key as ValueKey<String>).value;
      final pin = _latestPins.where((p) => p.id == pinId).firstOrNull;
      if (pin == null) continue;

      final moved = (pin.x - node.offset.dx).abs() > 0.5 ||
          (pin.y - node.offset.dy).abs() > 0.5 ||
          (pin.width - node.size.width).abs() > 0.5 ||
          (pin.height - node.size.height).abs() > 0.5;

      if (!moved) continue;

      await repo.updatePinPosition(
        pinId,
        x: node.offset.dx,
        y: node.offset.dy,
        width: node.size.width,
        height: node.size.height,
      );
    }
  }

  void _syncPins(List<PinEntity> pins) {
    _latestPins = pins;
    if (_controller.mouseDown) return;

    final pinIds = pins.map((p) => p.id).toSet();
    for (final node in List<InfiniteCanvasNode>.from(_controller.nodes)) {
      final id = (node.key as ValueKey<String>).value;
      if (!pinIds.contains(id)) {
        _controller.remove(node.key);
      }
    }

    for (final pin in pins) {
      final key = ValueKey<String>(pin.id);
      final existing = _controller.getNode(key);
      if (existing != null) {
        if (existing.currentlyResizing) continue;
        existing
          ..offset = Offset(pin.x, pin.y)
          ..size = Size(pin.width, pin.height);
      } else {
        _controller.add(_pinToNode(pin));
      }
    }
    _controller.notifyListeners();
  }

  InfiniteCanvasNode _pinToNode(PinEntity pin) {
    return InfiniteCanvasNode(
      key: ValueKey<String>(pin.id),
      offset: Offset(pin.x, pin.y),
      size: Size(pin.width, pin.height),
      resizeMode: ResizeMode.corners,
      child: SizedBox.expand(
        child: BoardPinCard(
          type: pin.type,
          content: pin.content,
          colorTag: pin.colorTag,
        ),
      ),
    );
  }

  Future<void> deleteSelection() async {
    final repo = ref.read(pinRepositoryProvider);
    final selected = _controller.selection.toList();
    for (final node in selected) {
      final pinId = (node.key as ValueKey<String>).value;
      await repo.deletePin(pinId);
      _controller.remove(node.key);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pinsStream = ref.watch(pinRepositoryProvider).watchPinsForBoard(widget.boardId);

    return StreamBuilder<List<PinEntity>>(
      stream: pinsStream,
      builder: (context, snapshot) {
        final pins = snapshot.data ?? const <PinEntity>[];
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _syncPins(pins);
        });

        final showEmptyHint = pins.isEmpty && snapshot.connectionState == ConnectionState.active;
        final connectorsData = ref.watch(connectorRenderDataProvider(widget.boardId));

        return Stack(
          children: [
            Container(color: EpicordiaColors.surfaceSunkenLight),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Transform(
                  transform: _controller.transform.value,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: ConnectorLayerPainter(connectorsData, Theme.of(context).colorScheme),
                  ),
                );
              },
            ),
            InfiniteCanvas(
              controller: _controller,
              menuVisible: false,
              drawVisibleOnly: true,
              gridSize: const Size.square(24),
              backgroundBuilder: (context, viewport) {
                return const SizedBox();
              },
            ),
            if (showEmptyHint)
              _EmptyCanvasHint(
                onAddNote: widget.onAddNote,
                onAddTask: widget.onAddTask,
              ),
          ],
        );
      },
    );
  }
}

class _EmptyCanvasHint extends StatelessWidget {
  final VoidCallback? onAddNote;
  final VoidCallback? onAddTask;

  const _EmptyCanvasHint({this.onAddNote, this.onAddTask});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: EpicordiaColors.surfaceSunkenLight,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.dashboard_customize_outlined, size: 40, color: EpicordiaColors.textTertiaryLight),
          const SizedBox(height: 12),
          const Text(
            'This board is empty',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: EpicordiaColors.textPrimaryLight),
          ),
          const SizedBox(height: 6),
          const Text(
            'Use the toolbar to add a note or task',
            style: TextStyle(fontSize: 13, color: EpicordiaColors.textSecondaryLight),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onAddNote != null)
                FilledButton.icon(
                  onPressed: onAddNote,
                  icon: const Icon(Icons.sticky_note_2_outlined, size: 18),
                  label: const Text('Add note'),
                ),
              if (onAddNote != null && onAddTask != null) const SizedBox(width: 8),
              if (onAddTask != null)
                OutlinedButton.icon(
                  onPressed: onAddTask,
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Add task'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
