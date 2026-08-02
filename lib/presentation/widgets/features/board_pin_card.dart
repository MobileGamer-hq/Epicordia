import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
      onTap: () => _handlePrimaryTap(context, ref),
      onDoubleTap: () => _handlePrimaryTap(context, ref),
      onLongPress: () => _showCardContextMenu(context, ref),
      child: EpicordiaCard(
        indicatorColor: _colorFromTag(colorTag),
        padding: _paddingForType(type),
        child: _buildBody(context, ref),
      ),
    );
  }

  void _handlePrimaryTap(BuildContext context, WidgetRef ref) {
    if (type == 'board') {
      _handleBoardTap(context, ref);
    } else {
      onEdit?.call(pinId);
    }
  }

  void _showCardContextMenu(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;

    showModalBottomSheet(
      context: context,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: EpicordiaColors.borderSubtleLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: Text('Edit Card', style: TextStyle(color: textPrimary)),
                  onTap: () {
                    Navigator.pop(context);
                    onEdit?.call(pinId);
                  },
                ),
                ListTile(
                  leading: Icon(isPinCollapsed(content) ? Icons.unfold_more_rounded : Icons.unfold_less_rounded),
                  title: Text(isPinCollapsed(content) ? 'Expand Card' : 'Collapse Card', style: TextStyle(color: textPrimary)),
                  onTap: () async {
                    Navigator.pop(context);
                    await togglePinCollapse(ref, pinId, content);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: Text('Change Color Tag', style: TextStyle(color: textPrimary)),
                  onTap: () {
                    Navigator.pop(context);
                    _showColorTagPicker(context, ref);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.copy_rounded),
                  title: Text('Duplicate Pin', style: TextStyle(color: textPrimary)),
                  onTap: () async {
                    Navigator.pop(context);
                    await _duplicatePin(ref);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: EpicordiaColors.errorLight),
                  title: const Text('Remove from Board', style: TextStyle(color: EpicordiaColors.errorLight)),
                  onTap: () async {
                    Navigator.pop(context);
                    await ref.read(pinRepositoryProvider).deletePin(pinId);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _duplicatePin(WidgetRef ref) async {
    final repo = ref.read(pinRepositoryProvider);
    final pin = await repo.getPin(pinId);
    if (pin != null) {
      final newId = DateTime.now().millisecondsSinceEpoch.toString();
      await repo.createPin(
        PinsCompanion.insert(
          id: newId,
          boardId: Value(pin.boardId),
          type: pin.type,
          x: Value(pin.x + 20),
          y: Value(pin.y + 20),
          width: Value(pin.width),
          height: Value(pin.height),
          content: Value(pin.content),
          colorTag: Value(pin.colorTag),
        ),
      );
    }
  }

  void _showColorTagPicker(BuildContext context, WidgetRef ref) {
    const tags = ['yellow', 'coral', 'mint', 'lavender', 'sky', 'grey'];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Color Tag'),
          content: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ...tags.map((tag) {
                final clr = _colorFromTag(tag);
                return GestureDetector(
                  onTap: () async {
                    Navigator.pop(context);
                    final repo = ref.read(pinRepositoryProvider);
                    final pin = await repo.getPin(pinId);
                    if (pin != null) {
                      await repo.updatePin(pin.copyWith(colorTag: Value(tag)));
                    }
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: clr,
                    ),
                  ),
                );
              }),
              GestureDetector(
                onTap: () async {
                  Navigator.pop(context);
                  final repo = ref.read(pinRepositoryProvider);
                  final pin = await repo.getPin(pinId);
                  if (pin != null) {
                    await repo.updatePin(pin.copyWith(colorTag: const Value(null)));
                  }
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: EpicordiaColors.borderStrongLight),
                  ),
                  child: const Icon(Icons.clear, size: 18),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleBoardTap(BuildContext context, WidgetRef ref) {
    if (content != null && content!.isNotEmpty && !content!.startsWith('{')) {
      context.push('/board/$content');
    } else {
      onEdit?.call(pinId);
    }
  }

  EdgeInsets _paddingForType(String t) {
    switch (t) {
      case 'image':
      case 'link':
      case 'colorSwatch':
        return EdgeInsets.zero;
      case 'heading':
        return const EdgeInsets.symmetric(horizontal: 4, vertical: 4);
      case 'audio':
      case 'file':
        return const EdgeInsets.all(12);
      default:
        return const EdgeInsets.all(14);
    }
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    switch (type) {
      case 'note':
        return _NoteCardBody(pinId: pinId, content: content ?? '');
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
        return _FrameCardBody(content: content, pinId: pinId);
      case 'board':
        return _BoardTileBody(content: content ?? '');
      case 'file':
        return _FileCardBody(content: content);
      default:
        return _NoteCardBody(pinId: pinId, content: content ?? '');
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

bool isPinCollapsed(String? content) {
  if (content == null || content.isEmpty) return false;
  if (content.startsWith('{') && content.endsWith('}')) {
    try {
      final map = jsonDecode(content) as Map<String, dynamic>;
      return map['collapsed'] as bool? ?? false;
    } catch (_) {}
  }
  return false;
}

Future<void> togglePinCollapse(WidgetRef ref, String pinId, String? currentContent) async {
  final pinRepo = ref.read(pinRepositoryProvider);
  final pin = await pinRepo.getPin(pinId);
  if (pin == null) return;

  Map<String, dynamic> data = {};
  if (currentContent != null && currentContent.startsWith('{') && currentContent.endsWith('}')) {
    try {
      data = Map<String, dynamic>.from(jsonDecode(currentContent) as Map<String, dynamic>);
    } catch (_) {
      data = {'text': currentContent};
    }
  } else if (currentContent != null && currentContent.isNotEmpty) {
    data = {'text': currentContent};
  }

  final isCurrentlyCollapsed = data['collapsed'] as bool? ?? false;
  data['collapsed'] = !isCurrentlyCollapsed;

  final updated = pin.copyWith(
    content: Value(jsonEncode(data)),
    modifiedAt: DateTime.now(),
  );
  await pinRepo.updatePin(updated);
}

// ─────────────────────────────────────────────────────────────────────────────
// NOTE CARD
// ─────────────────────────────────────────────────────────────────────────────
class _NoteCardBody extends ConsumerWidget {
  final String pinId;
  final String content;
  const _NoteCardBody({required this.pinId, required this.content});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final iconColor = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;

    final collapsed = isPinCollapsed(content);
    final parsed = _parseContent(content);
    final title = parsed['title'] as String;
    final body = parsed['body'] as String;
    final displayTitle = title.isNotEmpty ? title : (body.isNotEmpty ? body.split('\n').first : 'Untitled Note');

    if (collapsed) {
      return Row(
        children: [
          _TypeLabel(label: 'NOTE', icon: Icons.sticky_note_2_outlined),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              displayTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => togglePinCollapse(ref, pinId, content),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Icon(Icons.unfold_more_rounded, size: 18, color: iconColor),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _TypeLabel(label: 'NOTE', icon: Icons.sticky_note_2_outlined),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => togglePinCollapse(ref, pinId, content),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(Icons.unfold_less_rounded, size: 18, color: iconColor),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.drag_indicator, size: 14, color: iconColor.withValues(alpha: 0.5)),
              ],
            ),
          ],
        ),
        if (title.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: textPrimary,
              letterSpacing: -0.2,
            ),
          ),
        ],
        const SizedBox(height: 6),
        Expanded(
          child: ClipRect(
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black, Colors.transparent],
                stops: [0.75, 1.0],
              ).createShader(bounds),
              blendMode: BlendMode.dstIn,
              child: MarkdownBody(
                data: body.isEmpty ? '_Empty note — tap to edit_' : body,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(fontSize: 12, color: textSecondary, height: 1.45),
                  h1: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                  h2: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
                  listBullet: TextStyle(fontSize: 12, color: textSecondary),
                  blockquote: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: textSecondary),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Map<String, String> _parseContent(String text) {
    if (text.trim().isEmpty) return {'title': '', 'body': ''};
    String rawText = text;
    if (text.startsWith('{') && text.endsWith('}')) {
      try {
        final map = jsonDecode(text) as Map<String, dynamic>;
        if (map.containsKey('text')) {
          rawText = map['text'] as String? ?? '';
        } else if (map.containsKey('body')) {
          return {'title': map['title'] as String? ?? '', 'body': map['body'] as String? ?? ''};
        }
      } catch (_) {}
    }
    final lines = rawText.trim().split('\n');
    if (lines.first.startsWith('#')) {
      final title = lines.first.replaceAll(RegExp(r'^#+\s*'), '');
      final body = lines.skip(1).join('\n').trim();
      return {'title': title, 'body': body};
    }
    return {'title': '', 'body': text};
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
    final taskStream = ref.watch(taskForPinProvider(pinId));

    return taskStream.when(
      loading: () => const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
      error: (_, _) => _FallbackTaskBody(content: content),
      data: (task) {
        if (task == null) return _FallbackTaskBody(content: content);
        return _TaskBodyWithData(pinId: pinId, content: content, task: task, ref: ref);
      },
    );
  }
}

class _FallbackTaskBody extends StatelessWidget {
  final String content;
  const _FallbackTaskBody({required this.content});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;

    final title = content.trim().split('\n').first.isEmpty ? 'Untitled Task' : content.trim().split('\n').first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TypeLabel(label: 'TASK', icon: Icons.check_circle_outline_rounded),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _StatusRing(status: 'todo', onToggle: null),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Assigned to: Self',
                    style: TextStyle(fontSize: 10, color: textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TaskBodyWithData extends StatelessWidget {
  final String pinId;
  final String content;
  final TaskEntity task;
  final WidgetRef ref;
  const _TaskBodyWithData({required this.pinId, required this.content, required this.task, required this.ref});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final isOverdue = task.status != 'done' && task.dueDate != null && task.dueDate!.isBefore(DateTime.now());
    final isCompleted = task.status == 'done';
    final collapsed = isPinCollapsed(content);

    if (collapsed) {
      return Row(
        children: [
          _StatusRing(
            status: task.status,
            onToggle: () {
              final next = _nextStatus(task.status);
              ref.read(taskRepositoryProvider).updateTask(task.copyWith(status: next));
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              task.title.isEmpty ? 'Untitled task' : task.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isCompleted ? textSecondary : textPrimary,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
                decorationColor: textSecondary,
              ),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => togglePinCollapse(ref, pinId, content),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Icon(Icons.unfold_more_rounded, size: 18, color: textSecondary),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _TypeLabel(label: 'TASK', icon: Icons.check_circle_outline_rounded),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => togglePinCollapse(ref, pinId, content),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(Icons.unfold_less_rounded, size: 18, color: textSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title.isEmpty ? 'Untitled task' : task.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isCompleted ? textSecondary : textPrimary,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                      decorationColor: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Assigned to: Self',
                    style: TextStyle(fontSize: 10, color: textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Spacer(),
        Row(
          children: [
            if (task.priority > 0) ...[
              _PillChip(
                label: task.priority == 2 ? 'HIGH PRIORITY' : 'MED PRIORITY',
                color: task.priority == 2 ? const Color(0xFFE02424) : const Color(0xFFB5730A),
                backgroundColor: task.priority == 2 ? const Color(0xFFFDE8E8) : const Color(0xFFFEF3C7),
              ),
              const SizedBox(width: 6),
            ],
            if (task.dueDate != null)
              _PillChip(
                label: _formatDate(task.dueDate!),
                color: isOverdue ? const Color(0xFFE02424) : textSecondary,
                backgroundColor: isOverdue ? const Color(0xFFFDE8E8) : (isDark ? const Color(0xFF2B2E34) : const Color(0xFFF3F4F6)),
                icon: Icons.calendar_today_rounded,
              ),
          ],
        ),
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
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final borderSubtle = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;

    final tasksStream = ref.watch(tasksForGroupPinProvider(pinId));
    final title = _parseTitle(content);
    final collapsed = isPinCollapsed(content);

    if (collapsed) {
      return Row(
        children: [
          _TypeLabel(label: 'TASKLIST', icon: Icons.checklist_rounded),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title.isEmpty ? 'Development Milestones' : title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => togglePinCollapse(ref, pinId, content),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Icon(Icons.unfold_more_rounded, size: 18, color: textSecondary),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title.isEmpty ? 'Development Milestones' : title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                tasksStream.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (tasks) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2B2E34) : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${tasks.length} items',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: textSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => togglePinCollapse(ref, pinId, content),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(Icons.unfold_less_rounded, size: 18, color: textSecondary),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: tasksStream.when(
            loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            error: (_, _) => const SizedBox.shrink(),
            data: (tasks) {
              if (tasks.isEmpty) {
                return Center(
                  child: Text('No milestones yet', style: TextStyle(fontSize: 11, color: textSecondary)),
                );
              }
              return ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tasks.length > 4 ? 4 : tasks.length,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  final isDone = task.status == 'done';
                  return Row(
                    children: [
                      _MiniStatusRing(
                        isDone: isDone,
                        onToggle: () {
                          final next = isDone ? 'todo' : 'done';
                          ref.read(taskRepositoryProvider).updateTask(task.copyWith(status: next));
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          task.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDone ? textSecondary : textPrimary,
                            decoration: isDone ? TextDecoration.lineThrough : null,
                            decorationColor: textSecondary,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: borderSubtle, style: BorderStyle.solid),
          ),
          child: Text(
            '+ Add Item',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textSecondary),
          ),
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
// CHECKLIST CARD (lightweight, interactive)
// ─────────────────────────────────────────────────────────────────────────────
class _ChecklistCardBody extends ConsumerWidget {
  final String pinId;
  final String? content;
  const _ChecklistCardBody({required this.pinId, this.content});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;

    final items = _parseItems(content);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TypeLabel(label: 'SHOPPING LIST', icon: Icons.shopping_cart_outlined),
        const SizedBox(height: 6),
        Divider(height: 1, color: isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight),
        const SizedBox(height: 6),
        Expanded(
          child: items.isEmpty
              ? Center(child: Text('Empty list — tap to edit', style: TextStyle(fontSize: 11, color: textSecondary)))
              : ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length > 5 ? 5 : items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isDone = item['done'] == true;
                    return Row(
                      children: [
                        _PlainCheckbox(
                          isDone: isDone,
                          onToggle: () {
                            final updated = items.map((i) {
                              if (i['id'] == item['id']) return {...i, 'done': !isDone};
                              return i;
                            }).toList();
                            ref.read(pinRepositoryProvider).updatePinContent(pinId, jsonEncode({'items': updated}));
                          },
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item['text'] as String? ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDone ? textSecondary : textPrimary,
                              decoration: isDone ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final placeholderBg = isDark ? EpicordiaColors.surfaceSunkenDark : const Color(0xFFF4F5F7);
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final iconColor = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;

    final data = _parseData(content);
    final filePath = data['filePath'] as String? ?? '';
    final caption = data['caption'] as String? ?? '';
    final hasFile = filePath.isNotEmpty && File(filePath).existsSync();

    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: placeholderBg,
            ),
            child: hasFile
                ? ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    child: Image.file(
                      File(filePath),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Center(
                        child: Icon(Icons.broken_image_outlined, size: 36, color: iconColor),
                      ),
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_a_photo_outlined, size: 32, color: EpicordiaColors.blue600),
                        const SizedBox(height: 6),
                        Text(
                          'Double-tap to add image',
                          style: TextStyle(fontSize: 11, color: textSecondary, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  caption.isEmpty ? 'Team Offsite Heatmap' : caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
              Icon(Icons.more_vert_rounded, size: 16, color: iconColor),
            ],
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _parseData(String? content) {
    if (content == null || content.isEmpty) return {};
    try {
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      return {};
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;

    final data = _parseLinkData(content);
    final url = data['url'] as String? ?? content;
    final title = data['cachedTitle'] as String? ?? (url.isNotEmpty ? url : 'Web Bookmark');
    final description = data['cachedDescription'] as String? ?? 'Tap to edit URL or view link details.';
    final domain = _extractDomain(url);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Upper Web Preview Header Container
        Expanded(
          flex: 3,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E222A) : const Color(0xFFEDF1F7),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Center(
              child: Icon(Icons.language_rounded, size: 36, color: EpicordiaColors.blue600.withValues(alpha: 0.6)),
            ),
          ),
        ),
        // Bottom Metadata Container
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.public, size: 12, color: textTertiary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        domain.isEmpty ? 'LINK' : domain.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: textTertiary,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary, height: 1.2),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: textSecondary, height: 1.2),
                  ),
                ),
              ],
            ),
          ),
        ),
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
      final host = uri.host.replaceFirst('www.', '');
      return host.isEmpty ? 'catchme.live' : host;
    } catch (_) {
      return 'catchme.live';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;
    final strokes = _parseStrokes(content);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _TypeLabel(label: type == 'handwriting' ? 'HANDWRITING' : 'SKETCH', icon: Icons.draw_outlined),
            Icon(Icons.edit_outlined, size: 14, color: textTertiary),
          ],
        ),
        const SizedBox(height: 6),
        Expanded(
          child: strokes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(type == 'handwriting' ? Icons.edit_note_outlined : Icons.gesture_outlined,
                          size: 28, color: textTertiary),
                      const SizedBox(height: 4),
                      Text(
                        'Double-tap to ${type == 'handwriting' ? 'write' : 'draw'}',
                        style: TextStyle(fontSize: 10, color: textTertiary),
                      ),
                    ],
                  ),
                )
              : CustomPaint(
                  painter: _StrokePreviewPainter(strokes, isDark: isDark),
                  size: Size.infinite,
                ),
        ),
        const SizedBox(height: 4),
        Text(
          'SKETCH: FLOW DIAGRAM',
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: textTertiary, letterSpacing: 0.8),
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
  final bool isDark;
  const _StrokePreviewPainter(this.strokes, {required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      final colorHex = stroke['color'] as String? ?? '#16181C';
      final width = (stroke['widthPx'] as num?)?.toDouble() ?? 2.0;
      final points = (stroke['points'] as List<dynamic>? ?? []);

      final color = _hexToColor(colorHex, isDark);
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

  Color _hexToColor(String hex, bool isDark) {
    final clean = hex.replaceFirst('#', '').toUpperCase();
    if (clean == '16181C' && isDark) {
      return const Color(0xFFE2E8F0);
    }
    if (clean.length == 6) return Color(int.parse('FF$clean', radix: 16));
    return isDark ? const Color(0xFFE2E8F0) : const Color(0xFF16181C);
  }

  @override
  bool shouldRepaint(_StrokePreviewPainter old) => old.strokes != strokes || old.isDark != isDark;
}

// ─────────────────────────────────────────────────────────────────────────────
// AUDIO CARD
// ─────────────────────────────────────────────────────────────────────────────
class _AudioCardBody extends StatelessWidget {
  final String? content;
  const _AudioCardBody({this.content});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final duration = _parseDuration(content);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF0137C3),
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _WaveformPlaceholder(),
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'VOICE MEMO - FEEDBACK',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              _formatDuration(duration),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ],
    );
  }

  int _parseDuration(String? content) {
    if (content == null) return 42; // default matching mockup spec
    try {
      final map = jsonDecode(content) as Map<String, dynamic>;
      return (map['durationSeconds'] as num?)?.toInt() ?? 42;
    } catch (_) {
      return 42;
    }
  }

  String _formatDuration(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _WaveformPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Row(
        children: List.generate(24, (i) {
          final height = (math.sin(i * 0.7) * 9 + 12).abs();
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0.8),
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  color: const Color(0xFF0137C3).withValues(alpha: 0.85),
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
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDarkTheme ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textTertiary = isDarkTheme ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;

    final (hex, label) = _parseSwatch(content);
    final color = _hexToColor(hex);
    final isLightColor = color.computeLuminance() > 0.5;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          // Upper Large Rectangular Solid Color Fill Block
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: color,
                border: isLightColor
                    ? Border(bottom: BorderSide(color: Colors.black.withValues(alpha: 0.08)))
                    : null,
              ),
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isLightColor ? Colors.black : Colors.white).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  hex.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isLightColor ? Colors.black87 : Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),
          // Lower Metadata Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDarkTheme ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight,
            ),
            child: Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    border: Border.all(
                      color: isDarkTheme ? Colors.white24 : Colors.black12,
                      width: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'COLOR SWATCH',
                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: textTertiary, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        label.isNotEmpty ? label : hex.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textPrimary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDarkTheme ? const Color(0xFF2B2E34) : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    hex.toUpperCase(),
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: textPrimary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (String, String) _parseSwatch(String content) {
    if (content.trim().startsWith('#')) {
      return (content.trim(), '');
    }
    try {
      final map = jsonDecode(content) as Map<String, dynamic>;
      final hex = map['hex'] as String? ?? map['color'] as String? ?? '#3D68EE';
      final label = map['label'] as String? ?? '';
      return (hex, label);
    } catch (_) {
      return (content.trim().isNotEmpty ? content.trim() : '#3D68EE', '');
    }
  }

  Color _hexToColor(String hex) {
    final clean = hex.replaceFirst('#', '');
    if (clean.length == 6) return Color(int.parse('FF$clean', radix: 16));
    return const Color(0xFF3D68EE);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADING / SECTION HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _HeadingCardBody extends StatelessWidget {
  final String content;
  const _HeadingCardBody({required this.content});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final borderClr = isDark ? EpicordiaColors.borderStrongDark : EpicordiaColors.borderStrongLight;

    String text = 'Phase 1: Research';
    String subtitle = 'Initial discovery and competitor analysis.';

    try {
      final map = jsonDecode(content) as Map<String, dynamic>;
      if (map.containsKey('text')) text = map['text'] as String;
      if (map.containsKey('subtitle')) subtitle = map['subtitle'] as String;
    } catch (_) {
      if (content.isNotEmpty) text = content;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 1.5,
          width: double.infinity,
          color: borderClr,
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontStyle: FontStyle.italic,
            color: textSecondary,
          ),
        ),
      ],
    );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final data = _parseTable(content);
    final columns = data['columns'] as List<String>? ?? ['ASSET NAME', 'FORMAT', 'OWNER'];
    final rows = data['rows'] as List<List<String>>? ?? [
      ['Hero_Banner_Draft', 'PNG', 'Sarah K.'],
      ['App_Icon_v3', 'SVG', 'Alex M.'],
    ];

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
                Row(
                  children: columns.map((col) => _TableCell(text: col, isHeader: true, isDark: isDark)).toList(),
                ),
                ...rows.map((row) => Row(
                  children: row.map((cell) => _TableCell(text: cell, isHeader: false, isDark: isDark)).toList(),
                )),
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
  final bool isDark;
  const _TableCell({required this.text, required this.isHeader, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;
    final borderClr = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;

    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isHeader ? (isDark ? const Color(0xFF22262E) : const Color(0xFFF3F4F6)) : Colors.transparent,
        border: Border.all(color: borderClr, width: 0.5),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500,
          color: isHeader ? textTertiary : textPrimary,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FRAME / GROUP CARD
// ─────────────────────────────────────────────────────────────────────────────
class _FrameCardBody extends ConsumerWidget {
  final String? content;
  final String pinId;
  const _FrameCardBody({this.content, required this.pinId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final data = _parseData(content);
    final label = data['label'] as String? ?? '';
    final isCollapsed = data['collapsed'] as bool? ?? false;
    final titleText = label.isNotEmpty ? label : 'Weekly Sprint';

    final primaryColor = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue700;
    final borderColor = isDark
        ? EpicordiaColors.blue500.withValues(alpha: 0.4)
        : EpicordiaColors.blue400.withValues(alpha: 0.4);
    final headerBg = isDark
        ? EpicordiaColors.surfaceCardDark.withValues(alpha: 0.9)
        : EpicordiaColors.surfaceCardLight.withValues(alpha: 0.95);
    final fillBg = isDark
        ? EpicordiaColors.surfaceAppDark.withValues(alpha: 0.5)
        : EpicordiaColors.blue50.withValues(alpha: 0.25);
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final cardBg = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
    final borderSubtle = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;

    final childPinsStream = ref.watch(pinRepositoryProvider).watchPinsForFrame(pinId);

    return StreamBuilder<List<PinEntity>>(
      stream: childPinsStream,
      builder: (context, snapshot) {
        final children = snapshot.data ?? const <PinEntity>[];

        return DragTarget<PinEntity>(
          onAcceptWithDetails: (details) async {
            final pin = details.data;
            if (pin.id != pinId && pin.parentFrameId != pinId) {
              final pinRepo = ref.read(pinRepositoryProvider);
              final updated = pin.copyWith(
                parentFrameId: Value(pinId),
                modifiedAt: DateTime.now(),
              );
              await pinRepo.updatePin(updated);
            }
          },
          builder: (context, candidateData, rejectedData) {
            final isTargeted = candidateData.isNotEmpty;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isTargeted ? primaryColor.withValues(alpha: 0.12) : fillBg,
                border: Border.all(
                  color: isTargeted ? primaryColor : borderColor,
                  width: isTargeted ? 2.5 : 1.5,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Column Header Bar ─────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: headerBg,
                      borderRadius: BorderRadius.vertical(
                        top: const Radius.circular(14),
                        bottom: isCollapsed ? const Radius.circular(14) : Radius.zero,
                      ),
                      border: isCollapsed
                          ? null
                          : Border(bottom: BorderSide(color: borderColor.withValues(alpha: 0.3), width: 1)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.view_column_outlined,
                          size: 18,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            titleText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${children.length} ITEMS',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => _toggleCollapse(ref, data),
                          child: Icon(
                            isCollapsed ? Icons.unfold_more_rounded : Icons.remove_rounded,
                            size: 18,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Stacked Child Cards List ───────────────────────────
                  if (!isCollapsed)
                    Expanded(
                      child: children.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  'Drag cards here to stack',
                                  style: TextStyle(fontSize: 11, color: textSecondary),
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: children.length,
                              itemBuilder: (context, index) {
                                final childPin = children[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Draggable<PinEntity>(
                                    data: childPin,
                                    feedback: Material(
                                      elevation: 8,
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        width: 200,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: cardBg,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: primaryColor, width: 1.5),
                                        ),
                                        child: Text(
                                          _childPreview(childPin),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight,
                                          ),
                                        ),
                                      ),
                                    ),
                                    childWhenDragging: Opacity(
                                      opacity: 0.3,
                                      child: _ColumnItemTile(
                                        pin: childPin,
                                        isDark: isDark,
                                        cardBg: cardBg,
                                        borderSubtle: borderSubtle,
                                        textSecondary: textSecondary,
                                        onDetach: () => _detachChild(ref, childPin),
                                      ),
                                    ),
                                    child: _ColumnItemTile(
                                      pin: childPin,
                                      isDark: isDark,
                                      cardBg: cardBg,
                                      borderSubtle: borderSubtle,
                                      textSecondary: textSecondary,
                                      onDetach: () => _detachChild(ref, childPin),
                                    ),
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
      },
    );
  }

  static String _childPreview(PinEntity pin) {
    final typeName = pin.type.toUpperCase();
    if (pin.content == null || pin.content!.isEmpty) {
      return '$typeName Card';
    }

    final raw = pin.content!.trim();

    if (pin.type == 'colorSwatch') {
      if (raw.startsWith('#')) return 'Color: $raw';
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final hex = map['hex'] as String? ?? map['color'] as String? ?? '#3D68EE';
        final label = map['label'] as String? ?? '';
        return label.isNotEmpty ? 'Color: $label ($hex)' : 'Color: $hex';
      } catch (_) {
        return 'Color: $raw';
      }
    }

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;

      if (pin.type == 'checklist' || map.containsKey('items')) {
        final items = map['items'] as List<dynamic>? ?? [];
        if (items.isNotEmpty) {
          final first = items.first;
          if (first is Map && first.containsKey('text')) {
            return 'Checklist: ${first['text']} (${items.length} items)';
          }
        }
        return 'Checklist (${items.length} items)';
      }

      if (pin.type == 'link' || map.containsKey('url')) {
        final title = map['cachedTitle'] as String? ?? map['title'] as String? ?? map['url'] as String? ?? 'Web Link';
        return 'Link: $title';
      }

      if (pin.type == 'drawing' || pin.type == 'handwriting' || map.containsKey('strokes')) {
        final strokes = map['strokes'] as List<dynamic>? ?? [];
        return 'Sketch (${strokes.length} strokes)';
      }

      if (pin.type == 'image' || map.containsKey('filePath')) {
        final caption = map['caption'] as String? ?? '';
        if (caption.isNotEmpty) return 'Image: $caption';
        final path = map['filePath'] as String? ?? '';
        if (path.isNotEmpty) {
          final filename = path.split(RegExp(r'[/\\]')).last;
          return 'Image: $filename';
        }
        return 'Image Card';
      }

      if (pin.type == 'file' || map.containsKey('displayName')) {
        final name = map['displayName'] as String? ?? map['fileName'] as String? ?? 'Document';
        return 'File: $name';
      }

      if (pin.type == 'audio' || map.containsKey('durationSeconds')) {
        final title = map['title'] as String? ?? 'Voice Memo';
        final secs = (map['durationSeconds'] as num?)?.toInt() ?? 42;
        final m = secs ~/ 60;
        final s = secs % 60;
        return '$title ($m:${s.toString().padLeft(2, '0')})';
      }

      if (map.containsKey('title') && (map['title'] as String).isNotEmpty) return map['title'] as String;
      if (map.containsKey('text') && (map['text'] as String).isNotEmpty) return map['text'] as String;
      if (map.containsKey('label') && (map['label'] as String).isNotEmpty) return map['label'] as String;
    } catch (_) {}

    final firstLine = raw.split('\n').first.replaceAll(RegExp(r'^#+\s*'), '').trim();
    if (firstLine.isNotEmpty) {
      return firstLine;
    }
    return '$typeName Card';
  }

  Future<void> _detachChild(WidgetRef ref, PinEntity childPin) async {
    final pinRepo = ref.read(pinRepositoryProvider);
    final updated = childPin.copyWith(
      parentFrameId: const Value(null),
      x: childPin.x + 240,
      y: childPin.y,
      modifiedAt: DateTime.now(),
    );
    await pinRepo.updatePin(updated);
  }

  Map<String, dynamic> _parseData(String? content) {
    if (content == null || content.isEmpty) return {};
    try {
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      return {'label': content};
    }
  }

  Future<void> _toggleCollapse(WidgetRef ref, Map<String, dynamic> currentData) async {
    final pinRepo = ref.read(pinRepositoryProvider);
    final pin = await pinRepo.getPin(pinId);
    if (pin != null) {
      final isCurrentlyCollapsed = currentData['collapsed'] as bool? ?? false;
      final newData = Map<String, dynamic>.from(currentData);
      newData['collapsed'] = !isCurrentlyCollapsed;
      final updated = pin.copyWith(
        content: Value(jsonEncode(newData)),
        modifiedAt: DateTime.now(),
      );
      await pinRepo.updatePin(updated);
    }
  }
}

class _ColumnItemTile extends StatelessWidget {
  final PinEntity pin;
  final bool isDark;
  final Color cardBg;
  final Color borderSubtle;
  final Color textSecondary;
  final VoidCallback onDetach;

  const _ColumnItemTile({
    required this.pin,
    required this.isDark,
    required this.cardBg,
    required this.borderSubtle,
    required this.textSecondary,
    required this.onDetach,
  });

  @override
  Widget build(BuildContext context) {
    final preview = _FrameCardBody._childPreview(pin);
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderSubtle),
      ),
      child: Row(
        children: [
          Icon(_iconForType(pin.type), size: 16, color: EpicordiaColors.blue600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              preview,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.output_rounded, size: 16),
            tooltip: 'Detach to canvas',
            color: textSecondary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onDetach,
          ),
        ],
      ),
    );
  }

  static IconData _iconForType(String type) {
    return switch (type) {
      'note' => Icons.sticky_note_2_outlined,
      'task' => Icons.check_circle_outline,
      'checklist' => Icons.checklist_rounded,
      'image' => Icons.image_outlined,
      'link' => Icons.link,
      'drawing' => Icons.draw_outlined,
      'audio' => Icons.mic_none_outlined,
      'heading' => Icons.title,
      'board' => Icons.dashboard_outlined,
      _ => Icons.push_pin_outlined,
    };
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final borderSubtle = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Upper Rounded Thumbnail Placeholder
        Expanded(
          flex: 5,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF22262E) : const Color(0xFFEEF1F6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderSubtle),
            ),
            child: Center(
              child: Icon(
                Icons.grid_view_rounded,
                size: 32,
                color: isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Footer Title and Action Arrow Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                content.isEmpty ? 'Marketing Strategy' : content,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_rounded, size: 16, color: textSecondary),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;

    final displayName = _parseDisplayName(content);
    final title = displayName.isEmpty ? 'Project_Brief_v2.pdf' : displayName;
    final isPdf = title.toLowerCase().endsWith('.pdf');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // File Icon Container Box
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isPdf ? const Color(0xFFFDE8E8) : (isDark ? const Color(0xFF2B2E34) : const Color(0xFFF3F4F6)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isPdf ? Icons.picture_as_pdf_rounded : Icons.insert_drive_file_rounded,
            color: isPdf ? const Color(0xFFE02424) : EpicordiaColors.blue600,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        // File Title and Metadata
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                '2.4 MB • ${isPdf ? 'PDF' : 'DOC'}',
                style: TextStyle(fontSize: 10, color: textSecondary, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        Icon(Icons.download_rounded, size: 20, color: textTertiary),
      ],
    );
  }

  String _parseDisplayName(String? content) {
    if (content == null || content.trim().isEmpty) return '';
    try {
      final map = jsonDecode(content) as Map<String, dynamic>;
      final displayName = map['displayName'] as String? ?? map['fileName'] as String? ?? map['title'] as String? ?? '';
      if (displayName.isNotEmpty) return displayName;
      final filePath = map['filePath'] as String? ?? map['path'] as String? ?? '';
      if (filePath.isNotEmpty) {
        return filePath.split(RegExp(r'[/\\]')).last;
      }
      return '';
    } catch (_) {
      return content.trim().split('\n').first;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: textTertiary),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: textTertiary,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
        ringColor = EpicordiaColors.blue600;
        fillColor = EpicordiaColors.blue600;
        icon = Icons.check;
        break;
      default:
        ringColor = isDark ? EpicordiaColors.borderStrongDark : EpicordiaColors.borderStrongLight;
        fillColor = null;
        icon = null;
    }

    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: fillColor ?? Colors.transparent,
          border: Border.all(
            color: ringColor,
            width: status == 'in_progress' ? 2.5 : 1.8,
          ),
        ),
        child: icon != null ? Icon(icon, size: 14, color: Colors.white) : null,
      ),
    );
  }
}

class _MiniStatusRing extends StatelessWidget {
  final bool isDone;
  final VoidCallback? onToggle;
  const _MiniStatusRing({required this.isDone, this.onToggle});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDone ? EpicordiaColors.blue600 : Colors.transparent,
          border: Border.all(
            color: isDone ? EpicordiaColors.blue600 : (isDark ? EpicordiaColors.borderStrongDark : EpicordiaColors.borderStrongLight),
            width: 1.8,
          ),
        ),
        child: isDone ? const Icon(Icons.check, size: 10, color: Colors.white) : null,
      ),
    );
  }
}

class _PlainCheckbox extends StatelessWidget {
  final bool isDone;
  final VoidCallback onToggle;
  const _PlainCheckbox({required this.isDone, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: isDone ? EpicordiaColors.blue600 : Colors.transparent,
          border: Border.all(
            color: isDone ? EpicordiaColors.blue600 : (isDark ? EpicordiaColors.borderStrongDark : EpicordiaColors.borderStrongLight),
            width: 1.8,
          ),
          borderRadius: BorderRadius.circular(3),
        ),
        child: isDone ? const Icon(Icons.check, size: 11, color: Colors.white) : null,
      ),
    );
  }
}

class _PillChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color? backgroundColor;
  final IconData? icon;

  const _PillChip({
    required this.label,
    required this.color,
    this.backgroundColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor ?? color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

