import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/repository/pin_repository.dart';
import '../../data/repository/board_repository.dart';
import '../../data/database/database.dart';
import '../widgets/layout/responsive_scaffold.dart';
import '../widgets/core/epicordia_card.dart';
import '../widgets/core/interactive_note_card.dart';
import '../../core/theme.dart';

class NotesTab extends ConsumerStatefulWidget {
  const NotesTab({super.key});

  @override
  ConsumerState<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends ConsumerState<NotesTab> {
  String _selectedFilter = 'All';
  final _searchController = TextEditingController();

  final List<String> _filters = ['All', 'Recent', 'Pinned', 'Ideas'];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(allNotesProvider);
    final boardsAsync = ref.watch(allBoardsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgApp = Theme.of(context).scaffoldBackgroundColor;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;
    final borderStrong = isDark ? EpicordiaColors.borderStrongDark : EpicordiaColors.borderStrongLight;
    final activeBlue = isDark ? EpicordiaColors.blue600 : EpicordiaColors.blue700;

    final boardsMap = boardsAsync.value?.fold<Map<String, BoardEntity>>(
          {},
          (map, board) {
            map[board.id] = board;
            return map;
          },
        ) ??
        {};

    return ResponsiveScaffold(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notes',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Capture thoughts, lists, and quick ideas',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          // Search + filters
          Container(
            color: bgApp,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Column(
              children: [
                TextField(

                  controller: _searchController,
                  style: TextStyle(color: textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search across all notes...',
                    prefixIcon: Icon(
                      Icons.search,
                      size: 18,
                      color: textTertiary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((f) {
                      final selected = _selectedFilter == f;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedFilter = f),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? activeBlue
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected
                                    ? activeBlue
                                    : borderStrong,
                              ),
                            ),
                            child: Text(
                              f,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: selected
                                      ? Colors.white
                                      : textSecondary),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          // Notes list
          Expanded(
            child: SelectionArea(
              child: notesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
                data: (notes) {
                  // 1. Search Filter
                  final query = _searchController.text.trim().toLowerCase();
                  var filtered = notes.where((note) {
                    if (query.isEmpty) return true;
                    final title = (note.content ?? '').split('\n').first.toLowerCase();
                    final body = (note.content ?? '').toLowerCase();
                    return title.contains(query) || body.contains(query);
                  }).toList();

                  // 2. Chip Filter
                  if (_selectedFilter == 'Recent') {
                    filtered.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
                  } else if (_selectedFilter == 'Pinned') {
                    filtered = filtered.where((n) => n.boardId != null).toList();
                  } else if (_selectedFilter == 'Ideas') {
                    filtered = filtered.where((n) {
                      final c = (n.content ?? '').toLowerCase();
                      return c.contains('idea') || c.contains('thought');
                    }).toList();
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                    itemCount: filtered.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      if (index == filtered.length) {
                        return _CreateNoteButton(
                          onTap: () => context.push('/create/note'),
                        );
                      }
                      final note = filtered[index];
                      final boardTitle = nBoardTitle(note.boardId, boardsMap);

                      return InteractiveNoteCard(
                        note: note,
                        boardTitle: boardTitle,
                        timeFormatted: _formatModified(note.modifiedAt),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String nBoardTitle(String? boardId, Map<String, BoardEntity> boardsMap) {
    if (boardId == null) return 'Inbox';
    return boardsMap[boardId]?.title ?? 'Inbox';
  }
}

// ── Note list item ────────────────────────────────────────────
class _NoteListItem extends StatelessWidget {
  final PinEntity note;
  final String boardTitle;
  final String timeFormatted;
  final VoidCallback onTap;

  const _NoteListItem({
    required this.note,
    required this.boardTitle,
    required this.timeFormatted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lines = (note.content ?? '').split('\n');
    final title = lines.isNotEmpty && lines[0].trim().isNotEmpty ? lines[0] : 'Untitled Note';
    final preview = lines.length > 1 ? lines.sublist(1).join('\n').trim() : 'No additional content';
    final isPinned = note.boardId != null;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;
    final borderStrong = isDark ? EpicordiaColors.borderStrongDark : EpicordiaColors.borderStrongLight;
    final activeBlue = isDark ? EpicordiaColors.blue600 : EpicordiaColors.blue600;

    return GestureDetector(
      onTap: onTap,
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
                  timeFormatted,
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
                    color: isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600,
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

class _CreateNoteButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CreateNoteButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final borderStrong = isDark ? EpicordiaColors.borderStrongDark : EpicordiaColors.borderStrongLight;

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderStrong,
              style: BorderStyle.solid,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add,
                size: 18,
                color: textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                'Create New Note',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
