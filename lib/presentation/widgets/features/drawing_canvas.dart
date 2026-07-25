import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class StrokePoint {
  final double x;
  final double y;
  final double pressure;

  const StrokePoint(this.x, this.y, [this.pressure = 1.0]);

  List<dynamic> toJson() => [x, y, pressure];

  factory StrokePoint.fromJson(List<dynamic> json) {
    return StrokePoint(
      (json[0] as num).toDouble(),
      (json[1] as num).toDouble(),
      json.length > 2 ? (json[2] as num).toDouble() : 1.0,
    );
  }
}

class StrokeData {
  final List<StrokePoint> points;
  final String color;
  final double widthPx;

  const StrokeData({
    required this.points,
    required this.color,
    required this.widthPx,
  });

  Map<String, dynamic> toJson() => {
        'points': points.map((p) => p.toJson()).toList(),
        'color': color,
        'widthPx': widthPx,
      };

  factory StrokeData.fromJson(Map<String, dynamic> json) {
    final rawPoints = (json['points'] as List<dynamic>? ?? []);
    return StrokeData(
      points: rawPoints.map((p) => StrokePoint.fromJson(p as List<dynamic>)).toList(),
      color: json['color'] as String? ?? '#16181C',
      widthPx: (json['widthPx'] as num?)?.toDouble() ?? 2.5,
    );
  }
}

class DrawingEditorCanvas extends StatefulWidget {
  final String? initialContent;
  final ValueChanged<String> onChanged;

  const DrawingEditorCanvas({
    super.key,
    this.initialContent,
    required this.onChanged,
  });

  @override
  State<DrawingEditorCanvas> createState() => _DrawingEditorCanvasState();
}

class _DrawingEditorCanvasState extends State<DrawingEditorCanvas> {
  final List<StrokeData> _strokes = [];
  final List<StrokePoint> _currentPoints = [];
  String _selectedColor = '#16181C';
  double _selectedWidth = 3.0;
  bool _isEraser = false;

  static const List<String> _palette = [
    '#16181C',
    '#F0806B',
    '#5FA8F5',
    '#5FC7A3',
    '#F4C453',
    '#9C8CF0',
    '#FFFFFF',
  ];

  static const List<double> _widths = [2.0, 4.0, 8.0, 14.0];

  @override
  void initState() {
    super.initState();
    _loadInitialStrokes();
  }

  void _loadInitialStrokes() {
    if (widget.initialContent == null || widget.initialContent!.isEmpty) return;
    try {
      final map = jsonDecode(widget.initialContent!) as Map<String, dynamic>;
      final rawStrokes = map['strokes'] as List<dynamic>? ?? [];
      for (final s in rawStrokes) {
        _strokes.add(StrokeData.fromJson(s as Map<String, dynamic>));
      }
    } catch (_) {}
  }

  void _notifyChange() {
    final json = jsonEncode({
      'strokes': _strokes.map((s) => s.toJson()).toList(),
    });
    widget.onChanged(json);
  }

  void _onPanStart(DragStartDetails details, RenderBox box) {
    final local = box.globalToLocal(details.globalPosition);
    setState(() {
      _currentPoints.clear();
      _currentPoints.add(StrokePoint(local.dx, local.dy));
    });
  }

