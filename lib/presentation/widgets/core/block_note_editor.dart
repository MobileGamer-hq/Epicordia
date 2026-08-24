import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../domain/models/note_model.dart';
import '../../../core/theme.dart';
import 'link_preview_dialog.dart';

class BlockTextController extends TextEditingController {
  List<Mark> marks;

  BlockTextController({super.text, List<Mark>? marks})
      : marks = marks != null ? List<Mark>.from(marks) : [];

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final baseStyle = style ?? const TextStyle();
    if (text.isEmpty) {
      return TextSpan(style: baseStyle, text: '');
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeBlue = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600;

    if (marks.isEmpty) {
      return TextSpan(style: baseStyle, text: text);
    }

    final boundaries = <int>{0, text.length};
    for (final mark in marks) {
      if (mark.start >= 0 && mark.start <= text.length) boundaries.add(mark.start);
      if (mark.end >= 0 && mark.end <= text.length) boundaries.add(mark.end);
    }

    final sortedBoundaries = boundaries.toList()..sort();
    final spans = <TextSpan>[];

    for (int i = 0; i < sortedBoundaries.length - 1; i++) {
      final start = sortedBoundaries[i];
      final end = sortedBoundaries[i + 1];
      if (start >= end) continue;

      final chunkText = text.substring(start, end);
      final activeMarks = marks.where((m) => m.start <= start && m.end >= end).toList();

      TextStyle spanStyle = baseStyle;

      for (final mark in activeMarks) {
        switch (mark.type) {
          case MarkType.bold:
            spanStyle = spanStyle.copyWith(fontWeight: FontWeight.w800);
            break;
          case MarkType.italic:
            spanStyle = spanStyle.copyWith(fontStyle: FontStyle.italic);
            break;
          case MarkType.underline:
            spanStyle = spanStyle.copyWith(decoration: TextDecoration.underline);
            break;
          case MarkType.strikethrough:
            spanStyle = spanStyle.copyWith(
              decoration: TextDecoration.combine([
                if (spanStyle.decoration != null) spanStyle.decoration!,
                TextDecoration.lineThrough,
              ]),
            );
            break;
          case MarkType.link:
            spanStyle = spanStyle.copyWith(
              color: activeBlue,
              decoration: TextDecoration.underline,
            );
            break;
        }
      }

      spans.add(TextSpan(text: chunkText, style: spanStyle));
    }

    return TextSpan(children: spans, style: baseStyle);
  }
}

class BlockNoteEditor extends StatefulWidget {
  final List<NoteBlock> initialBlocks;
  final ValueChanged<List<NoteBlock>> onChanged;

  const BlockNoteEditor({
    super.key,
    required this.initialBlocks,
    required this.onChanged,
  });

  @override
  State<BlockNoteEditor> createState() => BlockNoteEditorStateController();
}

class BlockNoteEditorStateController extends State<BlockNoteEditor> {
  late List<NoteBlock> _blocks;
  final List<BlockTextController> _controllers = [];
  final List<FocusNode> _focusNodes = [];

  int _focusedIndex = 0;
  TextSelection _lastSelection = const TextSelection.collapsed(offset: 0);

  @override
  void initState() {
    super.initState();
    _blocks = widget.initialBlocks.isNotEmpty
        ? widget.initialBlocks.map((b) => b.copyWith()).toList()
        : [NoteBlock(type: BlockType.paragraph, text: '')];

    for (int i = 0; i < _blocks.length; i++) {
      _initBlockController(i, _blocks[i]);
    }
  }

