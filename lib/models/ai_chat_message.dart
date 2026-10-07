// AI Chat Message Models and Enums

/// The role of a chat message in the conversation.
enum ChatMessageRole {
  user,
  assistant,
  system,
  tool,
}

/// Active mode and persona of the AI Assistant.
enum AiRoleMode {
  receptionist,
  patient,
  dentist;

  String get displayName {
    switch (this) {
      case AiRoleMode.receptionist:
        return 'Receptionist Assistant';
      case AiRoleMode.patient:
        return 'Patient Health Advisor';
      case AiRoleMode.dentist:
        return 'Dentist Clinical Copilot';
    }
  }

  String get description {
    switch (this) {
      case AiRoleMode.receptionist:
        return 'Front-desk operations, real-time appointments, patient lookup & billing.';
      case AiRoleMode.patient:
        return 'General dental health education, procedure explanations & preparation.';
      case AiRoleMode.dentist:
        return 'Clinical documentation, SOAP note drafting & dental treatment summaries.';
    }
  }
}

/// Represents a function/tool call requested by the LLM.
class AiToolCall {
  final String id;
  final String name;
  final Map<String, dynamic> arguments;

  const AiToolCall({
    required this.id,
    required this.name,
    required this.arguments,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': 'function',
        'function': {
          'name': name,
          'arguments': arguments,
        },
      };

  factory AiToolCall.fromJson(Map<String, dynamic> json) {
    return AiToolCall(
      id: json['id'] as String? ?? 'tool_call_${DateTime.now().millisecondsSinceEpoch}',
      name: (json['function'] as Map<String, dynamic>?)?['name'] as String? ?? '',
      arguments: (json['function'] as Map<String, dynamic>?)?['arguments'] is Map<String, dynamic>
          ? (json['function'] as Map<String, dynamic>)['arguments'] as Map<String, dynamic>
          : {},
    );
  }
}

/// Individual chat message inside a conversation session.
class ChatMessage {
  final String id;
  final ChatMessageRole role;
  String content;
  final DateTime timestamp;
  final bool isStreaming;
  final bool isError;
  final String? errorMessage;
  final List<AiToolCall>? toolCalls;
  final String? toolCallId;
  final String? toolName;
  final String? executedToolSummary;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isStreaming = false,
    this.isError = false,
    this.errorMessage,
    this.toolCalls,
    this.toolCallId,
    this.toolName,
    this.executedToolSummary,
  });

  bool get isUser => role == ChatMessageRole.user;
  bool get isAssistant => role == ChatMessageRole.assistant;
  bool get isTool => role == ChatMessageRole.tool;
  bool get isSystem => role == ChatMessageRole.system;

  ChatMessage copyWith({
    String? content,
    bool? isStreaming,
    bool? isError,
    String? errorMessage,
    List<AiToolCall>? toolCalls,
    String? toolCallId,
    String? toolName,
    String? executedToolSummary,
  }) {
    return ChatMessage(
      id: id,
      role: role,
      content: content ?? this.content,
      timestamp: timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
      isError: isError ?? this.isError,
      errorMessage: errorMessage ?? this.errorMessage,
      toolCalls: toolCalls ?? this.toolCalls,
      toolCallId: toolCallId ?? this.toolCallId,
      toolName: toolName ?? this.toolName,
      executedToolSummary: executedToolSummary ?? this.executedToolSummary,
    );
  }

  Map<String, dynamic> toApiMessage() {
    switch (role) {
      case ChatMessageRole.user:
        return {'role': 'user', 'content': content};
      case ChatMessageRole.assistant:
        final map = <String, dynamic>{'role': 'assistant', 'content': content};
        if (toolCalls != null && toolCalls!.isNotEmpty) {
          map['tool_calls'] = toolCalls!.map((t) => t.toJson()).toList();
        }
        return map;
      case ChatMessageRole.system:
        return {'role': 'system', 'content': content};
      case ChatMessageRole.tool:
        return {
          'role': 'tool',
          'tool_call_id': toolCallId ?? '',
          'name': toolName ?? '',
          'content': content,
        };
    }
  }
}
