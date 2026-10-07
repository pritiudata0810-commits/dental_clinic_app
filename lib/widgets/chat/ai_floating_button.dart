import 'package:flutter/material.dart';
import 'ai_chat_panel.dart';

/// Floating AI Chatbot overlay widget that can be placed in any application shell.
class AiFloatingChatbot extends StatefulWidget {
  const AiFloatingChatbot({super.key});

  @override
  State<AiFloatingChatbot> createState() => _AiFloatingChatbotState();
}

class _AiFloatingChatbotState extends State<AiFloatingChatbot> {
  bool _isOpen = false;

  void _toggleChat() {
    setState(() => _isOpen = !_isOpen);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Stack(
      children: [
        // 1. Floating Chat Panel when Open
        if (_isOpen)
          Positioned(
            right: isMobile ? 12 : 24,
            bottom: isMobile ? 12 : 84,
            left: isMobile ? 12 : null,
            child: Material(
              color: Colors.transparent,
              child: AiChatPanel(
                onClose: () => setState(() => _isOpen = false),
              ),
            ),
          ),

        // 2. Floating Action Button Launcher
        if (!_isOpen || !isMobile)
          Positioned(
            right: 24,
            bottom: 24,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _toggleChat,
                borderRadius: BorderRadius.circular(30),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5856D6), Color(0xFF706BF0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5856D6).withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isOpen ? Icons.keyboard_arrow_down_rounded : Icons.auto_awesome,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isOpen ? 'Close AI' : 'Ask AI Assistant',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
