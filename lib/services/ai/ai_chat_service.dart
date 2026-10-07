import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/ai_chat_message.dart';
import '../../state/clinic_state.dart';
import 'ai_config.dart';
import 'ai_system_prompts.dart';
import 'clinic_tools_registry.dart';

import 'local_assistant_engine.dart';

/// Real, functional AI Conversational Service connecting to local engine (and remote LLMs).
/// Supports offline local engine processing, streaming SSE responses, tool/function calling,
/// conversation memory, and multi-role personas.
class AiChatService extends ChangeNotifier {
  static final AiChatService instance = AiChatService._internal();

  factory AiChatService() => instance;

  AiChatService._internal() {
    _initInitialGreeting();
  }

  final AiConfig config = AiConfig();
  final List<ChatMessage> _messages = [];
  AiRoleMode _activeRole = AiRoleMode.receptionist;
  bool _isLoading = false;
  String? _toolStatus;
  String? _lastUserPrompt;

  /// Whether the chat service uses the offline LocalAssistantEngine (default true).
  /// Requires NO API key, makes NO external network requests, and executes deterministically.
  bool useLocalAssistant = true;

  // Getters
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  AiRoleMode get activeRole => _activeRole;
  bool get isLoading => _isLoading;
  String? get toolStatus => _toolStatus;
  bool get hasMessages => _messages.isNotEmpty;
  bool get isConfigured => config.isConfigured;
  bool get isReady => useLocalAssistant || config.isConfigured;

  void _initInitialGreeting() {
    _messages.clear();
    final greeting = _getInitialGreetingText(_activeRole);
    _messages.add(
      ChatMessage(
        id: 'msg_welcome_${DateTime.now().millisecondsSinceEpoch}',
        role: ChatMessageRole.assistant,
        content: greeting,
        timestamp: DateTime.now(),
      ),
    );
  }

  String _getInitialGreetingText(AiRoleMode role) {
    switch (role) {
      case AiRoleMode.receptionist:
        return 'Hello! I am your SmileCare Front-Desk AI Assistant. How can I help you manage appointments, patients, doctor availability, or billing today?';
      case AiRoleMode.patient:
        return 'Welcome to SmileCare Dental Assistant! I can explain dental treatments (like root canals or teeth cleaning), provide post-procedure care tips, and help you prepare for your visit.';
      case AiRoleMode.dentist:
        return 'Greetings Doctor. I am your Clinical Copilot ready to assist with SOAP documentation, treatment plan summaries, and post-op care drafting.';
    }
  }

  /// Switch the active persona mode and reset conversation
  void setRole(AiRoleMode role) {
    if (_activeRole != role) {
      _activeRole = role;
      _initInitialGreeting();
      notifyListeners();
    }
  }

