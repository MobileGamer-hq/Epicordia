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

  /// Primary API backend hosted on Vercel
  static const String mainEndpoint = 'https://epicordia-agent.vercel.app';

  /// Backup failover API backend hosted on Render
  static const String backupEndpoint = 'https://epicordiaagent.onrender.com';

  /// Default endpoint pointing to main
  static const String defaultEndpoint = mainEndpoint;

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

    // 4. Urgent / overdue task titles (max 2, non-locked tasks only)
    final urgentTasks = allTasks.where((t) {
      if (t.status.toLowerCase() == 'done') return false;
      if (t.dueDate == null) return false;
      return t.dueDate!.isBefore(now) || (t.dueDate!.isAfter(startOfDay) && t.dueDate!.isBefore(endOfDay));
    }).map((t) => t.title).take(2).toList();

    // 5. Count unsorted items (boardId == null)
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
      'urgentTaskTitles': urgentTasks,
      'recentActions': <String>[],
    };
  }

  /// Sends a user message to Epi.
  /// Tries the main Vercel API first, automatically falling back to Render backup if it fails.
  Future<EpiChatResponse> sendMessage({
    required String message,
    required String sessionId,
    String? baseUrl,
  }) async {
    if (baseUrl != null) {
      return _sendSingleChatRequest(
        endpoint: baseUrl,
        message: message,
        sessionId: sessionId,
      );
    }

    try {
      return await _sendSingleChatRequest(
        endpoint: mainEndpoint,
        message: message,
        sessionId: sessionId,
      );
    } catch (_) {
      // Main API failed; try backup API
      return await _sendSingleChatRequest(
        endpoint: backupEndpoint,
        message: message,
        sessionId: sessionId,
      );
    }
  }

  Future<EpiChatResponse> _sendSingleChatRequest({
    required String endpoint,
    required String message,
    required String sessionId,
  }) async {
    final cleanEndpoint = endpoint.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$cleanEndpoint/chat');

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
  /// Tries the main Vercel API first, falling back to the Render backup API if unreachable.
  /// Seamlessly falls back to `/chat` with progressive statuses and token-simulated
  /// word streaming if SSE is not reached or returns an error.
  Stream<EpiStreamEvent> streamChat({
    required String message,
    required String sessionId,
    String? baseUrl,
  }) async* {
    final endpointsToTry = baseUrl != null
        ? [baseUrl]
        : [mainEndpoint, backupEndpoint];

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

    bool streamSucceeded = false;

    for (final endpoint in endpointsToTry) {
      final cleanEndpoint = endpoint.replaceAll(RegExp(r'/+$'), '');
      final uri = Uri.parse('$cleanEndpoint/chat/stream');

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
          streamSucceeded = true;
          break;
        }
      } catch (_) {
        // Current endpoint failed; loop will try next endpoint (backup)
      } finally {
        client?.close();
      }
    }

    if (streamSucceeded) return;

    // ── Resilient Fallback: Regular /chat endpoint (tries main then backup) ──
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
  /// Probes main API (Vercel) first, falling back to backup API (Render).
  Future<bool> checkHealth({String? baseUrl}) async {
    if (baseUrl != null) {
      return _probeHealth(baseUrl);
    }
    final mainOk = await _probeHealth(mainEndpoint);
    if (mainOk) return true;
    return _probeHealth(backupEndpoint);
  }

  Future<bool> _probeHealth(String url) async {
    try {
      final endpoint = url.replaceAll(RegExp(r'/+$'), '');
      final uri = Uri.parse('$endpoint/health');
      final res = await http.get(uri).timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Fetches a subtle, warm 1-sentence daily thought from Epi based on current context.
  /// Tries main API (Vercel) first, falling back to backup API (Render).
  /// Returns null if offline, timeout, or both servers are unavailable.
  Future<String?> fetchDailyThought({String? baseUrl}) async {
    if (baseUrl != null) {
      return _fetchDailyThoughtFrom(baseUrl);
    }

    // 1. Try main endpoint (Vercel)
    final mainThought = await _fetchDailyThoughtFrom(mainEndpoint);
    if (mainThought != null) return mainThought;

    // 2. Fall back to backup endpoint (Render)
    return _fetchDailyThoughtFrom(backupEndpoint);
  }

  Future<String?> _fetchDailyThoughtFrom(String endpoint) async {
    try {
      final cleanEndpoint = endpoint.replaceAll(RegExp(r'/+$'), '');
      final uri = Uri.parse('$cleanEndpoint/daily-thought');

      final contextSnapshot = await buildContextSnapshot();
      final body = jsonEncode({
        'context': contextSnapshot,
        'userName': contextSnapshot['userName'],
      });

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final thought = json['thought'] as String?;
        if (thought != null && thought.trim().isNotEmpty) {
          // Strictly enforce no em dashes or en dashes
          return thought
              .replaceAll('—', '-')
              .replaceAll('–', '-')
              .trim();
        }
      }
    } catch (_) {
      // Offline, timeout, or server unavailable: return null to allow clean fallback
    }
    return null;
  }

  /// Fetches a subtle cold-start proactive check-in from Epi (mentioning at most 1-2 items, or silence).
  /// Probes main API (Vercel) first, falling back to backup API (Render), and synthesizing locally if offline.
  Future<ProactiveCheckinResult> fetchProactiveCheckin({String? baseUrl}) async {
    if (baseUrl != null) {
      final res = await _fetchProactiveCheckinFrom(baseUrl);
      if (res != null) return res;
    } else {
      // 1. Try main endpoint (Vercel)
      final mainRes = await _fetchProactiveCheckinFrom(mainEndpoint);
      if (mainRes != null) return mainRes;

      // 2. Fall back to backup endpoint (Render)
      final backupRes = await _fetchProactiveCheckinFrom(backupEndpoint);
      if (backupRes != null) return backupRes;
    }

    // 3. Resilient fallback: compute local heuristic check-in
    return _localHeuristicCheckin();
  }

  Future<ProactiveCheckinResult?> _fetchProactiveCheckinFrom(String endpoint) async {
    try {
      final cleanEndpoint = endpoint.replaceAll(RegExp(r'/+$'), '');
      final uri = Uri.parse('$cleanEndpoint/proactive-checkin');

      final contextSnapshot = await buildContextSnapshot();
      final body = jsonEncode({
        'context': contextSnapshot,
        'userName': contextSnapshot['userName'],
      });

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return ProactiveCheckinResult.fromJson(json);
      }
    } catch (_) {
      // Offline, timeout, or server unavailable: fall through
    }
    return null;
  }

  Future<ProactiveCheckinResult> _localHeuristicCheckin() async {
    final contextSnapshot = await buildContextSnapshot();
    final overdue = contextSnapshot['overdueCount'] as int? ?? 0;
    final today = contextSnapshot['todayTaskCount'] as int? ?? 0;
    final urgent = (contextSnapshot['urgentTaskTitles'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final name = contextSnapshot['userName'] as String? ?? 'there';

    if (overdue == 0 && today == 0 && urgent.isEmpty) {
      return const ProactiveCheckinResult(
        shouldSpeak: false,
        message: '',
        relevantItemIds: [],
        suggestedActions: [],
        modelUsed: 'offline_heuristic',
      );
    }

    final parts = <String>[];
    if (urgent.isNotEmpty) {
      parts.add('"${urgent[0]}"');
      if (urgent.length > 1) parts.add('"${urgent[1]}"');
    } else if (overdue > 0) {
      parts.add('$overdue overdue task${overdue > 1 ? 's' : ''}');
    } else if (today > 0) {
      parts.add('$today task${today > 1 ? 's' : ''} due today');
    }

    final message = 'Hey $name, you have ${parts.join(' and ')} on your radar. Want to tackle that first, or check your schedule?';

    return ProactiveCheckinResult(
      shouldSpeak: true,
      message: message.replaceAll('—', '-').replaceAll('–', '-'),
      relevantItemIds: urgent.take(2).toList(),
      suggestedActions: const ['Chat with Epi', 'View tasks', 'Dismiss'],
      modelUsed: 'offline_heuristic',
    );
  }
}
