import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:drift/drift.dart' as drift;
import '../../data/database/database.dart';
import '../../data/providers.dart';
import '../../domain/models/note_model.dart';
import '../../domain/models/task_subitem.dart';
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

  static String _formatOffset(Duration offset) {
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    return '$sign$hours:$minutes';
  }

  static String _formatHumanReadableLocalTime(DateTime dt) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final dayName = days[dt.weekday - 1];
    final monthName = months[dt.month - 1];
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$dayName, $monthName ${dt.day}, ${dt.year} at $hour12:$minute $period';
  }

  /// Builds the local device context snapshot for Epi.
  /// 
  /// CRITICAL PRIVACY INVARIANT:
  /// Notes, journal entries, or pins marked as PIN-locked (`isLocked == true`)
  /// MUST NEVER leave the device. They are strictly filtered out here.
  Future<Map<String, dynamic>> buildContextSnapshot({
    String? userQuery,
    List<EpiAttachedItem>? attachedItems,
  }) async {
    final now = DateTime.now();
    final userName = ref.read(userNameProvider);

    final boardDao = ref.read(boardDaoProvider);
    final pinDao = ref.read(pinDaoProvider);
    final taskDao = ref.read(taskDaoProvider);
    final timetableDao = ref.read(timetableDaoProvider);

    // 1. Gather non-locked boards
    final boards = await boardDao.getAllBoards();
    final boardMap = {for (final b in boards) b.id: b.title};
    final boardSummaries = boards.map((b) => {
      'id': b.id,
      'title': b.title,
      'viewMode': b.defaultViewMode,
    }).toList();

    // 2. "About Me" Note: Find or auto-create, strictly non-locked
    final allNotes = await pinDao.getAllNotes();
    PinEntity? aboutMePin;
    for (final note in allNotes) {
      if (note.isLocked) continue;
      final blocks = NoteDocument.decodeBlocks(note.content ?? '');
      if (blocks.isNotEmpty) {
        final title = blocks.first.text.trim().toLowerCase();
        if (title == 'about me' || title == '# about me') {
          aboutMePin = note;
          break;
        }
      }
    }

    String aboutMeContent = '';
    if (aboutMePin == null) {
      // Auto-create on first Epi usage so both user and Epi have it immediately
      final newId = DateTime.now().millisecondsSinceEpoch.toString();
      final initialBlocks = [
        NoteBlock(type: BlockType.heading, text: 'About Me'),
        NoteBlock(
          type: BlockType.paragraph,
          text: 'Preferences, routines, background, and goals learned by Epi.',
        ),
      ];
      final contentJson = NoteDocument.encode(NoteDocumentPayload(blocks: initialBlocks));
      await pinDao.insertPin(PinsCompanion.insert(
        id: newId,
        type: 'note',
        content: drift.Value(contentJson),
        tags: const drift.Value('Profile'),
      ));
      aboutMeContent = 'About Me\nPreferences, routines, background, and goals learned by Epi.';
    } else {
      final blocks = NoteDocument.decodeBlocks(aboutMePin.content ?? '');
      aboutMeContent = NoteDocument.exportToMarkdown(blocks);
    }

    // 3. Timetable / Schedule slots
    final allSlots = await timetableDao.getAllSlots();
    final scheduleSlots = allSlots.map((s) => {
      'id': s.id,
      'title': s.title,
      'dayOfWeek': s.dayOfWeek,
      'startTime': s.startTime,
      'endTime': s.endTime,
      'location': s.location,
      'notes': s.notes,
    }).toList();

    // 4. Tasks and Subtasks
    final allTasks = await taskDao.getAllTasks();
    final overdueCount = allTasks.where((t) {
      if (t.status.toLowerCase() == 'done') return false;
      if (t.dueDate == null) return false;
      return t.dueDate!.isBefore(now);
    }).length;

    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    final todayTaskCount = allTasks.where((t) {
      if (t.status.toLowerCase() == 'done') return false;
      if (t.dueDate == null) return false;
      return t.dueDate!.isAfter(startOfDay) && t.dueDate!.isBefore(endOfDay);
    }).length;

    final urgentTasks = allTasks.where((t) {
      if (t.status.toLowerCase() == 'done') return false;
      if (t.dueDate == null) return false;
      return t.dueDate!.isBefore(now) || (t.dueDate!.isAfter(startOfDay) && t.dueDate!.isBefore(endOfDay));
    }).map((t) => t.title).take(2).toList();

    final unsortedTasksCount = allTasks.where((t) => t.boardId == null).length;
    final unsortedNotesCount = allNotes.where((p) => p.boardId == null && !p.isLocked).length;

    // Filter relevant tasks for context:
    // If user attached specific tasks: prioritize them first!
    // Plus tasks matching keywords in userQuery, plus active tasks (todo / in_progress / due today / overdue)
    final queryLower = (userQuery ?? '').toLowerCase();
    const commonStopwords = {
      'the', 'and', 'for', 'that', 'this', 'with', 'have', 'any', 'task', 'tasks',
      'about', 'what', 'you', 'can', 'are', 'not', 'did', 'does', 'from', 'all',
      'get', 'show', 'tell', 'see', 'look', 'find', 'there', 'some'
    };
    final rawTokens = queryLower
        .split(RegExp(r'[^a-zA-Z0-9_-]+'))
        .where((tok) => tok.length >= 2)
        .toList();
    final meaningfulTokens =
        rawTokens.where((tok) => !commonStopwords.contains(tok)).toList();

    final attachedTaskIds = (attachedItems ?? [])
        .where((a) => a.type == EpiAttachedItemType.task)
        .map((a) => a.id)
        .toSet();

    // Score and rank all tasks
    final scoredTasks = <({TaskEntity task, int score, TaskNotesPayload decoded})>[];

    for (final t in allTasks) {
      final isAttached = attachedTaskIds.contains(t.id);
      final decodedNotes = TaskSubitem.decodeNotes(t.notes);
      final tTitle = t.title.toLowerCase();
      final userNotesLower = decodedNotes.userNotes?.toLowerCase() ?? '';
      final subtasksText =
          decodedNotes.subitems.map((s) => s.title.toLowerCase()).join(' ');

      int score = 0;
      if (isAttached) {
        score += 1000;
      }

      if (meaningfulTokens.isNotEmpty) {
        for (final tok in meaningfulTokens) {
          if (tTitle == tok) {
            score += 100;
          } else if (tTitle.contains(tok)) {
            score += 50;
          }
          if (subtasksText.contains(tok)) {
            score += 30;
          }
          if (userNotesLower.contains(tok)) {
            score += 20;
          }
        }
      }

      if (t.status.toLowerCase() != 'done') {
        score += 2;
        if (t.dueDate != null && t.dueDate!.isBefore(endOfDay)) {
          score += 3;
        }
      }

      scoredTasks.add((task: t, score: score, decoded: decodedNotes));
    }

    // Sort descending by score
    scoredTasks.sort((a, b) => b.score.compareTo(a.score));

    final hasSpecificQueryMatches = scoredTasks.any((st) => st.score >= 20);

    const greetingWords = {'hey', 'hi', 'hello', 'yo', 'sup', 'morning', 'afternoon', 'evening', 'howdy'};
    final isCasualGreeting = (attachedItems == null || attachedItems.isEmpty) &&
        (meaningfulTokens.isEmpty || meaningfulTokens.every((t) => greetingWords.contains(t)));

    final taskContextList = <Map<String, dynamic>>[];
    final maxTasks = isCasualGreeting ? 0 : (hasSpecificQueryMatches ? 10 : 15);

    for (final item in scoredTasks) {
      final t = item.task;
      final decodedNotes = item.decoded;
      final subtasksFormatted = decodedNotes.subitems
          .map((s) => '${s.isDone ? "[x]" : "[ ]"} ${s.title}')
          .toList();

      if (hasSpecificQueryMatches && item.score < 2) continue;

      taskContextList.add({
        'id': t.id,
        'title': t.title,
        'status': t.status,
        'priority': t.priority,
        'dueDate': t.dueDate?.toIso8601String(),
        'scheduledDate': t.scheduledDate?.toIso8601String(),
        'boardTitle': t.boardId != null ? (boardMap[t.boardId] ?? 'Board') : 'Unsorted',
        'subtasks': subtasksFormatted,
        'notes': decodedNotes.userNotes,
        if (item.score >= 20) 'isRelevantMatch': true,
      });

      if (taskContextList.length >= maxTasks) break;
    }

    // 5. Notes (strictly non-locked):
    final noteContextList = <Map<String, dynamic>>[];
    final attachedNoteIds = (attachedItems ?? [])
        .where((a) => a.type == EpiAttachedItemType.note)
        .map((a) => a.id)
        .toSet();

    for (final note in allNotes) {
      if (note.isLocked) continue; // STRICT PRIVACY INVARIANT
      final blocks = NoteDocument.decodeBlocks(note.content ?? '');
      String noteTitle = 'Untitled Note';
      String notePreview = '';
      if (blocks.isNotEmpty) {
        noteTitle = blocks.first.text.trim();
        final bodyBlocks = blocks.sublist(1);
        notePreview = bodyBlocks.map((b) => b.text).take(5).join(' ');
      }

      final isAttached = attachedNoteIds.contains(note.id);
      final matchesQuery = meaningfulTokens.isNotEmpty && meaningfulTokens.any((tok) =>
          noteTitle.toLowerCase().contains(tok) || notePreview.toLowerCase().contains(tok));

      if (isAttached || matchesQuery) {
        noteContextList.add({
          'id': note.id,
          'title': noteTitle,
          'preview': notePreview.isNotEmpty ? notePreview : noteTitle,
          'tags': note.tags,
        });
      }
      if (noteContextList.length >= 10) break;
    }

    final offsetStr = _formatOffset(now.timeZoneOffset);
    final localIso = '${now.toIso8601String()}$offsetStr';
    final humanReadable = _formatHumanReadableLocalTime(now);

    return {
      'currentTime': localIso,
      'formattedLocalTime': humanReadable,
      'userTimezone': now.timeZoneName.isNotEmpty ? now.timeZoneName : offsetStr,
      'timeZoneOffset': offsetStr,
      'userName': userName,
      'boards': boardSummaries,
      'overdueCount': overdueCount,
      'unsortedCount': unsortedTasksCount + unsortedNotesCount,
      'todayTaskCount': todayTaskCount,
      'urgentTaskTitles': urgentTasks,
      'aboutMe': aboutMeContent,
      'tasks': taskContextList,
      'notes': noteContextList,
      'scheduleSlots': scheduleSlots,
      'recentActions': <String>[],
    };
  }

  /// Sends a user message to Epi.
  /// Tries the main Vercel API first, automatically falling back to Render backup if it fails.
  Future<EpiChatResponse> sendMessage({
    required String message,
    required String sessionId,
    List<EpiAttachedItem>? attachedItems,
    List<EpiToolExecutionResult>? toolResults,
    List<EpiActionCall>? inFlightToolCalls,
    String? baseUrl,
  }) async {
    if (baseUrl != null) {
      return _sendSingleChatRequest(
        endpoint: baseUrl,
        message: message,
        sessionId: sessionId,
        attachedItems: attachedItems,
        toolResults: toolResults,
        inFlightToolCalls: inFlightToolCalls,
      );
    }

    try {
      return await _sendSingleChatRequest(
        endpoint: mainEndpoint,
        message: message,
        sessionId: sessionId,
        attachedItems: attachedItems,
        toolResults: toolResults,
        inFlightToolCalls: inFlightToolCalls,
      );
    } catch (_) {
      // Main API failed; try backup API
      return await _sendSingleChatRequest(
        endpoint: backupEndpoint,
        message: message,
        sessionId: sessionId,
        attachedItems: attachedItems,
        toolResults: toolResults,
        inFlightToolCalls: inFlightToolCalls,
      );
    }
  }

  Future<EpiChatResponse> _sendSingleChatRequest({
    required String endpoint,
    required String message,
    required String sessionId,
    List<EpiAttachedItem>? attachedItems,
    List<EpiToolExecutionResult>? toolResults,
    List<EpiActionCall>? inFlightToolCalls,
  }) async {
    final cleanEndpoint = endpoint.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$cleanEndpoint/chat');

    final contextSnapshot = await buildContextSnapshot(
      userQuery: message,
      attachedItems: attachedItems,
    );

    final body = jsonEncode({
      'message': message,
      'sessionId': sessionId,
      'userId': 'epicordia_user',
      'context': contextSnapshot,
      if (toolResults != null) 'toolResults': toolResults.map((t) => t.toJson()).toList(),
      if (inFlightToolCalls != null) 'inFlightToolCalls': inFlightToolCalls.map((a) => a.toJson()).toList(),
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
    List<EpiAttachedItem>? attachedItems,
    List<EpiToolExecutionResult>? toolResults,
    List<EpiActionCall>? inFlightToolCalls,
    String? baseUrl,
  }) async* {
    final endpointsToTry = baseUrl != null
        ? [baseUrl]
        : [mainEndpoint, backupEndpoint];

    yield const EpiStreamEvent(
      type: EpiStreamEventType.status,
      statusMessage: 'Connecting to Epi...',
    );

    final contextSnapshot = await buildContextSnapshot(
      userQuery: message,
      attachedItems: attachedItems,
    );
    final body = jsonEncode({
      'message': message,
      'sessionId': sessionId,
      'userId': 'epicordia_user',
      'context': contextSnapshot,
      if (toolResults != null) 'toolResults': toolResults.map((t) => t.toJson()).toList(),
      if (inFlightToolCalls != null) 'inFlightToolCalls': inFlightToolCalls.map((a) => a.toJson()).toList(),
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
                  final rawStatus = json['status'] as String? ?? 'final_response';
                  final parsedStatus = rawStatus == 'requires_tools'
                      ? EpiResponseStatus.requiresTools
                      : EpiResponseStatus.finalResponse;
                  yield EpiStreamEvent(
                    type: EpiStreamEventType.done,
                    fullReply: json['reply'] as String?,
                    finalActions: actionsList,
                    status: parsedStatus,
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
        attachedItems: attachedItems,
        toolResults: toolResults,
        inFlightToolCalls: inFlightToolCalls,
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
        status: res.status,
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