  void _initBlockController(int index, NoteBlock block) {
    final controller = BlockTextController(
      text: block.text,
      marks: block.marks,
    );
    final focusNode = FocusNode();

    controller.addListener(() {
      _onBlockTextChanged(index);
    });

    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        setState(() {
          _focusedIndex = index;
        });
      }
    });

    if (index < _controllers.length) {
      _controllers[index] = controller;
      _focusNodes[index] = focusNode;
    } else {
      _controllers.add(controller);
      _focusNodes.add(focusNode);
    }
  }

  void _onBlockTextChanged(int index) {
    if (index >= _controllers.length || index >= _blocks.length) return;
    final controller = _controllers[index];
    final oldText = _blocks[index].text;
    final newText = controller.text;

    if (controller.selection.isValid) {
      _lastSelection = controller.selection;
    }

    if (oldText != newText) {
      final newMarks = _adjustMarksOnTextChange(
        controller.marks,
        oldText,
        newText,
        controller.selection,
      );
      controller.marks = newMarks;
      _blocks[index] = _blocks[index].copyWith(
        text: newText,
        marks: newMarks,
      );
      widget.onChanged(_blocks);
    }
  }

  List<Mark> _adjustMarksOnTextChange(
    List<Mark> currentMarks,
    String oldText,
    String newText,
    TextSelection selection,
  ) {
    final diff = newText.length - oldText.length;
    if (diff == 0 || currentMarks.isEmpty) return currentMarks;

    final cursor = selection.start;
    final adjusted = <Mark>[];

    for (final mark in currentMarks) {
      int start = mark.start;
      int end = mark.end;

      if (diff > 0) {
        // Insertion
        final insertPos = cursor - diff;
        if (insertPos <= start) {
          start += diff;
          end += diff;
        } else if (insertPos > start && insertPos <= end) {
          end += diff;
        }
      } else {
        // Deletion
        final deletePos = cursor;
        final deletedCount = -diff;
        final deleteEnd = deletePos + deletedCount;

        if (deleteEnd <= start) {
          start -= deletedCount;
          end -= deletedCount;
        } else if (deletePos >= end) {
          // Unaffected
        } else {
          if (deletePos <= start && deleteEnd >= end) {
            continue; // Completely deleted
          }
          if (deletePos <= start) {
            start = deletePos;
            end -= deletedCount;
          } else {
            end -= deletedCount;
          }
        }
      }

      start = start.clamp(0, newText.length);
      end = end.clamp(0, newText.length);

      if (end > start) {
        adjusted.add(mark.copyWith(start: start, end: end));
      }
    }

    return adjusted;
  }

  int get activeIndex => _focusedIndex.clamp(0, _blocks.length - 1);
  BlockTextController get activeController => _controllers[activeIndex];
  NoteBlock get activeBlock => _blocks[activeIndex];
  TextSelection get activeSelection =>
      activeController.selection.isValid ? activeController.selection : _lastSelection;

  bool isMarkActive(MarkType type) {
    if (_blocks.isEmpty) return false;
    final controller = activeController;
    final text = controller.text;
    if (text.isEmpty) return false;

    final sel = activeSelection;
    final start = sel.start.clamp(0, text.length);
    final end = sel.end.clamp(0, text.length);

    for (final mark in controller.marks) {
      if (mark.type == type) {
        if (start == end) {
          if (start >= mark.start && start <= mark.end) return true;
        } else {
          if (mark.start <= start && mark.end >= end) return true;
        }
      }
    }
    return false;
  }

  bool isBlockTypeActive(BlockType type) {
    if (_blocks.isEmpty) return false;
    return activeBlock.type == type;
  }

  /// Toggle mark over current selection range cleanly without destroying existing formatting.
  void toggleMark(MarkType type, {String? href}) {
    if (_blocks.isEmpty) return;
    final index = activeIndex;
    final controller = activeController;
    final text = controller.text;
    if (text.isEmpty) return;

    final sel = activeSelection;
    int start = sel.start.clamp(0, text.length);
    int end = sel.end.clamp(0, text.length);

    // If collapsed selection, select current word
    if (start == end) {
      start = _findWordStart(text, start);
      end = _findWordEnd(text, end);
    }
    if (start >= end) return;

    final isActive = isMarkActive(type);
    List<Mark> updatedMarks;

    if (isActive) {
      updatedMarks = _removeMarkFromRange(controller.marks, type, start, end);
    } else {
      updatedMarks = _addMarkToRange(controller.marks, type, start, end, href: href);
    }

    controller.marks = updatedMarks;
    _blocks[index] = _blocks[index].copyWith(marks: updatedMarks);
    setState(() {});
    widget.onChanged(_blocks);
    _focusNodes[index].requestFocus();
  }

  int _findWordStart(String text, int pos) {
    int start = pos;
    while (start > 0 && _isWordChar(text[start - 1])) {
      start--;
    }
    return start;
  }

  int _findWordEnd(String text, int pos) {
    int end = pos;
    while (end < text.length && _isWordChar(text[end])) {
      end++;
    }
    return end;
  }

  bool _isWordChar(String ch) {
    return RegExp(r'[\w\u00C0-\u024F]').hasMatch(ch);
  }

  List<Mark> _addMarkToRange(List<Mark> marks, MarkType type, int start, int end, {String? href}) {
    final result = <Mark>[];
    int newStart = start;
    int newEnd = end;

    for (final mark in marks) {
      if (mark.type == type) {
        if (mark.start <= newEnd && mark.end >= newStart) {
          newStart = mark.start < newStart ? mark.start : newStart;
          newEnd = mark.end > newEnd ? mark.end : newEnd;
          continue;
        }
      }
      result.add(mark);
    }

    result.add(Mark(type: type, start: newStart, end: newEnd, href: href));
    result.sort((a, b) => a.start.compareTo(b.start));
    return result;
  }

  List<Mark> _removeMarkFromRange(List<Mark> marks, MarkType type, int start, int end) {
    final result = <Mark>[];

    for (final mark in marks) {
      if (mark.type != type) {
        result.add(mark);
        continue;
      }

      if (mark.end <= start || mark.start >= end) {
        result.add(mark);
        continue;
      }

      if (mark.start < start && mark.end > end) {
        result.add(mark.copyWith(end: start));
        result.add(mark.copyWith(start: end));
        continue;
      }

      if (mark.start < start) {
        result.add(mark.copyWith(end: start));
      }

      if (mark.end > end) {
        result.add(mark.copyWith(start: end));
      }
    }

    result.sort((a, b) => a.start.compareTo(b.start));
    return result;
  }

  void toggleBlockType(BlockType targetType) {
    if (_blocks.isEmpty) return;
    final index = activeIndex;
    final currentType = _blocks[index].type;

    final nextType = (currentType == targetType) ? BlockType.paragraph : targetType;
    _blocks[index] = _blocks[index].copyWith(type: nextType);

    setState(() {});
    widget.onChanged(_blocks);
    _focusNodes[index].requestFocus();
  }

  void insertLink() {
    if (_blocks.isEmpty) return;
    final controller = activeController;
    final text = controller.text;
    final sel = activeSelection;

    final start = sel.start.clamp(0, text.length);
    final end = sel.end.clamp(0, text.length);
    final selectedText = text.substring(start, end);

    for (final mark in controller.marks) {
      if (mark.type == MarkType.link && start >= mark.start && end <= mark.end) {
        final label = text.substring(mark.start, mark.end);
        LinkPreviewDialog.show(context, label, mark.href ?? '');
        return;
      }
    }

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
                  if (selectedText.isEmpty && linkText.isNotEmpty) {
                    final newText = text.replaceRange(start, end, linkText);
                    controller.text = newText;
                    controller.marks = _addMarkToRange(
                      controller.marks,
                      MarkType.link,
                      start,
                      start + linkText.length,
                      href: linkUrl,
                    );
                    controller.selection = TextSelection.collapsed(offset: start + linkText.length);
                  } else {
                    toggleMark(MarkType.link, href: linkUrl);
                  }
                }
                Navigator.of(context).pop();
                _focusNodes[activeIndex].requestFocus();
              },
              child: const Text('Insert'),
            ),
          ],
        );
      },
    );
  }

  void _handleEnter(int index) {
    final controller = _controllers[index];
    final text = controller.text;
    final sel = controller.selection.isValid ? controller.selection : TextSelection.collapsed(offset: text.length);
    final cursor = sel.start.clamp(0, text.length);

    final currentBlock = _blocks[index];

    if (text.trim().isEmpty &&
        (currentBlock.type == BlockType.bulletListItem ||
            currentBlock.type == BlockType.numberedListItem ||
            currentBlock.type == BlockType.checklistItem ||
            currentBlock.type == BlockType.heading ||
            currentBlock.type == BlockType.quote)) {
      _blocks[index] = currentBlock.copyWith(type: BlockType.paragraph);
      setState(() {});
      widget.onChanged(_blocks);
      return;
    }

    final leftText = text.substring(0, cursor);
    final rightText = text.substring(cursor);

    final leftMarks = <Mark>[];
    final rightMarks = <Mark>[];

    for (final mark in controller.marks) {
      if (mark.end <= cursor) {
        leftMarks.add(mark);
      } else if (mark.start >= cursor) {
        rightMarks.add(mark.copyWith(
          start: mark.start - cursor,
          end: mark.end - cursor,
        ));
      } else {
        leftMarks.add(mark.copyWith(end: cursor));
        rightMarks.add(mark.copyWith(
          start: 0,
          end: mark.end - cursor,
        ));
      }
    }

    controller.text = leftText;
    controller.marks = leftMarks;
    _blocks[index] = currentBlock.copyWith(text: leftText, marks: leftMarks);

    BlockType newBlockType = BlockType.paragraph;
    if (currentBlock.type == BlockType.bulletListItem ||
        currentBlock.type == BlockType.numberedListItem ||
        currentBlock.type == BlockType.checklistItem) {
      newBlockType = currentBlock.type;
    }

    final newBlock = NoteBlock(
      type: newBlockType,
      text: rightText,
      marks: rightMarks,
    );

    final newController = BlockTextController(text: rightText, marks: rightMarks);
    final newFocusNode = FocusNode();

    newController.addListener(() {
      _onBlockTextChanged(index + 1);
    });
    newFocusNode.addListener(() {
      if (newFocusNode.hasFocus) {
        setState(() {
          _focusedIndex = index + 1;
        });
      }
    });

    _blocks.insert(index + 1, newBlock);
    _controllers.insert(index + 1, newController);
    _focusNodes.insert(index + 1, newFocusNode);

    setState(() {});
    widget.onChanged(_blocks);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (index + 1 < _focusNodes.length) {
        _focusNodes[index + 1].requestFocus();
        _controllers[index + 1].selection = const TextSelection.collapsed(offset: 0);
      }
    });
  }

  void _handleBackspace(int index) {
    if (index < 0 || index >= _blocks.length) return;
    final currentBlock = _blocks[index];
    final controller = _controllers[index];

    if (currentBlock.type != BlockType.paragraph) {
      _blocks[index] = currentBlock.copyWith(type: BlockType.paragraph);
      setState(() {});
      widget.onChanged(_blocks);
      return;
    }

    if (index > 0) {
      final prevIndex = index - 1;
      final prevController = _controllers[prevIndex];
      final prevText = prevController.text;
      final joinOffset = prevText.length;

      final currentText = controller.text;
      final currentMarks = controller.marks;

      final mergedText = prevText + currentText;
      final shiftedMarks = currentMarks
          .map((m) => m.copyWith(start: m.start + joinOffset, end: m.end + joinOffset))
          .toList();

      final mergedMarks = List<Mark>.from(prevController.marks)..addAll(shiftedMarks);

      prevController.text = mergedText;
      prevController.marks = mergedMarks;
      _blocks[prevIndex] = _blocks[prevIndex].copyWith(text: mergedText, marks: mergedMarks);

      _controllers[index].dispose();
      _focusNodes[index].dispose();
      _controllers.removeAt(index);
      _focusNodes.removeAt(index);
      _blocks.removeAt(index);

      setState(() {});
      widget.onChanged(_blocks);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (prevIndex < _focusNodes.length) {
          _focusNodes[prevIndex].requestFocus();
          _controllers[prevIndex].selection = TextSelection.collapsed(offset: joinOffset);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;
    final activeBlue = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600;

    int numberedIndex = 1;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _blocks.length,
      itemBuilder: (context, index) {
        final block = _blocks[index];
        final controller = _controllers[index];
        final focusNode = _focusNodes[index];

        if (block.type == BlockType.numberedListItem) {
          if (index == 0 || _blocks[index - 1].type != BlockType.numberedListItem) {
            numberedIndex = 1;
          }
        } else {
          numberedIndex = 1;
        }

        Widget prefixWidget = const SizedBox.shrink();

        switch (block.type) {
          case BlockType.paragraph:
            break;
          case BlockType.bulletListItem:
            prefixWidget = Padding(
              padding: const EdgeInsets.only(right: 10, top: 4),
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: activeBlue,
                  shape: BoxShape.circle,
                ),
              ),
            );
            break;
          case BlockType.numberedListItem:
            final numStr = '$numberedIndex.';
            numberedIndex++;
            prefixWidget = Padding(
              padding: const EdgeInsets.only(right: 8, top: 2),
              child: Text(
                numStr,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: activeBlue,
                ),
              ),
            );
            break;
          case BlockType.checklistItem:
            prefixWidget = Padding(
              padding: const EdgeInsets.only(right: 10, top: 2),
              child: GestureDetector(
                onTap: () {
                  final newChecked = !block.checked;
                  _blocks[index] = block.copyWith(checked: newChecked);
                  setState(() {});
                  widget.onChanged(_blocks);
                },
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: block.checked ? activeBlue : Colors.transparent,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: block.checked ? activeBlue : textTertiary,
                      width: 1.5,
                    ),
                  ),
                  child: block.checked
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : null,
                ),
              ),
            );
            break;
          case BlockType.heading:
            prefixWidget = const SizedBox.shrink();
            break;
          case BlockType.quote:
            prefixWidget = Container(
              margin: const EdgeInsets.only(right: 12),
              width: 3.5,
              height: 28,
              decoration: BoxDecoration(
                color: activeBlue,
                borderRadius: BorderRadius.circular(2),
              ),
            );
            break;
        }

        final isCheckedItem = block.checked && block.type == BlockType.checklistItem;

        TextStyle textStyle = TextStyle(
          fontSize: block.type == BlockType.heading ? 22 : 15,
          fontWeight: block.type == BlockType.heading ? FontWeight.w800 : FontWeight.normal,
          fontStyle: block.type == BlockType.quote ? FontStyle.italic : FontStyle.normal,
          color: isCheckedItem ? textTertiary : textPrimary,
          decoration: isCheckedItem ? TextDecoration.lineThrough : null,
          height: 1.6,
        );

        Widget blockContent = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            prefixWidget,
            Expanded(
              child: KeyboardListener(
                focusNode: FocusNode(),
                onKeyEvent: (event) {
                  if (event is KeyDownEvent) {
                    if (event.logicalKey == LogicalKeyboardKey.enter) {
                      _handleEnter(index);
                    } else if (event.logicalKey == LogicalKeyboardKey.backspace) {
                      if (controller.selection.isCollapsed && controller.selection.start == 0) {
                        _handleBackspace(index);
                      }
                    }
                  }
                },
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  style: textStyle,
                  decoration: InputDecoration(
                    filled: false,
                    fillColor: Colors.transparent,
                    hintText: index == 0 && _blocks.length == 1 ? 'Start writing...' : '',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintStyle: TextStyle(color: textTertiary),
                  ),
                ),
              ),
            ),
          ],
        );

        if (block.type == BlockType.quote) {
          blockContent = Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: activeBlue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: blockContent,
          );
        }

        return Padding(
          padding: EdgeInsets.only(
            top: block.type == BlockType.heading ? 12 : 4,
            bottom: 4,
          ),
          child: blockContent,
        );
      },
    );
  }
}
