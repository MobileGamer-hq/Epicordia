import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../domain/models/note_model.dart';

/// A transparent pen drawing layer that sits over note content.
/// Supports Samsung S-Pen, Apple Pencil, Microsoft Surface Pen, finger, and mouse drawing.
class PenDrawingOverlay extends StatefulWidget {
  final List<PenStroke> strokes;
  final ValueChanged<List<PenStroke>> onChanged;
  final bool isPenActive;
  final bool isStylusOnlyMode;
  final PenTool selectedTool;
  final String selectedColor;
  final double selectedWidth;

  const PenDrawingOverlay({
    super.key,
    required this.strokes,
    required this.onChanged,
    required this.isPenActive,
    required this.isStylusOnlyMode,
    required this.selectedTool,
    required this.selectedColor,
    required this.selectedWidth,
  });

  @override
  State<PenDrawingOverlay> createState() => _PenDrawingOverlayState();
}

class _PenDrawingOverlayState extends State<PenDrawingOverlay> {
  late List<PenStroke> _strokes;
  final List<PenPoint> _currentPoints = [];

  @override
  void initState() {
    super.initState();
    _strokes = List.from(widget.strokes);
  }

  @override
  void didUpdateWidget(PenDrawingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.strokes != oldWidget.strokes) {
      _strokes = List.from(widget.strokes);
    }
  }

  bool _shouldProcessPointer(PointerEvent event) {
    if (!widget.isPenActive) return false;
    final isStylus = event.kind == PointerDeviceKind.stylus ||
        event.kind == PointerDeviceKind.invertedStylus;
    if (widget.isStylusOnlyMode && !isStylus) {
      return false; // Palm rejection mode: ignore finger touches/mouse
    }
    return true;
  }

  void _onPointerDown(PointerDownEvent event, RenderBox box) {
    if (!_shouldProcessPointer(event)) return;
    final local = box.globalToLocal(event.position);
    final pressure = event.pressure > 0 ? event.pressure : 1.0;

    // Automatic eraser tip detection (inverted stylus tip)
    final toolToUse = event.kind == PointerDeviceKind.invertedStylus
        ? PenTool.eraser
        : widget.selectedTool;

    setState(() {
      _currentPoints.clear();
      _currentPoints.add(PenPoint(local.dx, local.dy, pressure));
      if (toolToUse == PenTool.eraser) {
        _eraseStrokesNear([PenPoint(local.dx, local.dy, pressure)]);
      }
    });
  }

  void _onPointerMove(PointerMoveEvent event, RenderBox box) {
    if (!_shouldProcessPointer(event) || _currentPoints.isEmpty) return;
    final local = box.globalToLocal(event.position);
    final pressure = event.pressure > 0 ? event.pressure : 1.0;

    final toolToUse = event.kind == PointerDeviceKind.invertedStylus
        ? PenTool.eraser
        : widget.selectedTool;

    setState(() {
      final newPoint = PenPoint(local.dx, local.dy, pressure);
      _currentPoints.add(newPoint);
      if (toolToUse == PenTool.eraser) {
        _eraseStrokesNear([newPoint]);
      }
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_currentPoints.isEmpty) return;
    _finishCurrentStroke(event.kind);
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (_currentPoints.isEmpty) return;
    _finishCurrentStroke(event.kind);
  }

  void _finishCurrentStroke(PointerDeviceKind kind) {
    final toolToUse =
        kind == PointerDeviceKind.invertedStylus ? PenTool.eraser : widget.selectedTool;

    if (toolToUse != PenTool.eraser && _currentPoints.isNotEmpty) {
      final double opacity = toolToUse == PenTool.highlighter ? 0.38 : 1.0;
      setState(() {
        _strokes.add(PenStroke(
          points: List.from(_currentPoints),
          color: widget.selectedColor,
          widthPx: widget.selectedWidth,
          opacity: opacity,
          tool: toolToUse,
        ));
      });
      widget.onChanged(_strokes);
    }
    setState(() {
      _currentPoints.clear();
    });
  }

  void _eraseStrokesNear(List<PenPoint> eraserPoints) {
    bool erasedAny = false;
    const thresholdSq = 625.0; // ~25px erase radius

    _strokes.removeWhere((stroke) {
      for (final ep in eraserPoints) {
        for (final sp in stroke.points) {
          final dx = ep.x - sp.x;
          final dy = ep.y - sp.y;
          if ((dx * dx + dy * dy) < thresholdSq) {
            erasedAny = true;
            return true;
          }
        }
      }
      return false;
    });

    if (erasedAny) {
      widget.onChanged(_strokes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IgnorePointer(
      ignoring: !widget.isPenActive,
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          return Listener(
            behavior: widget.isPenActive
                ? HitTestBehavior.opaque
                : HitTestBehavior.translucent,
            onPointerDown: (e) {
              final box = ctx.findRenderObject() as RenderBox?;
              if (box != null) _onPointerDown(e, box);
            },
            onPointerMove: (e) {
              final box = ctx.findRenderObject() as RenderBox?;
              if (box != null) _onPointerMove(e, box);
            },
            onPointerUp: _onPointerUp,
            onPointerCancel: _onPointerCancel,
            child: CustomPaint(
              painter: PenDrawingCanvasPainter(
                strokes: _strokes,
                currentPoints: _currentPoints,
                currentColor: widget.selectedColor,
                currentWidth: widget.selectedWidth,
                currentTool: widget.selectedTool,
                isDark: isDark,
              ),
              size: Size.infinite,
            ),
          );
        },
      ),
    );
  }
}

