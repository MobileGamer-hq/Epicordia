import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// A utility to format markdown text strings into styled [TextSpan]s
/// for note titles, previews, and cards throughout the app.
class MarkdownFormatter {
  static final RegExp _inlinePattern = RegExp(
    r'(\*\*.*?\*\*)|(\*[^\*\n]+?\*)|(<u>.*?</u>)|(~~.*?~~)|(\[[^\]]*?\]\([^\)]*?\))',
    dotAll: true,
  );

  /// Converts raw markdown text into a styled [TextSpan] tree.
  /// If [isTitle] is true, header `#` prefixes are stripped and formatted as bold title text.
  static TextSpan formatToTextSpan(
    String text, {
    required TextStyle baseStyle,
    Color? activeBlue,
    bool isTitle = false,
    void Function(String label, String url)? onLinkTap,
  }) {
    if (text.isEmpty) {
      return TextSpan(text: text, style: baseStyle);
    }

    final lines = text.split('\n');
    final lineSpans = <TextSpan>[];

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];

      // Handle block level prefixes for lines (bullet list, numbered list, headers)
      String prefix = '';
      TextStyle lineBaseStyle = baseStyle;

      if (!isTitle) {
        if (RegExp(r'^[\*\-\+]\s+').hasMatch(line)) {
          prefix = '• ';
          line = line.replaceFirst(RegExp(r'^[\*\-\+]\s+'), '');
        } else if (RegExp(r'^\d+\.\s+').hasMatch(line)) {
          final match = RegExp(r'^\d+\.\s+').firstMatch(line)!;
          prefix = match.group(0)!;
          line = line.substring(match.end);
        } else if (line.startsWith('#')) {
          final headerMatch = RegExp(r'^#+\s*').firstMatch(line);
          if (headerMatch != null) {
            line = line.substring(headerMatch.end);
            lineBaseStyle = baseStyle.copyWith(fontWeight: FontWeight.bold);
          }
        }
      } else {
        if (line.startsWith('#')) {
          final headerMatch = RegExp(r'^#+\s*').firstMatch(line);
          if (headerMatch != null) {
            line = line.substring(headerMatch.end);
          }
        }
      }

      final children = <TextSpan>[];
      if (prefix.isNotEmpty) {
        children.add(TextSpan(
          text: prefix,
          style: lineBaseStyle.copyWith(fontWeight: FontWeight.bold),
        ));
      }

      // Parse inline markdown syntax for this line
      int pos = 0;
      for (final match in _inlinePattern.allMatches(line)) {
        if (match.start > pos) {
          children.add(TextSpan(
            text: line.substring(pos, match.start),
            style: lineBaseStyle,
          ));
        }

        final token = match.group(0)!;
        children.add(_styledInlineSpan(token, lineBaseStyle, activeBlue, onLinkTap));
        pos = match.end;
      }

      if (pos < line.length) {
        children.add(TextSpan(
          text: line.substring(pos),
          style: lineBaseStyle,
        ));
      }

      lineSpans.add(TextSpan(
        children: children,
        style: lineBaseStyle,
      ));

      if (i < lines.length - 1) {
        lineSpans.add(const TextSpan(text: '\n'));
      }
    }

    return TextSpan(style: baseStyle, children: lineSpans);
  }

  static TextSpan _styledInlineSpan(
    String token,
    TextStyle baseStyle,
    Color? activeBlue,
    void Function(String label, String url)? onLinkTap,
  ) {
    // Bold: **text**
    if (token.startsWith('**') && token.endsWith('**') && token.length >= 4) {
      final inner = token.substring(2, token.length - 2);
      return TextSpan(
        text: inner,
        style: baseStyle.copyWith(fontWeight: FontWeight.w700),
      );
    }

    // Underline: <u>text</u>
    if (token.startsWith('<u>') && token.endsWith('</u>') && token.length >= 7) {
      final inner = token.substring(3, token.length - 4);
      return TextSpan(
        text: inner,
        style: baseStyle.copyWith(decoration: TextDecoration.underline),
      );
    }

    // Strikethrough: ~~text~~
    if (token.startsWith('~~') && token.endsWith('~~') && token.length >= 4) {
      final inner = token.substring(2, token.length - 2);
      return TextSpan(
        text: inner,
        style: baseStyle.copyWith(decoration: TextDecoration.lineThrough),
      );
    }

    // Link: [label](url)
    if (token.startsWith('[') && token.contains('](') && token.endsWith(')')) {
      final closeBracket = token.indexOf(']');
      final label = token.substring(1, closeBracket);
      final url = token.substring(closeBracket + 2, token.length - 1);
      return TextSpan(
        text: label,
        style: baseStyle.copyWith(
          color: activeBlue ?? Colors.blue,
          decoration: TextDecoration.underline,
        ),
        recognizer: onLinkTap != null
            ? (TapGestureRecognizer()..onTap = () => onLinkTap(label, url))
            : null,
      );
    }

    // Italic: *text*
    if (token.startsWith('*') && token.endsWith('*') && token.length >= 2) {
      final inner = token.substring(1, token.length - 1);
      return TextSpan(
        text: inner,
        style: baseStyle.copyWith(fontStyle: FontStyle.italic),
      );
    }

    return TextSpan(text: token, style: baseStyle);
  }
}
