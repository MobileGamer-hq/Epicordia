import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../data/database/database.dart';
import '../../../data/repository/pin_repository.dart';
import 'epicordia_card.dart';
import 'item_interaction_dialogs.dart';

class InteractiveNoteCard extends ConsumerWidget {
  final PinEntity note;
  final String boardTitle;
  final String? timeFormatted;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDoubleTap;

  const InteractiveNoteCard({
    super.key,
    required this.note,
    required this.boardTitle,
    this.timeFormatted,
    this.onTap,
    this.onLongPress,
    this.onDoubleTap,
  });

  String _formatModified(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inMinutes < 60) {
      return 'Modified ${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return 'Modified ${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Modified Yesterday';
    } else {
      return 'Modified ${date.month}/${date.day}';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lines = (note.content ?? '').split('\n');
    final title = lines.isNotEmpty && lines[0].trim().isNotEmpty ? lines[0] : 'Untitled Note';
    final preview = lines.length > 1 ? lines.sublist(1).join('\n').trim() : 'No additional content';
    final body = note.content ?? '';
    final isPinned = note.boardId != null;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;
    final borderStrong = isDark ? EpicordiaColors.borderStrongDark : EpicordiaColors.borderStrongLight;
    final activeBlue = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600;

    final formattedTime = timeFormatted ?? _formatModified(note.modifiedAt);

    return GestureDetector(
      onTap: onTap ?? () => context.push('/note/${note.id}'),
      onLongPress: onLongPress ??
          () => ItemInteractionDialogs.showNoteDetailDialog(
                context: context,
                ref: ref,
                note: note,
                boardTitle: boardTitle,
              ),
      onDoubleTap: onDoubleTap ??
          () => ItemInteractionDialogs.showDoubleTapMenu(
                context: context,
                title: title,
                subtitle: 'Note in $boardTitle',
                items: [
                  DoubleTapMenuItem(
                    icon: Icons.copy_rounded,
                    label: 'Copy Note',
                    onTap: () {
                      ItemInteractionDialogs.copyToClipboard(
                        context,
                        '$title\n\n$body',
                      );
                    },
                  ),
                  DoubleTapMenuItem(
                    icon: Icons.share_outlined,
                    label: 'Share Note',
                    onTap: () {
                      ItemInteractionDialogs.shareContent(
                        context,
                        '$title\n\n$body',
                      );
                    },
                  ),
                  DoubleTapMenuItem(
                    icon: Icons.edit_note_rounded,
                    label: 'Edit Note',
                    onTap: () => context.push('/note/${note.id}'),
                  ),
                  DoubleTapMenuItem(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete Note',
                    color: EpicordiaColors.errorLight,
                    onTap: () async {
                      await ref.read(pinRepositoryProvider).deletePin(note.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Note deleted'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
      child: EpicordiaCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ),
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPinned ? activeBlue : Colors.transparent,
                    border: Border.all(
                      color: isPinned ? activeBlue : borderStrong,
                      width: 1.5,
                    ),
                  ),
                  child: isPinned ? const Icon(Icons.check, size: 10, color: Colors.white) : null,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              preview,
              style: TextStyle(
                fontSize: 13,
                color: textSecondary,
                height: 1.45,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  formattedTime,
                  style: TextStyle(
                    fontSize: 11,
                    color: textTertiary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Board: $boardTitle',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: activeBlue,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.more_horiz,
                  size: 16,
                  color: textTertiary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
