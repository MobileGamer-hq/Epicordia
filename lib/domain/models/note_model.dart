import 'dart:convert';
import 'package:uuid/uuid.dart';

enum MarkType {
  bold,
  italic,
  underline,
  strikethrough,
  link,
}

class Mark {
  final MarkType type;
  final int start; // inclusive char offset into Block.text
  final int end;   // exclusive char offset into Block.text
  final String? href; // only for link marks

  const Mark({
    required this.type,
    required this.start,
    required this.end,
    this.href,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'start': start,
      'end': end,
      if (href != null) 'href': href,
    };
  }

  factory Mark.fromJson(Map<String, dynamic> json) {
    return Mark(
      type: MarkType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MarkType.bold,
      ),
      start: json['start'] as int,
      end: json['end'] as int,
      href: json['href'] as String?,
    );
  }

  Mark copyWith({
    MarkType? type,
    int? start,
    int? end,
    String? href,
  }) {
    return Mark(
      type: type ?? this.type,
      start: start ?? this.start,
      end: end ?? this.end,
      href: href ?? this.href,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Mark &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          start == other.start &&
          end == other.end &&
          href == other.href;

  @override
  int get hashCode => type.hashCode ^ start.hashCode ^ end.hashCode ^ href.hashCode;
}

enum BlockType {
  paragraph,
  bulletListItem,
  numberedListItem,
  checklistItem,
  heading,
  quote,
}

class NoteBlock {
  final String id;
  final BlockType type;
  final String text; // PLAIN text only, no raw markdown symbols
  final List<Mark> marks;
  final int indentLevel;
  final bool checked; // for checklistItem
  final int? listIndex; // computed or stored for numberedListItem

  NoteBlock({
    String? id,
    this.type = BlockType.paragraph,
    this.text = '',
    List<Mark>? marks,
    this.indentLevel = 0,
    this.checked = false,
    this.listIndex,
  })  : id = id ?? const Uuid().v4(),
        marks = marks != null ? List.unmodifiable(marks) : const [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'text': text,
      'marks': marks.map((m) => m.toJson()).toList(),
      'indentLevel': indentLevel,
      'checked': checked,
      if (listIndex != null) 'listIndex': listIndex,
    };
  }

  factory NoteBlock.fromJson(Map<String, dynamic> json) {
    return NoteBlock(
      id: json['id'] as String?,
      type: BlockType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => BlockType.paragraph,
      ),
      text: json['text'] as String? ?? '',
      marks: (json['marks'] as List<dynamic>?)
              ?.map((m) => Mark.fromJson(m as Map<String, dynamic>))
              .toList() ??
          const [],
      indentLevel: json['indentLevel'] as int? ?? 0,
      checked: json['checked'] as bool? ?? false,
      listIndex: json['listIndex'] as int?,
    );
  }

  NoteBlock copyWith({
    String? id,
    BlockType? type,
    String? text,
    List<Mark>? marks,
    int? indentLevel,
    bool? checked,
    int? listIndex,
  }) {
    return NoteBlock(
      id: id ?? this.id,
      type: type ?? this.type,
      text: text ?? this.text,
      marks: marks ?? this.marks,
      indentLevel: indentLevel ?? this.indentLevel,
      checked: checked ?? this.checked,
      listIndex: listIndex ?? this.listIndex,
    );
  }
}

enum PenTool {
  pen,
  highlighter,
  pencil,
  eraser,
}

class PenPoint {
  final double x;
  final double y;
  final double pressure;

  const PenPoint(this.x, this.y, [this.pressure = 1.0]);

  List<dynamic> toJson() => [x, y, pressure];

  factory PenPoint.fromJson(List<dynamic> json) {
    return PenPoint(
      (json[0] as num).toDouble(),
      (json[1] as num).toDouble(),
      json.length > 2 ? (json[2] as num).toDouble() : 1.0,
    );
  }
}

class PenStroke {
  final List<PenPoint> points;
  final String color;
  final double widthPx;
  final double opacity;
  final PenTool tool;

  const PenStroke({
    required this.points,
    required this.color,
    required this.widthPx,
    this.opacity = 1.0,
    this.tool = PenTool.pen,
  });

  Map<String, dynamic> toJson() => {
        'points': points.map((p) => p.toJson()).toList(),
        'color': color,
        'widthPx': widthPx,
        'opacity': opacity,
        'tool': tool.name,
      };