  /// Clears the current conversation and resets with clean session memory
  void clearConversation() {
    _initInitialGreeting();
    _lastUserPrompt = null;
    _toolStatus = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Starts a new conversation session
  void newConversation() {
    clearConversation();
  }

  /// Send user message to the local assistant engine (or legacy remote AI pipeline)
  Future<void> sendMessage(String text, {required ClinicState clinicState}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isLoading) return;

    _lastUserPrompt = trimmed;

    // 1. Append User Message
    final userMsg = ChatMessage(
      id: 'msg_user_${DateTime.now().millisecondsSinceEpoch}',
      role: ChatMessageRole.user,
      content: trimmed,
      timestamp: DateTime.now(),
    );
    _messages.add(userMsg);
    _isLoading = true;
    _toolStatus = null;
    notifyListeners();

    // 2. Active Path: LocalAssistantEngine (zero external calls, zero API keys required)
    if (useLocalAssistant) {
      try {
        final response = await LocalAssistantEngine.processQuery(
          trimmed,
          clinicState: clinicState,
        );

        final assistantMsg = ChatMessage(
          id: 'msg_ai_${DateTime.now().millisecondsSinceEpoch}',
          role: ChatMessageRole.assistant,
          content: response.text,
          timestamp: DateTime.now(),
          isError: !response.success,
          errorMessage: response.errorMessage,
        );
        _messages.add(assistantMsg);
      } catch (e) {
        debugPrint('[AiChatService] Error executing local assistant: $e');
        _messages.add(
          ChatMessage(
            id: 'msg_err_${DateTime.now().millisecondsSinceEpoch}',
            role: ChatMessageRole.assistant,
            content: 'Error: $e',
            timestamp: DateTime.now(),
            isError: true,
            errorMessage: e.toString(),
          ),
        );
      } finally {
        _isLoading = false;
        _toolStatus = null;
        notifyListeners();
      }
      return;
    }

    // 3. Fallback: Legacy Remote AI Pipeline (for Phase 8 deprecation)
    if (!config.isConfigured) {
      _isLoading = false;
      _messages.add(
        ChatMessage(
          id: 'msg_err_${DateTime.now().millisecondsSinceEpoch}',
          role: ChatMessageRole.assistant,
          content: 'The AI Assistant is not configured yet.\n\nPlease click the ⚙️ icon in the chat header to add your API Key (e.g. OpenAI / Groq / Gemini), or configure AI_API_KEY in your environment.',
          timestamp: DateTime.now(),
          isError: true,
          errorMessage: 'AI API Key is missing.',
        ),
      );
      notifyListeners();
      return;
    }

    // 4. Prepare AI Request with System Prompt, Grounding, and Memory History
    try {
      await _executeAiChatPipeline(clinicState);
    } catch (e) {
      debugPrint('[AiChatService] Error executing AI chat: $e');
      _messages.add(
        ChatMessage(
          id: 'msg_err_${DateTime.now().millisecondsSinceEpoch}',
          role: ChatMessageRole.assistant,
          content: 'Unable to connect to the AI assistant.\n\nError details: $e\n\nPlease check your internet connection or verify your API settings.',
          timestamp: DateTime.now(),
          isError: true,
          errorMessage: e.toString(),
        ),
      );
    } finally {
      _isLoading = false;
      _toolStatus = null;
      notifyListeners();
    }
  }

  /// Retry the last failed user message
  Future<void> retryLastMessage(ClinicState clinicState) async {
    if (_lastUserPrompt == null || _isLoading) return;
    // Remove last error message if present
    if (_messages.isNotEmpty && _messages.last.isError) {
      _messages.removeLast();
    }
    // Remove last user prompt from message list so sendMessage does not duplicate it
    if (_messages.isNotEmpty && _messages.last.isUser && _messages.last.content == _lastUserPrompt) {
      _messages.removeLast();
    }
    await sendMessage(_lastUserPrompt!, clinicState: clinicState);
  }

  /// Core HTTP pipeline supporting Tool Calling and Streaming
  Future<void> _executeAiChatPipeline(ClinicState clinicState) async {
    final systemPrompt = AiSystemPrompts.getSystemPrompt(_activeRole, clinicState);

    // Build context window (system prompt + recent conversation messages)
    final List<Map<String, dynamic>> apiMessages = [
      {'role': 'system', 'content': systemPrompt},
    ];

    // Only include last 8 messages for memory efficiency & token economy
    final history = _messages.length > 8 ? _messages.sublist(_messages.length - 8) : _messages;
    for (final msg in history) {
      if (!msg.isError) {
        apiMessages.add(msg.toApiMessage());
      }
    }

    final tools = _activeRole == AiRoleMode.receptionist ? ClinicToolsRegistry.getToolDefinitions() : null;

    final requestBody = <String, dynamic>{
      'model': config.model,
      'messages': apiMessages,
      'temperature': config.temperature,
      'max_tokens': config.maxTokens,
    };

    if (tools != null && tools.isNotEmpty) {
      requestBody['tools'] = tools;
      requestBody['tool_choice'] = 'auto';
    }

    final uri = Uri.parse('${config.baseUrl}/chat/completions');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (config.apiKey.isNotEmpty) 'Authorization': 'Bearer ${config.apiKey}',
    };

    // First Call: Evaluate if tool execution is required
    final response = await http
        .post(uri, headers: headers, body: jsonEncode(requestBody))
        .timeout(const Duration(seconds: 25));

    if (response.statusCode == 401) {
      throw Exception('Invalid or unauthorized API key (HTTP 401). Please check your key in settings.');
    } else if (response.statusCode == 429) {
      throw Exception('AI rate limit reached or quota exceeded (HTTP 429). Please try again shortly.');
    } else if (response.statusCode >= 500) {
      throw Exception('AI service provider server error (${response.statusCode}).');
    } else if (response.statusCode != 200) {
      throw Exception('API request failed with status ${response.statusCode}: ${response.body}');
    }