/// CustomPainter that renders vector pen strokes and live active drawing with smooth curves.
class PenDrawingCanvasPainter extends CustomPainter {
  final List<PenStroke> strokes;
  final List<PenPoint> currentPoints;
  final String currentColor;
  final double currentWidth;
  final PenTool currentTool;
  final bool isDark;

  const PenDrawingCanvasPainter({
    required this.strokes,
    required this.currentPoints,
    required this.currentColor,
    required this.currentWidth,
    required this.currentTool,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Render saved strokes
    for (final stroke in strokes) {
      _paintStroke(
        canvas: canvas,
        points: stroke.points,
        hexColor: stroke.color,
        width: stroke.widthPx,
        opacity: stroke.opacity,
        tool: stroke.tool,
      );
    }

    // Render active drawing stroke
    if (currentPoints.isNotEmpty && currentTool != PenTool.eraser) {
      final double opacity = currentTool == PenTool.highlighter ? 0.38 : 1.0;
      _paintStroke(
        canvas: canvas,
        points: currentPoints,
        hexColor: currentColor,
        width: currentWidth,
        opacity: opacity,
        tool: currentTool,
      );
    }
  }

  void _paintStroke({
    required Canvas canvas,
    required List<PenPoint> points,
    required String hexColor,
    required double width,
    required double opacity,
    required PenTool tool,
  }) {
    if (points.isEmpty) return;

    final Color baseColor = _hexToColor(hexColor);
    final Color strokeColor = baseColor.withValues(alpha: opacity);

    if (points.length == 1) {
      // Single tap point dot
      final p = points.first;
      final dotPaint = Paint()
        ..color = strokeColor
        ..style = PaintingStyle.fill;
      final radius = (width * p.pressure) / 2.0;
      canvas.drawCircle(Offset(p.x, p.y), radius > 1.0 ? radius : 1.0, dotPaint);
      return;
    }

    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (tool == PenTool.highlighter) {
      paint.blendMode = isDark ? BlendMode.lighten : BlendMode.multiply;
    }

    final path = Path();
    path.moveTo(points.first.x, points.first.y);

    // Smooth quadratic curve interpolation for fluid natural pen stroke
    for (int i = 1; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final midX = (p0.x + p1.x) / 2.0;
      final midY = (p0.y + p1.y) / 2.0;
      path.quadraticBezierTo(p0.x, p0.y, midX, midY);
    }

    if (points.length > 1) {
      final last = points.last;
      path.lineTo(last.x, last.y);
    }

    canvas.drawPath(path, paint);
  }

  Color _hexToColor(String hex) {
    final clean = hex.replaceFirst('#', '').toUpperCase();
    if (clean == '16181C' && isDark) {
      return const Color(0xFFE2E8F0);
    }
    if (clean.length == 6) return Color(int.parse('FF$clean', radix: 16));
    return isDark ? const Color(0xFFE2E8F0) : Colors.black;
  }

  @override
  bool shouldRepaint(PenDrawingCanvasPainter old) => true;
}

/// Floating Toolbar Widget for controlling Pen settings (Tools, Colors, Width, Palm Rejection, Undo, Redo)
class PenControlToolbar extends StatelessWidget {
  final PenTool activeTool;
  final String activeColor;
  final double activeWidth;
  final bool isStylusOnlyMode;
  final bool canUndo;
  final bool canRedo;
  final ValueChanged<PenTool> onToolSelected;
  final ValueChanged<String> onColorSelected;
  final ValueChanged<double> onWidthSelected;
  final ValueChanged<bool> onStylusOnlyToggle;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onClear;
  final VoidCallback onClosePenMode;

  const PenControlToolbar({
    super.key,
    required this.activeTool,
    required this.activeColor,
    required this.activeWidth,
    required this.isStylusOnlyMode,
    required this.canUndo,
    required this.canRedo,
    required this.onToolSelected,
    required this.onColorSelected,
    required this.onWidthSelected,
    required this.onStylusOnlyToggle,
    required this.onUndo,
    required this.onRedo,
    required this.onClear,
    required this.onClosePenMode,
  });