  factory PenStroke.fromJson(Map<String, dynamic> json) {
    final rawPoints = (json['points'] as List<dynamic>? ?? []);
    return PenStroke(
      points: rawPoints.map((p) => PenPoint.fromJson(p as List<dynamic>)).toList(),
      color: json['color'] as String? ?? '#16181C',
      widthPx: (json['widthPx'] as num?)?.toDouble() ?? 3.0,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      tool: PenTool.values.firstWhere(
        (e) => e.name == json['tool'],
        orElse: () => PenTool.pen,
      ),
    );
  }
}

class NoteDrawingData {
  final List<PenStroke> strokes;

  const NoteDrawingData({this.strokes = const []});

  bool get isEmpty => strokes.isEmpty;
  bool get isNotEmpty => strokes.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'strokes': strokes.map((s) => s.toJson()).toList(),
      };

  factory NoteDrawingData.fromJson(Map<String, dynamic> json) {
    final rawStrokes = json['strokes'] as List<dynamic>? ?? [];
    return NoteDrawingData(
      strokes: rawStrokes.map((s) => PenStroke.fromJson(s as Map<String, dynamic>)).toList(),
    );
  }
}

class NoteDocumentPayload {
  final List<NoteBlock> blocks;
  final NoteDrawingData drawing;

  const NoteDocumentPayload({
    required this.blocks,
    this.drawing = const NoteDrawingData(),
  });
}

class NoteDocument {
  /// Extract a clean title string from note content (whether structured JSON or markdown).
  static String extractTitle(String content) {
    if (content.trim().isEmpty) return 'Untitled Note';
    final payload = decode(content);
    if (payload.blocks.isNotEmpty) {
      final first = payload.blocks.first;
      if (first.text.trim().isNotEmpty) {
        return first.text.trim();
      }
      for (final b in payload.blocks.sublist(1)) {
        if (b.text.trim().isNotEmpty) {
          return b.text.trim();
        }
      }
    }
    return 'Untitled Note';
  }

  /// Extract clean plain text from note blocks for search and activity logging.
  static String extractPlainText(String content) {
    if (content.trim().isEmpty) return '';
    final payload = decode(content);
    return payload.blocks.map((b) => b.text).where((t) => t.trim().isNotEmpty).join(' ');
  }

