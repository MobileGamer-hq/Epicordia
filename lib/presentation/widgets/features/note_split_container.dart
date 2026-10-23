import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../domain/state/note_workspace_provider.dart';
import 'note_tab_bar.dart';
import 'single_note_editor.dart';

class NoteSplitContainer extends ConsumerWidget {
  final bool isWideScreen;
  final bool canSplit;

  const NoteSplitContainer({
    super.key,
    required this.isWideScreen,
    required this.canSplit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceState = ref.watch(noteWorkspaceProvider);
    final notifier = ref.read(noteWorkspaceProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderClr = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;

    final pane0Tabs = workspaceState.panes[0];
    final active0Idx = workspaceState.activeTabIndices[0];
    final activeTab0 = (pane0Tabs.isNotEmpty && active0Idx < pane0Tabs.length)
        ? pane0Tabs[active0Idx]
        : null;

    if (!workspaceState.isSplit || !canSplit) {
      // Single Pane Mode
      if (activeTab0 == null) {
        return const Center(child: Text('No active note'));
      }

      return Column(
        children: [
          if (isWideScreen)
            NoteTabBar(
              tabs: pane0Tabs,
              activeIndex: active0Idx,
              canSplit: canSplit,
              isSplit: false,
              onTabSelected: (idx) => notifier.switchTab(0, idx),
              onTabClosed: (idx) => notifier.closeTab(0, idx),
              onAddTab: () => notifier.openNewNote(targetPane: 0),
              onToggleSplit: () => notifier.splitPane(),
            ),
          Expanded(
            child: SingleNoteEditor(
              key: ValueKey(activeTab0.id),
              noteId: activeTab0.id,
              isNewNote: activeTab0.isNew,
              onTitleChanged: (title) => notifier.updateTabTitle(activeTab0.id, title),
              onNotePersisted: (newId, title) => notifier.updateTabId(activeTab0.id, newId, title: title),
              onDelete: () => notifier.closeTab(0, active0Idx),
            ),
          ),
        ],
      );
    }

    // Split Pane Mode (Side-by-Side)
    final pane1Tabs = workspaceState.panes[1];
    final active1Idx = workspaceState.activeTabIndices[1];
    final activeTab1 = (pane1Tabs.isNotEmpty && active1Idx < pane1Tabs.length)
        ? pane1Tabs[active1Idx]
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        const dividerWidth = 8.0;
        final availableWidth = (totalWidth - dividerWidth).clamp(200.0, 5000.0);
        final pane0Width = (availableWidth * workspaceState.splitRatio).clamp(150.0, availableWidth - 150.0);
        final pane1Width = availableWidth - pane0Width;

        return Row(
          children: [
            // Left Pane (Pane 0)
            SizedBox(
              width: pane0Width,
              child: Column(
                children: [
                  NoteTabBar(
                    tabs: pane0Tabs,
                    activeIndex: active0Idx,
                    canSplit: canSplit,
                    isSplit: true,
                    onTabSelected: (idx) => notifier.switchTab(0, idx),
                    onTabClosed: (idx) => notifier.closeTab(0, idx),
                    onAddTab: () => notifier.openNewNote(targetPane: 0),
                    onToggleSplit: () => notifier.closeSplit(paneToKeep: 0),
                    onMoveToOtherPane: (idx) => notifier.moveTabToOtherPane(0, idx),
                  ),
                  Expanded(
                    child: activeTab0 != null
                        ? SingleNoteEditor(
                            key: ValueKey(activeTab0.id),
                            noteId: activeTab0.id,
                            isNewNote: activeTab0.isNew,
                            onTitleChanged: (title) => notifier.updateTabTitle(activeTab0.id, title),
                            onNotePersisted: (newId, title) =>
                                notifier.updateTabId(activeTab0.id, newId, title: title),
                            onDelete: () => notifier.closeTab(0, active0Idx),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),

            // Draggable Divider
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: (details) {
                final newRatio = (pane0Width + details.delta.dx) / availableWidth;
                notifier.setSplitRatio(newRatio);
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeColumn,
                child: Container(
                  width: dividerWidth,
                  color: isDark ? EpicordiaColors.surfaceAppDark : EpicordiaColors.surfaceSunkenLight,
                  child: Center(
                    child: Container(
                      width: 2,
                      decoration: BoxDecoration(
                        color: borderClr,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Right Pane (Pane 1)
            SizedBox(
              width: pane1Width,
              child: Column(
                children: [
                  NoteTabBar(
                    tabs: pane1Tabs,
                    activeIndex: active1Idx,
                    canSplit: canSplit,
                    isSplit: true,
                    onTabSelected: (idx) => notifier.switchTab(1, idx),
                    onTabClosed: (idx) => notifier.closeTab(1, idx),
                    onAddTab: () => notifier.openNewNote(targetPane: 1),
                    onToggleSplit: () => notifier.closeSplit(paneToKeep: 1),
                    onMoveToOtherPane: (idx) => notifier.moveTabToOtherPane(1, idx),
                  ),
                  Expanded(
                    child: activeTab1 != null
                        ? SingleNoteEditor(
                            key: ValueKey(activeTab1.id),
                            noteId: activeTab1.id,
                            isNewNote: activeTab1.isNew,
                            onTitleChanged: (title) => notifier.updateTabTitle(activeTab1.id, title),
                            onNotePersisted: (newId, title) =>
                                notifier.updateTabId(activeTab1.id, newId, title: title),
                            onDelete: () => notifier.closeTab(1, active1Idx),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
