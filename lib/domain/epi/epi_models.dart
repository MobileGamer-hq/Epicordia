import '../models/chat_attachment_model.dart';

class EpiActionCall {
  final String id;
  final String tool;
  final String tier; // 'read', 'safe_write', 'destructive_or_sensitive'
  final Map<String, dynamic> parameters;

  const EpiActionCall({
    required this.id,
    required this.tool,
    required this.tier,
    required this.parameters,
  });

  factory EpiActionCall.fromJson(Map<String, dynamic> json) {
    return EpiActionCall(
      id: json['id'] as String? ?? '',
      tool: json['tool'] as String? ?? '',
      tier: json['tier'] as String? ?? 'safe_write',
      parameters: (json['parameters'] as Map<String, dynamic>?) ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tool': tool,
        'tier': tier,
        'parameters': parameters,
      };
}

enum EpiResponseStatus {
  requiresTools,
  finalResponse,
}

class EpiToolExecutionResult {
  final String toolCallId;
  final String tool;
  final String status; // 'success', 'failed', 'cancelled'
  final String message;
  final dynamic data;
  final bool wasNoOp;

  const EpiToolExecutionResult({
    required this.toolCallId,
    required this.tool,
    required this.status,
    this.message = '',
    this.data,
    this.wasNoOp = false,
  });

  Map<String, dynamic> toJson() => {
        'toolCallId': toolCallId,
        'tool': tool,
        'status': status,
        'message': message,
        if (data != null) 'data': data,
        'wasNoOp': wasNoOp,
      };

  factory EpiToolExecutionResult.fromJson(Map<String, dynamic> json) {
    return EpiToolExecutionResult(
      toolCallId: json['toolCallId'] as String? ?? '',
      tool: json['tool'] as String? ?? '',
      status: json['status'] as String? ?? 'success',
      message: json['message'] as String? ?? '',
      data: json['data'],
      wasNoOp: json['wasNoOp'] as bool? ?? false,
    );
  }
}

class EpiChatResponse {
  final String reply;
  final List<EpiActionCall> actions;
  final List<EpiActionCall> executedActions;
  final EpiResponseStatus status;
  final String sessionId;
  final String modelUsed;

  const EpiChatResponse({
    required this.reply,
    required this.actions,
    this.executedActions = const [],
    this.status = EpiResponseStatus.finalResponse,
    required this.sessionId,
    required this.modelUsed,
  });

