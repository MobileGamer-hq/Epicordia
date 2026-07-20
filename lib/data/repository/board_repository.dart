import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../providers.dart';

final boardRepositoryProvider = Provider<BoardRepository>((ref) => BoardRepository(ref));

final allBoardsProvider = StreamProvider<List<BoardEntity>>((ref) {
  return ref.watch(boardRepositoryProvider).watchAllBoards();
});

class BoardRepository {
  final Ref ref;

  BoardRepository(this.ref);

  Stream<List<BoardEntity>> watchAllBoards() {
    return ref.watch(boardDaoProvider).watchAllBoards();
  }

  Future<BoardEntity?> getBoard(String id) {
    return ref.read(boardDaoProvider).getBoard(id);
  }

  Future<void> createBoard(BoardsCompanion board) {
    return ref.read(boardDaoProvider).insertBoard(board);
  }

  Future<void> updateBoard(BoardEntity board) {
    return ref.read(boardDaoProvider).updateBoard(board);
  }

  Future<void> deleteBoard(String id) {
    return ref.read(boardDaoProvider).deleteBoard(id);
  }
}
