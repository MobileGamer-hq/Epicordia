import 'package:flutter/material.dart';
import '../theme.dart';

/// A custom TextEditingController that styles Markdown syntax in real-time
/// within a standard TextField, making headings, bold text, lists, and quotes
/// visually formatted without raw unstyled token clutter.
class MarkdownTextEditingController extends TextEditingController {
  MarkdownTextEditingController({super.text});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseStyle = style ??
        TextStyle(
          fontSize: 16,
          height: 1.6,
          color: isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight,
        );

    final activeBlue = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600;
    final syntaxColor = (baseStyle.color ?? Colors.grey).withValues(alpha: 0.35);

    if (text.isEmpty) {
      return TextSpan(style: baseStyle, text: '');
    }

    final lines = text.split('\n');
    final lineSpans = <TextSpan>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      lineSpans.add(_formatLine(line, baseStyle, activeBlue, syntaxColor));

      if (i < lines.length - 1) {
        lineSpans.add(const TextSpan(text: '\n'));
      }
    }

    return TextSpan(style: baseStyle, children: lineSpans);
  }

  TextSpan _formatLine(
    String line,
    TextStyle baseStyle,
    Color activeBlue,
    Color syntaxColor,
  ) {
    if (line.isEmpty) {
      return TextSpan(text: '', style: baseStyle);
    }

    // 1. Headings (# Heading, ## Heading, ### Heading)
    final headingMatch = RegExp(r'^(#{1,6})(\s+)(.*)$').firstMatch(line);
    if (headingMatch != null) {
      final hashes = headingMatch.group(1)!;
      final space = headingMatch.group(2)!;
      final content = headingMatch.group(3)!;

      final double scale = switch (hashes.length) {
        1 => 1.45,
        2 => 1.30,
        3 => 1.18,
        _ => 1.10,
      };

      final headingStyle = baseStyle.copyWith(
        fontSize: (baseStyle.fontSize ?? 16) * scale,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      );

      return TextSpan(
        style: headingStyle,
        children: [
          TextSpan(text: hashes, style: headingStyle.copyWith(color: syntaxColor, fontWeight: FontWeight.normal)),
          TextSpan(text: space, style: headingStyle),
          ..._formatInline(content, headingStyle, activeBlue, syntaxColor),
        ],
      );
    }

    // 2. Checklist items ([ ] todo, [x] done)
    final checkMatch = RegExp(r'^(\[([ xX])\])(\s+)(.*)$').firstMatch(line);
    if (checkMatch != null) {
      final isDone = checkMatch.group(2)!.toLowerCase() == 'x';
      final space = checkMatch.group(3)!;
      final content = checkMatch.group(4)!;

      final checkStyle = isDone
          ? baseStyle.copyWith(
              decoration: TextDecoration.lineThrough,
              color: baseStyle.color?.withValues(alpha: 0.55),
            )
          : baseStyle;

      return TextSpan(
        style: checkStyle,
        children: [
          TextSpan(
            text: isDone ? '[x]' : '[ ]',
            style: baseStyle.copyWith(
              color: isDone ? activeBlue : syntaxColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: space, style: checkStyle),
          ..._formatInline(content, checkStyle, activeBlue, syntaxColor),
        ],
      );
    }

    // 3. Bullet list items (- item, * item)
    final bulletMatch = RegExp(r'^([\*\-\+])(\s+)(.*)$').firstMatch(line);
    if (bulletMatch != null) {
      final bullet = bulletMatch.group(1)!;
      final space = bulletMatch.group(2)!;
      final content = bulletMatch.group(3)!;

      return TextSpan(
        style: baseStyle,
        children: [
          TextSpan(
            text: bullet,
            style: baseStyle.copyWith(
              color: activeBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: space, style: baseStyle),
          ..._formatInline(content, baseStyle, activeBlue, syntaxColor),
        ],
      );
    }

    // 4. Numbered list items (1. item)
    final numberMatch = RegExp(r'^(\d+\.)(\s+)(.*)$').firstMatch(line);
    if (numberMatch != null) {
      final numPrefix = numberMatch.group(1)!;
      final space = numberMatch.group(2)!;
      final content = numberMatch.group(3)!;

      return TextSpan(
        style: baseStyle,
        children: [
          TextSpan(
            text: numPrefix,
            style: baseStyle.copyWith(
              color: activeBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: space, style: baseStyle),
          ..._formatInline(content, baseStyle, activeBlue, syntaxColor),
        ],
      );
    }

    // 5. Blockquote (> quote)
    final quoteMatch = RegExp(r'^(>)(\s*)(.*)$').firstMatch(line);
    if (quoteMatch != null) {
      final quoteSymbol = quoteMatch.group(1)!;
      final space = quoteMatch.group(2)!;
      final content = quoteMatch.group(3)!;

      final quoteStyle = baseStyle.copyWith(
        fontStyle: FontStyle.italic,
        color: baseStyle.color?.withValues(alpha: 0.85),
      );

      return TextSpan(
        style: quoteStyle,
        children: [
          TextSpan(
            text: quoteSymbol,
            style: quoteStyle.copyWith(color: activeBlue, fontWeight: FontWeight.bold),
          ),
          TextSpan(text: space, style: quoteStyle),
          ..._formatInline(content, quoteStyle, activeBlue, syntaxColor),
        ],
      );
    }

    // Default paragraph line with inline formatting
    return TextSpan(
      style: baseStyle,
      children: _formatInline(line, baseStyle, activeBlue, syntaxColor),
    );
  }

  List<TextSpan> _formatInline(
    String text,
    TextStyle baseStyle,
    Color activeBlue,
    Color syntaxColor,
  ) {
    if (text.isEmpty) return [TextSpan(text: '', style: baseStyle)];

    final spans = <TextSpan>[];
    final inlineRegex = RegExp(
      r'(\*\*[^\n]+?\*\*)|(\*[^\*\n]+?\*)|(~~[^\n]+?~~)|(`[^\n`]+?`)|(\[[^\]\n]+?\]\([^\)\n]+?\))',
    );

    int lastIndex = 0;

    for (final match in inlineRegex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: baseStyle,
        ));
      }

      final matchedStr = match.group(0)!;

      if (matchedStr.startsWith('**') && matchedStr.endsWith('**') && matchedStr.length >= 4) {
        // Bold
        final inner = matchedStr.substring(2, matchedStr.length - 2);
        spans.add(TextSpan(
          children: [
            TextSpan(text: '**', style: baseStyle.copyWith(color: syntaxColor)),
            TextSpan(text: inner, style: baseStyle.copyWith(fontWeight: FontWeight.w800)),
            TextSpan(text: '**', style: baseStyle.copyWith(color: syntaxColor)),
          ],
        ));
      } else if (matchedStr.startsWith('*') && matchedStr.endsWith('*') && matchedStr.length >= 2) {
        // Italic
        final inner = matchedStr.substring(1, matchedStr.length - 1);
        spans.add(TextSpan(
          children: [
            TextSpan(text: '*', style: baseStyle.copyWith(color: syntaxColor)),
            TextSpan(text: inner, style: baseStyle.copyWith(fontStyle: FontStyle.italic)),
            TextSpan(text: '*', style: baseStyle.copyWith(color: syntaxColor)),
          ],
        ));
      } else if (matchedStr.startsWith('~~') && matchedStr.endsWith('~~') && matchedStr.length >= 4) {
        // Strikethrough
        final inner = matchedStr.substring(2, matchedStr.length - 2);
        spans.add(TextSpan(
          children: [
            TextSpan(text: '~~', style: baseStyle.copyWith(color: syntaxColor)),
            TextSpan(text: inner, style: baseStyle.copyWith(decoration: TextDecoration.lineThrough)),
            TextSpan(text: '~~', style: baseStyle.copyWith(color: syntaxColor)),
          ],
        ));
      } else if (matchedStr.startsWith('`') && matchedStr.endsWith('`') && matchedStr.length >= 2) {
        // Inline code
        final inner = matchedStr.substring(1, matchedStr.length - 1);
        spans.add(TextSpan(
          children: [
            TextSpan(text: '`', style: baseStyle.copyWith(color: syntaxColor)),
            TextSpan(
              text: inner,
              style: baseStyle.copyWith(
                fontFamily: 'monospace',
                backgroundColor: activeBlue.withValues(alpha: 0.12),
              ),
            ),
            TextSpan(text: '`', style: baseStyle.copyWith(color: syntaxColor)),
          ],
        ));
      } else if (matchedStr.startsWith('[') && matchedStr.contains('](') && matchedStr.endsWith(')')) {
        // Link [label](url)
        final labelEnd = matchedStr.indexOf('](');
        final label = matchedStr.substring(1, labelEnd);
        final url = matchedStr.substring(labelEnd + 2, matchedStr.length - 1);

        spans.add(TextSpan(
          children: [
            TextSpan(text: '[', style: baseStyle.copyWith(color: syntaxColor)),
            TextSpan(
              text: label,
              style: baseStyle.copyWith(
                color: activeBlue,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(text: ']($url)', style: baseStyle.copyWith(color: syntaxColor, fontSize: (baseStyle.fontSize ?? 16) * 0.85)),
          ],
        ));
      } else {
        spans.add(TextSpan(text: matchedStr, style: baseStyle));
      }

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: baseStyle,
      ));
    }

    return spans;
  }
}
