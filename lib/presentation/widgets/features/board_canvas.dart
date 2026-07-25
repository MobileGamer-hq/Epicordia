import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_canvas/infinite_canvas.dart';


import '../../../core/theme.dart';
import '../../../data/database/database.dart';
import '../../../data/repository/connector_repository.dart';
import '../../../data/repository/pin_repository.dart';
import 'board_pin_card.dart';
import 'connector_layer.dart';
import 'pin_editor_panel.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Dot grid background painter — scales with canvas zoom
// ─────────────────────────────────────────────────────────────────────────────
class _DotGridPainter extends CustomPainter {
  final double dotSpacing;
  final double dotRadius;
  final Color dotColor;
  final Offset offset; // pan offset from canvas transform
  final double scale;  // zoom scale from canvas transform

  const _DotGridPainter({
    required this.dotSpacing,
    required this.dotRadius,
    required this.dotColor,
    required this.offset,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = dotColor;
    final spacing = dotSpacing * scale;
    if (spacing < 4) return; // too zoomed out to see dots

    final startX = offset.dx % spacing;
    final startY = offset.dy % spacing;

    for (double x = startX; x < size.width; x += spacing) {
      for (double y = startY; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) =>
      old.offset != offset || old.scale != scale;
}

// ─────────────────────────────────────────────────────────────────────────────
// Board Canvas
// ─────────────────────────────────────────────────────────────────────────────
class BoardCanvas extends ConsumerStatefulWidget {
  final String boardId;
  final VoidCallback? onAddNote;
  final VoidCallback? onAddTask;
  final VoidCallback? onDeleteSelection;
  final ValueChanged<bool>? onEditStateChanged;

  const BoardCanvas({
    super.key,
    required this.boardId,
    this.onAddNote,
    this.onAddTask,
    this.onDeleteSelection,
    this.onEditStateChanged,
  });

  @override
  ConsumerState<BoardCanvas> createState() => BoardCanvasState();
}

class BoardCanvasState extends ConsumerState<BoardCanvas> {
  late final InfiniteCanvasController _controller;
  bool _wasDragging = false;
  List<PinEntity> _latestPins = const [];

  // Connector Creation Mode
  bool _isConnectingMode = false;
  String? _connectorSourcePinId;

  bool get isConnectingMode => _isConnectingMode;

  void toggleConnectorMode() {
    setState(() {
      _isConnectingMode = !_isConnectingMode;
      _connectorSourcePinId = null;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (_isConnectingMode) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connector Mode: Tap source card then tap target card to connect.'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _handlePinTap(String pinId) async {
    if (_isConnectingMode) {
      if (_connectorSourcePinId == null) {
        setState(() => _connectorSourcePinId = pinId);
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Selected source card. Now tap target card to connect.'),
              duration: Duration(seconds: 4),
            ),
          );
        }
      } else {
        if (_connectorSourcePinId != pinId) {
          final id = DateTime.now().millisecondsSinceEpoch.toString();
          await ref.read(connectorRepositoryProvider).createConnector(
            ConnectorsCompanion.insert(
              id: id,
              boardId: widget.boardId,
              fromPinId: _connectorSourcePinId!,
              toPinId: pinId,
              style: const Value('curved'),
            ),
          );
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cards connected successfully!'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
        setState(() {
          _connectorSourcePinId = null;
          _isConnectingMode = false;
        });
      }
    }
  }

  // The pin currently open in the editor panel
  String? _editingPinId;

  void _setEditingPinId(String? id) {
    setState(() => _editingPinId = id);
    widget.onEditStateChanged?.call(id != null);
  }

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
    final frames = _latestPins.where((p) => p.type == 'frame').toList();

    for (final node in _controller.nodes) {
      final pinId = (node.key as ValueKey<String>).value;
      final pin = _latestPins.where((p) => p.id == pinId).firstOrNull;
      if (pin == null) continue;

      final deltaX = node.offset.dx - pin.x;
      final deltaY = node.offset.dy - pin.y;

      final moved = deltaX.abs() > 0.5 ||
          deltaY.abs() > 0.5 ||
          (pin.width - node.size.width).abs() > 0.5 ||
          (pin.height - node.size.height).abs() > 0.5;

      if (!moved) continue;

      String? newParentFrameId = pin.parentFrameId;
      if (pin.type != 'frame') {
        final pinCenter = Offset(
          node.offset.dx + node.size.width / 2,
          node.offset.dy + node.size.height / 2,
        );
        final containingFrame = frames.where((f) {
          return pinCenter.dx >= f.x &&
              pinCenter.dx <= (f.x + f.width) &&
              pinCenter.dy >= f.y &&
              pinCenter.dy <= (f.y + f.height);
        }).firstOrNull;
        newParentFrameId = containingFrame?.id;
      }

      await repo.updatePinPosition(
        pinId,
        x: node.offset.dx,
        y: node.offset.dy,
        width: node.size.width,
        height: node.size.height,
      );

      if (newParentFrameId != pin.parentFrameId) {
        final updated = pin.copyWith(
          x: node.offset.dx,
          y: node.offset.dy,
          width: node.size.width,
          height: node.size.height,
          parentFrameId: Value(newParentFrameId),
          modifiedAt: DateTime.now(),
        );
        await repo.updatePin(updated);
      }

      // If a frame pin moved, move all child pins inside it!
      if (pin.type == 'frame' && (deltaX.abs() > 0.5 || deltaY.abs() > 0.5)) {
        final children = _latestPins.where((p) => p.parentFrameId == pin.id);
        for (final child in children) {
          final childNodeKey = ValueKey<String>(child.id);
          final childNode = _controller.getNode(childNodeKey);
          final newX = child.x + deltaX;
          final newY = child.y + deltaY;
          if (childNode != null) {
            childNode.offset = Offset(newX, newY);
          }
          await repo.updatePinPosition(
            child.id,
            x: newX,
            y: newY,
          );
        }
      }
    }
  }

  void _syncPins(List<PinEntity> pins) {
    _latestPins = pins;
    if (_controller.mouseDown) return;

    // Only top-level pins spawn canvas nodes on the main board canvas
    final topLevelPins = List<PinEntity>.from(pins.where((p) => p.parentFrameId == null))
      ..sort((a, b) {
        if (a.type == 'frame' && b.type != 'frame') return -1;
        if (a.type != 'frame' && b.type == 'frame') return 1;
        return a.zIndex.compareTo(b.zIndex);
      });

    final topLevelIds = topLevelPins.map((p) => p.id).toSet();

    for (final node in List<InfiniteCanvasNode>.from(_controller.nodes)) {
      final id = (node.key as ValueKey<String>).value;
      if (!topLevelIds.contains(id)) {
        _controller.remove(node.key);
      }
    }

    for (final pin in topLevelPins) {
      final key = ValueKey<String>(pin.id);
      final existing = _controller.getNode(key);
      if (existing != null) {
        if (existing.currentlyResizing) continue;
        existing.offset = Offset(pin.x, pin.y);
        existing.size = Size(pin.width, pin.height);
      } else {
        _controller.add(_pinToNode(pin));
      }
    }

    // Reorder nodes in controller so frame nodes are drawn first (background layer)
    final nodeMap = {for (var n in _controller.nodes) (n.key as ValueKey<String>).value: n};
    _controller.nodes.clear();
    for (final pin in topLevelPins) {
      final node = nodeMap[pin.id];
      if (node != null) {
        _controller.nodes.add(node);
      }
    }

    // Trigger a repaint without calling the protected notifyListeners
    if (mounted) setState(() {});
  }

  InfiniteCanvasNode _pinToNode(PinEntity pin) {
    final isHeading = pin.type == 'heading';
    final isSelectedSource = _connectorSourcePinId == pin.id;

    return InfiniteCanvasNode(
      key: ValueKey<String>(pin.id),
      offset: Offset(pin.x, pin.y),
      size: Size(pin.width, pin.height),
      resizeMode: isHeading ? ResizeMode.disabled : ResizeMode.corners,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_isConnectingMode) {
            _handlePinTap(pin.id);
          }
        },
        child: Container(
          decoration: isSelectedSource
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: EpicordiaColors.blue600, width: 3),
                )
              : null,
          child: SizedBox.expand(
            child: BoardPinCard(
              pinId: pin.id,
              type: pin.type,
              content: pin.content,
              colorTag: pin.colorTag,
              onEdit: (id) {
                if (_isConnectingMode) {
                  _handlePinTap(id);
                } else {
                  _setEditingPinId(id);
                }
              },
            ),
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF101216) : EpicordiaColors.surfaceSunkenLight;
    final dotColor = isDark ? const Color(0xFF2A2D33) : const Color(0xFFD0D3D8);

    final connectorsData = ref.watch(connectorRenderDataProvider(widget.boardId));

    return StreamBuilder<List<PinEntity>>(
      stream: pinsStream,
      builder: (context, snapshot) {
        final pins = snapshot.data ?? const <PinEntity>[];
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _syncPins(pins);
        });

        final showEmptyHint = pins.isEmpty && snapshot.connectionState == ConnectionState.active;

        return DragTarget<PinEntity>(
          onAcceptWithDetails: (details) async {
            final pin = details.data;
            final renderBox = context.findRenderObject() as RenderBox?;
            if (renderBox == null) return;
            final localPos = renderBox.globalToLocal(details.offset);
            final transform = _controller.transform.value;
            final inverse = Matrix4.tryInvert(transform);
            final worldPos = inverse != null ? MatrixUtils.transformPoint(inverse, localPos) : localPos;

            final pinRepo = ref.read(pinRepositoryProvider);
            final updated = pin.copyWith(
              x: worldPos.dx,
              y: worldPos.dy,
              parentFrameId: const Value(null),
              modifiedAt: DateTime.now(),
            );
            await pinRepo.updatePin(updated);
          },
          builder: (context, candidateData, rejectedData) {
            return Stack(
              children: [
            // ── Background fill ───────────────────────────────────────────
            Positioned.fill(child: ColoredBox(color: bgColor)),

            // ── Dot grid overlay ──────────────────────────────────────────
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller.transform,
                builder: (context, _) {
                  final m = _controller.transform.value;
                  final s = m.getMaxScaleOnAxis();
                  final dx = m.getTranslation().x;
                  final dy = m.getTranslation().y;
                  return CustomPaint(
                    painter: _DotGridPainter(
                      dotSpacing: 24,
                      dotRadius: 1.0,
                      dotColor: dotColor,
                      offset: Offset(dx, dy),
                      scale: s,
                    ),
                  );
                },
              ),
            ),

            // ── Connector layer ───────────────────────────────────────────
            AnimatedBuilder(
              animation: _controller.transform,
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

            // ── Main canvas ───────────────────────────────────────────────
            InfiniteCanvas(
              controller: _controller,
              menuVisible: false,
              drawVisibleOnly: true,
              gridSize: const Size.square(24),
              backgroundBuilder: (context, viewport) => const SizedBox.shrink(),
            ),

            // ── Empty hint ────────────────────────────────────────────────
            if (showEmptyHint)
              _EmptyCanvasHint(
                onAddNote: widget.onAddNote,
                onAddTask: widget.onAddTask,
              ),

            // ── Zoom toolbar (bottom-right) ────────────────────────────────
            if (_editingPinId == null)
              Positioned(
                right: 16,
                bottom: 24,
                child: _ZoomToolbar(controller: _controller),
              ),

            // ── Pin Editor Panel / Bottom Sheet ────────────────────────────
            if (_editingPinId != null)
              _PinEditorOverlay(
                pinId: _editingPinId!,
                boardId: widget.boardId,
                onClose: () => _setEditingPinId(null),
              ),
          ],
        );
      },
    );
  },
);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pin Editor overlay — side panel on wide / bottom sheet on narrow
// ─────────────────────────────────────────────────────────────────────────────
class _PinEditorOverlay extends StatelessWidget {
  final String pinId;
  final String boardId;
  final VoidCallback onClose;

