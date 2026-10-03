import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'epi_models.dart';
import 'epi_api_service.dart';
import 'epi_tool_executor.dart';
import 'epi_action_log.dart';
import 'epi_chat_repository.dart';

class EpiChatState {
  final List<EpiChatMessage> messages;
  final bool isLoading;
  final String sessionId;
  final String? error;
  final bool isBackendOnline;
  final String? statusText; // Live activity feedback: "Connecting...", "Epi is thinking...", etc.
  final String? activeStreamingId; // ID of message currently streaming

  const EpiChatState({
    required this.messages,
    required this.isLoading,
    required this.sessionId,
    this.error,
    this.isBackendOnline = true,
    this.statusText,
    this.activeStreamingId,
  });

  EpiChatState copyWith({
    List<EpiChatMessage>? messages,
    bool? isLoading,
    String? sessionId,
    String? error,
    bool? isBackendOnline,
    String? statusText,
    bool clearStatusText = false,
    String? activeStreamingId,
    bool clearActiveStreamingId = false,
  }) {
    return EpiChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      sessionId: sessionId ?? this.sessionId,
      error: error,
      isBackendOnline: isBackendOnline ?? this.isBackendOnline,
      statusText: clearStatusText ? null : (statusText ?? this.statusText),
      activeStreamingId: clearActiveStreamingId ? null : (activeStreamingId ?? this.activeStreamingId),
    );
  }
}

