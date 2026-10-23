import 'package:flutter_riverpod/flutter_riverpod.dart';

class NoteTabItem {
  final String id;
  final String title;
  final bool isNew;

  const NoteTabItem({
    required this.id,
    required this.title,
    this.isNew = false,
  });

  NoteTabItem copyWith({
    String? id,
    String? title,
    bool? isNew,
  }) {
    return NoteTabItem(
      id: id ?? this.id,
      title: title ?? this.title,
      isNew: isNew ?? this.isNew,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteTabItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          isNew == other.isNew;

  @override
  int get hashCode => id.hashCode ^ title.hashCode ^ isNew.hashCode;
}

class NoteWorkspaceState {
  final bool isSidebarOpen;
  final bool isSplit;
  final double splitRatio;
  final int activePaneIndex; // 0 or 1
  final List<List<NoteTabItem>> panes; // panes[0] and panes[1]
  final List<int> activeTabIndices; // [activeIdxPane0, activeIdxPane1]

  const NoteWorkspaceState({
    required this.isSidebarOpen,
    required this.isSplit,
    required this.splitRatio,
    required this.activePaneIndex,
    required this.panes,
    required this.activeTabIndices,
  });

  NoteTabItem? get activeTabInActivePane {
    if (panes.isEmpty || activePaneIndex >= panes.length) return null;
    final tabs = panes[activePaneIndex];
    final activeIdx = activeTabIndices[activePaneIndex];
    if (tabs.isEmpty || activeIdx < 0 || activeIdx >= tabs.length) return null;
    return tabs[activeIdx];
  }

  NoteWorkspaceState copyWith({
    bool? isSidebarOpen,
    bool? isSplit,
    double? splitRatio,
    int? activePaneIndex,
    List<List<NoteTabItem>>? panes,
    List<int>? activeTabIndices,
  }) {
    return NoteWorkspaceState(
      isSidebarOpen: isSidebarOpen ?? this.isSidebarOpen,
      isSplit: isSplit ?? this.isSplit,
      splitRatio: splitRatio ?? this.splitRatio,
      activePaneIndex: activePaneIndex ?? this.activePaneIndex,
      panes: panes ?? this.panes,
      activeTabIndices: activeTabIndices ?? this.activeTabIndices,
    );
  }
}

final noteWorkspaceProvider =
    NotifierProvider<NoteWorkspaceNotifier, NoteWorkspaceState>(() {
  return NoteWorkspaceNotifier();
});

class NoteWorkspaceNotifier extends Notifier<NoteWorkspaceState> {
  @override
  NoteWorkspaceState build() {
    return const NoteWorkspaceState(
      isSidebarOpen: true,
      isSplit: false,
      splitRatio: 0.5,
      activePaneIndex: 0,
      panes: [<NoteTabItem>[], <NoteTabItem>[]],
      activeTabIndices: [0, 0],
    );
  }

  /// Initializes the workspace with an optional initial note ID or creates a blank tab
  void initialize({String? initialNoteId, String? initialTitle, bool isWideScreen = true}) {
    final firstTab = initialNoteId != null && initialNoteId.isNotEmpty
        ? NoteTabItem(id: initialNoteId, title: initialTitle ?? 'Untitled Note')
        : NoteTabItem(
            id: 'new_${DateTime.now().millisecondsSinceEpoch}',
            title: 'Untitled Note',
            isNew: true,
          );

    state = NoteWorkspaceState(
      isSidebarOpen: isWideScreen,
      isSplit: false,
      splitRatio: 0.5,
      activePaneIndex: 0,
      panes: [
        [firstTab],
        <NoteTabItem>[],
      ],
      activeTabIndices: [0, 0],
    );
  }

  /// Open an existing note in the active pane (or targetPane)
  void openNote(String noteId, {String? title, int? targetPane}) {
    final paneIdx = targetPane ?? state.activePaneIndex;
    final targetTabs = List<NoteTabItem>.from(state.panes[paneIdx]);
    final otherPaneIdx = 1 - paneIdx;
    final otherTabs = List<NoteTabItem>.from(state.panes[otherPaneIdx]);

    // Check if it is already open in target pane
    final existingIndex = targetTabs.indexWhere((t) => t.id == noteId);
    if (existingIndex != -1) {
      final updatedActive = List<int>.from(state.activeTabIndices);
      updatedActive[paneIdx] = existingIndex;
      state = state.copyWith(
        activePaneIndex: paneIdx,
        activeTabIndices: updatedActive,
      );
      return;
    }

    // Add note to target pane
    final newTab = NoteTabItem(id: noteId, title: title ?? 'Untitled Note');
    targetTabs.add(newTab);

    final newPanes = <List<NoteTabItem>>[];
    final updatedActive = List<int>.from(state.activeTabIndices);

    if (paneIdx == 0) {
      newPanes.add(targetTabs);
      newPanes.add(otherTabs);
      updatedActive[0] = targetTabs.length - 1;
    } else {
      newPanes.add(otherTabs);
      newPanes.add(targetTabs);
      updatedActive[1] = targetTabs.length - 1;
    }

    state = state.copyWith(
      panes: newPanes,
      activePaneIndex: paneIdx,
      activeTabIndices: updatedActive,
    );
  }

  /// Open a new blank note tab
  void openNewNote({int? targetPane}) {
    final paneIdx = targetPane ?? state.activePaneIndex;
    final targetTabs = List<NoteTabItem>.from(state.panes[paneIdx]);
    final otherPaneIdx = 1 - paneIdx;
    final otherTabs = List<NoteTabItem>.from(state.panes[otherPaneIdx]);

    final newTab = NoteTabItem(
      id: 'new_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Untitled Note',
      isNew: true,
    );
    targetTabs.add(newTab);

    final newPanes = <List<NoteTabItem>>[];
    final updatedActive = List<int>.from(state.activeTabIndices);

    if (paneIdx == 0) {
      newPanes.add(targetTabs);
      newPanes.add(otherTabs);
      updatedActive[0] = targetTabs.length - 1;
    } else {
      newPanes.add(otherTabs);
      newPanes.add(targetTabs);
      updatedActive[1] = targetTabs.length - 1;
    }

    state = state.copyWith(
      panes: newPanes,
      activePaneIndex: paneIdx,
      activeTabIndices: updatedActive,
    );
  }

  /// Switch active tab within a pane
  void switchTab(int paneIndex, int tabIndex) {
    if (paneIndex < 0 || paneIndex >= state.panes.length) return;
    if (tabIndex < 0 || tabIndex >= state.panes[paneIndex].length) return;

    final updatedActive = List<int>.from(state.activeTabIndices);
    updatedActive[paneIndex] = tabIndex;

    state = state.copyWith(
      activePaneIndex: paneIndex,
      activeTabIndices: updatedActive,
    );
  }

  /// Update tab title dynamically when editing note header
  void updateTabTitle(String noteId, String newTitle) {
    bool changed = false;
    final newPanes = <List<NoteTabItem>>[];

    for (final pane in state.panes) {
      final updatedPane = pane.map((tab) {
        if (tab.id == noteId) {
          if (tab.title != newTitle) {
            changed = true;
            return tab.copyWith(title: newTitle.isEmpty ? 'Untitled Note' : newTitle);
          }
        }
        return tab;
      }).toList();
      newPanes.add(updatedPane);
    }

    if (changed) {
      state = state.copyWith(panes: newPanes);
    }
  }

  /// Replace a temporary tab ID with the real ID after first auto-save
  void updateTabId(String oldId, String realId, {String? title}) {
    bool changed = false;
    final newPanes = <List<NoteTabItem>>[];

    for (final pane in state.panes) {
      final updatedPane = pane.map((tab) {
        if (tab.id == oldId) {
          changed = true;
          return tab.copyWith(
            id: realId,
            title: title ?? tab.title,
            isNew: false,
          );
        }
        return tab;
      }).toList();
      newPanes.add(updatedPane);
    }

    if (changed) {
      state = state.copyWith(panes: newPanes);
    }
  }

  /// Close a tab
  void closeTab(int paneIndex, int tabIndex) {
    if (paneIndex < 0 || paneIndex >= state.panes.length) return;
    final targetTabs = List<NoteTabItem>.from(state.panes[paneIndex]);
    if (tabIndex < 0 || tabIndex >= targetTabs.length) return;

    targetTabs.removeAt(tabIndex);

    // If target pane still has tabs remaining:
    if (targetTabs.isNotEmpty) {
      final updatedActive = List<int>.from(state.activeTabIndices);
      var currentActive = updatedActive[paneIndex];
      if (currentActive >= targetTabs.length) {
        currentActive = targetTabs.length - 1;
      }
      updatedActive[paneIndex] = currentActive;

      final newPanes = <List<NoteTabItem>>[];
      if (paneIndex == 0) {
        newPanes.add(targetTabs);
        newPanes.add(List.from(state.panes[1]));
      } else {
        newPanes.add(List.from(state.panes[0]));
        newPanes.add(targetTabs);
      }

      state = state.copyWith(
        panes: newPanes,
        activeTabIndices: updatedActive,
      );
      return;
    }

    // Target pane is now empty!
    if (state.isSplit) {
      // Close split and keep the other pane
      final otherPane = 1 - paneIndex;
      final remainingTabs = List<NoteTabItem>.from(state.panes[otherPane]);
      final remainingActiveIdx = state.activeTabIndices[otherPane];

      state = state.copyWith(
        isSplit: false,
        activePaneIndex: 0,
        panes: [
          remainingTabs,
          <NoteTabItem>[],
        ],
        activeTabIndices: [remainingActiveIdx, 0],
      );
      return;
    }

    // Single pane had its only tab closed -> spawn a new blank tab
    final freshTab = NoteTabItem(
      id: 'new_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Untitled Note',
      isNew: true,
    );
    state = state.copyWith(
      panes: [
        [freshTab],
        <NoteTabItem>[],
      ],
      activeTabIndices: [0, 0],
      activePaneIndex: 0,
    );
  }

  /// Enable split mode
  void splitPane() {
    if (state.isSplit) return;

    final pane0Tabs = List<NoteTabItem>.from(state.panes[0]);
    final active0 = state.activeTabIndices[0];

    List<NoteTabItem> pane1Tabs;
    int active1 = 0;

    if (pane0Tabs.length > 1) {
      // If pane 0 has multiple tabs, move or open the active tab into pane 1
      final movedTab = pane0Tabs.removeAt(active0);
      pane1Tabs = [movedTab];
      final newActive0 = active0 >= pane0Tabs.length ? pane0Tabs.length - 1 : active0;
      state = state.copyWith(
        isSplit: true,
        activePaneIndex: 1,
        panes: [pane0Tabs, pane1Tabs],
        activeTabIndices: [newActive0, active1],
      );
    } else {
      // Pane 0 only has 1 tab: open a new note in pane 1
      pane1Tabs = [
        NoteTabItem(
          id: 'new_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Untitled Note',
          isNew: true,
        ),
      ];
      state = state.copyWith(
        isSplit: true,
        activePaneIndex: 1,
        panes: [pane0Tabs, pane1Tabs],
        activeTabIndices: [active0, 0],
      );
    }
  }

  /// Close split mode and merge tabs into pane 0
  void closeSplit({int paneToKeep = 0}) {
    if (!state.isSplit) return;

    final allTabs = <NoteTabItem>[];
    allTabs.addAll(state.panes[0]);
    for (final tab in state.panes[1]) {
      if (!allTabs.any((t) => t.id == tab.id)) {
        allTabs.add(tab);
      }
    }

    final activeTab = state.panes[paneToKeep].isNotEmpty
        ? state.panes[paneToKeep][state.activeTabIndices[paneToKeep]]
        : (allTabs.isNotEmpty ? allTabs.first : null);

    final newActiveIdx = activeTab != null
        ? allTabs.indexWhere((t) => t.id == activeTab.id)
        : 0;

    state = state.copyWith(
      isSplit: false,
      activePaneIndex: 0,
      panes: [
        allTabs,
        <NoteTabItem>[],
      ],
      activeTabIndices: [newActiveIdx >= 0 ? newActiveIdx : 0, 0],
    );
  }

  /// Move a tab from one pane to another
  void moveTabToOtherPane(int fromPane, int tabIndex) {
    if (!state.isSplit) return;
    if (fromPane < 0 || fromPane >= state.panes.length) return;
    final sourceTabs = List<NoteTabItem>.from(state.panes[fromPane]);
    if (tabIndex < 0 || tabIndex >= sourceTabs.length) return;

    final toPane = 1 - fromPane;
    final targetTabs = List<NoteTabItem>.from(state.panes[toPane]);

    final tabToMove = sourceTabs.removeAt(tabIndex);
    targetTabs.add(tabToMove);

    if (sourceTabs.isEmpty) {
      // Source pane is now empty, collapse split
      state = state.copyWith(
        isSplit: false,
        activePaneIndex: 0,
        panes: [
          targetTabs,
          <NoteTabItem>[],
        ],
        activeTabIndices: [targetTabs.length - 1, 0],
      );
      return;
    }

    final updatedActive = List<int>.from(state.activeTabIndices);
    var sourceActive = updatedActive[fromPane];
    if (sourceActive >= sourceTabs.length) {
      sourceActive = sourceTabs.length - 1;
    }
    updatedActive[fromPane] = sourceActive;
    updatedActive[toPane] = targetTabs.length - 1;

    final newPanes = <List<NoteTabItem>>[];
    if (fromPane == 0) {
      newPanes.add(sourceTabs);
      newPanes.add(targetTabs);
    } else {
      newPanes.add(targetTabs);
      newPanes.add(sourceTabs);
    }

    state = state.copyWith(
      panes: newPanes,
      activePaneIndex: toPane,
      activeTabIndices: updatedActive,
    );
  }

  /// Toggle sidebar visibility
  void toggleSidebar({bool? force}) {
    state = state.copyWith(
      isSidebarOpen: force ?? !state.isSidebarOpen,
    );
  }

  /// Update the split divider position
  void setSplitRatio(double ratio) {
    final clamped = ratio.clamp(0.2, 0.8);
    state = state.copyWith(splitRatio: clamped);
  }
}
