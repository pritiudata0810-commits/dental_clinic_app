import 'package:flutter/material.dart';
import '../../services/ai/ai_chat_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../common/app_button.dart';
import '../common/toast_notification.dart';

class AiConfigDialog extends StatefulWidget {
  const AiConfigDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const AiConfigDialog(),
    );
  }

  @override
  State<AiConfigDialog> createState() => _AiConfigDialogState();
}

class _AiConfigDialogState extends State<AiConfigDialog> {
  late TextEditingController _apiKeyController;
  late TextEditingController _baseUrlController;
  late TextEditingController _modelController;
  late TextEditingController _proxyUrlController;
  late bool _useProxy;
  late double _temperature;
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    final config = AiChatService.instance.config;
    _apiKeyController = TextEditingController(text: config.apiKey);
    _baseUrlController = TextEditingController(text: config.rawBaseUrl);
    _modelController = TextEditingController(text: config.model);
    _proxyUrlController = TextEditingController(text: config.proxyUrl);
    _useProxy = config.useProxy;
    _temperature = config.temperature;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    _proxyUrlController.dispose();
    super.dispose();
  }

  void _applyPreset(String name, String baseUrl, String model) {
    setState(() {
      _useProxy = false;
      _baseUrlController.text = baseUrl;
      _modelController.text = model;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title Bar
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.psychology_rounded, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('AI Assistant Configuration', style: AppTextStyles.h4),
                            Text(
                              'Connect to OpenAI, Groq, Gemini, or a custom backend proxy',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.borderLight, height: 28),

                  // Quick Presets
                  const Text('Quick Provider Presets:', style: AppTextStyles.label),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPresetChip('OpenAI (gpt-4o-mini)', 'https://api.openai.com/v1', 'gpt-4o-mini'),
                      _buildPresetChip('Groq Cloud (Fast)', 'https://api.groq.com/openai/v1', 'llama-3.3-70b-versatile'),
                      _buildPresetChip('Together AI', 'https://api.together.xyz/v1', 'meta-llama/Llama-3.3-70B-Instruct-Turbo'),
                      _buildPresetChip('Local LLM (Ollama)', 'http://localhost:11434/v1', 'llama3'),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // API Key Field
                  const Text('API Key', style: AppTextStyles.label),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _apiKeyController,
                    obscureText: _obscureKey,
                    decoration: InputDecoration(
                      hintText: 'sk-proj-... or gsk_...',
                      prefixIcon: const Icon(Icons.key_rounded, size: 18, color: AppColors.textSecondary),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureKey ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                        onPressed: () => setState(() => _obscureKey = !_obscureKey),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Stored safely in your current browser/session memory. Never committed to source code.',
                    style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.textSecondary),
                  ),

                  const SizedBox(height: 16),

                  // Base URL Field
                  const Text('API Base URL', style: AppTextStyles.label),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _baseUrlController,
                    decoration: InputDecoration(
                      hintText: 'https://api.openai.com/v1',
                      prefixIcon: const Icon(Icons.link_rounded, size: 18, color: AppColors.textSecondary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Model Name Field
                  const Text('Model Name', style: AppTextStyles.label),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _modelController,
                    decoration: InputDecoration(
                      hintText: 'gpt-4o-mini',
                      prefixIcon: const Icon(Icons.memory_rounded, size: 18, color: AppColors.textSecondary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Backend Proxy Toggle
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.dns_outlined, size: 18, color: AppColors.primary),
                                SizedBox(width: 8),
                                Text('Route through Backend Proxy', style: AppTextStyles.label),
                              ],
                            ),
                            Switch(
                              value: _useProxy,
                              activeColor: AppColors.primary,
                              onChanged: (v) => setState(() => _useProxy = v),
                            ),
                          ],
                        ),
                        if (_useProxy) ...[
                          const SizedBox(height: 8),
                          TextField(
                            controller: _proxyUrlController,
                            decoration: InputDecoration(
                              labelText: 'Proxy Endpoint URL',
                              hintText: 'http://localhost:3000/api/chat',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Forwards requests through server-side /api/chat keeping credentials off the client.',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      AppButton(
                        text: 'Save & Apply',
                        icon: Icons.check,
                        onPressed: () {
                          AiChatService.instance.config.update(
                            apiKey: _apiKeyController.text,
                            baseUrl: _baseUrlController.text,
                            model: _modelController.text,
                            temperature: _temperature,
                            useProxy: _useProxy,
                            proxyUrl: _proxyUrlController.text,
                          );
                          Navigator.of(context).pop();
                          AppFeedback.showSuccess(context, 'AI configuration applied successfully!');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, String baseUrl, String model) {
    final isSelected = _baseUrlController.text == baseUrl && _modelController.text == model;
    return InkWell(
      onTap: () => _applyPreset(label, baseUrl, model),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