  /// Check if stored text content is in structured JSON format (`blocks_v1` or `v2_payload`).
  static bool isJsonBlocks(String content) {
    final trimmed = content.trim();
    if (trimmed.startsWith('[')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is List) {
          if (decoded.isEmpty) return true;
          if (decoded.first is Map && (decoded.first as Map).containsKey('type')) {
            return true;
          }
        }
      } catch (_) {}
    } else if (trimmed.startsWith('{')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map && decoded.containsKey('blocks')) {
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  /// Decode text content into a complete `NoteDocumentPayload` (blocks + pen drawing overlay).
  static NoteDocumentPayload decode(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      return NoteDocumentPayload(
        blocks: [NoteBlock(type: BlockType.paragraph, text: '')],
        drawing: const NoteDrawingData(),
      );
    }

    if (isJsonBlocks(trimmed)) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map<String, dynamic>) {
          final rawBlocks = decoded['blocks'] as List<dynamic>? ?? [];
          final blocks = rawBlocks
              .map((b) => NoteBlock.fromJson(b as Map<String, dynamic>))
              .toList();
          final drawingJson = decoded['drawing'] as Map<String, dynamic>?;
          final drawing = drawingJson != null
              ? NoteDrawingData.fromJson(drawingJson)
              : const NoteDrawingData();
          return NoteDocumentPayload(
            blocks: blocks.isNotEmpty ? blocks : [NoteBlock(type: BlockType.paragraph, text: '')],
            drawing: drawing,
          );
        } else if (decoded is List<dynamic>) {
          final blocks = decoded
              .map((b) => NoteBlock.fromJson(b as Map<String, dynamic>))
              .toList();
          return NoteDocumentPayload(
            blocks: blocks.isNotEmpty ? blocks : [NoteBlock(type: BlockType.paragraph, text: '')],
            drawing: const NoteDrawingData(),
          );
        }
      } catch (_) {}
    }

    return NoteDocumentPayload(
      blocks: parseLegacyMarkdown(content),
      drawing: const NoteDrawingData(),
    );
  }

  /// Encode full `NoteDocumentPayload` into JSON.
  static String encode(NoteDocumentPayload payload) {
    if (payload.drawing.isEmpty) {
      return jsonEncode(payload.blocks.map((b) => b.toJson()).toList());
    }
    return jsonEncode({
      'version': 2,
      'blocks': payload.blocks.map((b) => b.toJson()).toList(),
      'drawing': payload.drawing.toJson(),
    });
  }

  /// Decode text content into `List<NoteBlock>`.
  /// Automatically parses legacy markdown strings into `NoteBlock` objects.
  static List<NoteBlock> decodeBlocks(String content) {
    return decode(content).blocks;
  }

  /// Serialize `List<NoteBlock>` into a JSON string.
  static String encodeBlocks(List<NoteBlock> blocks) {
    return jsonEncode(blocks.map((b) => b.toJson()).toList());
  }

  /// Convert blocks to clean Markdown string for copying, sharing, or export.
  static String exportToMarkdown(List<NoteBlock> blocks) {
    final buffer = StringBuffer();
    int numberedCounter = 1;

    for (int i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      if (block.type == BlockType.numberedListItem) {
        if (i == 0 || blocks[i - 1].type != BlockType.numberedListItem) {
          numberedCounter = 1;
        }
      } else {
        numberedCounter = 1;
      }

      // Build formatted text with markdown symbols for marks
      final formattedText = _applyMarksToMarkdown(block.text, block.marks);

      switch (block.type) {
        case BlockType.paragraph:
          buffer.write(formattedText);
          break;
        case BlockType.bulletListItem:
          buffer.write('- $formattedText');
          break;
        case BlockType.numberedListItem:
          buffer.write('$numberedCounter. $formattedText');
          numberedCounter++;
          break;
        case BlockType.checklistItem:
          final checkStr = block.checked ? '[x]' : '[ ]';
          buffer.write('$checkStr $formattedText');
          break;
        case BlockType.heading:
          buffer.write('# $formattedText');
          break;
        case BlockType.quote:
          buffer.write('> $formattedText');
          break;
      }

      if (i < blocks.length - 1) {
        buffer.write('\n');
      }
    }

    return buffer.toString();
  }

  /// Parse legacy raw markdown string into a `List<NoteBlock>`.
  static List<NoteBlock> parseLegacyMarkdown(String rawContent) {
    if (rawContent.trim().isEmpty) {
      return [NoteBlock(type: BlockType.paragraph, text: '')];
    }

    final lines = rawContent.split('\n');
    final blocks = <NoteBlock>[];
    int numberedCounter = 1;

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];
      BlockType type = BlockType.paragraph;
      bool checked = false;

      // 1. Check line-level block prefixes
      if (RegExp(r'^[\*\-\+]\s+').hasMatch(line)) {
        type = BlockType.bulletListItem;
        line = line.replaceFirst(RegExp(r'^[\*\-\+]\s+'), '');
      } else if (RegExp(r'^\d+\.\s+').hasMatch(line)) {
        type = BlockType.numberedListItem;
        final match = RegExp(r'^\d+\.\s+').firstMatch(line)!;
        numberedCounter = int.tryParse(match.group(0)!.split('.').first) ?? numberedCounter;
        line = line.substring(match.end);
      } else if (RegExp(r'^\[([ xX])\]\s+').hasMatch(line)) {
        type = BlockType.checklistItem;
        final match = RegExp(r'^\[([ xX])\]\s+').firstMatch(line)!;
        checked = match.group(1)!.toLowerCase() == 'x';
        line = line.substring(match.end);
      } else if (line.startsWith('#')) {
        type = BlockType.heading;
        final headerMatch = RegExp(r'^#+\s*').firstMatch(line);
        if (headerMatch != null) {
          line = line.substring(headerMatch.end);
        }
      } else if (line.startsWith('>')) {
        type = BlockType.quote;
        final quoteMatch = RegExp(r'^>\s*').firstMatch(line);
        if (quoteMatch != null) {
          line = line.substring(quoteMatch.end);
        }
      }

      // 2. Extract inline formatting marks and build plain text
      final extracted = _extractMarksFromLine(line);

      blocks.add(NoteBlock(
        type: type,
        text: extracted.plainText,
        marks: extracted.marks,
        checked: checked,
        listIndex: type == BlockType.numberedListItem ? numberedCounter : null,
      ));

      if (type == BlockType.numberedListItem) {
        numberedCounter++;
      } else {
        numberedCounter = 1;
      }
    }

    return blocks.isNotEmpty ? blocks : [NoteBlock(type: BlockType.paragraph, text: '')];
  }

  /// Extracts inline markdown tokens (**bold**, *italic*, <u>underline</u>, ~~strikethrough~~, [label](url))
  /// and calculates exact character ranges in the resulting plain text string.
  static _ExtractedLine _extractMarksFromLine(String line) {
    if (line.isEmpty) return _ExtractedLine('', const []);

    final RegExp inlinePattern = RegExp(
      r'(\*\*[^\n]*?\*\*)|(\*[^\*\n]+?\*)|(<u>[^\n]*?</u>)|(~~[^\n]*?~~)|(\[[^\]\n]*?\]\([^\)\n]*?\))',
    );

    final marks = <Mark>[];
    final sb = StringBuffer();

    int lastEnd = 0;

    for (final match in inlinePattern.allMatches(line)) {
      if (match.start > lastEnd) {
        sb.write(line.substring(lastEnd, match.start));
      }

      final token = match.group(0)!;
      final startOffset = sb.length;

      if (token.startsWith('**') && token.endsWith('**') && token.length >= 4) {
        final inner = token.substring(2, token.length - 2);
        sb.write(inner);
        marks.add(Mark(type: MarkType.bold, start: startOffset, end: startOffset + inner.length));
      } else if (token.startsWith('<u>') && token.endsWith('</u>') && token.length >= 7) {
        final inner = token.substring(3, token.length - 4);
        sb.write(inner);
        marks.add(Mark(type: MarkType.underline, start: startOffset, end: startOffset + inner.length));
      } else if (token.startsWith('~~') && token.endsWith('~~') && token.length >= 4) {
        final inner = token.substring(2, token.length - 2);
        sb.write(inner);
        marks.add(Mark(type: MarkType.strikethrough, start: startOffset, end: startOffset + inner.length));
      } else if (token.startsWith('[') && token.contains('](') && token.endsWith(')')) {
        final closeBracket = token.indexOf(']');
        final label = token.substring(1, closeBracket);
        final url = token.substring(closeBracket + 2, token.length - 1);
        sb.write(label);
        marks.add(Mark(type: MarkType.link, start: startOffset, end: startOffset + label.length, href: url));
      } else if (token.startsWith('*') && token.endsWith('*') && token.length >= 2) {
        final inner = token.substring(1, token.length - 1);
        sb.write(inner);
        marks.add(Mark(type: MarkType.italic, start: startOffset, end: startOffset + inner.length));
      } else {
        sb.write(token);
      }

      lastEnd = match.end;
    }

    if (lastEnd < line.length) {
      sb.write(line.substring(lastEnd));
    }

    return _ExtractedLine(sb.toString(), marks);
  }

  static String _applyMarksToMarkdown(String text, List<Mark> marks) {
    if (marks.isEmpty) return text;
    // Simple conversion for export
    // Sort marks descending by start offset to avoid shifting offsets during insertion
    final sortedMarks = List<Mark>.from(marks)..sort((a, b) => b.start.compareTo(a.start));
    String result = text;

    for (final mark in sortedMarks) {
      if (mark.start < 0 || mark.end > result.length || mark.start >= mark.end) continue;
      final before = result.substring(0, mark.start);
      final inner = result.substring(mark.start, mark.end);
      final after = result.substring(mark.end);

      switch (mark.type) {
        case MarkType.bold:
          result = '$before**$inner**$after';
          break;
        case MarkType.italic:
          result = '$before*$inner*$after';
          break;
        case MarkType.underline:
          result = '$before<u>$inner</u>$after';
          break;
        case MarkType.strikethrough:
          result = '$before~~$inner~~$after';
          break;
        case MarkType.link:
          final href = mark.href ?? '';
          result = '$before[$inner]($href)$after';
          break;
      }
    }

    return result;
  }
}

class _ExtractedLine {
  final String plainText;
  final List<Mark> marks;
  const _ExtractedLine(this.plainText, this.marks);
}
