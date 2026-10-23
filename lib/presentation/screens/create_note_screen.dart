import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../domain/models/note_model.dart';
import '../../domain/state/note_workspace_provider.dart';
import '../widgets/features/note_explorer_sidebar.dart';
import '../widgets/features/note_split_container.dart';

class CreateNoteScreen extends ConsumerStatefulWidget {
  final String? noteId;
  const CreateNoteScreen({super.key, this.noteId});

  @override
  ConsumerState<CreateNoteScreen> createState() => _CreateNoteScreenState();
}

class _CreateNoteScreenState extends ConsumerState<CreateNoteScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final width = MediaQuery.of(context).size.width;
      final isWide = width >= 1024;
      String? initialTitle;
      if (widget.noteId != null && !widget.noteId!.startsWith('new_')) {
        final note = await ref.read(pinDaoProvider).getPin(widget.noteId!);
        if (note != null) {
          final t = NoteDocument.extractTitle(note.content ?? '');
          if (t.trim().isNotEmpty) initialTitle = t.trim();
        }
      }
      ref.read(noteWorkspaceProvider.notifier).initialize(
            initialNoteId: widget.noteId,
            initialTitle: initialTitle ?? (widget.noteId != null ? 'Untitled Note' : 'Untitled Note'),
            isWideScreen: isWide,
          );
    });
  }

  @override
  void didUpdateWidget(covariant CreateNoteScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.noteId != widget.noteId && widget.noteId != null) {
      ref.read(noteWorkspaceProvider.notifier).openNote(widget.noteId!);
    }
  }

  void _onNoteSelectedInSidebar(String selectedId, String title, bool isMobile) {
    ref.read(noteWorkspaceProvider.notifier).openNote(selectedId, title: title);
    if (isMobile && _scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.of(context).pop(); // Close mobile drawer
    }
  }

  void _onNewNoteInSidebar(bool isMobile) {
    ref.read(noteWorkspaceProvider.notifier).openNewNote();
    if (isMobile && _scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.of(context).pop(); // Close mobile drawer
    }
  }

  @override
  Widget build(BuildContext context) {
    final workspaceState = ref.watch(noteWorkspaceProvider);
    final notifier = ref.read(noteWorkspaceProvider.notifier);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgApp = isDark ? EpicordiaColors.surfaceAppDark : EpicordiaColors.surfaceAppLight;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;
    final activeBlue = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600;

    final activeTab = workspaceState.activeTabInActivePane;
    final activeNoteId = activeTab?.id;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isMobile = screenWidth < 768;
        final isTablet = screenWidth >= 768 && screenWidth < 1024;
        final canSplit = screenWidth >= 850;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: bgApp,
          appBar: AppBar(
            backgroundColor: bgApp,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: textPrimary),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/notes');
                }
              },
            ),
            titleSpacing: 0,
            title: Row(
              children: [
                // Sidebar Toggle Button
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    workspaceState.isSidebarOpen ? Icons.view_sidebar : Icons.view_sidebar_outlined,
                    color: workspaceState.isSidebarOpen ? activeBlue : textTertiary,
                    size: 20,
                  ),
                  tooltip: workspaceState.isSidebarOpen ? 'Hide Sidebar' : 'Show Sidebar',
                  onPressed: () {
                    if (isMobile) {
                      _scaffoldKey.currentState?.openDrawer();
                    } else {
                      notifier.toggleSidebar();
                    }
                  },
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    activeTab?.title.isNotEmpty == true
                        ? activeTab!.title
                        : (widget.noteId != null ? 'Edit Note' : 'Notes'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            actions: [
              // Split Pane Toggle in AppBar if screen allows splitting
              if (canSplit)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    workspaceState.isSplit ? Icons.vertical_split : Icons.vertical_split_outlined,
                    color: workspaceState.isSplit ? activeBlue : textTertiary,
                    size: 20,
                  ),
                  tooltip: workspaceState.isSplit ? 'Close Split View' : 'Split Editor Right',
                  onPressed: () {
                    if (workspaceState.isSplit) {
                      notifier.closeSplit();
                    } else {
                      notifier.splitPane();
                    }
                  },
                ),

              // Done button
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/notes');
                    }
                  },
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: Text(
                    'Done',
                    style: TextStyle(
                      color: activeBlue,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          drawer: isMobile
              ? Drawer(
                  child: SafeArea(
                    child: NoteExplorerSidebar(
                      width: double.infinity,
                      activeNoteId: activeNoteId,
                      onNoteSelected: (id, title) => _onNoteSelectedInSidebar(id, title, true),
                      onNewNote: () => _onNewNoteInSidebar(true),
                    ),
                  ),
                )
              : null,
          body: SafeArea(
            top: false,
            child: Row(
              children: [
                // Sidebar on Desktop / Tablet (if open)
                if (!isMobile && workspaceState.isSidebarOpen)
                  NoteExplorerSidebar(
                    width: isTablet ? 240 : 280,
                    activeNoteId: activeNoteId,
                    onNoteSelected: (id, title) => _onNoteSelectedInSidebar(id, title, false),
                    onNewNote: () => _onNewNoteInSidebar(false),
                    onCollapse: () => notifier.toggleSidebar(force: false),
                  ),

                // Editor area (Single or Split)
                Expanded(
                  child: NoteSplitContainer(
                    isWideScreen: !isMobile,
                    canSplit: canSplit,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
