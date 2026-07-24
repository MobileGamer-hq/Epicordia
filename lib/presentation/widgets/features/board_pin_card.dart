import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../data/database/database.dart';
import '../../../data/providers.dart';
import '../../../data/repository/pin_repository.dart';
import '../../../data/repository/task_repository.dart';
import '../core/epicordia_card.dart';

/// Callback type for opening the pin editor panel.
typedef OnEditPin = void Function(String pinId);

class BoardPinCard extends ConsumerWidget {
  final String pinId;
  final String type;
  final String? content;
  final String? colorTag;
  final OnEditPin? onEdit;

  const BoardPinCard({
    super.key,
    required this.pinId,
    required this.type,
    this.content,
    this.colorTag,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onDoubleTap: () => onEdit?.call(pinId),
      child: EpicordiaCard(
        indicatorColor: _colorFromTag(colorTag),
        padding: _paddingForType(type),
        child: _buildBody(context, ref),
      ),
    );
  }

  EdgeInsets _paddingForType(String t) {
    switch (t) {
      case 'image':
        return EdgeInsets.zero; // image is edge-to-edge
      case 'colorSwatch':
        return EdgeInsets.zero;
      case 'heading':
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
      default:
        return const EdgeInsets.all(14);
    }
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    switch (type) {
      case 'note':
        return _NoteCardBody(content: content ?? '');
      case 'task':
        return _TaskCardBody(pinId: pinId, content: content ?? '');
      case 'tasklist':
        return _TaskListCardBody(pinId: pinId, content: content);
      case 'checklist':
        return _ChecklistCardBody(pinId: pinId, content: content);
      case 'image':
        return _ImageCardBody(content: content);
      case 'link':
        return _LinkCardBody(content: content ?? '');
      case 'drawing':
      case 'handwriting':
        return _DrawingCardBody(content: content, type: type);
      case 'audio':
        return _AudioCardBody(content: content);
      case 'colorSwatch':
        return _ColorSwatchBody(content: content ?? '');
      case 'heading':
        return _HeadingCardBody(content: content ?? '');
      case 'table':
        return _TableCardBody(content: content);
      case 'frame':
        return _FrameCardBody(content: content);
      case 'board':
        return _BoardTileBody(content: content ?? '');
      case 'file':
        return _FileCardBody(content: content);
      default:
        return _NoteCardBody(content: content ?? '');
    }
  }

  static Color? _colorFromTag(String? tag) {
    if (tag == null || tag.isEmpty) return null;
    const named = {
      'yellow': Color(0xFFF4C453),
      'coral': Color(0xFFF0806B),
      'mint': Color(0xFF5FC7A3),
      'lavender': Color(0xFF9C8CF0),
      'sky': Color(0xFF5FA8F5),
      'grey': Color(0xFFB9BCC2),
    };
    return named[tag.toLowerCase()] ?? (tag.startsWith('#') ? _tryParseHex(tag) : null);
  }

  static Color? _tryParseHex(String hex) {
    final value = hex.replaceFirst('#', '');
    if (value.length == 6) {
      return Color(int.parse('FF$value', radix: 16));
    }
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NOTE CARD
// ─────────────────────────────────────────────────────────────────────────────
class _NoteCardBody extends StatelessWidget {
  final String content;
  const _NoteCardBody({required this.content});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TypeLabel(label: 'NOTE', icon: Icons.sticky_note_2_outlined),
        const SizedBox(height: 6),
        Expanded(
          child: ClipRect(
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black, Colors.transparent],
                stops: [0.7, 1.0],
              ).createShader(bounds),
              blendMode: BlendMode.dstIn,
              child: MarkdownBody(
                data: content.isEmpty ? '_Empty note — double-tap to edit_' : content,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(fontSize: 12, color: EpicordiaColors.textPrimaryLight, height: 1.4),
                  h1: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: EpicordiaColors.textPrimaryLight),
                  h2: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: EpicordiaColors.textPrimaryLight),
                  listBullet: const TextStyle(fontSize: 12, color: EpicordiaColors.textPrimaryLight),
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
// TASK CARD
// ─────────────────────────────────────────────────────────────────────────────
class _TaskCardBody extends ConsumerWidget {
  final String pinId;
  final String content;
  const _TaskCardBody({required this.pinId, required this.content});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the task linked to this pin
    final taskStream = ref.watch(taskForPinProvider(pinId));

    return taskStream.when(
      loading: () => const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
      error: (_, _) => _FallbackTaskBody(content: content),
      data: (task) {
        if (task == null) return _FallbackTaskBody(content: content);
        return _TaskBodyWithData(task: task, ref: ref);
      },
    );
  }
}

class _FallbackTaskBody extends StatelessWidget {
  final String content;
  const _FallbackTaskBody({required this.content});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusRing(status: 'todo', onToggle: null),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            content.trim().split('\n').first.isEmpty ? 'Untitled task' : content.trim().split('\n').first,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: EpicordiaColors.textPrimaryLight),
          ),
        ),
      ],
    );
  }
}

