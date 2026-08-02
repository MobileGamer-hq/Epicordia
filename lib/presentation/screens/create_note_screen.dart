import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import '../../data/database/database.dart';
import '../../data/repository/pin_repository.dart';
import '../../core/theme.dart';
import '../widgets/core/link_preview_dialog.dart';

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

  TextSelection _lastSelection = const TextSelection.collapsed(offset: 0);

  PinEntity? _existingNote;
  String? _currentNoteId;
  Timer? _debounceTimer;
  String _saveStatus = 'Saved';
  bool _isLoadingNote = false;

  @override
  void initState() {
    super.initState();
    _currentNoteId = widget.noteId;
    _bodyController.addListener(_onTextChanged);
    _titleController.addListener(_onTextChanged);
    if (widget.noteId != null) {
      _loadExistingNote();
    }
  }

  String _previousText = '';

  void _onTextChanged() {
    final currentText = _bodyController.text;
    if (_bodyController.selection.isValid) {
      _lastSelection = _bodyController.selection;
    }

    _handleSmartListContinuation(currentText);
    _previousText = currentText;

    if (_isLoadingNote) return;
    if (mounted && _saveStatus != 'Saving...') {
      setState(() {
        _saveStatus = 'Saving...';
      });
    }
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), _autoSave);
  }

  void _handleSmartListContinuation(String currentText) {
    if (currentText.length != _previousText.length + 1) return;
    final selection = _bodyController.selection;
    if (!selection.isCollapsed || selection.start <= 0) return;

    final cursor = selection.start;
    if (currentText[cursor - 1] != '\n') return;

    int prevLineEnd = cursor - 1;
    int prevLineStart = prevLineEnd;
    while (prevLineStart > 0 && currentText[prevLineStart - 1] != '\n') {
      prevLineStart--;
    }

    final prevLine = currentText.substring(prevLineStart, prevLineEnd);

    // 1. Bullet list item with content
    if (RegExp(r'^[\*\-\+]\s+(.+)$').hasMatch(prevLine)) {
      final newText = '${currentText.substring(0, cursor)}- ${currentText.substring(cursor)}';
      _bodyController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: cursor + 2),
      );
      _lastSelection = _bodyController.selection;
      return;
    }

    // 2. Empty bullet list item -> turn OFF list mode
    if (RegExp(r'^[\*\-\+]\s*$').hasMatch(prevLine)) {
      final newText = '${currentText.substring(0, prevLineStart)}\n${currentText.substring(cursor)}';
      _bodyController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: prevLineStart + 1),
      );
      _lastSelection = _bodyController.selection;
      return;
    }

    // 3. Numbered list item with content
    final numMatch = RegExp(r'^\s*(\d+)\.\s+(.+)$').firstMatch(prevLine);
    if (numMatch != null) {
      final numVal = int.tryParse(numMatch.group(1)!) ?? 1;
      final nextPrefix = '${numVal + 1}. ';
      final newText = '${currentText.substring(0, cursor)}$nextPrefix${currentText.substring(cursor)}';
      _bodyController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: cursor + nextPrefix.length),
      );
      _lastSelection = _bodyController.selection;
      return;
    }

    // 4. Empty numbered list item -> turn OFF list mode
    if (RegExp(r'^\s*\d+\.\s*$').hasMatch(prevLine)) {
      final newText = '${currentText.substring(0, prevLineStart)}\n${currentText.substring(cursor)}';
      _bodyController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: prevLineStart + 1),
      );
      _lastSelection = _bodyController.selection;
      return;
    }
  }

  Future<void> _loadExistingNote() async {
    _isLoadingNote = true;
    final note = await ref.read(pinDaoProvider).getPin(_currentNoteId!);
    if (note != null && mounted) {
      setState(() {
        _existingNote = note;
        final lines = (note.content ?? '').split('\n');
        _titleController.text = lines.isNotEmpty ? lines[0] : '';
        _bodyController.text = lines.length > 1
            ? lines.sublist(1).join('\n').trim()
            : '';
        _saveStatus = 'Saved';
      });
    }
    _isLoadingNote = false;
  }

  Future<void> _autoSave() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty && body.isEmpty) return;

    final content = title.isNotEmpty ? '$title\n\n$body' : body;
    if (_currentNoteId != null && _existingNote != null) {
      final updatedPin = _existingNote!.copyWith(
        content: drift.Value(content),
        modifiedAt: DateTime.now(),
      );
      await ref.read(pinRepositoryProvider).updatePin(updatedPin);
      _existingNote = updatedPin;
    } else {
      final newId = DateTime.now().millisecondsSinceEpoch.toString();
      _currentNoteId = newId;
      final companion = PinsCompanion.insert(
        id: newId,
        boardId: const drift.Value(null),
        type: 'note',
        content: drift.Value(content),
      );
      await ref.read(pinRepositoryProvider).createPin(companion);
      _existingNote = await ref.read(pinDaoProvider).getPin(newId);
    }
    if (mounted) {
      setState(() {
        _saveStatus = 'Saved';
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
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
      if (_currentNoteId != null) {
        await ref.read(pinRepositoryProvider).deletePin(_currentNoteId!);
      }
      if (mounted) context.go('/notes');
    }
  }

  Future<void> _save() async {
    await _autoSave();
    if (mounted) context.go('/notes');
  }

  /// Selection to use for a formatting action. Falls back to the last known
  /// good selection when the field has lost focus (e.g. tapping a toolbar
  /// button), instead of bailing out on an invalid (-1,-1) selection.
  TextSelection _currentSelection() {
    final selection = _bodyController.selection;
    return selection.isValid ? selection : _lastSelection;
  }

  bool _isPatternActive(RegExp regex) {
    final selection = _currentSelection();
    final text = _bodyController.text;
    if (text.isEmpty) return false;
    final start = selection.start.clamp(0, text.length);
    final end = selection.end.clamp(0, text.length);

    for (final match in regex.allMatches(text)) {
      if (start >= match.start && end <= match.end && match.start < match.end) {
        return true;
      }
    }
    return false;
  }

  bool _isBoldActive() {
    return _isPatternActive(RegExp(r'\*\*.*?\*\*', dotAll: true));
  }

  bool _isItalicActive() {
    final selection = _currentSelection();
    final text = _bodyController.text;
    if (text.isEmpty) return false;
    final start = selection.start.clamp(0, text.length);
    final end = selection.end.clamp(0, text.length);

    for (final match in RegExp(r'\*\*.*?\*\*', dotAll: true).allMatches(text)) {
      if (start >= match.start && end <= match.end) {
        return false;
      }
    }
    return _isPatternActive(RegExp(r'\*[^\*\n]+?\*', dotAll: true));
  }

  bool _isUnderlineActive() {
    return _isPatternActive(RegExp(r'<u>.*?</u>', dotAll: true));
  }

  bool _isBulletActive() {
    final selection = _currentSelection();
    final text = _bodyController.text;
    if (text.isEmpty) return false;
    final start = selection.start.clamp(0, text.length);
    int lineStart = start;
    while (lineStart > 0 && text[lineStart - 1] != '\n') {
      lineStart--;
    }
    int lineEnd = start;
    while (lineEnd < text.length && text[lineEnd] != '\n') {
      lineEnd++;
    }
    final line = text.substring(lineStart, lineEnd);
    return line.startsWith('- ') || line.startsWith('* ');
  }

  bool _isNumberedActive() {
    final selection = _currentSelection();
    final text = _bodyController.text;
    if (text.isEmpty) return false;
    final start = selection.start.clamp(0, text.length);
    int lineStart = start;
    while (lineStart > 0 && text[lineStart - 1] != '\n') {
      lineStart--;
    }
    int lineEnd = start;
    while (lineEnd < text.length && text[lineEnd] != '\n') {
      lineEnd++;
    }
    final line = text.substring(lineStart, lineEnd);
    return RegExp(r'^\d+\.\s').hasMatch(line);
  }

  bool _isLinkActive() {
    return _isPatternActive(RegExp(r'\[[^\]]*?\]\([^\)]*?\)', dotAll: true));
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
      int lineEnd = start;
      while (lineEnd < text.length && text[lineEnd] != '\n') {
        lineEnd++;
      }
      final line = text.substring(lineStart, lineEnd);

      String newLine;
      int cursorOffset;

      if (prefix == '- ') {
        if (line.startsWith('- ') || line.startsWith('* ')) {
          newLine = line.replaceFirst(RegExp(r'^[\*\-]\s+'), '');
          cursorOffset = (lineStart + newLine.length).clamp(0, text.length);
        } else if (RegExp(r'^\d+\.\s+').hasMatch(line)) {
          newLine = line.replaceFirst(RegExp(r'^\d+\.\s+'), '- ');
          cursorOffset = (lineStart + newLine.length).clamp(0, text.length);
        } else {
          newLine = '- $line';
          cursorOffset = (lineStart + newLine.length).clamp(0, text.length);
        }
      } else if (prefix == '1. ') {
        if (RegExp(r'^\d+\.\s+').hasMatch(line)) {
          newLine = line.replaceFirst(RegExp(r'^\d+\.\s+'), '');
          cursorOffset = (lineStart + newLine.length).clamp(0, text.length);
        } else if (line.startsWith('- ') || line.startsWith('* ')) {
          newLine = line.replaceFirst(RegExp(r'^[\*\-]\s+'), '1. ');
          cursorOffset = (lineStart + newLine.length).clamp(0, text.length);
        } else {
          newLine = '1. $line';
          cursorOffset = (lineStart + newLine.length).clamp(0, text.length);
        }
      } else {
        if (line.startsWith(prefix)) {
          newLine = line.substring(prefix.length);
          cursorOffset = (lineStart + newLine.length).clamp(0, text.length);
        } else {
          newLine = prefix + line;
          cursorOffset = (lineStart + newLine.length).clamp(0, text.length);
        }
      }

      final newText = text.replaceRange(lineStart, lineEnd, newLine);
      _bodyController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: cursorOffset),
      );
      _lastSelection = _bodyController.selection;
      _bodyFocusNode.requestFocus();
      return;
    }

    final selectedText = text.substring(start, end);

    final pattern = prefix == '**'
        ? RegExp(r'\*\*.*?\*\*', dotAll: true)
        : (prefix == '<u>'
            ? RegExp(r'<u>.*?</u>', dotAll: true)
            : RegExp(r'\*[^\*\n]+?\*', dotAll: true));

    Match? enclosingMatch;
    for (final m in pattern.allMatches(text)) {
      if (start >= m.start && end <= m.end) {
        enclosingMatch = m;
        break;
      }
    }

    if (enclosingMatch != null) {
      final matchStr = text.substring(enclosingMatch.start, enclosingMatch.end);
      final innerText = matchStr.substring(prefix.length, matchStr.length - suffix.length);
      final newText = text.replaceRange(enclosingMatch.start, enclosingMatch.end, innerText);
      final newCursor = (start - prefix.length).clamp(enclosingMatch.start, enclosingMatch.start + innerText.length);
      _bodyController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newCursor),
      );
      _lastSelection = _bodyController.selection;
      _bodyFocusNode.requestFocus();
      return;
    }

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

    // If cursor is inside an existing link, show LinkPreviewDialog immediately!
    final linkPattern = RegExp(r'\[([^\]]*?)\]\(([^\)]*?)\)', dotAll: true);
    for (final match in linkPattern.allMatches(text)) {
      if (start >= match.start && end <= match.end) {
        final label = match.group(1) ?? '';
        final url = match.group(2) ?? '';
        LinkPreviewDialog.show(context, label, url);
        return;
      }
    }

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
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;
    final borderClr = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;
    final activeBlue = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        await _autoSave();
      },
      child: Scaffold(
        backgroundColor: bgApp,
        appBar: AppBar(
          backgroundColor: bgApp,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textPrimary),
            onPressed: () async {
              await _autoSave();
              if (context.mounted) context.go('/notes');
            },
          ),
          title: Row(
            children: [
              Text(
                isEditing ? 'Edit Note' : 'New Note',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _saveStatus == 'Saving...'
                      ? EpicordiaColors.blue100
                      : (isDark ? const Color(0xFF2B2E34) : const Color(0xFFF3F4F6)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _saveStatus,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _saveStatus == 'Saving...'
                        ? EpicordiaColors.blue600
                        : EpicordiaColors.textSecondaryLight,
                  ),
                ),
              ),
            ],
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
                      isActive: _isBoldActive(),
                      onTap: () => _applyFormat('**', '**'),
                    ),
                    const SizedBox(width: 4),
                    _FmtButton(
                      icon: Icons.format_italic,
                      isActive: _isItalicActive(),
                      onTap: () => _applyFormat('*', '*'),
                    ),
                    const SizedBox(width: 4),
                    _FmtButton(
                      icon: Icons.format_underline,
                      isActive: _isUnderlineActive(),
                      onTap: () => _applyFormat('<u>', '</u>'),
                    ),
                    const SizedBox(width: 4),
                    _FmtButton(
                      icon: Icons.format_list_bulleted,
                      isActive: _isBulletActive(),
                      onTap: () => _applyFormat('- ', '', isLineStart: true),
                    ),
                    const SizedBox(width: 4),
                    _FmtButton(
                      icon: Icons.format_list_numbered,
                      isActive: _isNumberedActive(),
                      onTap: () => _applyFormat('1. ', '', isLineStart: true),
                    ),
                    const SizedBox(width: 4),
                    _FmtButton(
                      icon: Icons.link,
                      isActive: _isLinkActive(),
                      onTap: _insertLink,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}

class _FmtButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;
  const _FmtButton({
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600;
    final inactiveColor = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final iconColor = isActive ? activeColor : inactiveColor;
    final bgColor = isActive ? activeColor.withValues(alpha: 0.15) : Colors.transparent;

    return InkWell(
      onTap: onTap,
      canRequestFocus: false,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 20, color: iconColor),
      ),
    );
  }
}