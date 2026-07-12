import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart';
import '../database/database.dart';
import '../providers.dart';

part 'board_repository.g.dart';

@riverpod
class BoardRepository extends _$BoardRepository {
  @override
  Stream<List<BoardEntity>> build() {
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