class _TaskBodyWithData extends StatelessWidget {
  final TaskEntity task;
  final WidgetRef ref;
  const _TaskBodyWithData({required this.task, required this.ref});

  @override
  Widget build(BuildContext context) {
    final isOverdue = task.status != 'done' && task.dueDate != null && task.dueDate!.isBefore(DateTime.now());
    final isCompleted = task.status == 'done';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusRing(
              status: task.status,
              onToggle: () {
                final next = _nextStatus(task.status);
                ref.read(taskRepositoryProvider).updateTask(task.copyWith(status: next));
              },
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                task.title.isEmpty ? 'Untitled task' : task.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: EpicordiaColors.textPrimaryLight,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                  decorationColor: EpicordiaColors.textTertiaryLight,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Chips row
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            if (task.dueDate != null)
              _PillChip(
                label: _formatDate(task.dueDate!),
                color: isOverdue ? EpicordiaColors.errorLight : EpicordiaColors.textTertiaryLight,
                icon: isOverdue ? Icons.warning_amber_rounded : Icons.schedule_outlined,
              ),
            if (task.priority > 0)
              _PillChip(
                label: task.priority == 1 ? 'Med' : 'High',
                color: task.priority == 2 ? EpicordiaColors.errorLight : const Color(0xFFE5A030),
                icon: Icons.flag_outlined,
              ),
          ],
        ),
        if ((task.notes ?? '').isNotEmpty) ...[
          const SizedBox(height: 6),
          Expanded(
            child: ClipRect(
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black, Colors.transparent],
                  stops: [0.7, 1.0],
                ).createShader(bounds),
                blendMode: BlendMode.dstIn,
                child: Text(
                  task.notes!,
                  style: const TextStyle(fontSize: 11, color: EpicordiaColors.textSecondaryLight, height: 1.4),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _nextStatus(String current) {
    switch (current) {
      case 'todo': return 'in_progress';
      case 'in_progress': return 'done';
      default: return 'todo';
    }
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dDay = DateTime(d.year, d.month, d.day);
    if (dDay == today) return 'Today';
    if (dDay == today.add(const Duration(days: 1))) return 'Tomorrow';
    return '${d.month}/${d.day}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TASK LIST CARD
// ─────────────────────────────────────────────────────────────────────────────
class _TaskListCardBody extends ConsumerWidget {
  final String pinId;
  final String? content;
  const _TaskListCardBody({required this.pinId, this.content});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksStream = ref.watch(tasksForGroupPinProvider(pinId));
    final title = _parseTitle(content);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TypeLabel(label: 'TASK LIST', icon: Icons.checklist_rounded),
        if (title.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: EpicordiaColors.textPrimaryLight)),
        ],
        const SizedBox(height: 6),
        tasksStream.when(
          loading: () => const SizedBox(height: 24, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
          error: (_, _) => const SizedBox.shrink(),
          data: (tasks) {
            final done = tasks.where((t) => t.status == 'done').length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$done of ${tasks.length} done',
                  style: const TextStyle(fontSize: 10, color: EpicordiaColors.textTertiaryLight, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                ...tasks.take(5).map((task) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      _MiniStatusRing(isDone: task.status == 'done'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          task.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: EpicordiaColors.textPrimaryLight,
                            decoration: task.status == 'done' ? TextDecoration.lineThrough : null,
                            decorationColor: EpicordiaColors.textTertiaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
                if (tasks.length > 5)
                  Text('+${tasks.length - 5} more', style: const TextStyle(fontSize: 10, color: EpicordiaColors.textTertiaryLight)),
              ],
            );
          },
        ),
      ],
    );
  }

  String _parseTitle(String? content) {
    if (content == null || content.isEmpty) return '';
    try {
      final map = jsonDecode(content) as Map<String, dynamic>;
      return map['title'] as String? ?? '';
    } catch (_) {
      return '';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHECKLIST CARD (lightweight, no Tasks table)
// ─────────────────────────────────────────────────────────────────────────────
class _ChecklistCardBody extends ConsumerWidget {
  final String pinId;
  final String? content;
  const _ChecklistCardBody({required this.pinId, this.content});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = _parseItems(content);
    final done = items.where((i) => i['done'] == true).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TypeLabel(label: 'CHECKLIST', icon: Icons.checklist_outlined),
        const SizedBox(height: 4),
        Text('$done of ${items.length} done',
            style: const TextStyle(fontSize: 10, color: EpicordiaColors.textTertiaryLight, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        ...items.take(6).map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Row(
            children: [
              _PlainCheckbox(isDone: item['done'] == true, onToggle: () {
                final updated = items.map((i) {
                  if (i['id'] == item['id']) return {...i, 'done': !(i['done'] as bool)};
                  return i;
                }).toList();
                ref.read(pinRepositoryProvider).updatePinContent(pinId, jsonEncode({'items': updated}));
              }),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item['text'] as String? ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: item['done'] == true ? EpicordiaColors.textTertiaryLight : EpicordiaColors.textPrimaryLight,
                    decoration: item['done'] == true ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ],
          ),
        )),
        if (items.length > 6)
          Text('+${items.length - 6} more', style: const TextStyle(fontSize: 10, color: EpicordiaColors.textTertiaryLight)),
      ],
    );
  }

  List<Map<String, dynamic>> _parseItems(String? content) {
    if (content == null || content.isEmpty) return [];
    try {
      final map = jsonDecode(content) as Map<String, dynamic>;
      final list = map['items'] as List<dynamic>? ?? [];
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// IMAGE CARD
// ─────────────────────────────────────────────────────────────────────────────
class _ImageCardBody extends StatelessWidget {
  final String? content;
  const _ImageCardBody({this.content});

  @override
  Widget build(BuildContext context) {
    final caption = _parseCaption(content);
    // Note: filePath comes from Attachments table, not content.
    // For now we show a placeholder image icon.
    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF0F0F0),
            ),
            child: const Center(
              child: Icon(Icons.image_outlined, size: 40, color: EpicordiaColors.textTertiaryLight),
            ),
          ),
        ),
        if (caption.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(caption, style: const TextStyle(fontSize: 11, color: EpicordiaColors.textSecondaryLight)),
          ),
      ],
    );
  }

  String _parseCaption(String? content) {
    if (content == null || content.isEmpty) return '';
    try {
      final map = jsonDecode(content) as Map<String, dynamic>;
      return map['caption'] as String? ?? '';
    } catch (_) {
      return '';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LINK CARD
// ─────────────────────────────────────────────────────────────────────────────
class _LinkCardBody extends StatelessWidget {
  final String content;
  const _LinkCardBody({required this.content});

  @override
  Widget build(BuildContext context) {
    final data = _parseLinkData(content);
    final url = data['url'] as String? ?? content;
    final title = data['cachedTitle'] as String? ?? url;
    final description = data['cachedDescription'] as String? ?? '';
    final domain = _extractDomain(url);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.link_rounded, size: 14, color: EpicordiaColors.blue600),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                domain,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: EpicordiaColors.textTertiaryLight, fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.open_in_new, size: 12, color: EpicordiaColors.textTertiaryLight),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: EpicordiaColors.textPrimaryLight),
        ),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: EpicordiaColors.textSecondaryLight),
          ),
        ],
      ],
    );
  }

  Map<String, dynamic> _parseLinkData(String content) {
    try {
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      return {'url': content};
    }
  }

  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.replaceFirst('www.', '');
    } catch (_) {
      return url;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DRAWING / HANDWRITING CARD
// ─────────────────────────────────────────────────────────────────────────────
class _DrawingCardBody extends StatelessWidget {
  final String? content;
  final String type;
  const _DrawingCardBody({this.content, required this.type});

  @override
  Widget build(BuildContext context) {
    final strokes = _parseStrokes(content);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TypeLabel(label: type == 'handwriting' ? 'HANDWRITING' : 'DRAWING', icon: Icons.draw_outlined),
        const SizedBox(height: 6),
        Expanded(
          child: strokes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(type == 'handwriting' ? Icons.edit_note_outlined : Icons.gesture_outlined,
                          size: 28, color: EpicordiaColors.textTertiaryLight),
                      const SizedBox(height: 4),
                      Text(
                        'Double-tap to ${type == 'handwriting' ? 'write' : 'draw'}',
                        style: const TextStyle(fontSize: 10, color: EpicordiaColors.textTertiaryLight),
                      ),
                    ],
                  ),
                )
              : CustomPaint(
                  painter: _StrokePreviewPainter(strokes),
                  size: Size.infinite,
                ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _parseStrokes(String? content) {
    if (content == null || content.isEmpty) return [];
    try {
      final map = jsonDecode(content) as Map<String, dynamic>;
      return (map['strokes'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }
}

class _StrokePreviewPainter extends CustomPainter {
  final List<Map<String, dynamic>> strokes;
  const _StrokePreviewPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      final colorHex = stroke['color'] as String? ?? '#16181C';
      final width = (stroke['widthPx'] as num?)?.toDouble() ?? 2.0;
      final points = (stroke['points'] as List<dynamic>? ?? []);

      final color = _hexToColor(colorHex);
      final paint = Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (points.length < 2) continue;
      final path = Path();
      final first = points.first as List<dynamic>;
      path.moveTo((first[0] as num).toDouble(), (first[1] as num).toDouble());
      for (int i = 1; i < points.length; i++) {
        final pt = points[i] as List<dynamic>;
        path.lineTo((pt[0] as num).toDouble(), (pt[1] as num).toDouble());
      }
      canvas.drawPath(path, paint);
    }
  }

  Color _hexToColor(String hex) {
    final clean = hex.replaceFirst('#', '');
    if (clean.length == 6) return Color(int.parse('FF$clean', radix: 16));
    return const Color(0xFF16181C);
  }

  @override
  bool shouldRepaint(_StrokePreviewPainter old) => old.strokes != strokes;
}

// ─────────────────────────────────────────────────────────────────────────────
// AUDIO CARD
// ─────────────────────────────────────────────────────────────────────────────
class _AudioCardBody extends StatelessWidget {
  final String? content;
  const _AudioCardBody({this.content});

  @override
  Widget build(BuildContext context) {
    final duration = _parseDuration(content);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TypeLabel(label: 'AUDIO', icon: Icons.mic_outlined),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: EpicordiaColors.blue700,
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _WaveformPlaceholder(),
                    const SizedBox(height: 4),
                    Text(
                      _formatDuration(duration),
                      style: const TextStyle(fontSize: 10, color: EpicordiaColors.textTertiaryLight, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  int _parseDuration(String? content) {
    if (content == null) return 0;
    try {
      final map = jsonDecode(content) as Map<String, dynamic>;
      return (map['durationSeconds'] as num?)?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  String _formatDuration(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _WaveformPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Row(
        children: List.generate(20, (i) {
          final height = (math.sin(i * 0.8) * 10 + 12).abs();
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  color: EpicordiaColors.blue600.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COLOR SWATCH CARD
// ─────────────────────────────────────────────────────────────────────────────
class _ColorSwatchBody extends StatelessWidget {
  final String content;
  const _ColorSwatchBody({required this.content});

  @override
  Widget build(BuildContext context) {
    final hex = _parseHex(content);
    final color = _hexToColor(hex);
    final isDark = ThemeData.estimateBrightnessForColor(color) == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.all(8),
      child: Text(
        hex.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textColor.withValues(alpha: 0.8), letterSpacing: 1.2),
      ),
    );
  }

  String _parseHex(String content) {
    try {
      final map = jsonDecode(content) as Map<String, dynamic>;
      return map['hex'] as String? ?? '#FFFFFF';
    } catch (_) {
      return '#FFFFFF';
    }
  }

  Color _hexToColor(String hex) {
    final clean = hex.replaceFirst('#', '');
    if (clean.length == 6) return Color(int.parse('FF$clean', radix: 16));
    return Colors.white;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADING / DIVIDER — no card shell, raw text on canvas
// ─────────────────────────────────────────────────────────────────────────────
class _HeadingCardBody extends StatelessWidget {
  final String content;
  const _HeadingCardBody({required this.content});

  @override
  Widget build(BuildContext context) {
    try {
      final map = jsonDecode(content) as Map<String, dynamic>;
      final style = map['style'] as String? ?? 'heading';
      final text = map['text'] as String? ?? '';

      if (style == 'divider') {
        return const Divider(thickness: 1.5, color: EpicordiaColors.borderStrongLight);
      }
      return Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: EpicordiaColors.textPrimaryLight,
          letterSpacing: -0.3,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    } catch (_) {
      return Text(content, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800));
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TABLE CARD
// ─────────────────────────────────────────────────────────────────────────────
class _TableCardBody extends StatelessWidget {
  final String? content;
  const _TableCardBody({this.content});

  @override
  Widget build(BuildContext context) {
    final data = _parseTable(content);
    final columns = data['columns'] as List<String>? ?? [];
    final rows = data['rows'] as List<List<String>>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TypeLabel(label: 'TABLE', icon: Icons.table_chart_outlined),
        const SizedBox(height: 6),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: columns.map((col) => _TableCell(text: col, isHeader: true)).toList(),
                ),
                // Data rows
                ...rows.take(5).map((row) => Row(
                  children: row.map((cell) => _TableCell(text: cell, isHeader: false)).toList(),
                )),
                if (rows.length > 5)
                  Text('+${rows.length - 5} rows', style: const TextStyle(fontSize: 10, color: EpicordiaColors.textTertiaryLight)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _parseTable(String? content) {
    if (content == null) return {};
    try {
      final map = jsonDecode(content) as Map<String, dynamic>;
      return {
        'columns': (map['columns'] as List<dynamic>? ?? []).cast<String>(),
        'rows': (map['rows'] as List<dynamic>? ?? []).map((r) => (r as List<dynamic>).cast<String>()).toList(),
      };
    } catch (_) {
      return {};
    }
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  final bool isHeader;
  const _TableCell({required this.text, required this.isHeader});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: isHeader ? EpicordiaColors.surfaceCardLight : Colors.transparent,
        border: Border.all(color: EpicordiaColors.borderSubtleLight, width: 0.5),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: isHeader ? FontWeight.w700 : FontWeight.normal,
          color: EpicordiaColors.textPrimaryLight,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FRAME / GROUP CARD
// ─────────────────────────────────────────────────────────────────────────────
class _FrameCardBody extends StatelessWidget {
  final String? content;
  const _FrameCardBody({this.content});

  @override
  Widget build(BuildContext context) {
    final label = _parseLabel(content);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: EpicordiaColors.borderSubtleLight, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty)
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: EpicordiaColors.textSecondaryLight)),
          const Spacer(),
        ],
      ),
    );
  }

  String _parseLabel(String? content) {
    if (content == null) return '';
    try {
      final map = jsonDecode(content) as Map<String, dynamic>;
      return map['label'] as String? ?? '';
    } catch (_) {
      return '';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOARD TILE CARD
// ─────────────────────────────────────────────────────────────────────────────
class _BoardTileBody extends StatelessWidget {
  final String content;
  const _BoardTileBody({required this.content});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: EpicordiaColors.blue700.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.dashboard_outlined, size: 20, color: EpicordiaColors.blue700),
        ),
        const SizedBox(height: 8),
        const Text(
          'Board',
          style: TextStyle(fontSize: 10, color: EpicordiaColors.textTertiaryLight, fontWeight: FontWeight.w600, letterSpacing: 0.8),
        ),
        const SizedBox(height: 2),
        Text(
          content.isEmpty ? 'Unnamed Board' : content,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: EpicordiaColors.textPrimaryLight),
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text('Open', style: TextStyle(fontSize: 10, color: EpicordiaColors.blue600, fontWeight: FontWeight.w600)),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_forward_rounded, size: 12, color: EpicordiaColors.blue600),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FILE / DOCUMENT CARD
// ─────────────────────────────────────────────────────────────────────────────
class _FileCardBody extends StatelessWidget {
  final String? content;
  const _FileCardBody({this.content});

  @override
  Widget build(BuildContext context) {
    final displayName = _parseDisplayName(content);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TypeLabel(label: 'FILE', icon: Icons.attach_file_rounded),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 48,
                decoration: BoxDecoration(
                  color: EpicordiaColors.blue700.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: EpicordiaColors.borderSubtleLight),
                ),
                child: const Icon(Icons.description_outlined, color: EpicordiaColors.blue700, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  displayName.isEmpty ? 'Untitled file' : displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: EpicordiaColors.textPrimaryLight),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _parseDisplayName(String? content) {
    if (content == null) return '';
    try {
      final map = jsonDecode(content) as Map<String, dynamic>;
      return map['displayName'] as String? ?? '';
    } catch (_) {
      return '';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED MICRO-COMPONENTS
// ─────────────────────────────────────────────────────────────────────────────

class _TypeLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  const _TypeLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 10, color: EpicordiaColors.textTertiaryLight),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: EpicordiaColors.textTertiaryLight,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _StatusRing extends StatelessWidget {
  final String status;
  final VoidCallback? onToggle;
  const _StatusRing({required this.status, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    Color ringColor;
    Color? fillColor;
    IconData? icon;

    switch (status) {
      case 'in_progress':
        ringColor = EpicordiaColors.blue600;
        fillColor = null;
        icon = null;
        break;
      case 'done':
        ringColor = EpicordiaColors.successLight;
        fillColor = EpicordiaColors.successLight;
        icon = Icons.check;
        break;
      default:
        ringColor = EpicordiaColors.borderStrongLight;
        fillColor = null;
        icon = null;
    }

    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: fillColor ?? Colors.transparent,
          border: Border.all(
            color: ringColor,
            width: status == 'in_progress' ? 2.5 : 1.5,
          ),
        ),
        child: icon != null ? Icon(icon, size: 12, color: Colors.white) : null,
      ),
    );
  }
}

class _MiniStatusRing extends StatelessWidget {
  final bool isDone;
  const _MiniStatusRing({required this.isDone});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDone ? EpicordiaColors.successLight : Colors.transparent,
        border: Border.all(
          color: isDone ? EpicordiaColors.successLight : EpicordiaColors.borderStrongLight,
          width: 1.5,
        ),
      ),
      child: isDone ? const Icon(Icons.check, size: 8, color: Colors.white) : null,
    );
  }
}

class _PlainCheckbox extends StatelessWidget {
  final bool isDone;
  final VoidCallback onToggle;
  const _PlainCheckbox({required this.isDone, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: isDone ? EpicordiaColors.borderStrongLight : Colors.transparent,
          border: Border.all(color: EpicordiaColors.borderStrongLight, width: 1.5),
          borderRadius: BorderRadius.circular(2),
        ),
        child: isDone ? const Icon(Icons.check, size: 10, color: Colors.white) : null,
      ),
    );
  }
}

class _PillChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const _PillChip({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 9, color: color),
            const SizedBox(width: 2),
          ],
          Text(label, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
