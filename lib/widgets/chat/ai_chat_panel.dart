import 'package:flutter/material.dart';
import '../../models/ai_chat_message.dart';
import '../../services/ai/ai_chat_service.dart';
import '../../state/clinic_scope.dart';
import '../../theme/app_colors.dart';
import 'ai_chat_bubble.dart';
import 'ai_config_dialog.dart';

/// Floating / Embedded AI Chatbot Panel integrating seamlessly into SmileCare OS.
class AiChatPanel extends StatefulWidget {
  final VoidCallback? onClose;

  const AiChatPanel({
    super.key,
    this.onClose,
  });

  @override
  State<AiChatPanel> createState() => _AiChatPanelState();
}

class _AiChatPanelState extends State<AiChatPanel> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  late final AiChatService _chatService;

  @override
  void initState() {
    super.initState();
    _chatService = AiChatService.instance;
    _chatService.addListener(_handleServiceUpdate);
  }

  @override
  void dispose() {
    _chatService.removeListener(_handleServiceUpdate);
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleServiceUpdate() {
    if (!mounted) return;
    setState(() {});
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty || _chatService.isLoading) return;

    final clinicState = context.clinic;
    _textController.clear();
    _chatService.sendMessage(text, clinicState: clinicState);
    _focusNode.requestFocus();
  }

  List<String> _getStarterPrompts(AiRoleMode mode) {
    switch (mode) {
      case AiRoleMode.receptionist:
        return [
          "Show today's appointments",
          "Who has not confirmed?",
          "Show pending payments",
          "Give me today's clinic summary",
          "Which doctor is available at 4 PM?",
          "Find patient named Rahul",
        ];
      case AiRoleMode.patient:
        return [
          "What is a root canal?",
          "What is plaque?",
          "What should I do after extraction?",
          "How should I prepare for my visit?",
          "Why do gums bleed during brushing?",
          "What happens during teeth cleaning?",
        ];
      case AiRoleMode.dentist:
        return [
          "Draft SOAP note for root canal access",
          "Post-op care instructions for surgical extraction",
          "Standard antibiotics for dental abscess",
          "Summarize multi-visit crown restoration",
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final clinic = context.clinic;
    final isUnconfigured = !_chatService.useLocalAssistant && !_chatService.isConfigured;

    return Container(
      width: 420,
      height: 600,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E1B4B).withValues(alpha: 0.18),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // 1. Header Bar with Mode Selector & Controls
            _buildHeaderBar(),

            // 2. Unconfigured Warning Banner (if no key)
            if (isUnconfigured) _buildUnconfiguredBanner(),

            // 3. Tool Execution Live Status Indicator
            if (_chatService.toolStatus != null) _buildToolStatusBanner(),

            // 4. Messages List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: _chatService.messages.length,
                itemBuilder: (context, index) {
                  final msg = _chatService.messages[index];
                  return AiChatBubble(
                    message: msg,
                    onRetry: () => _chatService.retryLastMessage(clinic),
                  );
                },
              ),
            ),

            // 5. Typing / Loading Indicator
            if (_chatService.isLoading && _chatService.toolStatus == null)
              _buildTypingIndicator(),

            // 6. Quick Starter Chips Carousel
            _buildStarterChipsSection(),

            // 7. Input Control Bar
            _buildInputSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5856D6), Color(0xFF8B85F8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 17),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'SmileCare AI Assistant',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
                DropdownButton<AiRoleMode>(
                  value: _chatService.activeRole,
                  isDense: true,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  icon: const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.primary),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                  onChanged: (mode) {
                    if (mode != null) _chatService.setRole(mode);
                  },
                  items: AiRoleMode.values.map((mode) {
                    return DropdownMenuItem(
                      value: mode,
                      child: Text(
                        mode.displayName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),

          // Header Action Buttons with compact constraints
          IconButton(
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: const EdgeInsets.all(6),
            icon: const Icon(Icons.settings_outlined, size: 18, color: AppColors.textSecondary),
            tooltip: 'Configure AI Provider & API Key',
            onPressed: () => AiConfigDialog.show(context),
          ),
          IconButton(
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: const EdgeInsets.all(6),
            icon: const Icon(Icons.add_comment_outlined, size: 18, color: AppColors.textSecondary),
            tooltip: 'New Conversation',
            onPressed: () => _chatService.newConversation(),
          ),
          if (widget.onClose != null)
            IconButton(
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: const EdgeInsets.all(6),
              icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
              tooltip: 'Close AI Panel',
              onPressed: widget.onClose,
            ),
        ],
      ),
    );
  }

  Widget _buildUnconfiguredBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFFEF3C7),
        border: Border(bottom: BorderSide(color: Color(0xFFFDE68A))),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFD97706)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'AI API key is not configured yet.',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
            ),
          ),
          InkWell(
            onTap: () => AiConfigDialog.show(context),
            child: const Text(
              'Configure Now',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFFB45309),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolStatusBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: const BoxDecoration(
        color: Color(0xFFEEEDFC),
        border: Border(bottom: BorderSide(color: Color(0xFFDDD8FC))),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF5856D6)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _chatService.toolStatus!,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF4C45B2)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(strokeWidth: 1.8, color: AppColors.primary),
                ),
                SizedBox(width: 8),
                Text(
                  'AI is thinking...',
                  style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarterChipsSection() {
    final chips = _getStarterPrompts(_chatService.activeRole);

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final prompt = chips[i];
          return ActionChip(
            label: Text(prompt),
            labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFCBD5E1)),
            elevation: 0,
            pressElevation: 1,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            onPressed: _chatService.isLoading
                ? null
                : () {
                    final clinic = context.clinic;
                    _chatService.sendMessage(prompt, clinicState: clinic);
                  },
          );
        },
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _handleSend(),
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: _chatService.activeRole == AiRoleMode.receptionist
                    ? "Ask about appointments, patients, billing..."
                    : "Ask about dental care, RCT, cleaning...",
                hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5856D6), Color(0xFF706BF0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5856D6).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
              onPressed: _chatService.isLoading ? null : _handleSend,
            ),
          ),
        ],
      ),
    );
  }
}
