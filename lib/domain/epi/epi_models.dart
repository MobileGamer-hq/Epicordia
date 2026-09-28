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

class EpiChatResponse {
  final String reply;
  final List<EpiActionCall> actions;
  final String sessionId;
  final String modelUsed;

  const EpiChatResponse({
    required this.reply,
    required this.actions,
    required this.sessionId,
    required this.modelUsed,
  });

  factory EpiChatResponse.fromJson(Map<String, dynamic> json) {
    final actionsList = (json['actions'] as List<dynamic>?)
            ?.map((e) => EpiActionCall.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return EpiChatResponse(
      reply: json['reply'] as String? ?? '',
      actions: actionsList,
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
  final DateTime timestamp;

  const EpiActionExecutionRecord({
    required this.action,
    required this.status,
    required this.message,
    this.createdEntityId,
    this.entityIds = const [],
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'action': action.toJson(),
        'status': status.name,
        'message': message,
        'createdEntityId': createdEntityId,
        'entityIds': entityIds,
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
  }) {
    return EpiActionExecutionRecord(
      action: action,
      status: status ?? this.status,
      message: message ?? this.message,
      createdEntityId: createdEntityId ?? this.createdEntityId,
      entityIds: entityIds ?? this.entityIds,
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

class EpiChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<EpiActionExecutionRecord> actionRecords;
  final String? modelUsed;
  final bool isStreaming;

  const EpiChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.actionRecords = const [],
    this.modelUsed,
    this.isStreaming = false,
  });

  EpiChatMessage copyWith({
    String? text,
    List<EpiActionExecutionRecord>? actionRecords,
    String? modelUsed,
    bool? isStreaming,
  }) {
    return EpiChatMessage(
      id: id,
      text: text ?? this.text,
      isUser: isUser,
      timestamp: timestamp,
      actionRecords: actionRecords ?? this.actionRecords,
      modelUsed: modelUsed ?? this.modelUsed,
      isStreaming: isStreaming ?? this.isStreaming,
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
  final String? modelUsed;
  final String? errorMessage;

  const EpiStreamEvent({
    required this.type,
    this.statusMessage,
    this.tokenDelta,
    this.action,
    this.fullReply,
    this.finalActions,
    this.modelUsed,
    this.errorMessage,
  });
}
