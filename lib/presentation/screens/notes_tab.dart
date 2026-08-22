import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/repository/pin_repository.dart';
import '../../data/repository/board_repository.dart';
import '../../data/database/database.dart';
import '../widgets/layout/responsive_scaffold.dart';
import '../widgets/core/interactive_note_card.dart';
import '../../core/theme.dart';

enum NoteViewMode { list, grid, detailed }

class NotesTab extends ConsumerStatefulWidget {
  const NotesTab({super.key});

  @override
  ConsumerState<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends ConsumerState<NotesTab> {
  String _selectedFilter = 'All';
  NoteViewMode _viewMode = NoteViewMode.list;
  final _searchController = TextEditingController();

  final List<String> _filters = ['All', 'Journal', 'Ideas', 'Locked', 'Recent', 'Pinned'];

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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                // View Mode Switcher (Single toggle icon matching Boards tab)
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: borderStrong.withValues(alpha: 0.3)),
                    ),
                  ),
                  icon: Icon(
                    _viewMode == NoteViewMode.list
                        ? Icons.view_list
                        : (_viewMode == NoteViewMode.grid ? Icons.grid_view : Icons.view_headline),
                    color: activeBlue,
                    size: 20,
                  ),
                  tooltip: 'Toggle View Mode',
                  onPressed: () {
                    setState(() {
                      if (_viewMode == NoteViewMode.list) {
                        _viewMode = NoteViewMode.grid;
                      } else if (_viewMode == NoteViewMode.grid) {
                        _viewMode = NoteViewMode.detailed;
                      } else {
                        _viewMode = NoteViewMode.list;
                      }
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          // Search + filters
          Container(
            color: bgApp,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
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
                const SizedBox(height: 16),
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
                              horizontal: 14,
                              vertical: 6,
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
                                  fontSize: 12,
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
                const SizedBox(height: 16),
              ],
            ),
          ),
          // Notes list / grid / detailed
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
                  } else if (_selectedFilter == 'Journal') {
                    filtered = filtered.where((n) {
                      final t = (n.tags ?? n.colorTag ?? '').toLowerCase();
                      return t.contains('journal');
                    }).toList();
                  } else if (_selectedFilter == 'Ideas') {
                    filtered = filtered.where((n) {
                      final t = (n.tags ?? n.colorTag ?? '').toLowerCase();
                      final c = (n.content ?? '').toLowerCase();
                      return t.contains('idea') || c.contains('idea') || c.contains('thought');
                    }).toList();
                  } else if (_selectedFilter == 'Locked') {
                    filtered = filtered.where((n) => n.isLocked).toList();
                  }

                  if (_viewMode == NoteViewMode.grid) {
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      children: [
                        if (filtered.isNotEmpty)
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 0.95,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final note = filtered[index];
                              final boardTitle = nBoardTitle(note.boardId, boardsMap);
                              return InteractiveNoteCard(
                                note: note,
                                boardTitle: boardTitle,
                                timeFormatted: _formatModified(note.modifiedAt),
                              );
                            },
                          ),
                        _CreateNoteButton(
                          onTap: () => context.push('/create/note'),
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
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
                        isExpanded: _viewMode == NoteViewMode.detailed,
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
