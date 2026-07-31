import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/repository/task_repository.dart';
import '../../data/repository/pin_repository.dart';
import '../../data/repository/board_repository.dart';
import '../../data/database/database.dart';
import '../widgets/core/interactive_task_card.dart';
import '../widgets/core/interactive_note_card.dart';
import '../../core/theme.dart';

class EpicordiaSearchScreen extends ConsumerStatefulWidget {
  const EpicordiaSearchScreen({super.key});

  @override
  ConsumerState<EpicordiaSearchScreen> createState() => _EpicordiaSearchScreenState();
}

class _EpicordiaSearchScreenState extends ConsumerState<EpicordiaSearchScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getBoardColor(String? boardId) {
    if (boardId == null) return Colors.grey;
    final colors = [
      const Color(0xFF8B9DC3),
      const Color(0xFFA8B4C8),
      const Color(0xFF6B7FA0),
      const Color(0xFF9EAAC4)
    ];
    return colors[boardId.hashCode % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(allNotesProvider);
    final tasksAsync = ref.watch(allTasksProvider);
    final boardsAsync = ref.watch(allBoardsProvider);

    final notes = notesAsync.value ?? [];
    final tasks = tasksAsync.value ?? [];
    final boards = boardsAsync.value ?? [];

    final boardsMap = boards.fold<Map<String, BoardEntity>>(
      {},
      (map, board) {
        map[board.id] = board;
        return map;
      },
    );

    // Filtered results
    final filteredBoards = _query.isEmpty
        ? <BoardEntity>[]
        : boards.where((b) => b.title.toLowerCase().contains(_query.toLowerCase())).toList();

    final filteredTasks = _query.isEmpty
        ? <TaskEntity>[]
        : tasks.where((t) {
            final titleMatch = t.title.toLowerCase().contains(_query.toLowerCase());
            final notesMatch = (t.notes ?? '').toLowerCase().contains(_query.toLowerCase());
            return titleMatch || notesMatch;
          }).toList();

    final filteredNotes = _query.isEmpty
        ? <PinEntity>[]
        : notes.where((n) {
            return (n.content ?? '').toLowerCase().contains(_query.toLowerCase());
          }).toList();

    final hasResults = filteredBoards.isNotEmpty || filteredTasks.isNotEmpty || filteredNotes.isNotEmpty;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgApp = isDark ? EpicordiaColors.surfaceAppDark : EpicordiaColors.surfaceAppLight;
    final cardBg = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
    final borderClr = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;
    final activeBlue = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600;

    return Scaffold(
      backgroundColor: bgApp,
      body: SafeArea(
        child: Column(
          children: [
            // Search Input Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        // border: Border.all(color: borderStrong, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: TextStyle(fontSize: 15, color: textPrimary),
                        decoration: InputDecoration(
                          disabledBorder: InputBorder.none,
                          hintText: 'Search notes, tasks, boards...',
                          hintStyle: TextStyle(color: textTertiary),
                          prefixIcon: Icon(Icons.search, color: textSecondary),
                          suffixIcon: _query.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, size: 18, color: textSecondary),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _query = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: (val) {
                          setState(() => _query = val.trim());
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: activeBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: borderClr),

            // Results List
            Expanded(
              child: _query.isEmpty
                  ? _buildEmptyState(
                      context,
                      icon: Icons.search,
                      message: 'Search everything in Epicordia',
                      submessage: 'Type to search for tasks, notes, or boards',
                    )
                  : !hasResults
                      ? _buildEmptyState(
                          context,
                          icon: Icons.search_off_outlined,
                          message: 'No results found',
                          submessage: 'Try searching for different keywords',
                        )
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          children: [
                            if (filteredBoards.isNotEmpty) ...[
                              _buildSectionHeader(context, 'BOARDS'),
                              ...filteredBoards.map((board) => _buildBoardResultItem(context, board)),
                              const SizedBox(height: 16),
                            ],
                            if (filteredTasks.isNotEmpty) ...[
                              _buildSectionHeader(context, 'TASKS'),
                              ...filteredTasks.map((task) {
                                final boardTitle = boardsMap[task.boardId]?.title ?? 'Inbox';
                                final boardColor = _getBoardColor(task.boardId);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: InteractiveTaskCard(
                                    task: task,
                                    boardTitle: boardTitle,
                                    boardColor: boardColor,
                                  ),
                                );
                              }),
                              const SizedBox(height: 16),
                            ],
                            if (filteredNotes.isNotEmpty) ...[
                              _buildSectionHeader(context, 'NOTES'),
                              ...filteredNotes.map((note) {
                                final boardTitle = boardsMap[note.boardId]?.title ?? 'Inbox';
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: InteractiveNoteCard(
                                    note: note,
                                    boardTitle: boardTitle,
                                  ),
                                );
                              }),
                              const SizedBox(height: 16),
                            ],
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: textTertiary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildBoardResultItem(BuildContext context, BoardEntity board) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
    final borderClr = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final blueIcon = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue700;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: borderClr),
      ),
      color: cardBg,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: blueIcon.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.dashboard_outlined, size: 20, color: blueIcon),
        ),
        title: Text(
          board.title,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
        ),
        onTap: () {
          context.push('/board/${board.id}');
        },
      ),
    );
  }



  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String message,
    required String submessage,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: textTertiary.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            submessage,
            style: TextStyle(
              fontSize: 12,
              color: textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
