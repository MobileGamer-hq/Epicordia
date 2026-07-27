import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import '../../data/database/database.dart';
import '../../data/repository/pin_repository.dart';
import '../../core/theme.dart';

import '../../data/providers.dart';

/// A TextEditingController that renders basic markdown (bold, italic,
/// underline, links) live as the user types, instead of showing the raw
/// "**text**" characters as plain text. The raw markdown is still what's
/// stored/saved - this only changes how it's *displayed* in the editor.
///
/// The literal syntax characters ("**", "*", "<u>", "[](") are always
/// hidden - they're never rendered, even while the cursor is inside that
/// token - but they stay in the underlying text, so saving/loading and
/// re-toggling formatting still works off the raw markdown.
class MarkdownController extends TextEditingController {
  MarkdownController({super.text});

  static final RegExp _pattern = RegExp(
    r'(\*\*.*?\*\*)|(\*[^\*\n]+?\*)|(<u>.*?</u>)|(\[[^\]]*?\]\([^\)]*?\))',
    dotAll: true,
  );

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final source = text;
    if (source.isEmpty) {
      return TextSpan(style: style, text: source);
    }

    final children = <TextSpan>[];
    int pos = 0;

    for (final match in _pattern.allMatches(source)) {
      if (match.start > pos) {
        children.add(
          TextSpan(text: source.substring(pos, match.start), style: style),
        );
      }

      final token = match.group(0)!;
      // Markers are always hidden - never revealed, even while the cursor
      // is inside the token. They still exist in the raw text (so saving
      // and re-parsing works correctly), just never rendered visibly.
      children.add(_styledSpan(token, style, showMarkers: false));
      pos = match.end;
    }

    if (pos < source.length) {
      children.add(TextSpan(text: source.substring(pos), style: style));
    }

    return TextSpan(style: style, children: children);
  }

  /// Style used for the literal syntax characters. When [show] is false we
  /// don't just recolor them - we collapse their font size to near-zero and
  /// make them transparent so they take up (almost) no visible space, while
  /// the characters stay in the string so cursor/selection offsets still
  /// line up correctly with the raw text.
  TextStyle _markerStyle(TextStyle base, {required bool show}) {
    if (show) {
      return base.copyWith(color: EpicordiaColors.textTertiaryLight);
    }
    return base.copyWith(
      color: Colors.transparent,
      fontSize: (base.fontSize ?? 14) * 0.02,
      decoration: TextDecoration.none,
    );
  }

  TextSpan _styledSpan(
      String token,
      TextStyle? base, {
        required bool showMarkers,
      }) {
    final baseStyle = base ?? const TextStyle();
    final markerStyle = _markerStyle(baseStyle, show: showMarkers);

    if (token.startsWith('**') && token.endsWith('**')) {
      final inner = token.substring(2, token.length - 2);
      return TextSpan(
        children: [
          TextSpan(text: '**', style: markerStyle),
          TextSpan(
            text: inner,
            style: baseStyle.copyWith(fontWeight: FontWeight.w800),
          ),
          TextSpan(text: '**', style: markerStyle),
        ],
      );
    }

    if (token.startsWith('<u>') && token.endsWith('</u>')) {
      final inner = token.substring(3, token.length - 4);
      return TextSpan(
        children: [
          TextSpan(text: '<u>', style: markerStyle),
          TextSpan(
            text: inner,
            style: baseStyle.copyWith(decoration: TextDecoration.underline),
          ),
          TextSpan(text: '</u>', style: markerStyle),
        ],
      );
    }

    if (token.startsWith('[') && token.contains('](')) {
      final closeBracket = token.indexOf(']');
      final label = token.substring(1, closeBracket);
      final url = token.substring(closeBracket + 2, token.length - 1);
      return TextSpan(
        children: [
          TextSpan(text: '[', style: markerStyle),
          TextSpan(
            text: label,
            style: baseStyle.copyWith(
              color: EpicordiaColors.blue600,
              decoration: TextDecoration.underline,
            ),
          ),
          TextSpan(text: '](', style: markerStyle),
          TextSpan(text: url, style: markerStyle),
          TextSpan(text: ')', style: markerStyle),
        ],
      );
    }

    // Italic: single leading/trailing '*'
    final inner = token.substring(1, token.length - 1);
    return TextSpan(
      children: [
        TextSpan(text: '*', style: markerStyle),
        TextSpan(
          text: inner,
          style: baseStyle.copyWith(fontStyle: FontStyle.italic),
        ),
        TextSpan(text: '*', style: markerStyle),
      ],
    );
  }
}

class CreateNoteScreen extends ConsumerStatefulWidget {
  final String? noteId;
  const CreateNoteScreen({super.key, this.noteId});

  @override
  ConsumerState<CreateNoteScreen> createState() => _CreateNoteScreenState();
}

class _CreateNoteScreenState extends ConsumerState<CreateNoteScreen> {
  final _titleController = TextEditingController();
  final _bodyController = MarkdownController();
  final _bodyFocusNode = FocusNode();

