import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../database/database.dart';
import '../providers.dart';

final pinRepositoryProvider = Provider<PinRepository>((ref) => PinRepository(ref));

class PinRepository {
  final Ref ref;

  PinRepository(this.ref);

  Stream<List<PinEntity>> watchPinsForBoard(String boardId) {
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
