import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epicordia/domain/state/note_workspace_provider.dart';

void main() {
  group('NoteWorkspaceNotifier Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initialize creates first tab with specified note ID', () {
      final notifier = container.read(noteWorkspaceProvider.notifier);
      notifier.initialize(initialNoteId: 'note_123', initialTitle: 'My Project');

      final state = container.read(noteWorkspaceProvider);
      expect(state.panes[0].length, 1);
      expect(state.panes[0][0].id, 'note_123');
      expect(state.panes[0][0].title, 'My Project');
      expect(state.isSplit, false);
      expect(state.isSidebarOpen, true);
    });

    test('openNote adds new tab if not open, or switches to it if already open', () {
      final notifier = container.read(noteWorkspaceProvider.notifier);
      notifier.initialize(initialNoteId: 'note_1', initialTitle: 'First');

      // Open second note
      notifier.openNote('note_2', title: 'Second');
      var state = container.read(noteWorkspaceProvider);
      expect(state.panes[0].length, 2);
      expect(state.activeTabIndices[0], 1);
      expect(state.panes[0][1].id, 'note_2');

      // Open first note again -> should switch active index to 0 without adding duplicate tab
      notifier.openNote('note_1');
      state = container.read(noteWorkspaceProvider);
      expect(state.panes[0].length, 2);
      expect(state.activeTabIndices[0], 0);
    });

    test('updateTabTitle updates tab title across panes', () {
      final notifier = container.read(noteWorkspaceProvider.notifier);
      notifier.initialize(initialNoteId: 'note_1', initialTitle: 'Original Title');

      notifier.updateTabTitle('note_1', 'Updated Title');
      final state = container.read(noteWorkspaceProvider);
      expect(state.panes[0][0].title, 'Updated Title');
    });

    test('splitPane creates secondary pane and splits tabs', () {
      final notifier = container.read(noteWorkspaceProvider.notifier);
      notifier.initialize(initialNoteId: 'note_1', initialTitle: 'First');
      notifier.openNote('note_2', title: 'Second');

      // Now split pane
      notifier.splitPane();
      final state = container.read(noteWorkspaceProvider);
      expect(state.isSplit, true);
      expect(state.panes[0].length, 1);
      expect(state.panes[1].length, 1);
      expect(state.panes[1][0].id, 'note_2');
      expect(state.activePaneIndex, 1);
    });

    test('moveTabToOtherPane moves tab between panes and collapses if source becomes empty', () {
      final notifier = container.read(noteWorkspaceProvider.notifier);
      notifier.initialize(initialNoteId: 'note_1', initialTitle: 'First');
      notifier.openNote('note_2', title: 'Second');
      notifier.splitPane();

      // Panes: [ [note_1], [note_2] ]
      // Move note_2 from pane 1 to pane 0 -> pane 1 becomes empty, split auto-collapses
      notifier.moveTabToOtherPane(1, 0);
      final state = container.read(noteWorkspaceProvider);
      expect(state.isSplit, false);
      expect(state.panes[0].length, 2);
    });

    test('closing tab in single pane when only one tab remains resets to new blank tab', () {
      final notifier = container.read(noteWorkspaceProvider.notifier);
      notifier.initialize(initialNoteId: 'note_1', initialTitle: 'First');

      notifier.closeTab(0, 0);
      final state = container.read(noteWorkspaceProvider);
      expect(state.panes[0].length, 1);
      expect(state.panes[0][0].isNew, true);
      expect(state.panes[0][0].title, 'Untitled Note');
    });

    test('toggleSidebar updates sidebar visibility', () {
      final notifier = container.read(noteWorkspaceProvider.notifier);
      notifier.initialize(initialNoteId: 'note_1', isWideScreen: true);

      expect(container.read(noteWorkspaceProvider).isSidebarOpen, true);
      notifier.toggleSidebar();
      expect(container.read(noteWorkspaceProvider).isSidebarOpen, false);
      notifier.toggleSidebar();
      expect(container.read(noteWorkspaceProvider).isSidebarOpen, true);
    });
  });
}
