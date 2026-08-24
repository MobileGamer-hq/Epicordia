import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../domain/models/note_model.dart';
import '../theme.dart';

/// A utility to format note content (both structured JSON blocks and legacy raw markdown)
/// into styled [TextSpan] trees for note titles, previews, cards, and dialogs.
class MarkdownFormatter {
  /// Converts note content string (structured JSON blocks or legacy markdown) into a styled [TextSpan] tree.
  /// If [isTitle] is true, header `#` prefixes are stripped and formatted as bold title text.
  static TextSpan formatToTextSpan(
    String content, {
    required TextStyle baseStyle,
    Color? activeBlue,
    bool isTitle = false,
    void Function(String label, String url)? onLinkTap,
  }) {
    if (content.isEmpty) {
      return TextSpan(text: content, style: baseStyle);
    }

    final blocks = NoteDocument.decodeBlocks(content);
    return formatBlocksToTextSpan(
      blocks,
      baseStyle: baseStyle,
      activeBlue: activeBlue,
      isTitle: isTitle,
      onLinkTap: onLinkTap,
    );
  }

  /// Converts a list of [NoteBlock]s into a styled [TextSpan] tree.
  static TextSpan formatBlocksToTextSpan(
    List<NoteBlock> blocks, {
    required TextStyle baseStyle,
    Color? activeBlue,
    bool isTitle = false,
    void Function(String label, String url)? onLinkTap,
  }) {
    if (blocks.isEmpty) {
      return TextSpan(style: baseStyle, text: '');
    }

    final lineSpans = <TextSpan>[];
    int numberedCounter = 1;

    for (int i = 0; i < blocks.length; i++) {
      final block = blocks[i];

      if (block.type == BlockType.numberedListItem) {
        if (i == 0 || blocks[i - 1].type != BlockType.numberedListItem) {
          numberedCounter = block.listIndex ?? 1;
        }
      } else {
        numberedCounter = 1;
      }

      TextStyle blockStyle = baseStyle;
      String prefix = '';

      if (isTitle) {
        // Strip block markers if formatting a single title line
        blockStyle = baseStyle.copyWith(fontWeight: FontWeight.bold);
      } else {
        switch (block.type) {
          case BlockType.paragraph:
            break;
          case BlockType.bulletListItem:
            prefix = '• ';
            break;
          case BlockType.numberedListItem:
            prefix = '$numberedCounter. ';
            numberedCounter++;
            break;
          case BlockType.checklistItem:
            prefix = block.checked ? '☑ ' : '☐ ';
            break;
          case BlockType.heading:
            blockStyle = baseStyle.copyWith(
              fontSize: (baseStyle.fontSize ?? 14) * 1.25,
              fontWeight: FontWeight.w800,
            );
            break;
          case BlockType.quote:
            prefix = '│ ';
            blockStyle = baseStyle.copyWith(
              fontStyle: FontStyle.italic,
              color: (baseStyle.color ?? Colors.black).withValues(alpha: 0.75),
            );
            break;
        }
      }

      final children = <TextSpan>[];

      if (prefix.isNotEmpty) {
        children.add(TextSpan(
          text: prefix,
          style: blockStyle.copyWith(
            fontWeight: FontWeight.bold,
            color: activeBlue ?? EpicordiaColors.blue600,
          ),
        ));
      }

      // Render inline marks over plain text
      final inlineSpan = buildInlineTextSpan(
        block.text,
        block.marks,
        baseStyle: blockStyle,
        activeBlue: activeBlue,
        onLinkTap: onLinkTap,
      );

      children.add(inlineSpan);

      lineSpans.add(TextSpan(
        children: children,
        style: blockStyle,
      ));

      if (i < blocks.length - 1) {
        lineSpans.add(const TextSpan(text: '\n'));
      }
    }

    return TextSpan(style: baseStyle, children: lineSpans);
  }

  /// Map inline marks over plain text to styled [TextSpan]s.
  static TextSpan buildInlineTextSpan(
    String text,
    List<Mark> marks, {
    required TextStyle baseStyle,
    Color? activeBlue,
    void Function(String label, String url)? onLinkTap,
  }) {
    if (text.isEmpty) {
      return TextSpan(text: '', style: baseStyle);
    }
    if (marks.isEmpty) {
      return TextSpan(text: text, style: baseStyle);
    }

    // Collect all boundary offsets (0, text.length, mark.start, mark.end)
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

      // Find all active marks covering this chunk
      final activeMarks = marks.where((m) => m.start <= start && m.end >= end).toList();

      TextStyle spanStyle = baseStyle;
      String? linkUrl;

      for (final mark in activeMarks) {
        switch (mark.type) {
          case MarkType.bold:
            spanStyle = spanStyle.copyWith(fontWeight: FontWeight.w700);
            break;
          case MarkType.italic:
            spanStyle = spanStyle.copyWith(fontStyle: FontStyle.italic);
            break;
          case MarkType.underline:
            spanStyle = spanStyle.copyWith(decoration: TextDecoration.underline);
            break;
          case MarkType.strikethrough:
            spanStyle = spanStyle.copyWith(decoration: TextDecoration.lineThrough);
            break;
          case MarkType.link:
            linkUrl = mark.href;
            spanStyle = spanStyle.copyWith(
              color: activeBlue ?? EpicordiaColors.blue600,
              decoration: TextDecoration.underline,
            );
            break;
        }
      }

      TapGestureRecognizer? recognizer;
      if (linkUrl != null && linkUrl.isNotEmpty) {
        final url = linkUrl;
        recognizer = TapGestureRecognizer()
          ..onTap = () {
            if (onLinkTap != null) {
              onLinkTap(chunkText, url);
            }
          };
      }

      spans.add(TextSpan(
        text: chunkText,
        style: spanStyle,
        recognizer: recognizer,
      ));
    }

    return TextSpan(children: spans, style: baseStyle);
  }
}
