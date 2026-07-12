import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:app/data/database/database.dart';
import 'package:app/data/providers.dart';
import 'package:app/data/repository/board_repository.dart';
import 'package:app/domain/state/navigation_state.dart';

void main() {
  test('BoardRepository and NavigationState integrate correctly', () async {
    // Override the database provider to use an in-memory DB for tests
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(AppDatabase(NativeDatabase.memory())),
      ],
    );

    addTearDown(container.dispose);

    // Initial navigation state should be null
    final navState = container.read(navigationStateProvider);
    expect(navState, isNull);

    // Set navigation state
    container.read(navigationStateProvider.notifier).setActiveBoard('board_123');
    expect(container.read(navigationStateProvider), 'board_123');

    // Create a board via the repository
    final boardRepo = container.read(boardRepositoryProvider);
    await boardRepo.createBoard(BoardsCompanion.insert(id: 'b1', title: 'Repo Board'));

    // Verify the board was created and is emitted by the stream
    final stream = container.read(boardRepositoryProvider).watchAllBoards();
    final boards = await stream.first;
    expect(boards.length, 1);
    expect(boards.first.id, 'b1');
    expect(boards.first.title, 'Repo Board');
  });
}
