// lib/presentation/widgets/features/drawing_canvas.dart
//
// Full-screen drawing canvas overlay.
// Opens when the user double-taps a drawing/handwriting pin on the board.
//
// JSON schema (epicordia-per-card-schema.md §drawing):
//   {"strokes": [{"points": [[x, y, pressure], ...], "color": "#RRGGBB", "widthPx": 2.5}]}

import 'dart:convert';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide Path;
import 'package:flutter/material.dart' as material show Path;

import 'package:epicordia/core/theme.dart';

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

/// A single sampled point on a stroke.  [pressure] comes from the stylus;
/// for regular touch / mouse events it defaults to 1.0.
class DrawingPoint {
  final double x;
  final double y;
  final double pressure;

  const DrawingPoint(this.x, this.y, this.pressure);

  List<double> toJson() => [x, y, pressure];

  factory DrawingPoint.fromJson(List<dynamic> list) => DrawingPoint(
        (list[0] as num).toDouble(),
        (list[1] as num).toDouble(),
        (list[2] as num).toDouble(),
      );
}

/// One continuous pen-down → pen-up stroke.
class DrawingStroke {
  final Color color;
  final double widthPx;
  final List<DrawingPoint> points;

  const DrawingStroke({
    required this.color,
    required this.widthPx,
    required this.points,
  });

  // ── JSON ──────────────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'points': points.map((p) => p.toJson()).toList(),
        'color': _colorToHex(color),
        'widthPx': widthPx,
      };

  factory DrawingStroke.fromJson(Map<String, dynamic> json) => DrawingStroke(
        color: _colorFromHex(json['color'] as String? ?? '#16181C'),
        widthPx: (json['widthPx'] as num?)?.toDouble() ?? 2.5,
        points: (json['points'] as List<dynamic>)
            .map((p) => DrawingPoint.fromJson(p as List<dynamic>))
            .toList(),
      );

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _colorToHex(Color c) {
    final r = (c.r * 255).round().toRadixString(16).padLeft(2, '0');
    final g = (c.g * 255).round().toRadixString(16).padLeft(2, '0');
    final b = (c.b * 255).round().toRadixString(16).padLeft(2, '0');
    return '#$r$g$b';
  }

  static Color _colorFromHex(String hex) {
    final clean = hex.replaceFirst('#', '');
    if (clean.length == 6) {
      return Color(int.parse('FF$clean', radix: 16));
    }
    if (clean.length == 8) {
      return Color(int.parse(clean, radix: 16));
    }
    return const Color(0xFF16181C);
  }
}

// ---------------------------------------------------------------------------
// JSON helpers
// ---------------------------------------------------------------------------

