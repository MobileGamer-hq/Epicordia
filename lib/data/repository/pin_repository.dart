import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart';
import '../database/database.dart';
import '../providers.dart';

part 'pin_repository.g.dart';

@riverpod
class PinRepository extends _$PinRepository {
  @override
  Stream<List<PinEntity>> build(String boardId) {
    return ref.watch(pinDaoProvider).watchPinsForBoard(boardId);
  }

  Future<void> createPin(PinsCompanion pin) {
    return ref.read(pinDaoProvider).insertPin(pin);
  }

  Future<void> updatePin(PinEntity pin) {
    return ref.read(pinDaoProvider).updatePin(pin);
  }

  Future<void> deletePin(String id) {
    return ref.read(pinDaoProvider).deletePin(id);
  }
}