  const _PinEditorOverlay({
    required this.pinId,
    required this.boardId,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Modal barrier
        Positioned.fill(
          child: GestureDetector(
            onTap: onClose,
            child: Container(
              color: Colors.black.withValues(alpha: 0.45),
            ),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Material(
              elevation: 20,
              borderRadius: BorderRadius.circular(20),
              color: Theme.of(context).colorScheme.surface,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: math.min(580, screenSize.width * 0.9),
                  maxHeight: math.min(760, screenSize.height * 0.85),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: PinEditorPanel(
                    pinId: pinId,
                    boardId: boardId,
                    onClose: onClose,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Zoom toolbar
// ─────────────────────────────────────────────────────────────────────────────
class _ZoomToolbar extends StatelessWidget {
  final InfiniteCanvasController controller;

  const _ZoomToolbar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller.transform,
      builder: (context, _) {
        final scale = controller.getScale();
        final pct = (scale * 100).round();

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ZoomBtn(icon: Icons.remove, onTap: controller.zoomOut),
              GestureDetector(
                onTap: controller.zoomReset,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '$pct%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: EpicordiaColors.textSecondaryLight,
                    ),
                  ),
                ),
              ),
              _ZoomBtn(icon: Icons.add, onTap: controller.zoomIn),
            ],
          ),
        );
      },
    );
  }
}

