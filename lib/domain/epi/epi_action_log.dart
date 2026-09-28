import 'package:flutter_riverpod/flutter_riverpod.dart';

class EpiLogEntry {
  final String id;
  final String tool;
  final String tier;
  final Map<String, dynamic> parameters;
  final String? entityId;
  final String summary;
  final DateTime timestamp;
  final Future<void> Function()? undoAction;

  const EpiLogEntry({
    required this.id,
    required this.tool,
    required this.tier,
    required this.parameters,
    this.entityId,
    required this.summary,
    required this.timestamp,
    this.undoAction,
  });
}

class EpiActionLogNotifier extends Notifier<List<EpiLogEntry>> {
  @override
  List<EpiLogEntry> build() {
    return [];
  }

  void recordAction(EpiLogEntry entry) {
    state = [...state, entry];
  }

  Future<String?> undoLastAction() async {
    if (state.isEmpty) return null;
    final last = state.last;
    if (last.undoAction != null) {
      await last.undoAction!();
    }
    state = state.sublist(0, state.length - 1);
    return 'Undid: ${last.summary}';
  }

  void clearLog() {
    state = [];
  }
}

final epiActionLogProvider =
    NotifierProvider<EpiActionLogNotifier, List<EpiLogEntry>>(EpiActionLogNotifier.new);