  factory EpiChatResponse.fromJson(Map<String, dynamic> json) {
    final actionsList = (json['actions'] as List<dynamic>?)
            ?.map((e) => EpiActionCall.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final executedList = (json['executedActions'] as List<dynamic>?)
            ?.map((e) => EpiActionCall.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final rawStatus = json['status'] as String? ?? 'final_response';
    final parsedStatus = rawStatus == 'requires_tools'
        ? EpiResponseStatus.requiresTools
        : EpiResponseStatus.finalResponse;

    return EpiChatResponse(
      reply: json['reply'] as String? ?? '',
      actions: actionsList,
      executedActions: executedList,
      status: parsedStatus,
      sessionId: json['sessionId'] as String? ?? '',
      modelUsed: json['modelUsed'] as String? ?? '',
    );
  }
}

enum ActionExecutionStatus {
  pending,
  success,
  failed,
  cancelled,
}

class EpiActionExecutionRecord {
  final EpiActionCall action;
  final ActionExecutionStatus status;
  final String message;
  final String? createdEntityId;
  final List<String> entityIds;
  final dynamic outputData;
  final bool wasNoOp;
  final DateTime timestamp;

  const EpiActionExecutionRecord({
    required this.action,
    required this.status,
    required this.message,
    this.createdEntityId,
    this.entityIds = const [],
    this.outputData,
    this.wasNoOp = false,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'action': action.toJson(),
        'status': status.name,
        'message': message,
        'createdEntityId': createdEntityId,
        'entityIds': entityIds,
        if (outputData != null) 'outputData': outputData,
        'wasNoOp': wasNoOp,
        'timestamp': timestamp.toIso8601String(),
      };

  factory EpiActionExecutionRecord.fromJson(Map<String, dynamic> json) {
    return EpiActionExecutionRecord(
      action: EpiActionCall.fromJson(json['action'] as Map<String, dynamic>? ?? {}),
      status: ActionExecutionStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ActionExecutionStatus.success,
      ),
      message: json['message'] as String? ?? '',
      createdEntityId: json['createdEntityId'] as String?,
      entityIds: (json['entityIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          (json['createdEntityId'] != null ? [json['createdEntityId'].toString()] : const []),
      outputData: json['outputData'],
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  EpiActionExecutionRecord copyWith({
    ActionExecutionStatus? status,
    String? message,
    String? createdEntityId,
    List<String>? entityIds,
    dynamic outputData,
  }) {
    return EpiActionExecutionRecord(
      action: action,
      status: status ?? this.status,
      message: message ?? this.message,
      createdEntityId: createdEntityId ?? this.createdEntityId,
      entityIds: entityIds ?? this.entityIds,
      outputData: outputData ?? this.outputData,
      timestamp: timestamp,
    );
  }
}

class EpiConversation {
  final String id;
  final String title;
  final String? boardContext;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EpiConversation({
    required this.id,
    required this.title,
    this.boardContext,
    required this.createdAt,
    required this.updatedAt,
  });

  EpiConversation copyWith({
    String? title,
    String? boardContext,
    DateTime? updatedAt,
  }) {
    return EpiConversation(
      id: id,
      title: title ?? this.title,
      boardContext: boardContext ?? this.boardContext,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'boardContext': boardContext,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory EpiConversation.fromJson(Map<String, dynamic> json) {
    return EpiConversation(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Conversation',
      boardContext: json['boardContext'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

enum EpiTimelineStepStatus { running, success, failed, cancelled }

class EpiTimelineStep {
  final String id;
  final String title;
  final EpiTimelineStepStatus status;
  final DateTime timestamp;

  const EpiTimelineStep({
    required this.id,
    required this.title,
    required this.status,
    required this.timestamp,
  });

  EpiTimelineStep copyWith({
    String? title,
    EpiTimelineStepStatus? status,
    DateTime? timestamp,
  }) {
    return EpiTimelineStep(
      id: id,
      title: title ?? this.title,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

class EpiChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<EpiActionExecutionRecord> actionRecords;
  final List<EpiTimelineStep> timelineSteps;
  final String? modelUsed;
  final bool isStreaming;
  final bool isWorking;
  final ChatAttachment? attachment;

  const EpiChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.actionRecords = const [],
    this.timelineSteps = const [],
    this.modelUsed,
    this.isStreaming = false,
    this.isWorking = false,
    this.attachment,
  });

  EpiChatMessage copyWith({
    String? text,
    List<EpiActionExecutionRecord>? actionRecords,
    List<EpiTimelineStep>? timelineSteps,
    String? modelUsed,
    bool? isStreaming,
    bool? isWorking,
    ChatAttachment? attachment,
  }) {
    return EpiChatMessage(
      id: id,
      text: text ?? this.text,
      isUser: isUser,
      timestamp: timestamp,
      actionRecords: actionRecords ?? this.actionRecords,
      timelineSteps: timelineSteps ?? this.timelineSteps,
      modelUsed: modelUsed ?? this.modelUsed,
      isStreaming: isStreaming ?? this.isStreaming,
      isWorking: isWorking ?? this.isWorking,
      attachment: attachment ?? this.attachment,
    );
  }
}

enum EpiStreamEventType { status, token, action, done, error }

class EpiStreamEvent {
  final EpiStreamEventType type;
  final String? statusMessage;
  final String? tokenDelta;
  final EpiActionCall? action;
  final String? fullReply;
  final List<EpiActionCall>? finalActions;
  final List<EpiActionCall>? executedActions;
  final EpiResponseStatus? status;
  final String? modelUsed;
  final String? errorMessage;

  const EpiStreamEvent({
    required this.type,
    this.statusMessage,
    this.tokenDelta,
    this.action,
    this.fullReply,
    this.finalActions,
    this.executedActions,
    this.status,
    this.modelUsed,
    this.errorMessage,
  });
}

class ProactiveCheckinResult {
  final bool shouldSpeak;
  final String message;
  final List<String> relevantItemIds;
  final List<String> suggestedActions;
  final String? modelUsed;

  const ProactiveCheckinResult({
    required this.shouldSpeak,
    required this.message,
    this.relevantItemIds = const [],
    this.suggestedActions = const [],
    this.modelUsed,
  });

  factory ProactiveCheckinResult.fromJson(Map<String, dynamic> json) {
    final actionsList = (json['suggestedActions'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        ['Chat with Epi', 'View tasks', 'Dismiss'];

    return ProactiveCheckinResult(
      shouldSpeak: json['shouldSpeak'] as bool? ?? false,
      message: (json['message'] as String? ?? '')
          .replaceAll('—', '-')
          .replaceAll('–', '-')
          .trim(),
      relevantItemIds: (json['relevantItemIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      suggestedActions: actionsList,
      modelUsed: json['modelUsed'] as String?,
    );
  }
}

enum EpiAttachedItemType { note, task, schedule }

class EpiAttachedItem {
  final String id;
  final String title;
  final EpiAttachedItemType type;
  final String? preview;
  final Map<String, dynamic>? extraData;

  const EpiAttachedItem({
    required this.id,
    required this.title,
    required this.type,
    this.preview,
    this.extraData,
  });
}
