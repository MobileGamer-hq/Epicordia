import 'package:flutter/material.dart';
import '../widgets/layout/responsive_scaffold.dart';
import '../widgets/core/epicordia_brand.dart';
import '../widgets/core/epicordia_card.dart';
import '../../core/theme.dart';

class NotesTab extends StatefulWidget {
  const NotesTab({super.key});

  @override
  State<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<NotesTab> {
  String _selectedFilter = 'All';
  final _searchController = TextEditingController();

  final List<String> _filters = ['All', 'Recent', 'Pinned', 'Ideas'];

  final List<_NoteData> _notes = const [
    _NoteData(title: 'Product Roadmap 2024', preview: 'The focus for the upcoming quarters will be on enhancing the canvas-first workflow. We need to prioritize the transition from list-based tasks to spatial', board: 'Strategy', modified: 'Modified 9h ago', isPinned: true),
    _NoteData(title: 'Client Feedback · Zenith', preview: 'Zenith Corp mentioned that they love the \'Digital Zen\' aesthetic but would like more robust export options — like the canvas views. Need to investigate PDF filing.', board: 'Research', modified: 'Modified 9h ago', isPinned: false),
    _NoteData(title: 'Interaction Model Design', preview: 'Defining the tactile edge for mobile interactions. Every icon must sit within a 44px touchable touch target. Use scale-90 transitions on active states for feedback.', board: 'UX/UX', modified: 'Modified Yesterday', isPinned: true),
    _NoteData(title: 'Brutalist Pavilion Inspo', preview: 'Reference photos and initial sketches for the Epicordia Pavilion project in Milan.', board: 'Architecture', modified: 'Modified Oct 23', isPinned: false),
    _NoteData(title: 'Quick Ideas: Shader Effects', preview: 'Maybe add a subtle noise texture to the canvas background? Just enough to make it feel like paper — but digitally crisp. Test grain opacity at 0.02.', board: 'Ideas', modified: 'Modified Oct 23', isPinned: false),
    _NoteData(title: 'Meeting Notes: API V2', preview: 'Discussed moving to a more modular architecture for board endpoints. The current monolith is slowing down the canvas loading states. Aim for <200ms.', board: 'Engineering', modified: 'Modified Oct 23', isPinned: false),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      appBar: const EpicordiaSimpleAppBar(),
      child: Column(
        children: [
          // Search + filters
          Container(
            color: EpicordiaColors.surfaceAppLight,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search across all boards...',
                    prefixIcon: Icon(Icons.search, size: 18, color: EpicordiaColors.textTertiaryLight),
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
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected ? EpicordiaColors.blue700 : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: selected ? EpicordiaColors.blue700 : EpicordiaColors.borderStrongLight),
                            ),
                            child: Text(f, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: selected ? Colors.white : EpicordiaColors.textSecondaryLight)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          // Notes list
          Expanded(
            child: SelectionArea(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                itemCount: _notes.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _NoteListItem(note: _notes[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data model ───────────────────────────────────────────────
class _NoteData {
  final String title;
  final String preview;
  final String board;
  final String modified;
  final bool isPinned;
  const _NoteData({required this.title, required this.preview, required this.board, required this.modified, required this.isPinned});
}

// ── Note list item ────────────────────────────────────────────
class _NoteListItem extends StatelessWidget {
  final _NoteData note;
  const _NoteListItem({required this.note});

  @override
  Widget build(BuildContext context) {
    return EpicordiaCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(note.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: EpicordiaColors.textPrimaryLight)),
              ),
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: note.isPinned ? EpicordiaColors.blue600 : Colors.transparent,
                  border: Border.all(color: note.isPinned ? EpicordiaColors.blue600 : EpicordiaColors.borderStrongLight, width: 1.5),
                ),
                child: note.isPinned ? const Icon(Icons.check, size: 10, color: Colors.white) : null,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(note.preview, style: const TextStyle(fontSize: 13, color: EpicordiaColors.textSecondaryLight, height: 1.45), maxLines: 3, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(note.modified, style: const TextStyle(fontSize: 11, color: EpicordiaColors.textTertiaryLight)),
              const SizedBox(width: 8),
              Text('Board: ${note.board}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: EpicordiaColors.blue600)),
              const Spacer(),
              const Icon(Icons.more_horiz, size: 16, color: EpicordiaColors.textTertiaryLight),
            ],
          ),
        ],
      ),
    );
  }
}
