import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:epicordia/domain/models/note_model.dart';
import 'package:epicordia/core/utils/markdown_formatter.dart';

void main() {
  group('NoteDocument & NoteBlock Tests', () {
    test('parseLegacyMarkdown correctly parses inline bold, italic, underline, links, and lists', () {
      final rawMarkdown = [
        '# My Note Title',
        '- This is **bold** text and *italic* text.',
        '1. Numbered item with [Google](https://google.com).',
        '[x] Checklist completed item.',
        '[ ] Checklist open item.',
        '> A quoted line with <u>underline</u> and ~~strikethrough~~.',
      ].join('\n');

      final blocks = NoteDocument.parseLegacyMarkdown(rawMarkdown);

      expect(blocks.length, 6);

      // Block 0: Heading
      expect(blocks[0].type, BlockType.heading);
      expect(blocks[0].text, 'My Note Title');

      // Block 1: Bullet list
      expect(blocks[1].type, BlockType.bulletListItem);
      expect(blocks[1].text, 'This is bold text and italic text.');
      expect(blocks[1].marks.length, 2);
      expect(blocks[1].marks[0].type, MarkType.bold);
      expect(blocks[1].marks[0].start, 8);
      expect(blocks[1].marks[0].end, 12);
      expect(blocks[1].marks[1].type, MarkType.italic);
      expect(blocks[1].marks[1].start, 22);
      expect(blocks[1].marks[1].end, 28);

      // Block 2: Numbered list
      expect(blocks[2].type, BlockType.numberedListItem);
      expect(blocks[2].listIndex, 1);
      expect(blocks[2].text, 'Numbered item with Google.');
      expect(blocks[2].marks.length, 1);
      expect(blocks[2].marks[0].type, MarkType.link);
      expect(blocks[2].marks[0].href, 'https://google.com');

      // Block 3 & 4: Checklist
      expect(blocks[3].type, BlockType.checklistItem);
      expect(blocks[3].checked, isTrue);
      expect(blocks[4].type, BlockType.checklistItem);
      expect(blocks[4].checked, isFalse);

      // Block 5: Quote
      expect(blocks[5].type, BlockType.quote);
      expect(blocks[5].text, 'A quoted line with underline and strikethrough.');
      expect(blocks[5].marks.length, 2);
      expect(blocks[5].marks[0].type, MarkType.underline);
      expect(blocks[5].marks[1].type, MarkType.strikethrough);
    });

    test('JSON serialization & deserialization roundtrip', () {
      final originalBlocks = [
        NoteBlock(type: BlockType.heading, text: 'Title Block'),
        NoteBlock(
          type: BlockType.bulletListItem,
          text: 'Bullet item',
          marks: [
            const Mark(type: MarkType.bold, start: 0, end: 6),
          ],
        ),
      ];

      final jsonStr = NoteDocument.encodeBlocks(originalBlocks);
      expect(NoteDocument.isJsonBlocks(jsonStr), isTrue);

      final decodedBlocks = NoteDocument.decodeBlocks(jsonStr);
      expect(decodedBlocks.length, 2);
      expect(decodedBlocks[0].type, BlockType.heading);
      expect(decodedBlocks[0].text, 'Title Block');
      expect(decodedBlocks[1].type, BlockType.bulletListItem);
      expect(decodedBlocks[1].text, 'Bullet item');
      expect(decodedBlocks[1].marks.length, 1);
      expect(decodedBlocks[1].marks[0].type, MarkType.bold);
    });

    test('MarkdownFormatter produces valid TextSpan trees without crashing', () {
      final blocks = [
        NoteBlock(type: BlockType.bulletListItem, text: 'Bullet item', marks: [
          const Mark(type: MarkType.bold, start: 0, end: 6),
        ]),
      ];

      final span = MarkdownFormatter.formatBlocksToTextSpan(
        blocks,
        baseStyle: const TextStyle(fontSize: 14),
      );

      expect(span, isNotNull);
      expect(span.children, isNotEmpty);
    });
  });
}