class EpiChatNotifier extends Notifier<EpiChatState> {
  @override
  EpiChatState build() {
    _loadInitialConversation();
    return EpiChatState(
      messages: [
        EpiChatMessage(
          id: 'welcome_msg',
          text: "Hey! I'm Epi. Think out loud with me, we can sort out your tasks, jot down notes, or just chat about how your day's going.",
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ],
      isLoading: false,
      sessionId: 'session_${const Uuid().v4().substring(0, 8)}',
    );
  }

  Future<void> _loadInitialConversation() async {
    try {
      final repo = ref.read(epiChatRepositoryProvider);
      final convs = await repo.getConversations();
      if (convs.isNotEmpty) {
        final latest = convs.first;
        final msgs = await repo.getMessages(latest.id);
        if (msgs.isNotEmpty) {
          state = state.copyWith(
            sessionId: latest.id,
            messages: msgs,
          );
        }
      }
    } catch (_) {}
  }

  // ─── Helper: update a message's text in state ───────────────────────────────
  void _updateMessageText(String id, String text, {required bool isStreaming}) {
    final cleanText = text.replaceAll('—', ' - ').replaceAll('–', '-');
    final exists = state.messages.any((m) => m.id == id);
    if (!exists) {
      if (text.isEmpty) return;
      final newMsg = EpiChatMessage(
        id: id,
        text: cleanText,
        isUser: false,
        timestamp: DateTime.now(),
        isStreaming: isStreaming,
        isWorking: true,
      );
      state = state.copyWith(messages: [...state.messages, newMsg]);
    } else {
      state = state.copyWith(
        messages: state.messages.map((m) {
          if (m.id == id) return m.copyWith(text: cleanText, isStreaming: isStreaming);
          return m;
        }).toList(),
      );
    }
  }

  // ─── Helper: patch timeline steps on a specific message ────────────────────
  void _patchTimelineStep(String msgId, EpiTimelineStep step) {
    state = state.copyWith(
      messages: state.messages.map((m) {
        if (m.id != msgId) return m;
        final existing = m.timelineSteps.toList();
        final idx = existing.indexWhere((s) => s.id == step.id);
        if (idx >= 0) {
          existing[idx] = step;
        } else {
          existing.add(step);
        }
        return m.copyWith(timelineSteps: existing);
      }).toList(),
    );
  }

  // ─── Helper: add a timeline step to a specific message ─────────────────────
  void _addTimelineStep(String msgId, EpiTimelineStep step) {
    final exists = state.messages.any((m) => m.id == msgId);
    if (!exists) {
      final newMsg = EpiChatMessage(
        id: msgId,
        text: '',
        isUser: false,
        timestamp: DateTime.now(),
        timelineSteps: [step],
        isWorking: true,
      );
      state = state.copyWith(messages: [...state.messages, newMsg]);
    } else {
      state = state.copyWith(
        messages: state.messages.map((m) {
          if (m.id != msgId) return m;
          return m.copyWith(timelineSteps: [...m.timelineSteps, step]);
        }).toList(),
      );
    }
  }

  List<String> _splitIntoWords(String text) {
    final clean = text.replaceAll('—', ' - ').replaceAll('–', '-');
    final result = <String>[];
    final regex = RegExp(r'(\S+\s*)');
    for (final match in regex.allMatches(clean)) {
      result.add(match.group(0)!);
    }
    if (result.isEmpty && clean.isNotEmpty) result.add(clean);
    return result;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // MAIN SEND MESSAGE  (up to 3 agent turns)
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> sendMessage(
    String text,
    BuildContext context, {
    List<EpiAttachedItem>? attachedItems,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isLoading) return;

    final userMsg = EpiChatMessage(
      id: const Uuid().v4(),
      text: trimmed,
      isUser: true,
      timestamp: DateTime.now(),
    );

    final assistantMsgId = const Uuid().v4();
    final initialAssistantMsg = EpiChatMessage(
      id: assistantMsgId,
      text: '',
      isUser: false,
      timestamp: DateTime.now(),
      isStreaming: true,
      isWorking: true,
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg, initialAssistantMsg],
      isLoading: true,
      statusText: 'Epi is thinking...',
      activeStreamingId: assistantMsgId,
      error: null,
    );

    final repo = ref.read(epiChatRepositoryProvider);
    try {
      final existing = await repo.getConversations();
      final hasConv = existing.any((c) => c.id == state.sessionId);
      if (!hasConv) {
        final title = trimmed.length > 30 ? '${trimmed.substring(0, 30)}...' : trimmed;
        await repo.saveConversation(EpiConversation(
          id: state.sessionId,
          title: title,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      } else {
        final cur = existing.firstWhere((c) => c.id == state.sessionId);
        await repo.saveConversation(cur.copyWith(updatedAt: DateTime.now()));
      }
      await repo.saveMessage(state.sessionId, userMsg);
    } catch (_) {}

    final apiService = ref.read(epiApiServiceProvider);
    final toolExecutor = ref.read(epiToolExecutorProvider);

    // Accumulated across all turns
    var accumulatedText = '';
    final allExecutionRecords = <EpiActionExecutionRecord>[];

    // Tool-loop state
    List<EpiToolExecutionResult>? pendingToolResults;
    List<EpiActionCall>? inFlightToolCalls;

    try {
      // ── Agent Turn Loop (max 3 turns) ────────────────────────────────────────
      for (var turn = 0; turn < 3; turn++) {
        final pendingActionsThisTurn = <EpiActionCall>[];
        String? finalModelUsed;
        String? finalReplyText;
        EpiResponseStatus? responseStatus;

        var turnAccumulatedText = '';
        final wordQueue = <String>[];
        var turnStreamCompleted = false;

        // Scoped word drainer for this specific turn
        final drainerFuture = () async {
          while (!turnStreamCompleted || wordQueue.isNotEmpty) {
            if (wordQueue.isNotEmpty) {
              final countToPop = wordQueue.length > 25 ? 3 : (wordQueue.length > 10 ? 2 : 1);
              for (var i = 0; i < countToPop && wordQueue.isNotEmpty; i++) {
                turnAccumulatedText += wordQueue.removeAt(0);
              }
              accumulatedText = turnAccumulatedText;
              _updateMessageText(assistantMsgId, accumulatedText, isStreaming: true);
              final delayMs = wordQueue.length > 15 ? 10 : (wordQueue.length > 5 ? 18 : 28);
              await Future.delayed(Duration(milliseconds: delayMs));
            } else {
              await Future.delayed(const Duration(milliseconds: 16));
            }
          }
        }();

        // ── Stream this turn ──────────────────────────────────────────────────
        final stream = apiService.streamChat(
          message: trimmed,
          sessionId: state.sessionId,
          attachedItems: turn == 0 ? attachedItems : null,
          toolResults: pendingToolResults,
          inFlightToolCalls: inFlightToolCalls,
        );

        await for (final event in stream) {
          switch (event.type) {
            case EpiStreamEventType.status:
              if (event.statusMessage != null) {
                state = state.copyWith(statusText: event.statusMessage);
              }
              break;

            case EpiStreamEventType.token:
              if (event.tokenDelta != null && event.tokenDelta!.isNotEmpty) {
                if (state.statusText != null && !state.statusText!.startsWith('Executing')) {
                  state = state.copyWith(clearStatusText: true);
                }
                final words = _splitIntoWords(event.tokenDelta!);
                wordQueue.addAll(words);
              }
              break;

            case EpiStreamEventType.action:
              if (event.action != null) {
                pendingActionsThisTurn.add(event.action!);
              }
              break;

            case EpiStreamEventType.done:
              finalModelUsed = event.modelUsed;
              finalReplyText = event.fullReply;
              responseStatus = event.status ??
                  (pendingActionsThisTurn.isNotEmpty
                      ? EpiResponseStatus.requiresTools
                      : EpiResponseStatus.finalResponse);
              if (event.finalActions != null) {
                for (final a in event.finalActions!) {
                  if (!pendingActionsThisTurn.any((p) => p.id == a.id)) {
                    pendingActionsThisTurn.add(a);
                  }
                }
              }
              if (event.executedActions != null) {
                for (final a in event.executedActions!) {
                  final isAlreadyAdded = allExecutionRecords.any((r) => r.action.id == a.id);
                  if (!isAlreadyAdded) {
                    final query = a.parameters['query']?.toString() ?? '';
                    final title = a.tool == 'google_search' && query.isNotEmpty
                        ? 'Searched Google for "$query"'
                        : _friendlyToolName(a.tool);
                    final stepId = a.id;
                    _addTimelineStep(
                      assistantMsgId,
                      EpiTimelineStep(
                        id: stepId,
                        title: title,
                        status: EpiTimelineStepStatus.success,
                        timestamp: DateTime.now(),
                      ),
                    );
                    allExecutionRecords.add(EpiActionExecutionRecord(
                      action: a,
                      status: ActionExecutionStatus.success,
                      message: title,
                      timestamp: DateTime.now(),
                    ));
                  }
                }
              }
              break;

            case EpiStreamEventType.error:
              turnStreamCompleted = true;
              await drainerFuture;
              throw Exception(event.errorMessage ?? 'Streaming error');
          }
        }

        // Wait for drainer to finish all tokens in this turn
        turnStreamCompleted = true;
        await drainerFuture;

        // Reconcile text if fullReply had anything not drained
        if (finalReplyText != null && finalReplyText.isNotEmpty) {
          if (turnAccumulatedText.isEmpty || turnAccumulatedText.length < finalReplyText.length) {
            turnAccumulatedText = finalReplyText;
            accumulatedText = turnAccumulatedText;
            _updateMessageText(assistantMsgId, accumulatedText, isStreaming: false);
          }
        }

        // ── Check if this is a requires_tools turn ─────────────────────────────
        final isRequiresTools = responseStatus == EpiResponseStatus.requiresTools &&
            pendingActionsThisTurn.isNotEmpty;

        if (isRequiresTools && context.mounted) {
          // Mark message as working
          state = state.copyWith(
            messages: state.messages.map((m) {
              if (m.id == assistantMsgId) return m.copyWith(isWorking: true, isStreaming: false);
              return m;
            }).toList(),
          );

          // Execute tools, collect results for next turn
          final toolResults = <EpiToolExecutionResult>[];

          // Deduplicate actions in the turn batch to prevent redundant executions
          final deduplicatedActions = <EpiActionCall>[];
          for (final a in pendingActionsThisTurn) {
            final isDup = deduplicatedActions.any((existing) =>
                existing.tool == a.tool &&
                mapEquals(existing.parameters, a.parameters));
            if (!isDup) {
              deduplicatedActions.add(a);
            }
          }

          for (final action in deduplicatedActions) {
            if (!context.mounted) break;

            final stepId = const Uuid().v4();
            final friendlyName = _friendlyToolName(action.tool);

            // Add "running" timeline step
            _addTimelineStep(
              assistantMsgId,
              EpiTimelineStep(
                id: stepId,
                title: friendlyName,
                status: EpiTimelineStepStatus.running,
                timestamp: DateTime.now(),
              ),
            );
            state = state.copyWith(statusText: '$friendlyName...');

            EpiActionExecutionRecord record;

            // Tier 3: Show confirmation dialog first
            if (action.tier == 'destructive_or_sensitive') {
              record = await toolExecutor.executeAction(
                context: context,
                action: action,
              );
            } else {
              record = await toolExecutor.executeAction(
                context: context,
                action: action,
                forceConfirmed: true,
              );
            }

            allExecutionRecords.add(record);

            // Update timeline step with result
            final stepStatus = record.status == ActionExecutionStatus.success
                ? EpiTimelineStepStatus.success
                : record.status == ActionExecutionStatus.cancelled
                    ? EpiTimelineStepStatus.cancelled
                    : EpiTimelineStepStatus.failed;

            _patchTimelineStep(
              assistantMsgId,
              EpiTimelineStep(
                id: stepId,
                title: record.message.isNotEmpty ? record.message : friendlyName,
                status: stepStatus,
                timestamp: DateTime.now(),
              ),
            );

            // Build tool result for next turn
            toolResults.add(EpiToolExecutionResult(
              toolCallId: action.id,
              tool: action.tool,
              status: record.status == ActionExecutionStatus.success
                  ? 'success'
                  : record.status == ActionExecutionStatus.cancelled
                      ? 'cancelled'
                      : 'failed',
              message: record.message,
              data: record.outputData,
              wasNoOp: record.wasNoOp,
            ));
          }

          // Prepare for next turn
          pendingToolResults = toolResults;
          inFlightToolCalls = pendingActionsThisTurn;

          // Clear text for next turn so synthesized final answer streams cleanly
          accumulatedText = '';
          _updateMessageText(assistantMsgId, '', isStreaming: true);
          state = state.copyWith(statusText: 'Epi is processing results...');

          continue; // Proceed to next turn with tool results!
        }

        // ── Final response received (No tools requested or synthesis complete) ─
        final exists = state.messages.any((m) => m.id == assistantMsgId);
        final finalText = accumulatedText.isNotEmpty
            ? accumulatedText
            : (allExecutionRecords.isNotEmpty
                ? _buildFallbackText(allExecutionRecords)
                : "I didn't catch that. Could you say that again?");

        final existingMsg = state.messages.firstWhere(
          (m) => m.id == assistantMsgId,
          orElse: () => EpiChatMessage(
            id: assistantMsgId,
            text: '',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );

        final finalMsg = EpiChatMessage(
          id: assistantMsgId,
          text: finalText,
          isUser: false,
          timestamp: DateTime.now(),
          actionRecords: allExecutionRecords,
          timelineSteps: existingMsg.timelineSteps,
          modelUsed: finalModelUsed,
          isStreaming: false,
          isWorking: false,
        );

        final updatedMessages = exists
            ? state.messages.map((m) => m.id == assistantMsgId ? finalMsg : m).toList()
            : [...state.messages, finalMsg];

        state = state.copyWith(
          messages: updatedMessages,
          isLoading: false,
          clearStatusText: true,
          clearActiveStreamingId: true,
          isBackendOnline: true,
        );

        try {
          await repo.saveMessage(state.sessionId, finalMsg);
        } catch (_) {}

        return; // Done
      }

      // Max turns reached: finalize whatever we have
      _finalizeMessage(assistantMsgId, accumulatedText, allExecutionRecords, null, repo);
    } catch (e) {
      final exists = state.messages.any((m) => m.id == assistantMsgId);
      final errText = accumulatedText.isNotEmpty
          ? accumulatedText
          : "Oops, having a little trouble connecting right now. Give it another shot in a sec!";

      final existingMsg = state.messages.firstWhere(
        (m) => m.id == assistantMsgId,
        orElse: () => EpiChatMessage(
          id: assistantMsgId,
          text: '',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );

      final errMsg = EpiChatMessage(
        id: assistantMsgId,
        text: errText,
        isUser: false,
        timestamp: DateTime.now(),
        actionRecords: allExecutionRecords,
        timelineSteps: existingMsg.timelineSteps,
        isStreaming: false,
        isWorking: false,
      );

      final updatedMessages = exists
          ? state.messages.map((m) => m.id == assistantMsgId ? errMsg : m).toList()
          : [...state.messages, errMsg];

      state = state.copyWith(
        messages: updatedMessages,
        isLoading: false,
        clearStatusText: true,
        clearActiveStreamingId: true,
        error: e.toString(),
        isBackendOnline: false,
      );

      try {
        await repo.saveMessage(state.sessionId, errMsg);
      } catch (_) {}
    }
  }

  void _finalizeMessage(
    String assistantMsgId,
    String accumulatedText,
    List<EpiActionExecutionRecord> records,
    String? modelUsed,
    EpiChatRepository repo,
  ) {
    final exists = state.messages.any((m) => m.id == assistantMsgId);
    final finalText = accumulatedText.isNotEmpty
        ? accumulatedText
        : (records.isNotEmpty
            ? _buildFallbackText(records)
            : "I wasn't able to complete that request. Please try again.");

    final existingMsg = state.messages.firstWhere(
      (m) => m.id == assistantMsgId,
      orElse: () => EpiChatMessage(
        id: assistantMsgId,
        text: '',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );

    final finalMsg = EpiChatMessage(
      id: assistantMsgId,
      text: finalText,
      isUser: false,
      timestamp: DateTime.now(),
      actionRecords: records,
      timelineSteps: existingMsg.timelineSteps,
      modelUsed: modelUsed,
      isStreaming: false,
      isWorking: false,
    );

    final updatedMessages = exists
        ? state.messages.map((m) => m.id == assistantMsgId ? finalMsg : m).toList()
        : [...state.messages, finalMsg];

    state = state.copyWith(
      messages: updatedMessages,
      isLoading: false,
      clearStatusText: true,
      clearActiveStreamingId: true,
      isBackendOnline: true,
    );

    repo.saveMessage(state.sessionId, finalMsg).catchError((_) {});
  }

  String _buildFallbackText(List<EpiActionExecutionRecord> records) {
    final done = records.where((r) => r.status == ActionExecutionStatus.success).length;
    final total = records.length;
    if (done == total) return 'Done! Completed $total ${total == 1 ? 'action' : 'actions'}.';
    return 'Done. $done of $total ${total == 1 ? 'action' : 'actions'} succeeded.';
  }

  String _friendlyToolName(String tool) {
    switch (tool) {
      case 'create_task':
        return 'Creating task';
      case 'update_task':
        return 'Updating task';
      case 'remove_subtask':
        return 'Removing subtask';
      case 'update_subtask':
        return 'Updating subtask';
      case 'keep_overdue_task':
        return 'Keeping overdue task';
      case 'google_search':
        return 'Searching Google';
      case 'delete_task':
        return 'Deleting task';
      case 'set_task_status':
        return 'Updating task status';
      case 'create_note':
        return 'Creating note';
      case 'update_note':
        return 'Updating note';
      case 'delete_note':
        return 'Deleting note';
      case 'query_tasks':
        return 'Searching tasks';
      case 'query_notes':
        return 'Searching notes';
      case 'query_boards':
        return 'Searching projects';
      case 'create_board':
        return 'Creating project';
      case 'update_board':
        return 'Updating project';
      case 'delete_board':
        return 'Deleting project';
      case 'get_today_overview':
        return 'Getting your overview';
      case 'add_subtasks':
      case 'break_down_task':
        return 'Adding subtasks';
      case 'link_tasks':
        return 'Linking tasks';
      case 'create_schedule_slot':
        return 'Creating schedule slot';
      case 'update_schedule_slot':
        return 'Updating schedule';
      case 'delete_schedule_slot':
        return 'Removing schedule slot';
      case 'query_schedule':
        return 'Checking schedule';
      case 'update_about_me':
        return 'Updating your profile';
      case 'set_recurrence':
        return 'Setting recurrence';
      case 'get_productivity_report':
        return 'Analyzing your week';
      case 'wipe_thread':
      case 'clear_chat_history':
        return 'Wiping conversation';
      default:
        return tool.replaceAll('_', ' ');
    }
  }

  Future<String?> undoLastAction() async {
    return ref.read(epiActionLogProvider.notifier).undoLastAction();
  }

  Future<List<EpiConversation>> getConversations() async {
    final repo = ref.read(epiChatRepositoryProvider);
    return repo.getConversations();
  }

  Future<void> switchConversation(String sessionId) async {
    final repo = ref.read(epiChatRepositoryProvider);
    final msgs = await repo.getMessages(sessionId);
    state = EpiChatState(
      messages: msgs.isNotEmpty
          ? msgs
          : [
              EpiChatMessage(
                id: const Uuid().v4(),
                text: "Hey! What's on your mind?",
                isUser: false,
                timestamp: DateTime.now(),
              ),
            ],
      isLoading: false,
      sessionId: sessionId,
    );
  }

  Future<void> deleteConversation(String sessionId) async {
    final repo = ref.read(epiChatRepositoryProvider);
    await repo.deleteConversation(sessionId);
    if (state.sessionId == sessionId) {
      clearChat();
    }
  }

  void clearChat() {
    state = EpiChatState(
      messages: [
        EpiChatMessage(
          id: const Uuid().v4(),
          text: "Fresh start! What's on your mind?",
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ],
      isLoading: false,
      sessionId: 'session_${const Uuid().v4().substring(0, 8)}',
    );
  }
}

final epiChatProvider = NotifierProvider<EpiChatNotifier, EpiChatState>(EpiChatNotifier.new);
