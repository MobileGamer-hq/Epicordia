import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/repository/task_repository.dart';
import '../../data/repository/pin_repository.dart';
import '../../data/repository/board_repository.dart';
import '../../data/database/database.dart';
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

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(allNotesProvider);
    final tasksAsync = ref.watch(allTasksProvider);
    final boardsAsync = ref.watch(allBoardsProvider);

    final notes = notesAsync.value ?? [];
    final tasks = tasksAsync.value ?? [];
    final boards = boardsAsync.value ?? [];

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

    return Scaffold(
      backgroundColor: EpicordiaColors.surfaceAppLight,
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
                        color: EpicordiaColors.surfaceCardLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: EpicordiaColors.borderStrongLight, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: const TextStyle(fontSize: 15, color: EpicordiaColors.textPrimaryLight),
                        decoration: InputDecoration(
                          hintText: 'Search notes, tasks, boards...',
                          hintStyle: const TextStyle(color: EpicordiaColors.textTertiaryLight),
                          prefixIcon: const Icon(Icons.search, color: EpicordiaColors.textSecondaryLight),
                          suffixIcon: _query.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18, color: EpicordiaColors.textSecondaryLight),
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
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: EpicordiaColors.blue600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: EpicordiaColors.borderSubtleLight),

            // Results List
            Expanded(
              child: _query.isEmpty
                  ? _buildEmptyState(
                      icon: Icons.search,
                      message: 'Search everything in Epicordia',
                      submessage: 'Type to search for tasks, notes, or boards',
                    )
                  : !hasResults
                      ? _buildEmptyState(
                          icon: Icons.search_off_outlined,
                          message: 'No results found',
                          submessage: 'Try searching for different keywords',
                        )
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          children: [
                            if (filteredBoards.isNotEmpty) ...[
                              _buildSectionHeader('BOARDS'),
                              ...filteredBoards.map((board) => _buildBoardResultItem(board)),
                              const SizedBox(height: 16),
                            ],
                            if (filteredTasks.isNotEmpty) ...[
                              _buildSectionHeader('TASKS'),
                              ...filteredTasks.map((task) => _buildTaskResultItem(task)),
                              const SizedBox(height: 16),
                            ],
                            if (filteredNotes.isNotEmpty) ...[
                              _buildSectionHeader('NOTES'),
                              ...filteredNotes.map((note) => _buildNoteResultItem(note)),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: EpicordiaColors.textTertiaryLight,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildBoardResultItem(BoardEntity board) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: EpicordiaColors.borderSubtleLight),
      ),
      color: EpicordiaColors.surfaceCardLight,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: EpicordiaColors.blue100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.dashboard_outlined, size: 20, color: EpicordiaColors.blue700),
        ),
        title: Text(
          board.title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: EpicordiaColors.textPrimaryLight),
        ),
        onTap: () {
          context.push('/board/${board.id}');
        },
      ),
    );
  }

  Widget _buildTaskResultItem(TaskEntity task) {
    final isCompleted = task.status == 'done';
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: EpicordiaColors.borderSubtleLight),
      ),
      color: EpicordiaColors.surfaceCardLight,
      child: ListTile(
        leading: Icon(
          isCompleted ? Icons.check_circle_outline : Icons.radio_button_unchecked,
          color: isCompleted ? EpicordiaColors.successLight : EpicordiaColors.textTertiaryLight,
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: EpicordiaColors.textPrimaryLight,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: task.dueDate != null
            ? Text(
                'Due: ${task.dueDate!.month}/${task.dueDate!.day}/${task.dueDate!.year}',
                style: const TextStyle(fontSize: 11, color: EpicordiaColors.textTertiaryLight),
              )
            : null,
        onTap: () {
          context.push('/task/${task.id}');
        },
      ),
    );
  }

  Widget _buildNoteResultItem(PinEntity note) {
    final lines = (note.content ?? '').split('\n');
    final title = lines.isNotEmpty && lines[0].trim().isNotEmpty ? lines[0] : 'Untitled Note';
    final preview = lines.length > 1 ? lines.sublist(1).join('\n').trim() : 'No additional content';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: EpicordiaColors.borderSubtleLight),
      ),
      color: EpicordiaColors.surfaceCardLight,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3CD),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.description_outlined, size: 20, color: Color(0xFF785A00)),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: EpicordiaColors.textPrimaryLight),
        ),
        subtitle: Text(
          preview,
          style: const TextStyle(fontSize: 11, color: EpicordiaColors.textSecondaryLight),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () {
          context.push('/note/${note.id}');
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String submessage,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: EpicordiaColors.textTertiaryLight.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: EpicordiaColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            submessage,
            style: const TextStyle(
              fontSize: 12,
              color: EpicordiaColors.textTertiaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
