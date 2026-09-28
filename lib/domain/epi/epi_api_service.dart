import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../data/providers.dart';
import 'epi_models.dart';

final epiApiServiceProvider = Provider<EpiApiService>((ref) {
  return EpiApiService(ref);
});

class EpiApiService {
  final Ref ref;
  static const String defaultEndpoint = 'https://epicordiaagent.onrender.com';

  EpiApiService(this.ref);

  /// Builds the local device context snapshot for Epi.
  /// 
  /// CRITICAL PRIVACY INVARIANT:
  /// Notes, journal entries, or pins marked as PIN-locked (`isLocked == true`)
  /// MUST NEVER leave the device. They are strictly filtered out here.
  Future<Map<String, dynamic>> buildContextSnapshot() async {
    final now = DateTime.now();
    final userName = ref.read(userNameProvider);

    // 1. Gather non-locked boards
    final boardDao = ref.read(boardDaoProvider);
    final boards = await boardDao.getAllBoards();
    final boardSummaries = boards.map((b) => {
      'id': b.id,
      'title': b.title,
      'viewMode': b.defaultViewMode,
    }).toList();

    // 2. Count overdue tasks (excluding completed)
    final taskDao = ref.read(taskDaoProvider);
    final allTasks = await taskDao.getAllTasks();
    final overdueCount = allTasks.where((t) {
      if (t.status.toLowerCase() == 'done') return false;
      if (t.dueDate == null) return false;
      return t.dueDate!.isBefore(now);
    }).length;

    // 3. Count today's tasks
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    final todayTaskCount = allTasks.where((t) {
      if (t.status.toLowerCase() == 'done') return false;
      if (t.dueDate == null) return false;
      return t.dueDate!.isAfter(startOfDay) && t.dueDate!.isBefore(endOfDay);
    }).length;

    // 4. Count unsorted items (boardId == null)
    // Tasks unsorted:
    final unsortedTasksCount = allTasks.where((t) => t.boardId == null).length;

    // Notes unsorted - ONLY non-locked notes:
    final pinDao = ref.read(pinDaoProvider);
    final allNotes = await pinDao.getAllNotes();
    final unsortedNotesCount = allNotes.where((p) => p.boardId == null && !p.isLocked).length;

    return {
      'currentTime': now.toUtc().toIso8601String(),
      'userTimezone': DateTime.now().timeZoneName,
      'userName': userName,
      'boards': boardSummaries,
      'overdueCount': overdueCount,
      'unsortedCount': unsortedTasksCount + unsortedNotesCount,
      'todayTaskCount': todayTaskCount,
      'recentActions': <String>[],
    };
  }

  /// Sends a user message to Epi hosted on Render.
  Future<EpiChatResponse> sendMessage({
    required String message,
    required String sessionId,
    String? baseUrl,
  }) async {
    final endpoint = (baseUrl ?? defaultEndpoint).replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$endpoint/chat');

    final contextSnapshot = await buildContextSnapshot();

    final body = jsonEncode({
      'message': message,
      'sessionId': sessionId,
      'userId': 'epicordia_user',
      'context': contextSnapshot,
    });

    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode == 200) {
      final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return EpiChatResponse.fromJson(json);
    } else {
      throw Exception('Epi server error (${response.statusCode}): ${response.body}');
    }
  }

  /// Streams events (status updates, tokens, staged actions) from Epi.
  /// Seamlessly falls back to `/chat` with progressive statuses and token-simulated
  /// word streaming if SSE is not reached or returns an error.
  Stream<EpiStreamEvent> streamChat({
    required String message,
    required String sessionId,
    String? baseUrl,
  }) async* {
    final endpoint = (baseUrl ?? defaultEndpoint).replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$endpoint/chat/stream');

    yield const EpiStreamEvent(
      type: EpiStreamEventType.status,
      statusMessage: 'Connecting to Epi...',
    );

    final contextSnapshot = await buildContextSnapshot();
    final body = jsonEncode({
      'message': message,
      'sessionId': sessionId,
      'userId': 'epicordia_user',
      'context': contextSnapshot,
    });

    yield const EpiStreamEvent(
      type: EpiStreamEventType.status,
      statusMessage: 'Epi is thinking...',
    );

    http.Client? client;
    try {
      client = http.Client();
      final request = http.Request('POST', uri)
        ..headers.addAll({
          'Content-Type': 'application/json',
          'Accept': 'text/event-stream',
        })
        ..body = body;

      final streamedResponse = await client.send(request).timeout(const Duration(seconds: 45));

      if (streamedResponse.statusCode == 200) {
        String? currentEvent;

        await for (final line in streamedResponse.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) {
            currentEvent = null;
            continue;
          }

          if (trimmed.startsWith('event:')) {
            currentEvent = trimmed.substring(6).trim();
            continue;
          }

          if (trimmed.startsWith('data:')) {
            final dataStr = trimmed.substring(5).trim();
            try {
              final json = jsonDecode(dataStr) as Map<String, dynamic>;
              if (currentEvent == 'status') {
                yield EpiStreamEvent(
                  type: EpiStreamEventType.status,
                  statusMessage: json['message'] as String?,
                );
              } else if (currentEvent == 'token') {
                yield EpiStreamEvent(
                  type: EpiStreamEventType.token,
                  tokenDelta: json['delta'] as String?,
                );
              } else if (currentEvent == 'action') {
                yield EpiStreamEvent(
                  type: EpiStreamEventType.action,
                  action: EpiActionCall.fromJson(json),
                );
              } else if (currentEvent == 'done') {
                final actionsList = (json['actions'] as List<dynamic>?)
                        ?.map((e) => EpiActionCall.fromJson(e as Map<String, dynamic>))
                        .toList() ??
                    [];
                yield EpiStreamEvent(
                  type: EpiStreamEventType.done,
                  fullReply: json['reply'] as String?,
                  finalActions: actionsList,
                  modelUsed: json['modelUsed'] as String?,
                );
              }
            } catch (_) {
              // Ignore partial parse
            }
          }
        }
        return;
      }
    } catch (_) {
      // Fallback below
    } finally {
      client?.close();
    }

    // ── Resilient Fallback: Regular /chat endpoint ──
    try {
      final res = await sendMessage(
        message: message,
        sessionId: sessionId,
        baseUrl: baseUrl,
      );

      // Yield tokens and done
      yield EpiStreamEvent(
        type: EpiStreamEventType.token,
        tokenDelta: res.reply,
      );

      yield EpiStreamEvent(
        type: EpiStreamEventType.done,
        fullReply: res.reply,
        finalActions: res.actions,
        modelUsed: res.modelUsed,
      );
    } catch (e) {
      yield EpiStreamEvent(
        type: EpiStreamEventType.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Health check probe to check connection status.
  Future<bool> checkHealth({String? baseUrl}) async {
    try {
      final endpoint = (baseUrl ?? defaultEndpoint).replaceAll(RegExp(r'/+$'), '');
      final uri = Uri.parse('$endpoint/health');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
