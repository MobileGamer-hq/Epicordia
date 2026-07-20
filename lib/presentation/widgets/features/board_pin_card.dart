import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../core/theme.dart';
import '../core/epicordia_card.dart';

class BoardPinCard extends StatelessWidget {
  final String type;
  final String? content;
  final String? colorTag;

  const BoardPinCard({
    super.key,
    required this.type,
    this.content,
    this.colorTag,
  });

  @override
  Widget build(BuildContext context) {
    return EpicordiaCard(
      indicatorColor: _colorFromTag(colorTag),
      padding: const EdgeInsets.all(14),
      child: switch (type) {
        'task' => _TaskBody(title: _taskTitle(content), body: _taskBody(content)),
        'link' => _LinkBody(url: content ?? ''),
        _ => _NoteBody(content: content ?? ''),
      },
    );
  }

  static String _taskTitle(String? content) {
    if (content == null || content.trim().isEmpty) return 'Untitled task';
    return content.trim().split('\n').first;
  }

  static String _taskBody(String? content) {
    if (content == null || content.trim().isEmpty) return '';
    final parts = content.trim().split('\n');
    if (parts.length <= 1) return '';
    return parts.sublist(1).join('\n').trim();
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
    return named[tag.toLowerCase()] ??
        (tag.startsWith('#') ? _tryParseHex(tag) : null);
  }

  static Color? _tryParseHex(String hex) {
    final value = hex.replaceFirst('#', '');
    if (value.length == 6) {
      return Color(int.parse('FF$value', radix: 16));
    }
    return null;
  }
}

class _NoteBody extends StatelessWidget {
  final String content;

  const _NoteBody({required this.content});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'NOTE',
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: EpicordiaColors.textTertiaryLight,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: ClipRect(
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black, Colors.transparent],
                  stops: [0.7, 1.0],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: MarkdownBody(
                data: content.isEmpty ? 'Untitled note' : content,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(fontSize: 12, color: EpicordiaColors.textPrimaryLight, height: 1.4),
                  h1: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  h2: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  listBullet: const TextStyle(fontSize: 12, color: EpicordiaColors.textPrimaryLight),
                  checkbox: const TextStyle(fontSize: 12, color: EpicordiaColors.textPrimaryLight),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TaskBody extends StatelessWidget {
  final String title;
  final String body;

  const _TaskBody({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 18,
              height: 18,
              margin: const EdgeInsets.only(top: 1, right: 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: EpicordiaColors.borderStrongLight, width: 2),
              ),
            ),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: EpicordiaColors.textPrimaryLight,
                ),
              ),
            ),
          ],
        ),
        if (body.isNotEmpty) ...[
          const SizedBox(height: 6),
          Expanded(
            child: ClipRect(
              child: ShaderMask(
                shaderCallback: (Rect bounds) {
                  return const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black, Colors.transparent],
                    stops: [0.7, 1.0],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstIn,
                child: MarkdownBody(
                  data: body,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(fontSize: 11, color: EpicordiaColors.textSecondaryLight, height: 1.4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _LinkBody extends StatelessWidget {
  final String url;

  const _LinkBody({required this.url});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.link, size: 14, color: EpicordiaColors.blue600),
            SizedBox(width: 6),
            Text(
              'LINK',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: EpicordiaColors.textTertiaryLight,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          url.isEmpty ? 'New link' : url,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            color: EpicordiaColors.blue600,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
