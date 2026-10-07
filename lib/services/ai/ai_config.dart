import 'package:flutter/foundation.dart';

/// Centralized configuration for AI LLM API connectivity.
/// Supports build-time flags (--dart-define), runtime user inputs, and server proxy routing.
class AiConfig extends ChangeNotifier {
  // Built-in environment variable fallbacks
  static const String _envApiKey = String.fromEnvironment('AI_API_KEY', defaultValue: '');
  static const String _envBaseUrl = String.fromEnvironment('AI_BASE_URL', defaultValue: 'https://api.openai.com/v1');
  static const String _envModel = String.fromEnvironment('AI_MODEL', defaultValue: 'gpt-4o-mini');

  String _apiKey = _envApiKey;
  String _baseUrl = _envBaseUrl;
  String _model = _envModel;
  double _temperature = 0.3; // Low temperature for high factual accuracy in dental/clinical context
  int _maxTokens = 1200;
  bool _useProxy = false;
  String _proxyUrl = 'http://localhost:3000/api/chat';

  AiConfig() {
    // Trim whitespace
    _apiKey = _apiKey.trim();
    _baseUrl = _baseUrl.trim();
    _model = _model.trim();
  }

  String get apiKey => _apiKey;
  String get baseUrl => _useProxy ? _proxyUrl : _baseUrl;
  String get rawBaseUrl => _baseUrl;
  String get model => _model;
  double get temperature => _temperature;
  int get maxTokens => _maxTokens;
  bool get useProxy => _useProxy;
  String get proxyUrl => _proxyUrl;

  /// Whether the AI service has credentials or a proxy endpoint to send requests.
  bool get isConfigured {
    if (_useProxy && _proxyUrl.trim().isNotEmpty) return true;
    return _apiKey.trim().isNotEmpty;
  }

  /// Provider identification label
  String get providerDisplayName {
    if (_useProxy) return 'Custom Backend Proxy (/api/chat)';
    if (_baseUrl.contains('openai.com')) return 'OpenAI Direct API';
    if (_baseUrl.contains('groq.com')) return 'Groq Cloud LLM';
    if (_baseUrl.contains('together.xyz') || _baseUrl.contains('together.ai')) return 'Together AI';
    if (_baseUrl.contains('deepseek.com')) return 'DeepSeek API';
    if (_baseUrl.contains('localhost') || _baseUrl.contains('127.0.0.1')) return 'Local LLM (Ollama/vLLM)';
    return 'OpenAI-Compatible Endpoint';
  }

  /// Update configurations dynamically at runtime from settings UI
  void update({
    String? apiKey,
    String? baseUrl,
    String? model,
    double? temperature,
    int? maxTokens,
    bool? useProxy,
    String? proxyUrl,
  }) {
    if (apiKey != null) _apiKey = apiKey.trim();
    if (baseUrl != null) _baseUrl = baseUrl.trim();
    if (model != null) _model = model.trim();
    if (temperature != null) _temperature = temperature.clamp(0.0, 1.5);
    if (maxTokens != null) _maxTokens = maxTokens;
    if (useProxy != null) _useProxy = useProxy;
    if (proxyUrl != null) _proxyUrl = proxyUrl.trim();

    notifyListeners();
  }

  /// Reset to environment defaults
  void reset() {
    _apiKey = _envApiKey;
    _baseUrl = _envBaseUrl;
    _model = _envModel;
    _temperature = 0.3;
    _maxTokens = 1200;
    _useProxy = false;
    _proxyUrl = 'http://localhost:3000/api/chat';
    notifyListeners();
  }
}
