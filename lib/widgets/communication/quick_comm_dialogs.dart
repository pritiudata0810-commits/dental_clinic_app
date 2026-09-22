import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../state/clinic_scope.dart';
import '../../models/communication.dart';
import '../common/app_button.dart';
import '../common/toast_notification.dart';

class QuickCommDialogs {
  // CALL MODAL
  static void showCallDialog(
    BuildContext context, {
    required String patientId,
    required String patientName,
    required String phoneNumber,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _CallModal(
        patientId: patientId,
        patientName: patientName,
        phoneNumber: phoneNumber,
      ),
    );
  }

  // SMS MODAL
  static void showSmsDialog(
    BuildContext context, {
    required String patientId,
    required String patientName,
    required String phoneNumber,
    String? defaultTemplate,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => _SmsModal(
        patientId: patientId,
        patientName: patientName,
        phoneNumber: phoneNumber,
        defaultTemplate: defaultTemplate,
      ),
    );
  }

  // WHATSAPP MODAL
  static void showWhatsAppDialog(
    BuildContext context, {
    required String patientId,
    required String patientName,
    required String phoneNumber,
    String? defaultTemplate,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => _WhatsAppModal(
        patientId: patientId,
        patientName: patientName,
        phoneNumber: phoneNumber,
        defaultTemplate: defaultTemplate,
      ),
    );
  }
}

class _CallModal extends StatefulWidget {
  final String patientId;
  final String patientName;
  final String phoneNumber;

  const _CallModal({
    required this.patientId,
    required this.patientName,
    required this.phoneNumber,
  });

  @override
  State<_CallModal> createState() => _CallModalState();
}

