import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/app_lock_provider.dart';
import '../../../domain/state/journaling_provider.dart';
import '../../../core/utils/markdown_formatter.dart';
import '../../../data/database/database.dart';
import '../../../data/repository/pin_repository.dart';
import '../../screens/pin_lock_screen.dart';
import 'epicordia_card.dart';
import 'item_interaction_dialogs.dart';
import 'link_preview_dialog.dart';

class InteractiveNoteCard extends ConsumerWidget {
  final PinEntity note;
  final String boardTitle;
  final String? timeFormatted;
  final bool isExpanded;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDoubleTap;

  const InteractiveNoteCard({
    super.key,
    required this.note,
    required this.boardTitle,
    this.timeFormatted,
    this.isExpanded = false,
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

  Future<void> _handleTap(BuildContext context, WidgetRef ref) async {
    final lockAll = ref.read(lockAllJournalsProvider);
    final noteTags = (note.tags ?? note.colorTag ?? '').toLowerCase();
    final isJournal = noteTags.contains('journal');
    final isLocked = note.isLocked || (lockAll && isJournal);

    if (isLocked) {
      final appLock = ref.read(appLockProvider);
      bool? verified;
      if (!appLock.hasPin) {
        verified = await PinLockScreen.showCreate(context);
      } else {
        verified = await PinLockScreen.showVerify(context);
      }
      if (verified == true && context.mounted) {
        if (onTap != null) {
          onTap!();
        } else {
          context.push('/note/${note.id}');
        }
      }
    } else {
      if (onTap != null) {
        onTap!();
      } else {
        context.push('/note/${note.id}');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lockAll = ref.watch(lockAllJournalsProvider);
    final noteTags = note.tags ?? note.colorTag ?? 'Journal';
    final isJournal = noteTags.toLowerCase().contains('journal');
    final isLocked = note.isLocked || (lockAll && isJournal);

    final lines = (note.content ?? '').split('\n');
    final rawTitle = lines.isNotEmpty && lines[0].trim().isNotEmpty ? lines[0] : 'Untitled Note';
    final title = isLocked ? 'Locked Note' : rawTitle;
    final preview = isLocked
        ? 'Protected content. Tap to verify PIN and unlock.'
        : (lines.length > 1 ? lines.sublist(1).join('\n').trim() : 'No additional content');
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
      onTap: () => _handleTap(context, ref),
      onLongPress: isLocked
          ? null
          : (onLongPress ??
              () => ItemInteractionDialogs.showNoteDetailDialog(
                    context: context,
                    ref: ref,
                    note: note,
                    boardTitle: boardTitle,
                  )),
      onDoubleTap: isLocked
          ? null
          : (onDoubleTap ??
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
                  )),
      child: EpicordiaCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text.rich(
                    MarkdownFormatter.formatToTextSpan(
                      title,
                      baseStyle: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                      activeBlue: activeBlue,
                      isTitle: true,
                      onLinkTap: (label, url) => LinkPreviewDialog.show(context, label, url),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isLocked) ...[
                  const Icon(Icons.lock, size: 16, color: EpicordiaColors.blue600),
                  const SizedBox(width: 6),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? EpicordiaColors.blue900 : EpicordiaColors.blue100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    noteTags,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue700,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
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
            Text.rich(
              MarkdownFormatter.formatToTextSpan(
                preview,
                baseStyle: TextStyle(
                  fontSize: 13,
                  color: isLocked ? textTertiary : textSecondary,
                  fontStyle: isLocked ? FontStyle.italic : FontStyle.normal,
                  height: 1.45,
                ),
                activeBlue: activeBlue,
                onLinkTap: (label, url) => LinkPreviewDialog.show(context, label, url),
              ),
              maxLines: isExpanded ? null : 3,
              overflow: isExpanded ? TextOverflow.clip : TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.access_time, size: 12, color: textTertiary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    formattedTime,
                    style: TextStyle(
                      fontSize: 11,
                      color: textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
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