    final responseData = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final choices = responseData['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw Exception('Empty response returned from AI provider.');
    }

    final messageData = choices.first['message'] as Map<String, dynamic>;
    final toolCallsData = messageData['tool_calls'] as List<dynamic>?;

    // Check if Model Requested Function Tools (e.g. getTodaysAppointments)
    if (toolCallsData != null && toolCallsData.isNotEmpty) {
      // Add Assistant Message containing the tool calls
      final toolCalls = toolCallsData.map((t) => AiToolCall.fromJson(t as Map<String, dynamic>)).toList();
      apiMessages.add({
        'role': 'assistant',
        'tool_calls': toolCallsData,
      });

      // Execute each tool against real ClinicState
      for (final toolCall in toolCalls) {
        _toolStatus = '⚡ Querying clinic data: ${toolCall.name}()...';
        notifyListeners();

        final toolResult = await ClinicToolsRegistry.executeTool(
          toolName: toolCall.name,
          arguments: toolCall.arguments,
          clinicState: clinicState,
        );

        // Add Tool Result to context
        apiMessages.add({
          'role': 'tool',
          'tool_call_id': toolCall.id,
          'name': toolCall.name,
          'content': toolResult,
        });
      }

      _toolStatus = '✓ Clinic data retrieved. Formulating response...';
      notifyListeners();

      // Second Call: Stream the final answer incorporating the ground-truth data
      await _streamFinalAnswer(uri, headers, apiMessages);
    } else {
      // No tools needed: Display or stream response directly
      final content = messageData['content'] as String? ?? '';
      _messages.add(
        ChatMessage(
          id: 'msg_ai_${DateTime.now().millisecondsSinceEpoch}',
          role: ChatMessageRole.assistant,
          content: content,
          timestamp: DateTime.now(),
        ),
      );
      notifyListeners();
    }
  }

  /// Streams the final model completion using SSE chunks
  Future<void> _streamFinalAnswer(
    Uri uri,
    Map<String, String> headers,
    List<Map<String, dynamic>> apiMessages,
  ) async {
    final streamRequestBody = <String, dynamic>{
      'model': config.model,
      'messages': apiMessages,
      'temperature': config.temperature,
      'max_tokens': config.maxTokens,
      'stream': true,
    };

    final request = http.Request('POST', uri)
      ..headers.addAll(headers)
      ..body = jsonEncode(streamRequestBody);

    final assistantMsg = ChatMessage(
      id: 'msg_ai_${DateTime.now().millisecondsSinceEpoch}',
      role: ChatMessageRole.assistant,
      content: '',
      timestamp: DateTime.now(),
      isStreaming: true,
    );
    _messages.add(assistantMsg);
    notifyListeners();

    try {
      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));

      if (streamedResponse.statusCode != 200) {
        final errBody = await streamedResponse.stream.bytesToString();
        throw Exception('Streaming error (${streamedResponse.statusCode}): $errBody');
      }

      final stream = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in stream) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        if (trimmed == 'data: [DONE]') break;

        if (trimmed.startsWith('data: ')) {
          final jsonStr = trimmed.substring(6).trim();
          try {
            final chunk = jsonDecode(jsonStr) as Map<String, dynamic>;
            final choices = chunk['choices'] as List<dynamic>?;
            if (choices != null && choices.isNotEmpty) {
              final delta = choices.first['delta'] as Map<String, dynamic>?;
              final textDelta = delta?['content'] as String?;
              if (textDelta != null && textDelta.isNotEmpty) {
                assistantMsg.content += textDelta;
                notifyListeners();
              }
            }
          } catch (_) {
            // Ignore incomplete chunks
          }
        }
      }
    } catch (e) {
      if (assistantMsg.content.isEmpty) {
        // Fallback to non-streaming request if provider doesn't support SSE
        final fallback = await http.post(
          uri,
          headers: headers,
          body: jsonEncode({
            'model': config.model,
            'messages': apiMessages,
            'temperature': config.temperature,
          }),
        );
        if (fallback.statusCode == 200) {
          final res = jsonDecode(utf8.decode(fallback.bodyBytes));
          assistantMsg.content = res['choices'][0]['message']['content'] ?? '';
        } else {
          rethrow;
        }
      }
    } finally {
      // Mark streaming complete
      final index = _messages.indexWhere((m) => m.id == assistantMsg.id);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(isStreaming: false);
      }
      notifyListeners();
    }
  }
}