class _CallModalState extends State<_CallModal> {
  int _seconds = 0;
  Timer? _timer;
  bool _isConnected = false;
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Simulate call connecting after 1.5 seconds
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _isConnected = true);
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() => _seconds++);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _noteController.dispose();
    super.dispose();
  }

  String get _formattedDuration {
    final mins = _seconds ~/ 60;
    final secs = _seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _endCall() {
    _timer?.cancel();
    context.clinic.logCall(
      patientId: widget.patientId,
      patientName: widget.patientName,
      phoneNumber: widget.phoneNumber,
      direction: CallDirection.outgoing,
      status: _isConnected ? CallStatus.answered : CallStatus.missed,
      durationSeconds: _seconds,
      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
    );
    Navigator.of(context).pop();
    AppFeedback.showSuccess(context, 'Call logged for ${widget.patientName} ($_formattedDuration)');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _isConnected ? AppColors.callGreen.withOpacity(0.12) : AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.phone_in_talk_rounded,
                  size: 34,
                  color: _isConnected ? AppColors.callGreen : AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.patientName,
                style: AppTextStyles.h3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                widget.phoneNumber,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _isConnected ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isConnected ? 'Connected • $_formattedDuration' : 'Ringing...',
                  style: AppTextStyles.label.copyWith(
                    color: _isConnected ? const Color(0xFF047857) : const Color(0xFFB45309),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Call Notes (Optional)',
                  hintText: 'e.g., Patient confirmed arrival at 10 AM',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingActionButton.extended(
                    onPressed: _endCall,
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    icon: const Icon(Icons.call_end),
                    label: const Text('End Call & Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmsModal extends StatefulWidget {
  final String patientId;
  final String patientName;
  final String phoneNumber;
  final String? defaultTemplate;

  const _SmsModal({
    required this.patientId,
    required this.patientName,
    required this.phoneNumber,
    this.defaultTemplate,
  });

  @override
  State<_SmsModal> createState() => _SmsModalState();
}

class _SmsModalState extends State<_SmsModal> {
  late TextEditingController _controller;
  String _selectedCategory = 'Appointment Reminder';

  final Map<String, String> _templates = {
    'Appointment Reminder':
        'Dear {Patient}, reminder for your dental appointment at SmileCare Clinic today. Please arrive 10 min early.',
    'Payment Reminder':
        'SmileCare: Outstanding balance payment reminder of ₹1,500. Kindly settle via UPI or at reception.',
    'Follow-up':
        'Dear {Patient}, how is your recovery following your dental visit? Please call SmileCare for any discomfort.',
    'Custom': '',
  };

  @override
  void initState() {
    super.initState();
    final initial = widget.defaultTemplate ??
        _templates['Appointment Reminder']!.replaceAll('{Patient}', widget.patientName);
    _controller = TextEditingController(text: initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onCategoryChanged(String? category) {
    if (category != null) {
      setState(() {
        _selectedCategory = category;
        if (category != 'Custom') {
          _controller.text = _templates[category]!.replaceAll('{Patient}', widget.patientName);
        }
      });
    }
  }

  void _sendSms() {
    if (_controller.text.trim().isEmpty) return;
    context.clinic.logMessage(
      patientId: widget.patientId,
      patientName: widget.patientName,
      phoneNumber: widget.phoneNumber,
      channel: MessageChannel.sms,
      message: _controller.text.trim(),
      templateCategory: _selectedCategory,
    );
    Navigator.of(context).pop();
    AppFeedback.showSuccess(context, 'SMS sent successfully to ${widget.patientName}');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.sms_outlined, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Send SMS Message', style: AppTextStyles.h4),
                        Text('To: ${widget.patientName} (${widget.phoneNumber})',
                            style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Template Category'),
                items: _templates.keys.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: _onCategoryChanged,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Message Body',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${_controller.text.length} characters (1 SMS credit)',
                  style: AppTextStyles.caption,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton.ghost(
                    text: 'Cancel',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  AppButton(
                    text: 'Send SMS',
                    icon: Icons.send_rounded,
                    onPressed: _sendSms,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WhatsAppModal extends StatefulWidget {
  final String patientId;
  final String patientName;
  final String phoneNumber;
  final String? defaultTemplate;

  const _WhatsAppModal({
    required this.patientId,
    required this.patientName,
    required this.phoneNumber,
    this.defaultTemplate,
  });

  @override
  State<_WhatsAppModal> createState() => _WhatsAppModalState();
}

class _WhatsAppModalState extends State<_WhatsAppModal> {
  late TextEditingController _controller;
  String _selectedCategory = 'Appointment Reminder';

  final Map<String, String> _templates = {
    'Appointment Reminder':
        'Hello {Patient} 👋\n\nThis is a gentle reminder for your dental consultation at *SmileCare Dental Clinic* scheduled today.\n\n📍 Operatory Wing B\n⏱️ Please report 10 minutes prior.\n\nNeed to reschedule? Reply to this message directly.',
    'Follow-up':
        'Hello {Patient} 👋\n\nDr. Rahul Sharma and the team at *SmileCare Clinic* hope you are recovering well after your visit. Remember to follow prescribed post-op oral care guidelines. Contact us if you have any questions!',
    'Payment Reminder':
        'Dear {Patient} 👋\n\nYour digital invoice is ready from *SmileCare Dental Clinic*. Pending balance: *₹1,500*.\n\nYou can pay directly via UPI at reception or online.',
    'Custom': '',
  };

  @override
  void initState() {
    super.initState();
    final initial = widget.defaultTemplate ??
        _templates['Appointment Reminder']!.replaceAll('{Patient}', widget.patientName);
    _controller = TextEditingController(text: initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onCategoryChanged(String? category) {
    if (category != null) {
      setState(() {
        _selectedCategory = category;
        if (category != 'Custom') {
          _controller.text = _templates[category]!.replaceAll('{Patient}', widget.patientName);
        }
      });
    }
  }

  void _sendWhatsApp() {
    if (_controller.text.trim().isEmpty) return;
    context.clinic.logMessage(
      patientId: widget.patientId,
      patientName: widget.patientName,
      phoneNumber: widget.phoneNumber,
      channel: MessageChannel.whatsapp,
      message: _controller.text.trim(),
      templateCategory: _selectedCategory,
    );
    Navigator.of(context).pop();
    AppFeedback.showSuccess(context, 'WhatsApp notification sent to ${widget.patientName}');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.chat_bubble_outline, color: Color(0xFF16A34A), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('WhatsApp Patient Notification', style: AppTextStyles.h4),
                        Text('Patient: ${widget.patientName} • ${widget.phoneNumber}',
                            style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Notification Template'),
                items: _templates.keys.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: _onCategoryChanged,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFEAE2), // WhatsApp chat bubble bg look
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: 5,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    fillColor: Colors.white,
                    filled: true,
                    hintText: 'Type your message...',
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton.ghost(
                    text: 'Cancel',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  AppButton.success(
                    text: 'Send on WhatsApp',
                    icon: Icons.send,
                    onPressed: _sendWhatsApp,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
