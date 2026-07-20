import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../providers.dart';

final connectorRepositoryProvider = Provider<ConnectorRepository>((ref) => ConnectorRepository(ref));

class ConnectorRepository {
  final Ref ref;

  ConnectorRepository(this.ref);

  Stream<List<ConnectorEntity>> watchConnectorsForBoard(String boardId) {
    return ref.watch(connectorDaoProvider).watchConnectorsForBoard(boardId);
  }

  Future<void> createConnector(ConnectorsCompanion connector) {
    return ref.read(connectorDaoProvider).insertConnector(connector);
  }

  Future<void> updateConnector(ConnectorEntity connector) {
    return ref.read(connectorDaoProvider).updateConnector(connector);
  }

  Future<void> deleteConnector(String id) {
    return ref.read(connectorDaoProvider).deleteConnector(id);
  }
}