/// Deserialises the top-level {"strokes": [...]} wrapper.
List<DrawingStroke> strokesFromJson(String? json) {
  if (json == null || json.trim().isEmpty) return [];
  try {
    final map = jsonDecode(json) as Map<String, dynamic>;
    final list = map['strokes'] as List<dynamic>? ?? [];
    return list
        .map((e) => DrawingStroke.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
}

/// Serialises strokes to the {"strokes": [...]} wrapper.
String strokestoJson(List<DrawingStroke> strokes) =>
    jsonEncode({'strokes': strokes.map((s) => s.toJson()).toList()});

// ---------------------------------------------------------------------------
// Palette & width constants
// ---------------------------------------------------------------------------

/// The six palette colors available in the toolbar.
const List<Color> _kPaletteColors = [
  Color(0xFF16181C), // Black
  Color(0xFF1A3A6B), // Dark Blue
  Color(0xFFE53935), // Red
  Color(0xFF43A047), // Green
  Color(0xFFFB8C00), // Orange
  Color(0xFFFFFFFF), // White
];

/// Stroke-width presets.
const List<({String label, double px})> _kWidthPresets = [
  (label: 'Thin', px: 1.5),
  (label: 'Med', px: 3.0),
  (label: 'Thick', px: 6.0),
];

// ---------------------------------------------------------------------------
// DrawingCanvas widget
// ---------------------------------------------------------------------------

/// Full-screen drawing canvas that the caller pushes as an overlay (e.g.
/// via [Navigator.push] with a [MaterialPageRoute]) when the user
/// double-taps a drawing pin.
class DrawingCanvas extends StatefulWidget {
  /// JSON produced by a previous [onSave] call, or null for a blank canvas.
  final String? initialStrokesJson;

  /// Invoked when the user presses Done with the serialised stroke JSON.
  final void Function(String strokesJson) onSave;

  /// Invoked after [onSave] so the caller can pop / dismiss the overlay.
  final VoidCallback onClose;

  const DrawingCanvas({
    super.key,
    this.initialStrokesJson,
    required this.onSave,
    required this.onClose,
  });

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  // ── Stroke state ──────────────────────────────────────────────────────────
  late List<DrawingStroke> _strokes;
  final List<DrawingStroke> _redoStack = [];

  /// Points accumulated during the current pen-down gesture.
  List<DrawingPoint> _activePoints = [];

  // ── Tool state ────────────────────────────────────────────────────────────
  Color _currentColor = _kPaletteColors.first;
  double _currentWidthPx = _kWidthPresets[1].px; // Medium by default

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _strokes = strokesFromJson(widget.initialStrokesJson);
  }

  // ── Pointer handlers ──────────────────────────────────────────────────────

  void _onPointerDown(PointerDownEvent event) {
    _redoStack.clear(); // any new stroke clears the redo history
    _activePoints = [_pointFrom(event.localPosition, event.pressure, event.kind)];
    setState(() {});
  }

  void _onPointerMove(PointerMoveEvent event) {
    _activePoints.add(_pointFrom(event.localPosition, event.pressure, event.kind));
    setState(() {});
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_activePoints.length >= 2) {
      _activePoints.add(_pointFrom(event.localPosition, event.pressure, event.kind));
      _strokes.add(DrawingStroke(
        color: _currentColor,
        widthPx: _currentWidthPx,
        points: List.unmodifiable(_activePoints),
      ));
    }
    _activePoints = [];
    setState(() {});
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _activePoints = [];
    setState(() {});
  }

  DrawingPoint _pointFrom(Offset pos, double rawPressure, PointerDeviceKind kind) {
    // Stylus gives us real pressure; touch & mouse default to 1.0.
    final pressure = kind == PointerDeviceKind.stylus ? rawPressure : 1.0;
    return DrawingPoint(pos.dx, pos.dy, pressure.clamp(0.01, 1.0));
  }

  // ── Toolbar actions ───────────────────────────────────────────────────────

  void _undo() {
    if (_strokes.isEmpty) return;
    setState(() {
      _redoStack.add(_strokes.removeLast());
    });
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    setState(() {
      _strokes.add(_redoStack.removeLast());
    });
  }

  Future<void> _clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear canvas?'),
        content: const Text(
            'This will erase all strokes. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: EpicordiaColors.errorLight,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _strokes.clear();
        _redoStack.clear();
        _activePoints = [];
      });
    }
  }

  void _done() {
    widget.onSave(strokestoJson(_strokes));
    widget.onClose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EpicordiaColors.surfaceCardLight,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            _CanvasHeader(onClose: _done),

            // ── Drawing surface ───────────────────────────────────────────
            Expanded(
              child: Listener(
                onPointerDown: _onPointerDown,
                onPointerMove: _onPointerMove,
                onPointerUp: _onPointerUp,
                onPointerCancel: _onPointerCancel,
                // Allow all pointer kinds (stylus, touch, mouse).
                behavior: HitTestBehavior.opaque,
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _StrokesPainter(
                      strokes: _strokes,
                      activePoints: _activePoints,
                      activeColor: _currentColor,
                      activeWidthPx: _currentWidthPx,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),

            // ── Toolbar ───────────────────────────────────────────────────
            _DrawingToolbar(
              currentColor: _currentColor,
              currentWidthPx: _currentWidthPx,
              canUndo: _strokes.isNotEmpty,
              canRedo: _redoStack.isNotEmpty,
              onColorSelected: (c) => setState(() => _currentColor = c),
              onWidthSelected: (w) => setState(() => _currentWidthPx = w),
              onUndo: _undo,
              onRedo: _redo,
              onClear: _clear,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header bar
// ---------------------------------------------------------------------------

class _CanvasHeader extends StatelessWidget {
  final VoidCallback onClose;

  const _CanvasHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: EpicordiaColors.surfaceCardLight,
        border: Border(
          bottom: BorderSide(color: EpicordiaColors.borderSubtleLight),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.draw_outlined,
            size: 20,
            color: EpicordiaColors.textSecondaryLight,
          ),
          const SizedBox(width: 10),
          const Text(
            'Drawing',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: EpicordiaColors.textPrimaryLight,
            ),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: onClose,
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Done'),
            style: FilledButton.styleFrom(
              backgroundColor: EpicordiaColors.blue600,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              textStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Toolbar
// ---------------------------------------------------------------------------

class _DrawingToolbar extends StatelessWidget {
  final Color currentColor;
  final double currentWidthPx;
  final bool canUndo;
  final bool canRedo;
  final ValueChanged<Color> onColorSelected;
  final ValueChanged<double> onWidthSelected;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onClear;

  const _DrawingToolbar({
    required this.currentColor,
    required this.currentWidthPx,
    required this.canUndo,
    required this.canRedo,
    required this.onColorSelected,
    required this.onWidthSelected,
    required this.onUndo,
    required this.onRedo,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: EpicordiaColors.surfaceCardLight,
        border: Border(
          top: BorderSide(color: EpicordiaColors.borderSubtleLight),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Row 1: Color palette + undo / redo / clear ─────────────────
          Row(
            children: [
              // Color dots
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _kPaletteColors.map((color) {
                      final isSelected = color.toARGB32() == currentColor.toARGB32();
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _ColorDot(
                          color: color,
                          isSelected: isSelected,
                          onTap: () => onColorSelected(color),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Undo
              _ToolIconButton(
                icon: Icons.undo_rounded,
                tooltip: 'Undo',
                enabled: canUndo,
                onTap: onUndo,
              ),

              const SizedBox(width: 4),

              // Redo
              _ToolIconButton(
                icon: Icons.redo_rounded,
                tooltip: 'Redo',
                enabled: canRedo,
                onTap: onRedo,
              ),

              const SizedBox(width: 4),

              // Clear
              _ToolIconButton(
                icon: Icons.delete_outline_rounded,
                tooltip: 'Clear',
                enabled: true,
                onTap: onClear,
                dangerColor: EpicordiaColors.errorLight,
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Row 2: Width toggle ─────────────────────────────────────────
          Row(
            children: [
              const Text(
                'WIDTH',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: EpicordiaColors.textTertiaryLight,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 10),
              ..._kWidthPresets.map((preset) {
                final isSelected = (preset.px - currentWidthPx).abs() < 0.01;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _WidthChip(
                    label: preset.label,
                    widthPx: preset.px,
                    isSelected: isSelected,
                    previewColor: currentColor,
                    onTap: () => onWidthSelected(preset.px),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Toolbar sub-widgets
// ---------------------------------------------------------------------------

class _ColorDot extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorDot({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // White needs a visible border regardless of selection state.
    final isWhite = color.toARGB32() == const Color(0xFFFFFFFF).toARGB32();

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: isSelected
                ? EpicordiaColors.blue600
                : (isWhite
                    ? EpicordiaColors.borderStrongLight
                    : Colors.transparent),
            width: isSelected ? 2.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: EpicordiaColors.blue600.withValues(alpha: 0.35),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        // Checkmark for selected state
        child: isSelected
            ? Icon(
                Icons.check,
                size: 14,
                color: isWhite
                    ? EpicordiaColors.textPrimaryLight
                    : Colors.white,
              )
            : null,
      ),
    );
  }
}

class _WidthChip extends StatelessWidget {
  final String label;
  final double widthPx;
  final bool isSelected;
  final Color previewColor;
  final VoidCallback onTap;

  const _WidthChip({
    required this.label,
    required this.widthPx,
    required this.isSelected,
    required this.previewColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? EpicordiaColors.blue50
              : EpicordiaColors.surfaceSunkenLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? EpicordiaColors.blue600
                : EpicordiaColors.borderSubtleLight,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mini stroke-preview line
            Container(
              width: 22,
              height: widthPx.clamp(1.5, 6.0),
              decoration: BoxDecoration(
                // Use a border-like colour for the white preview so it is visible.
                color: previewColor == const Color(0xFFFFFFFF)
                    ? EpicordiaColors.borderStrongLight
                    : previewColor,
                borderRadius: BorderRadius.circular(widthPx),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? EpicordiaColors.blue600
                    : EpicordiaColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onTap;
  final Color? dangerColor;

  const _ToolIconButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onTap,
    this.dangerColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = enabled
        ? (dangerColor ?? EpicordiaColors.textSecondaryLight)
        : EpicordiaColors.textTertiaryLight;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 22, color: effectiveColor),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CustomPainter
// ---------------------------------------------------------------------------

/// Renders all committed [strokes] plus the currently-in-progress
/// [activePoints] as smooth round-capped paths.
///
/// Each consecutive pair of points is drawn as a quadratic Bezier using
/// midpoints, which produces a smooth curve without requiring a full
/// spline library.
class _StrokesPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final List<DrawingPoint> activePoints;
  final Color activeColor;
  final double activeWidthPx;

  const _StrokesPainter({
    required this.strokes,
    required this.activePoints,
    required this.activeColor,
    required this.activeWidthPx,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // White drawing background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = EpicordiaColors.surfaceCardLight,
    );

    // Draw all committed strokes
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke.points, stroke.color, stroke.widthPx);
    }

    // Draw the in-progress stroke
    if (activePoints.length >= 2) {
      _drawStroke(canvas, activePoints, activeColor, activeWidthPx);
    } else if (activePoints.length == 1) {
      // Single tap → draw a dot so the user gets immediate visual feedback.
      final p = activePoints.first;
      canvas.drawCircle(
        Offset(p.x, p.y),
        (activeWidthPx * p.pressure) / 2,
        Paint()
          ..color = activeColor
          ..style = PaintingStyle.fill,
      );
    }
  }

  void _drawStroke(
    Canvas canvas,
    List<DrawingPoint> pts,
    Color color,
    double widthPx,
  ) {
    if (pts.length < 2) return;

    // Draw segment-by-segment so pressure can modulate width along the stroke.
    for (int i = 0; i < pts.length - 1; i++) {
      final a = pts[i];
      final b = pts[i + 1];

      final avgPressure = (a.pressure + b.pressure) / 2.0;
      final strokeWidth = (widthPx * avgPressure).clamp(0.5, widthPx * 1.5);

      final paint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;

      // Quadratic Bezier smoothing via midpoints:
      //   - First segment: line from point[0] to midpoint(0,1).
      //   - Middle segments: curve from midpoint(i-1,i) through point[i]
      //                       to midpoint(i,i+1).
      //   - Last segment: curve from midpoint(n-2,n-1) through point[n-2]
      //                    to point[n-1].
      final material.Path path = material.Path();

      if (i == 0) {
        final mid = Offset((a.x + b.x) / 2, (a.y + b.y) / 2);
        path
          ..moveTo(a.x, a.y)
          ..lineTo(mid.dx, mid.dy);
      } else if (i == pts.length - 2) {
        final prev = pts[i - 1];
        final mid = Offset((prev.x + a.x) / 2, (prev.y + a.y) / 2);
        path
          ..moveTo(mid.dx, mid.dy)
          ..quadraticBezierTo(a.x, a.y, b.x, b.y);
      } else {
        final prev = pts[i - 1];
        final start = Offset((prev.x + a.x) / 2, (prev.y + a.y) / 2);
        final end = Offset((a.x + b.x) / 2, (a.y + b.y) / 2);
        path
          ..moveTo(start.dx, start.dy)
          ..quadraticBezierTo(a.x, a.y, end.dx, end.dy);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_StrokesPainter old) =>
      old.strokes != strokes ||
      old.activePoints != activePoints ||
      old.activeColor != activeColor ||
      old.activeWidthPx != activeWidthPx;
}
