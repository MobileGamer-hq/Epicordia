import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import '../../data/database/database.dart';
import '../../data/repository/pin_repository.dart';
import '../../core/theme.dart';

import '../../data/providers.dart';

class CreateNoteScreen extends ConsumerStatefulWidget {
  final String? noteId;
  const CreateNoteScreen({super.key, this.noteId});

  @override
  ConsumerState<CreateNoteScreen> createState() => _CreateNoteScreenState();
}

class _CreateNoteScreenState extends ConsumerState<CreateNoteScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  PinEntity? _existingNote;

  @override
  void initState() {
    super.initState();
    if (widget.noteId != null) {
      _loadExistingNote();
    }
  }

  Future<void> _loadExistingNote() async {
    final note = await ref.read(pinDaoProvider).getPin(widget.noteId!);
    if (note != null && mounted) {
      setState(() {
        _existingNote = note;
        final lines = (note.content ?? '').split('\n');
        _titleController.text = lines.isNotEmpty ? lines[0] : '';
        _bodyController.text = lines.length > 1 ? lines.sublist(1).join('\n').trim() : '';
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: EpicordiaColors.errorLight)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(pinRepositoryProvider).deletePin(widget.noteId!);
      if (mounted) context.go('/notes');
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty && body.isEmpty) return;

    final content = title.isNotEmpty ? '$title\n\n$body' : body;
    if (widget.noteId != null && _existingNote != null) {
      await ref.read(pinRepositoryProvider).updatePin(
            _existingNote!.copyWith(
              content: drift.Value(content),
              modifiedAt: DateTime.now(),
            ),
          );
    } else {
      await ref
          .read(pinRepositoryProvider)
          .createPin(
            PinsCompanion.insert(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              boardId: const drift.Value(null),
              type: 'note',
              content: drift.Value(content),
            ),
          );
    }
    if (mounted) context.go('/notes');
  }

  void _applyFormat(String prefix, String suffix, {bool isLineStart = false}) {
    final selection = _bodyController.selection;
    if (!selection.isValid) return;

    final text = _bodyController.text;
    final start = selection.start;
    final end = selection.end;

    if (isLineStart) {
      int lineStart = start;
      while (lineStart > 0 && text[lineStart - 1] != '\n') {
        lineStart--;
      }
      final line = text.substring(lineStart, end);

      String newLine;
      int cursorOffset;
      if (line.startsWith(prefix)) {
        newLine = line.substring(prefix.length);
        cursorOffset = lineStart + newLine.length;
      } else {
        newLine = prefix + line;
        cursorOffset = lineStart + newLine.length;
      }

      _bodyController.value = TextEditingValue(
        text: text.replaceRange(lineStart, end, newLine),
        selection: TextSelection.collapsed(offset: cursorOffset),
      );
      return;
    }

    final selectedText = text.substring(start, end);

    if (selectedText.isEmpty) {
      final replacement = prefix + suffix;
      _bodyController.value = TextEditingValue(
        text: text.replaceRange(start, end, replacement),
        selection: TextSelection.collapsed(offset: start + prefix.length),
      );
      return;
    }

    final alreadyWrapped = selectedText.startsWith(prefix) &&
        selectedText.endsWith(suffix) &&
        selectedText.length >= prefix.length + suffix.length;

    if (alreadyWrapped) {
      final inner = selectedText.substring(
        prefix.length,
        selectedText.length - suffix.length,
      );
      _bodyController.value = TextEditingValue(
        text: text.replaceRange(start, end, inner),
        selection: TextSelection(baseOffset: start, extentOffset: start + inner.length),
      );
      return;
    }

    final replacement = prefix + selectedText + suffix;
    _bodyController.value = TextEditingValue(
      text: text.replaceRange(start, end, replacement),
      selection: TextSelection(
        baseOffset: start + prefix.length,
        extentOffset: start + prefix.length + selectedText.length,
      ),
    );
  }

  void _insertLink() {
    final selection = _bodyController.selection;
    if (!selection.isValid) return;

    final text = _bodyController.text;
    final start = selection.start;
    final end = selection.end;
    final selectedText = text.substring(start, end);

    final urlController = TextEditingController(text: 'https://');
    final textController = TextEditingController(text: selectedText);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Insert Link', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selectedText.isEmpty) ...[
                TextField(
                  controller: textController,
                  decoration: const InputDecoration(
                    labelText: 'Link Text',
                    hintText: 'e.g. Google',
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'Link URL',
                  hintText: 'https://example.com',
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final linkText = textController.text.trim();
                final linkUrl = urlController.text.trim();
                if (linkUrl.isNotEmpty) {
                  final displayName = linkText.isNotEmpty ? linkText : linkUrl;
                  final replacement = '[$displayName]($linkUrl)';
                  _bodyController.value = TextEditingValue(
                    text: text.replaceRange(start, end, replacement),
                    selection: TextSelection.collapsed(offset: start + replacement.length),
                  );
                }
                Navigator.of(context).pop();
              },
              child: const Text('Insert'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.noteId != null;

    return Scaffold(
      backgroundColor: EpicordiaColors.surfaceAppLight,
      appBar: AppBar(
        backgroundColor: EpicordiaColors.surfaceAppLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: EpicordiaColors.textPrimaryLight,
          ),
          onPressed: () => context.go('/notes'),
        ),
        title: Text(
          isEditing ? 'Edit Note' : 'New Note',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: EpicordiaColors.textPrimaryLight,
          ),
        ),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: EpicordiaColors.errorLight),
              onPressed: _delete,
            ),
          TextButton(
            onPressed: _save,
            child: const Text(
              'Save',
              style: TextStyle(
                color: EpicordiaColors.blue600,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            children: [
              // Title
              TextField(
                controller: _titleController,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: EpicordiaColors.textPrimaryLight,
                ),
                decoration: const InputDecoration(
                  hintText: 'Note title...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  hintStyle: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: EpicordiaColors.textTertiaryLight,
                  ),
                ),
              ),
              const Divider(color: EpicordiaColors.borderSubtleLight),
              const SizedBox(height: 8),
              // Body
              Expanded(
                child: TextField(
                  controller: _bodyController,
                  autofocus: true,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(
                    fontSize: 15,
                    color: EpicordiaColors.textPrimaryLight,
                    height: 1.6,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Start writing...',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    hintStyle: TextStyle(
                      color: EpicordiaColors.textTertiaryLight,
                    ),
                  ),
                ),
              ),
               Container(
                 padding: const EdgeInsets.symmetric(vertical: 8),
                 decoration: const BoxDecoration(
                   border: Border(
                     top: BorderSide(color: EpicordiaColors.borderSubtleLight),
                   ),
                 ),
                 child: Row(
                   children: [
                     _FmtButton(
                       icon: Icons.format_bold,
                       onTap: () => _applyFormat('**', '**'),
                     ),
                     _FmtButton(
                       icon: Icons.format_italic,
                       onTap: () => _applyFormat('*', '*'),
                     ),
                     _FmtButton(
                       icon: Icons.format_underline,
                       onTap: () => _applyFormat('<u>', '</u>'),
                     ),
                     _FmtButton(
                       icon: Icons.format_list_bulleted,
                       onTap: () => _applyFormat('- ', '', isLineStart: true),
                     ),
                     _FmtButton(
                       icon: Icons.format_list_numbered,
                       onTap: () => _applyFormat('1. ', '', isLineStart: true),
                     ),
                     _FmtButton(
                       icon: Icons.link,
                       onTap: _insertLink,
                     ),
                   ],
                 ),
               ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FmtButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _FmtButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 20, color: EpicordiaColors.textSecondaryLight),
      ),
    );
  }
}