  // The TextField reports an invalid (-1,-1) selection the instant it loses
  // focus (e.g. when a toolbar button is tapped), so we cache the last known
  // good selection to fall back on.
  TextSelection _lastSelection = const TextSelection.collapsed(offset: 0);

  PinEntity? _existingNote;

  @override
  void initState() {
    super.initState();
    _bodyController.addListener(() {
      if (_bodyController.selection.isValid) {
        _lastSelection = _bodyController.selection;
      }
    });
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
        _bodyController.text = lines.length > 1
            ? lines.sublist(1).join('\n').trim()
            : '';
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _bodyFocusNode.dispose();
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
            child: const Text(
              'Delete',
              style: TextStyle(color: EpicordiaColors.errorLight),
            ),
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
      await ref
          .read(pinRepositoryProvider)
          .updatePin(
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

  /// Selection to use for a formatting action. Falls back to the last known
  /// good selection when the field has lost focus (e.g. tapping a toolbar
  /// button), instead of bailing out on an invalid (-1,-1) selection.
  TextSelection _currentSelection() {
    final selection = _bodyController.selection;
    return selection.isValid ? selection : _lastSelection;
  }

  void _applyFormat(String prefix, String suffix, {bool isLineStart = false}) {
    final selection = _currentSelection();

    final text = _bodyController.text;
    final start = selection.start.clamp(0, text.length);
    final end = selection.end.clamp(0, text.length);

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

      final newText = text.replaceRange(lineStart, end, newLine);
      _bodyController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: cursorOffset),
      );
      _lastSelection = _bodyController.selection;
      _bodyFocusNode.requestFocus();
      return;
    }

    final selectedText = text.substring(start, end);

    if (selectedText.isEmpty) {
      final replacement = prefix + suffix;
      final newText = text.replaceRange(start, end, replacement);
      _bodyController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start + prefix.length),
      );
      _lastSelection = _bodyController.selection;
      _bodyFocusNode.requestFocus();
      return;
    }

    final alreadyWrapped =
        selectedText.startsWith(prefix) &&
            selectedText.endsWith(suffix) &&
            selectedText.length >= prefix.length + suffix.length;

    if (alreadyWrapped) {
      final inner = selectedText.substring(
        prefix.length,
        selectedText.length - suffix.length,
      );
      final newText = text.replaceRange(start, end, inner);
      _bodyController.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: start,
          extentOffset: start + inner.length,
        ),
      );
      _lastSelection = _bodyController.selection;
      _bodyFocusNode.requestFocus();
      return;
    }

    final replacement = prefix + selectedText + suffix;
    final newText = text.replaceRange(start, end, replacement);
    _bodyController.value = TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: start + prefix.length,
        extentOffset: start + prefix.length + selectedText.length,
      ),
    );
    _lastSelection = _bodyController.selection;
    _bodyFocusNode.requestFocus();
  }

  void _insertLink() {
    final selection = _currentSelection();

    final text = _bodyController.text;
    final start = selection.start.clamp(0, text.length);
    final end = selection.end.clamp(0, text.length);
    final selectedText = text.substring(start, end);

    final urlController = TextEditingController(text: 'https://');
    final textController = TextEditingController(text: selectedText);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Insert Link',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
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
                  final newText = text.replaceRange(start, end, replacement);
                  _bodyController.value = TextEditingValue(
                    text: newText,
                    selection: TextSelection.collapsed(
                      offset: start + replacement.length,
                    ),
                  );
                  _lastSelection = _bodyController.selection;
                }
                Navigator.of(context).pop();
                _bodyFocusNode.requestFocus();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgApp = isDark ? EpicordiaColors.surfaceAppDark : EpicordiaColors.surfaceAppLight;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;
    final borderClr = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;
    final activeBlue = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600;

    return Scaffold(
      backgroundColor: bgApp,
      appBar: AppBar(
        backgroundColor: bgApp,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => context.go('/notes'),
        ),
        title: Text(
          isEditing ? 'Edit Note' : 'New Note',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        actions: [
          if (isEditing)
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: isDark ? EpicordiaColors.errorDark : EpicordiaColors.errorLight,
              ),
              onPressed: _delete,
            ),
          TextButton(
            onPressed: _save,
            child: Text(
              'Save',
              style: TextStyle(
                color: activeBlue,
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
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Note title...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  hintStyle: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: textTertiary,
                  ),
                ),
              ),
              Divider(color: borderClr),
              const SizedBox(height: 8),
              // Body
              Expanded(
                child: TextField(
                  controller: _bodyController,
                  focusNode: _bodyFocusNode,
                  autofocus: true,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: TextStyle(
                    fontSize: 15,
                    color: textPrimary,
                    height: 1.6,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Start writing...',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    hintStyle: TextStyle(color: textTertiary),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: borderClr),
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
                    _FmtButton(icon: Icons.link, onTap: _insertLink),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;

    return InkWell(
      onTap: onTap,
      canRequestFocus: false,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 20, color: iconColor),
      ),
    );
  }
}