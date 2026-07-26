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
      onLongPress: () => _showCardContextMenu(context, ref),
      child: EpicordiaCard(
        indicatorColor: _colorFromTag(colorTag),
        padding: _paddingForType(type),
        child: _buildBody(context, ref),
      ),
    );
  }

  void _handlePrimaryTap(BuildContext context, WidgetRef ref) {
    switch (type) {
      case 'note':
      case 'drawing':
      case 'handwriting':
      case 'task':
      case 'tasklist':
      case 'checklist':
      case 'table':
        onEdit?.call(pinId);
        break;
      case 'heading':
        _showHeadingEditDialog(context, ref);
        break;
      case 'image':
        _showImageLightbox(context, ref);
        break;
      case 'link':
        _showLinkEditPopover(context, ref);
        break;
      case 'file':
        _showFileEditPopover(context, ref);
        break;
      case 'audio':
        _showAudioPlayOrRenamePopover(context, ref);
        break;
      case 'colorSwatch':
        _showColorPickerPopover(context, ref);
        break;
      case 'board':
        _handleBoardTap(context, ref);
        break;
      default:
        onEdit?.call(pinId);
        break;
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

  void _showImageLightbox(BuildContext context, WidgetRef ref) {
    Map<String, dynamic> data = {};
    try {
      if (content != null && content!.isNotEmpty) {
        data = jsonDecode(content!) as Map<String, dynamic>;
      }
    } catch (_) {}

    final filePath = data['filePath'] as String? ?? '';
    final captionController = TextEditingController(text: data['caption'] as String? ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Material(
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  constraints: const BoxConstraints(maxHeight: 400),
                  width: double.infinity,
                  color: Colors.black,
                  child: filePath.isNotEmpty && File(filePath).existsSync()
                      ? Image.file(File(filePath), fit: BoxFit.contain)
                      : const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: Icon(Icons.image_outlined, size: 64, color: Colors.white54),
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: captionController,
                          decoration: const InputDecoration(
                            hintText: 'Add or edit caption...',
                            isDense: true,
                          ),
                          onSubmitted: (val) async {
                            final updatedData = {...data, 'caption': val};
                            await ref.read(pinRepositoryProvider).updatePinContent(pinId, jsonEncode(updatedData));
                            if (context.mounted) Navigator.pop(context);
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check),
                        onPressed: () async {
                          final updatedData = {...data, 'caption': captionController.text};
                          await ref.read(pinRepositoryProvider).updatePinContent(pinId, jsonEncode(updatedData));
                          if (context.mounted) Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLinkEditPopover(BuildContext context, WidgetRef ref) {
    Map<String, dynamic> data = {};
    try {
      if (content != null && content!.isNotEmpty) {
        data = jsonDecode(content!) as Map<String, dynamic>;
      }
    } catch (_) {}

    final urlController = TextEditingController(text: data['url'] as String? ?? content ?? '');
    final titleController = TextEditingController(text: data['cachedTitle'] as String? ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Link'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: urlController,
                decoration: const InputDecoration(labelText: 'URL', hintText: 'https://example.com'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title / Label'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final updatedData = {
                  ...data,
                  'url': urlController.text,
                  'cachedTitle': titleController.text,
                };
                await ref.read(pinRepositoryProvider).updatePinContent(pinId, jsonEncode(updatedData));
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showFileEditPopover(BuildContext context, WidgetRef ref) {
    Map<String, dynamic> data = {};
    try {
      if (content != null && content!.isNotEmpty) {
        data = jsonDecode(content!) as Map<String, dynamic>;
      }
    } catch (_) {}

    final nameController = TextEditingController(text: data['displayName'] as String? ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename File'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Display Name'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final updatedData = {...data, 'displayName': nameController.text};
                await ref.read(pinRepositoryProvider).updatePinContent(pinId, jsonEncode(updatedData));
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showAudioPlayOrRenamePopover(BuildContext context, WidgetRef ref) {
    onEdit?.call(pinId);
  }

  void _showColorPickerPopover(BuildContext context, WidgetRef ref) {
    const swatches = ['#F4C453', '#F0806B', '#5FC7A3', '#9C8CF0', '#5FA8F5', '#B9BCC2', '#E5A030', '#E53935', '#009688', '#3F51B5'];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Color Swatch'),
          content: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: swatches.map((hex) {
              final color = Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
              return GestureDetector(
                onTap: () async {
                  await ref.read(pinRepositoryProvider).updatePinContent(pinId, jsonEncode({'hex': hex}));
                  if (context.mounted) Navigator.pop(context);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: EpicordiaColors.borderSubtleLight),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showHeadingEditDialog(BuildContext context, WidgetRef ref) {
    Map<String, dynamic> data = {};
    try {
      if (content != null && content!.isNotEmpty) {
        data = jsonDecode(content!) as Map<String, dynamic>;
      }
    } catch (_) {
      data = {'text': content ?? ''};
    }

    final textController = TextEditingController(text: data['text'] as String? ?? content ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Heading'),
          content: TextField(
            controller: textController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Heading text...'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final updated = {...data, 'text': textController.text, 'style': 'heading'};
                await ref.read(pinRepositoryProvider).updatePinContent(pinId, jsonEncode(updated));
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
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
        return _FrameCardBody(content: content, pinId: pinId);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final placeholderBg = isDark ? EpicordiaColors.surfaceSunkenDark : const Color(0xFFF4F5F7);
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;
    final primaryIconColor = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600;

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
                    borderRadius: BorderRadius.vertical(
                      top: const Radius.circular(14),
                      bottom: caption.isEmpty ? const Radius.circular(14) : Radius.zero,
                    ),
                    child: Image.file(
                      File(filePath),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Center(
                        child: Icon(Icons.broken_image_outlined, size: 36, color: textTertiary),
                      ),
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_a_photo_outlined, size: 32, color: primaryIconColor),
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
        if (caption.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(
              caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: textSecondary),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;
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
    final titleText = label.isNotEmpty ? label : 'Column';

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
                            '${children.length} items',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
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
    if (pin.content == null || pin.content!.isEmpty) return '${pin.type.toUpperCase()} Card';
    try {
      final map = jsonDecode(pin.content!) as Map<String, dynamic>;
      if (map.containsKey('title')) return map['title'] as String;
      if (map.containsKey('text')) return map['text'] as String;
      if (map.containsKey('label')) return map['label'] as String;
    } catch (_) {}
    return pin.content!.trim().split('\n').first;
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
        width: 44,
        height: 44,
        alignment: Alignment.center,
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
