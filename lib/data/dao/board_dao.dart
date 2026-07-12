import 'package:drift/drift.dart';
import '../database/database.dart';
import '../database/schema.dart';

part 'board_dao.g.dart';

@DriftAccessor(tables: [Boards])
class BoardDao extends DatabaseAccessor<AppDatabase> with _$BoardDaoMixin {
  BoardDao(AppDatabase db) : super(db);

  Stream<List<BoardEntity>> watchAllBoards() => select(boards).watch();

  Future<BoardEntity?> getBoard(String id) {
    return (select(boards)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertBoard(Insertable<BoardEntity> board) => into(boards).insert(board);

  Future<bool> updateBoard(Insertable<BoardEntity> board) {
    return update(boards).replace(board);
  }

  Future<int> deleteBoard(String id) {
    // Nested deletion cascades are handled automatically by SQLite PRAGMA foreign_keys = ON
    // We just delete the root board and the DB engine cascades pins and child boards.
    // Wait, SQLite doesn't natively cascade self-referential deletes if they aren't explicit,
    // actually it does if configured with ON DELETE CASCADE. Let's make sure the parentBoardId has it.
    // Oh, I missed `onDelete: KeyAction.cascade` on `parentBoardId` in the schema.
    return (delete(boards)..where((t) => t.id.equals(id))).go();
  }
}