  void _onPanUpdate(DragUpdateDetails details, RenderBox box) {
    final local = box.globalToLocal(details.globalPosition);
    setState(() {
      _currentPoints.add(StrokePoint(local.dx, local.dy));
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentPoints.isEmpty) return;
    setState(() {
      if (_isEraser) {
        // Erase strokes intersecting current path
        _eraseStrokesNear(_currentPoints);
      } else {
        _strokes.add(StrokeData(
          points: List.from(_currentPoints),
          color: _selectedColor,
          widthPx: _selectedWidth,
        ));
      }
      _currentPoints.clear();
    });
    _notifyChange();
  }

  void _eraseStrokesNear(List<StrokePoint> eraserPoints) {
    _strokes.removeWhere((stroke) {
      for (final ep in eraserPoints) {
        for (final sp in stroke.points) {
          final dx = ep.x - sp.x;
          final dy = ep.y - sp.y;
          if ((dx * dx + dy * dy) < 400) return true; // 20px threshold
        }
      }
      return false;
    });
  }

  void _undo() {
    if (_strokes.isNotEmpty) {
      setState(() => _strokes.removeLast());
      _notifyChange();
    }
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _currentPoints.clear();
    });
    _notifyChange();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Canvas Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: EpicordiaColors.borderSubtleLight)),
          ),
          child: Row(
            children: [
              // Colors
              ..._palette.map((hex) {
                final isSelected = !_isEraser && _selectedColor == hex;
                final color = _hexToColor(hex);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _isEraser = false;
                      _selectedColor = hex;
                    });
                  },
                  child: Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      border: Border.all(
                        color: isSelected ? EpicordiaColors.blue600 : EpicordiaColors.borderStrongLight,
                        width: isSelected ? 2.5 : 1,
                      ),
                    ),
                  ),
                );
              }),
              const VerticalDivider(width: 16),
              // Widths
              ..._widths.map((w) {
                final isSelected = !_isEraser && _selectedWidth == w;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _isEraser = false;
                      _selectedWidth = w;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? EpicordiaColors.blue50 : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: CircleAvatar(
                      radius: w / 2 + 1,
                      backgroundColor: isSelected ? EpicordiaColors.blue600 : EpicordiaColors.textSecondaryLight,
                    ),
                  ),
                );
              }),
              const Spacer(),
              // Eraser
              IconButton(
                icon: Icon(Icons.cleaning_services_outlined,
                    size: 20, color: _isEraser ? EpicordiaColors.blue600 : EpicordiaColors.textSecondaryLight),
                tooltip: 'Eraser',
                onPressed: () => setState(() => _isEraser = !_isEraser),
              ),
              // Undo
              IconButton(
                icon: const Icon(Icons.undo, size: 20, color: EpicordiaColors.textSecondaryLight),
                tooltip: 'Undo',
                onPressed: _undo,
              ),
              // Clear
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: EpicordiaColors.errorLight),
                tooltip: 'Clear canvas',
                onPressed: _clear,
              ),
            ],
          ),
        ),
        // Drawing Area
        Expanded(
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              return Builder(
                builder: (builderContext) {
                  return GestureDetector(
                    onPanStart: (d) {
                      final box = builderContext.findRenderObject() as RenderBox;
                      _onPanStart(d, box);
                    },
                    onPanUpdate: (d) {
                      final box = builderContext.findRenderObject() as RenderBox;
                      _onPanUpdate(d, box);
                    },
                    onPanEnd: _onPanEnd,
                    child: Container(
                      color: isDark ? EpicordiaColors.surfaceCardDark : Colors.white,
                      child: CustomPaint(
                        painter: _DrawingCanvasPainter(
                          strokes: _strokes,
                          currentPoints: _currentPoints,
                          currentColor: _selectedColor,
                          currentWidth: _selectedWidth,
                          isEraser: _isEraser,
                          isDark: isDark,
                        ),
                        size: Size.infinite,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Color _hexToColor(String hex) {
    final clean = hex.replaceFirst('#', '');
    if (clean.length == 6) return Color(int.parse('FF$clean', radix: 16));
    return Colors.black;
  }
}

class _DrawingCanvasPainter extends CustomPainter {
  final List<StrokeData> strokes;
  final List<StrokePoint> currentPoints;
  final String currentColor;
  final double currentWidth;
  final bool isEraser;
  final bool isDark;

  const _DrawingCanvasPainter({
    required this.strokes,
    required this.currentPoints,
    required this.currentColor,
    required this.currentWidth,
    required this.isEraser,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Render existing strokes
    for (final stroke in strokes) {
      _paintStroke(canvas, stroke.points, stroke.color, stroke.widthPx);
    }
    // Render current active stroke
    if (currentPoints.isNotEmpty) {
      if (isEraser) {
        _paintStroke(canvas, currentPoints, '#F0806B', 12.0);
      } else {
        _paintStroke(canvas, currentPoints, currentColor, currentWidth);
      }
    }
  }

  void _paintStroke(Canvas canvas, List<StrokePoint> points, String hex, double width) {
    if (points.length < 2) return;
    final color = _hexToColor(hex);
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(points.first.x, points.first.y);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].x, points[i].y);
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
  bool shouldRepaint(_DrawingCanvasPainter old) => true;
}
