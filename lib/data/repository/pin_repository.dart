import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;

import '../database/database.dart';
import '../providers.dart';

final pinRepositoryProvider = Provider<PinRepository>((ref) => PinRepository(ref));

final allNotesProvider = StreamProvider<List<PinEntity>>((ref) {
  return ref.watch(pinRepositoryProvider).watchAllNotes();
});

final unsortedNotesProvider = StreamProvider<List<PinEntity>>((ref) {
  return ref.watch(pinRepositoryProvider).watchUnsortedNotes();
});

class PinRepository {
  final Ref ref;

  PinRepository(this.ref);

  Stream<List<PinEntity>> watchPinsForBoard(String boardId) {
    return ref.watch(pinDaoProvider).watchPinsForBoard(boardId);
  }

  Stream<List<PinEntity>> watchPinsForFrame(String frameId) {
    return ref.watch(pinDaoProvider).watchPinsForFrame(frameId);
  }

  Stream<List<PinEntity>> watchAllNotes() {
    return ref.watch(pinDaoProvider).watchAllNotes();
  }

  Stream<List<PinEntity>> watchUnsortedNotes() {
    return ref.watch(pinDaoProvider).watchUnsortedNotes();
  }


  Future<PinEntity?> getPin(String id) {
    return ref.read(pinDaoProvider).getPin(id);
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

  Future<void> updatePinPosition(
    String id, {
    required double x,
    required double y,
    double? width,
    double? height,
  }) async {
    final pin = await ref.read(pinDaoProvider).getPin(id);
    if (pin == null) return;

    await ref.read(pinDaoProvider).updatePin(
          pin.copyWith(
            x: x,
            y: y,
            width: width ?? pin.width,
            height: height ?? pin.height,
            modifiedAt: DateTime.now(),
          ),
        );
  }

  /// Convenience method to update just the content field of a pin.
  Future<void> updatePinContent(String id, String content) async {
    final pin = await ref.read(pinDaoProvider).getPin(id);
    if (pin == null) return;
    await ref.read(pinDaoProvider).updatePin(
          pin.copyWith(content: Value(content), modifiedAt: DateTime.now()),
        );
  }



  Future<PinEntity> createNoteOnBoard(
    String? boardId, {
    double x = 80,
    double y = 80,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await createPin(
      PinsCompanion.insert(
        id: id,
        boardId: Value(boardId),
        type: 'note',
        x: Value(x),
        y: Value(y),
        width: const Value(220),
        height: const Value(160),
        content: const Value('New Note\n\nTap to edit'),
      ),
    );
    return (await ref.read(pinDaoProvider).getPin(id))!;
  }

  Future<PinEntity> createTaskOnBoard(
    String? boardId, {
    double x = 80,
    double y = 80,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await createPin(
      PinsCompanion.insert(
        id: id,
        boardId: Value(boardId),
        type: 'task',
        x: Value(x),
        y: Value(y),
        width: const Value(240),
        height: const Value(100),
        content: const Value('New task'),
      ),
    );
    return (await ref.read(pinDaoProvider).getPin(id))!;
  }
}