class _ZoomBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ZoomBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(icon, size: 18, color: EpicordiaColors.textSecondaryLight),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty canvas hint
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyCanvasHint extends StatelessWidget {
  final VoidCallback? onAddNote;
  final VoidCallback? onAddTask;

  const _EmptyCanvasHint({this.onAddNote, this.onAddTask});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: EpicordiaColors.blue700.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.dashboard_customize_outlined, size: 32, color: EpicordiaColors.blue700),
          ),
          const SizedBox(height: 16),
          const Text(
            'This board is empty',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: EpicordiaColors.textPrimaryLight),
          ),
          const SizedBox(height: 6),
          const Text(
            'Use the toolbar to add a note or task',
            style: TextStyle(fontSize: 13, color: EpicordiaColors.textSecondaryLight),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onAddNote != null)
                FilledButton.icon(
                  onPressed: onAddNote,
                  icon: const Icon(Icons.sticky_note_2_outlined, size: 16),
                  label: const Text('Add note'),
                  style: FilledButton.styleFrom(backgroundColor: EpicordiaColors.blue700),
                ),
              if (onAddNote != null && onAddTask != null) const SizedBox(width: 8),
              if (onAddTask != null)
                OutlinedButton.icon(
                  onPressed: onAddTask,
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Add task'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