  static const List<String> paletteColors = [
    '#16181C',
    '#F0806B',
    '#5FA8F5',
    '#5FC7A3',
    '#F4C453',
    '#9C8CF0',
    '#FFFFFF',
  ];

  static const List<double> widthPresets = [2.0, 4.0, 8.0, 14.0, 22.0];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
    final borderClr = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;
    final activeBlue = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderClr, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pen Tool Selectors
            _ToolIconButton(
              icon: Icons.edit_outlined,
              label: 'Pen',
              isActive: activeTool == PenTool.pen,
              onTap: () => onToolSelected(PenTool.pen),
            ),
            _ToolIconButton(
              icon: Icons.border_color_outlined,
              label: 'Highlighter',
              isActive: activeTool == PenTool.highlighter,
              onTap: () => onToolSelected(PenTool.highlighter),
            ),
            _ToolIconButton(
              icon: Icons.brush_outlined,
              label: 'Pencil',
              isActive: activeTool == PenTool.pencil,
              onTap: () => onToolSelected(PenTool.pencil),
            ),
            _ToolIconButton(
              icon: Icons.cleaning_services_outlined,
              label: 'Eraser',
              isActive: activeTool == PenTool.eraser,
              onTap: () => onToolSelected(PenTool.eraser),
            ),
            const VerticalDivider(width: 16, indent: 6, endIndent: 6),
            // Color Palette
            if (activeTool != PenTool.eraser)
              ...paletteColors.map((hex) {
                final isSelected = activeColor == hex;
                final color = _hexToColor(hex, isDark);
                return GestureDetector(
                  onTap: () => onColorSelected(hex),
                  child: Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(right: 5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      border: Border.all(
                        color: isSelected ? activeBlue : (isDark ? Colors.white38 : Colors.black26),
                        width: isSelected ? 2.5 : 1.0,
                      ),
                    ),
                  ),
                );
              }),
            if (activeTool != PenTool.eraser)
              const VerticalDivider(width: 16, indent: 6, endIndent: 6),
            // Stroke Width Selector
            ...widthPresets.map((w) {
              final isSelected = activeWidth == w;
              return GestureDetector(
                onTap: () => onWidthSelected(w),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                  margin: const EdgeInsets.only(right: 3),
                  decoration: BoxDecoration(
                    color: isSelected ? activeBlue.withValues(alpha: 0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: CircleAvatar(
                    radius: mathMax(2.0, w / 3.0),
                    backgroundColor: isSelected ? activeBlue : textSecondary,
                  ),
                ),
              );
            }),
            const VerticalDivider(width: 16, indent: 6, endIndent: 6),
            // Palm Rejection / Stylus Only Mode Toggle
            Tooltip(
              message: isStylusOnlyMode ? 'Stylus Only Mode (Palm Rejection Active)' : 'Stylus + Touch/Mouse Mode',
              child: IconButton(
                icon: Icon(
                  isStylusOnlyMode ? Icons.do_not_touch : Icons.gesture,
                  size: 20,
                  color: isStylusOnlyMode ? activeBlue : textSecondary,
                ),
                onPressed: () => onStylusOnlyToggle(!isStylusOnlyMode),
              ),
            ),
            // Undo & Redo & Clear
            IconButton(
              icon: Icon(Icons.undo, size: 20, color: canUndo ? activeBlue : textSecondary.withValues(alpha: 0.4)),
              tooltip: 'Undo stroke',
              onPressed: canUndo ? onUndo : null,
            ),
            IconButton(
              icon: Icon(Icons.redo, size: 20, color: canRedo ? activeBlue : textSecondary.withValues(alpha: 0.4)),
              tooltip: 'Redo stroke',
              onPressed: canRedo ? onRedo : null,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: EpicordiaColors.errorLight),
              tooltip: 'Clear drawing layer',
              onPressed: onClear,
            ),
            const VerticalDivider(width: 16, indent: 6, endIndent: 6),
            // Done / Exit Pen Mode Button
            IconButton(
              icon: Icon(Icons.check_circle, size: 22, color: activeBlue),
              tooltip: 'Done drawing',
              onPressed: onClosePenMode,
            ),
          ],
        ),
      ),
    );
  }

  double mathMax(double a, double b) => a > b ? a : b;

  Color _hexToColor(String hex, bool isDark) {
    final clean = hex.replaceFirst('#', '').toUpperCase();
    if (clean == '16181C' && isDark) {
      return const Color(0xFFE2E8F0);
    }
    if (clean.length == 6) return Color(int.parse('FF$clean', radix: 16));
    return isDark ? const Color(0xFFE2E8F0) : Colors.black;
  }
}

class _ToolIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ToolIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600;
    final inactiveColor = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;

    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(7),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isActive ? activeColor.withValues(alpha: 0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 19, color: isActive ? activeColor : inactiveColor),
        ),
      ),
    );
  }
}
