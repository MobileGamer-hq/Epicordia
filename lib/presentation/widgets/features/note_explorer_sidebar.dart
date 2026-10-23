import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../data/repository/pin_repository.dart';
import '../../../domain/models/note_model.dart';

class NoteExplorerSidebar extends ConsumerStatefulWidget {
  final String? activeNoteId;
  final void Function(String id, String title) onNoteSelected;
  final VoidCallback onNewNote;
  final VoidCallback? onCollapse;
  final double width;

  const NoteExplorerSidebar({
    super.key,
    required this.activeNoteId,
    required this.onNoteSelected,
    required this.onNewNote,
    this.onCollapse,
    this.width = 280,
  });

  @override
  ConsumerState<NoteExplorerSidebar> createState() => _NoteExplorerSidebarState();
}

class _NoteExplorerSidebarState extends ConsumerState<NoteExplorerSidebar> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
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
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${date.month}/${date.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(allNotesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgSidebar = isDark ? EpicordiaColors.surfaceSunkenDark : EpicordiaColors.surfaceAppLight;
    final searchBg = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceSunkenLight;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;
    final borderClr = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;
    final activeBlue = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600;

    return Container(
      width: widget.width,
      decoration: BoxDecoration(
        color: bgSidebar,
        border: Border(
          right: BorderSide(color: borderClr.withValues(alpha: 0.8)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Minimalist Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 10, 8),
            child: Row(
              children: [
                Text(
                  'Notes',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(width: 6),
                notesAsync.maybeWhen(
                  data: (notes) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark
                          ? EpicordiaColors.surfaceCardDark
                          : EpicordiaColors.surfaceSunkenLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${notes.length}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: textTertiary,
                      ),
                    ),
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
                const Spacer(),
                // Quick + (New note) button
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.add, color: textPrimary, size: 20),
                  tooltip: 'New Note',
                  onPressed: widget.onNewNote,
                ),
                // Collapse sidebar
                if (widget.onCollapse != null)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.chevron_left, color: textTertiary, size: 20),
                    tooltip: 'Collapse Sidebar',
                    onPressed: widget.onCollapse,
                  ),
              ],
            ),
          ),

          // Minimalist Search Input
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Container(
              height: 34,
              decoration: BoxDecoration(
                color: searchBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderClr.withValues(alpha: 0.6)),
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(fontSize: 13, color: textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search notes...',
                  hintStyle: TextStyle(fontSize: 12, color: textTertiary),
                  prefixIcon: Icon(Icons.search, size: 16, color: textTertiary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, size: 14, color: textTertiary),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 7),
                  isDense: true,
                ),
              ),
            ),
          ),

          // Clean Divider
          Divider(color: borderClr.withValues(alpha: 0.6), height: 1),

          // Notes List
          Expanded(
            child: notesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text('Error loading notes', style: TextStyle(color: textTertiary, fontSize: 12)),
              ),
              data: (notes) {
                final query = _searchController.text.trim().toLowerCase();
                final filtered = notes.where((note) {
                  if (query.isEmpty) return true;
                  final title = NoteDocument.extractTitle(note.content ?? '').toLowerCase();
                  final body = NoteDocument.extractPlainText(note.content ?? '').toLowerCase();
                  return title.contains(query) || body.contains(query);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_note_outlined, size: 32, color: textTertiary.withValues(alpha: 0.7)),
                          const SizedBox(height: 8),
                          Text(
                            query.isEmpty ? 'No notes yet' : 'No matching notes',
                            style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final note = filtered[index];
                    final isSelected = widget.activeNoteId == note.id;
                    final title = NoteDocument.extractTitle(note.content ?? '');
                    final displayTitle = title.trim().isEmpty ? 'Untitled Note' : title.trim();
                    final preview = NoteDocument.extractPlainText(note.content ?? '');

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: InkWell(
                        onTap: () => widget.onNoteSelected(note.id, displayTitle),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? activeBlue.withValues(alpha: 0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Subtle active indicator pill
                              if (isSelected)
                                Container(
                                  width: 3,
                                  height: 28,
                                  margin: const EdgeInsets.only(right: 8, top: 2),
                                  decoration: BoxDecoration(
                                    color: activeBlue,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        if (note.isLocked) ...[
                                          Icon(Icons.lock, size: 11, color: activeBlue),
                                          const SizedBox(width: 4),
                                        ],
                                        Expanded(
                                          child: Text(
                                            displayTitle,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                              color: isSelected ? activeBlue : textPrimary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _formatModified(note.modifiedAt),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            color: textTertiary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (preview.isNotEmpty && !note.isLocked) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        preview,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isSelected ? textSecondary : textTertiary,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
