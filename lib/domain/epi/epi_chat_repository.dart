import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/database.dart';
import '../../data/providers.dart';
import 'epi_models.dart';

final epiChatRepositoryProvider = Provider<EpiChatRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return EpiChatRepository(db);
});

class EpiChatRepository {
  final AppDatabase _db;
  bool _initialized = false;

  EpiChatRepository(this._db);

  Future<void> init() async {
    if (_initialized) return;
    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS epi_conversations (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        board_context TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');

    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS epi_messages (
        id TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        text TEXT NOT NULL,
        is_user INTEGER NOT NULL,
        model_used TEXT,
        action_records_json TEXT,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (conversation_id) REFERENCES epi_conversations (id) ON DELETE CASCADE
      );
    ''');
    _initialized = true;
  }

  Future<List<EpiConversation>> getConversations() async {
    await init();
    final rows = await _db.customSelect(
      'SELECT id, title, board_context, created_at, updated_at FROM epi_conversations ORDER BY updated_at DESC;',
      readsFrom: {},
    ).get();

    return rows.map((row) {
      return EpiConversation(
        id: row.read<String>('id'),
        title: row.read<String>('title'),
        boardContext: row.readNullable<String>('board_context'),
        createdAt: DateTime.tryParse(row.read<String>('created_at')) ?? DateTime.now(),
        updatedAt: DateTime.tryParse(row.read<String>('updated_at')) ?? DateTime.now(),
      );
    }).toList();
  }

  Future<void> saveConversation(EpiConversation conversation) async {
    await init();
    await _db.customStatement('''
      INSERT INTO epi_conversations (id, title, board_context, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        title = excluded.title,
        board_context = excluded.board_context,
        updated_at = excluded.updated_at;
    ''', [
      conversation.id,
      conversation.title,
      conversation.boardContext,
      conversation.createdAt.toIso8601String(),
      conversation.updatedAt.toIso8601String(),
    ]);
  }

  Future<void> deleteConversation(String conversationId) async {
    await init();
    await _db.customStatement(
      'DELETE FROM epi_messages WHERE conversation_id = ?;',
      [conversationId],
    );
    await _db.customStatement(
      'DELETE FROM epi_conversations WHERE id = ?;',
      [conversationId],
    );
  }

  Future<List<EpiChatMessage>> getMessages(String conversationId) async {
    await init();
    final rows = await _db.customSelect(
      'SELECT id, text, is_user, model_used, action_records_json, timestamp FROM epi_messages WHERE conversation_id = ? ORDER BY timestamp ASC;',
      variables: [Variable<String>(conversationId)],
      readsFrom: {},
    ).get();

    return rows.map((row) {
      final actionsJson = row.readNullable<String>('action_records_json');
      List<EpiActionExecutionRecord> actionRecords = [];
      if (actionsJson != null && actionsJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(actionsJson) as List<dynamic>;
          actionRecords = decoded
              .map((e) => EpiActionExecutionRecord.fromJson(e as Map<String, dynamic>))
              .toList();
        } catch (_) {}
      }

      return EpiChatMessage(
        id: row.read<String>('id'),
        text: row.read<String>('text'),
        isUser: row.read<int>('is_user') == 1,
        modelUsed: row.readNullable<String>('model_used'),
        actionRecords: actionRecords,
        timestamp: DateTime.tryParse(row.read<String>('timestamp')) ?? DateTime.now(),
        isStreaming: false,
      );
    }).toList();
  }

  Future<void> saveMessage(String conversationId, EpiChatMessage message) async {
    await init();
    final actionsJson = message.actionRecords.isNotEmpty
        ? jsonEncode(message.actionRecords.map((a) => a.toJson()).toList())
        : null;

    await _db.customStatement('''
      INSERT INTO epi_messages (id, conversation_id, text, is_user, model_used, action_records_json, timestamp)
      VALUES (?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        text = excluded.text,
        model_used = excluded.model_used,
        action_records_json = excluded.action_records_json;
    ''', [
      message.id,
      conversationId,
      message.text,
      message.isUser ? 1 : 0,
      message.modelUsed,
      actionsJson,
      message.timestamp.toIso8601String(),
    ]);
  }
}
