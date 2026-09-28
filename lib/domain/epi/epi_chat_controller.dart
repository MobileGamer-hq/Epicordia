import 'package:flutter/material.dart';
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
  final String? statusText; // Live activity feedback: "Connecting to Epi...", "Epi is thinking...", "Executing: Creating task..."
  final String? activeStreamingId; // ID of message currently streaming words

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

  Future<void> sendMessage(String text, BuildContext context) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isLoading) return;

    final userMsg = EpiChatMessage(
      id: const Uuid().v4(),
      text: trimmed,
      isUser: true,
      timestamp: DateTime.now(),
    );

    final assistantMsgId = const Uuid().v4();

    state = state.copyWith(
      messages: [...state.messages, userMsg],
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
    final wordQueue = <String>[];
    var streamCompleted = false;
    var accumulatedText = '';
    final pendingActions = <EpiActionCall>[];
    String? finalModelUsed;
    String? finalReplyText;

    // Start background word drainer loop to display words one-by-one smoothly
    final drainerFuture = () async {
      while (!streamCompleted || wordQueue.isNotEmpty) {
        if (wordQueue.isNotEmpty) {
          // If queue builds up, pop in small batches to stay brisk and smooth
          final countToPop = wordQueue.length > 25 ? 3 : (wordQueue.length > 10 ? 2 : 1);
          for (var i = 0; i < countToPop && wordQueue.isNotEmpty; i++) {
            accumulatedText += wordQueue.removeAt(0);
          }

          // Update assistant message text
          _updateMessageText(assistantMsgId, accumulatedText, isStreaming: true);

          final delayMs = wordQueue.length > 15 ? 12 : (wordQueue.length > 5 ? 20 : 32);
          await Future.delayed(Duration(milliseconds: delayMs));
        } else {
          await Future.delayed(const Duration(milliseconds: 20));
        }
      }
    }();

    try {
      final stream = apiService.streamChat(
        message: trimmed,
        sessionId: state.sessionId,
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
              // Clear thinking or connecting status as soon as words start appearing
              if (state.statusText != null && !state.statusText!.startsWith('Executing')) {
                state = state.copyWith(clearStatusText: true);
              }
              // Token delta may contain multiple words. Split preserving trailing spaces/delimiters
              final words = _splitIntoWords(event.tokenDelta!);
              wordQueue.addAll(words);
            }
            break;

          case EpiStreamEventType.action:
            if (event.action != null) {
              pendingActions.add(event.action!);
            }
            break;

          case EpiStreamEventType.done:
            finalModelUsed = event.modelUsed;
            finalReplyText = event.fullReply;
            if (event.finalActions != null && event.finalActions!.isNotEmpty) {
              for (final a in event.finalActions!) {
                if (!pendingActions.any((p) => p.id == a.id)) {
                  pendingActions.add(a);
                }
              }
            }
            break;

          case EpiStreamEventType.error:
            throw Exception(event.errorMessage ?? 'Streaming error');
        }
      }

      // Signal stream done and wait for word queue to finish draining
      streamCompleted = true;
      await drainerFuture;

      // Reconcile in case finalReplyText has minor differences
      if (finalReplyText != null && finalReplyText.isNotEmpty && accumulatedText.length < finalReplyText.length) {
        accumulatedText = finalReplyText;
        _updateMessageText(assistantMsgId, accumulatedText, isStreaming: true);
      }

      // ── Execute Actions via Tool Executor Registry ──
      final toolExecutor = ref.read(epiToolExecutorProvider);
      final executionRecords = <EpiActionExecutionRecord>[];

      for (final action in pendingActions) {
        if (!context.mounted) break;
        final friendlyTool = action.tool.replaceAll('_', ' ');
        state = state.copyWith(statusText: 'Executing: $friendlyTool...');

        final record = await toolExecutor.executeAction(
          context: context,
          action: action,
        );
        executionRecords.add(record);
      }

      // Finalize assistant message
      final exists = state.messages.any((m) => m.id == assistantMsgId);
      final finalMsgText = accumulatedText.isEmpty && executionRecords.isNotEmpty
          ? 'Understood. Staged ${executionRecords.length} action(s).'
          : (accumulatedText.isEmpty ? 'All set!' : accumulatedText);

      final assistantMsg = EpiChatMessage(
        id: assistantMsgId,
        text: finalMsgText,
        isUser: false,
        timestamp: DateTime.now(),
        actionRecords: executionRecords,
        modelUsed: finalModelUsed,
        isStreaming: false,
      );

      final updatedMessages = exists
          ? state.messages.map((m) => m.id == assistantMsgId ? assistantMsg : m).toList()
          : [...state.messages, assistantMsg];

      state = state.copyWith(
        messages: updatedMessages,
        isLoading: false,
        clearStatusText: true,
        clearActiveStreamingId: true,
        isBackendOnline: true,
      );

      try {
        await repo.saveMessage(state.sessionId, assistantMsg);
      } catch (_) {}
    } catch (e) {
      streamCompleted = true;
      await drainerFuture;

      final exists = state.messages.any((m) => m.id == assistantMsgId);
      final errMsgText = accumulatedText.isNotEmpty
          ? accumulatedText
          : "Oops, having a little trouble connecting right now. Give it another shot in a sec!";

      final errAssistantMsg = EpiChatMessage(
        id: assistantMsgId,
        text: errMsgText,
        isUser: false,
        timestamp: DateTime.now(),
        isStreaming: false,
      );

      final updatedMessages = exists
          ? state.messages.map((m) => m.id == assistantMsgId ? errAssistantMsg : m).toList()
          : [...state.messages, errAssistantMsg];

      state = state.copyWith(
        messages: updatedMessages,
        isLoading: false,
        clearStatusText: true,
        clearActiveStreamingId: true,
        error: e.toString(),
        isBackendOnline: false,
      );

      try {
        await repo.saveMessage(state.sessionId, errAssistantMsg);
      } catch (_) {}
    }
  }

  void _updateMessageText(String id, String text, {required bool isStreaming}) {
    if (text.isEmpty) return;
    final cleanText = text.replaceAll('—', ' - ').replaceAll('–', '-');
    final exists = state.messages.any((m) => m.id == id);
    if (!exists) {
      final newMsg = EpiChatMessage(
        id: id,
        text: cleanText,
        isUser: false,
        timestamp: DateTime.now(),
        isStreaming: isStreaming,
      );
      state = state.copyWith(
        messages: [...state.messages, newMsg],
      );
    } else {
      state = state.copyWith(
        messages: state.messages.map((m) {
          if (m.id == id) {
            return m.copyWith(text: cleanText, isStreaming: isStreaming);
          }
          return m;
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
    if (result.isEmpty && clean.isNotEmpty) {
      result.add(clean);
    }
    return result;
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
